import 'package:flutter/material.dart';

import '../adapters/pet_adapter_factory.dart';
import '../core/capability_matrix.dart';
import '../core/pet_theme.dart';

/// 权限与常驻引导：告诉用户「开了什么，宠物才能陪着你」，并给出一键开启。
///
/// 采用友好的清单式引导，而不是生硬的权限弹窗：
/// - 每条都有图标 + 标题 + 一句说明 + 动作按钮
/// - 已完成的用对勾高亮，未完成的用强调色按钮
/// - 所有动作都走平台适配器，失败时给出 Snackbar 提示
class PermissionGuideCard extends StatefulWidget {
  const PermissionGuideCard({super.key, required this.bundle});

  final PetPlatformBundle bundle;

  @override
  State<PermissionGuideCard> createState() => _PermissionGuideCardState();
}

class _PermissionGuideCardState extends State<PermissionGuideCard> {
  bool _overlayGranted = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    if (widget.bundle.android != null) {
      final bool granted = await _isOverlayGranted();
      if (!mounted) return;
      setState(() => _overlayGranted = granted);
    }
  }

  Future<bool> _isOverlayGranted() async {
    try {
      return await widget.bundle.android?.isPermissionGranted() ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> _requestOverlay() async {
    final bool ok =
        await (widget.bundle.android?.ensurePermission() ?? Future<bool>.value(false));
    if (!mounted) return;
    setState(() => _overlayGranted = ok);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok ? '悬浮窗权限已开启，宠物可以常驻桌面啦' : '还没授权喔，开启后宠物才能陪你'),
    ));
    if (ok) {
      await widget.bundle.android?.showOverlay();
    }
  }

  Future<void> _startLiveActivity() async {
    await widget.bundle.ios?.renew();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('已启动实时活动，去灵动岛看看吧'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final DeviceKind kind = widget.bundle.kind;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PetTokens.surface,
        borderRadius: BorderRadius.circular(PetTokens.radiusMd),
        border: Border.all(color: PetTokens.border),
        boxShadow: PetTokens.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.pets, size: 18, color: PetTokens.primary),
              const SizedBox(width: 8),
              const Text('让宠物陪着你',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: PetTokens.text)),
            ],
          ),
          const SizedBox(height: 4),
          Text('按下面几步开启，宠物就能常驻在你身边',
              style:
                  const TextStyle(fontSize: 12, color: PetTokens.textSub)),
          const SizedBox(height: 14),
          ..._items(kind),
        ],
      ),
    );
  }

  List<Widget> _items(DeviceKind kind) {
    return switch (kind) {
      DeviceKind.android => <Widget>[
          _Step(
            icon: Icons.layers_outlined,
            title: '开启悬浮窗权限',
            hint: '允许宠物显示在其他应用上层',
            done: _overlayGranted,
            actionLabel: '去开启',
            onAction: _requestOverlay,
          ),
          _Step(
            icon: Icons.push_pin_outlined,
            title: '启动常驻悬浮宠物',
            hint: '开启后宠物浮在屏幕上，可拖拽',
            done: widget.bundle.android?.overlayActive ?? false,
            actionLabel: '开启悬浮',
            onAction: () => widget.bundle.android?.showOverlay(),
            enabled: _overlayGranted,
          ),
          _Hint(text: '部分厂商需在系统设置里给后台白名单，否则宠物会被系统清理'),
        ],
      DeviceKind.ios => <Widget>[
          _Step(
            icon: Icons.circle_outlined,
            title: '允许实时活动',
            hint: '系统设置 → 宠物 → 实时活动，打开即可',
            done: true,
            actionLabel: '我知道了',
            onAction: () {},
          ),
          _Step(
            icon: Icons.bolt_outlined,
            title: '启动灵动岛宠物',
            hint: '宠物会出现在灵动岛与锁屏卡片上',
            done: false,
            actionLabel: '启动',
            onAction: _startLiveActivity,
          ),
        ],
      DeviceKind.windows || DeviceKind.macos => <Widget>[
          _Step(
            icon: Icons.ads_click,
            title: '允许点击穿透（可选）',
            hint: '宠物休眠时，点击直接落到下层窗口',
            done: false,
            actionLabel: '开启',
            onAction: () => widget.bundle.desktop?.setClickThrough(true),
          ),
          _Step(
            icon: Icons.login,
            title: '开机自启（推荐）',
            hint: '电脑开机宠物自动出现',
            done: false,
            actionLabel: '开启',
            onAction: () {},
          ),
          _Hint(text: '全局热键 Ctrl/Cmd + Alt + P 可随时唤起宠物'),
        ],
      DeviceKind.unknown => <Widget>[
          const _Hint(text: '当前为预览环境，桌面常驻能力未启用。'),
        ],
    };
  }
}

/// 一条引导项。
class _Step extends StatelessWidget {
  const _Step({
    required this.icon,
    required this.title,
    required this.hint,
    required this.done,
    required this.actionLabel,
    required this.onAction,
    this.enabled = true,
  });

  final IconData icon;
  final String title;
  final String hint;
  final bool done;
  final String actionLabel;
  final VoidCallback onAction;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: <Widget>[
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: done ? PetTokens.successSoft : PetTokens.primarySoft,
              shape: BoxShape.circle,
            ),
            child: Icon(
              done ? Icons.check : icon,
              size: 18,
              color: done ? PetTokens.success : PetTokens.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: PetTokens.text)),
                const SizedBox(height: 1),
                Text(hint,
                    style: const TextStyle(
                        fontSize: 11.5,
                        color: PetTokens.textSub,
                        height: 1.35)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 32,
            child: done
                ? const Icon(Icons.check_circle,
                    color: PetTokens.success, size: 22)
                : TextButton(
                    onPressed: enabled ? onAction : null,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      backgroundColor: PetTokens.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(PetTokens.radiusPill),
                      ),
                    ),
                    child: Text(actionLabel,
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
          ),
        ],
      ),
    );
  }
}

/// 次要提示文字。
class _Hint extends StatelessWidget {
  const _Hint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(Icons.info_outline,
              size: 14, color: PetTokens.textMute),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 11.5,
                    color: PetTokens.textMute,
                    height: 1.4)),
          ),
        ],
      ),
    );
  }
}
