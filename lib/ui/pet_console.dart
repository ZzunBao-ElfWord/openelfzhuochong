import 'package:flutter/material.dart';

import '../adapters/pet_adapter_factory.dart';
import '../core/capability_matrix.dart';
import '../core/pet_app_launcher.dart';
import '../core/pet_asset.dart';
import '../core/pet_controller.dart';
import '../core/pet_settings.dart';
import '../core/pet_state.dart';
import '../core/pet_theme.dart';
import '../core/pet_wake.dart';
import 'pet_view.dart';
import 'widgets.dart';

/// 共享控制台面板：桌面端「设置面板」与移动端主页复用同一实现，
/// 差异只由 [bundle.kind] 驱动（端专属区块按需出现）。
class PetConsolePanel extends StatelessWidget {
  const PetConsolePanel({
    super.key,
    required this.controller,
    required this.bundle,
    required this.settings,
    required this.assets,
    required this.onSettingsChanged,
    this.onClose,
  });

  final PetController controller;
  final PetPlatformBundle bundle;
  final PetSettings settings;
  final PetAssetPackage? assets;
  final ValueChanged<PetSettings> onSettingsChanged;
  final VoidCallback? onClose;

  DeviceKind get kind => bundle.kind;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (BuildContext context, Widget? _) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            if (onClose != null)
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close),
                  tooltip: '收起为宠物窗',
                ),
              ),
            _petCard(),
            const SizedBox(height: 12),
            _capabilityCard(),
            const SizedBox(height: 12),
            _settingsCard(),
            const SizedBox(height: 12),
            if (kind == DeviceKind.windows || kind == DeviceKind.macos)
              _desktopCard(),
            if (kind == DeviceKind.android) ...<Widget>[
              _androidCard(context),
              const SizedBox(height: 12),
            ],
            if (kind == DeviceKind.ios) ...<Widget>[
              _iosCard(),
              const SizedBox(height: 12),
            ],
            _launcherCard(context),
            const SizedBox(height: 12),
            _assetCard(),
            const SizedBox(height: 12),
            _historyCard(),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  // ---------- 1. 宠物与互动 ----------
  Widget _petCard() {
    return SectionCard(
      title: '宠物与互动',
      subtitle: '常驻 → 唤起 → 发声 → 状态回写',
      child: Column(
        children: <Widget>[
          SizedBox(height: 34, child: Center(child: SpeechBubble(
            text: controller.bubble.isEmpty ? kLineOf(controller.state) : controller.bubble,
            visible: controller.bubble.isNotEmpty,
          ))),
          const SizedBox(height: 10),
          PetAvatar(state: controller.state, character: controller.character, size: 128),
          const SizedBox(height: 10),
          PetWaveform(speaking: controller.speaking),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              StatePill(meta: controller.meta),
              const SizedBox(width: 8),
              if (controller.busy)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: <Widget>[
              FilledButton.icon(
                onPressed: controller.busy
                    ? null
                    : () => controller.wake(WakeTrigger.tap),
                icon: const Icon(Icons.notifications_active, size: 18),
                label: const Text('唤起'),
              ),
              OutlinedButton.icon(
                onPressed: controller.busy ? null : controller.feed,
                icon: const Icon(Icons.set_meal, size: 18),
                label: const Text('投喂'),
              ),
              OutlinedButton.icon(
                onPressed: controller.nap,
                icon: const Icon(Icons.bedtime, size: 18),
                label: const Text('打盹'),
              ),
              OutlinedButton.icon(
                onPressed: controller.charge,
                icon: const Icon(Icons.battery_charging_full, size: 18),
                label: const Text('充电'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('状态机演示',
                style: TextStyle(fontSize: 12, color: PetTokens.textSub)),
          ),
          const SizedBox(height: 8),
          StateSelector(
            current: controller.state,
            onSelect: controller.select,
          ),
        ],
      ),
    );
  }

  // ---------- 2. 平台能力 ----------
  Widget _capabilityCard() {
    final PlatformCapability? cap = bundle.capability;
    return SectionCard(
      title: '平台能力与降级',
      subtitle: '${kind.label} · 业务按能力声明降级',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (cap != null)
            InfoTable(rows: <List<String>>[
              <String>['常驻形态', cap.form],
              <String>['唤起方式', cap.triggers],
              <String>['就地互动', cap.inPlace ? '支持' : '不支持（跳转 App）'],
              <String>['声音能力', cap.sound],
              <String>['语音热词', cap.hotword],
              <String>['主要限制', cap.limits],
            ]),
          const SizedBox(height: 10),
          NoticeBar(text: controller.capabilities.degradationNote),
          const SizedBox(height: 10),
          TriggerChips(capabilities: controller.capabilities),
        ],
      ),
    );
  }

  // ---------- 3. 设置 ----------
  Widget _settingsCard() {
    return SectionCard(
      title: '设置',
      subtitle: '与状态、台词一同本地存储，联网能力默认关闭',
      child: Column(
        children: <Widget>[
          SwitchRow(
            label: '声音开关',
            subtitle: '关闭后唤起仅保留视觉反馈',
            value: settings.sound,
            onChanged: (bool v) =>
                onSettingsChanged(settings.copyWith(sound: v)),
          ),
          SwitchRow(
            label: '语音热词',
            subtitle: controller.capabilities.voiceHotword
                ? '需麦克风授权，作为可选增强'
                : '本端默认关闭（政策/权限受限）',
            value: settings.hotword,
            disabled: !controller.capabilities.voiceHotword,
            onChanged: (bool v) =>
                onSettingsChanged(settings.copyWith(hotword: v)),
          ),
          SwitchRow(
            label: '点击穿透',
            subtitle: '让点击落到下层窗口（悬浮/置顶窗休眠时）',
            value: settings.clickThrough,
            onChanged: (bool v) {
              onSettingsChanged(settings.copyWith(clickThrough: v));
              bundle.desktop?.setClickThrough(v);
            },
          ),
          SwitchRow(
            label: '开机自启',
            subtitle: '桌面端随系统启动常驻',
            value: settings.autoStart,
            disabled: !kind.isDesktop,
            onChanged: (bool v) =>
                onSettingsChanged(settings.copyWith(autoStart: v)),
          ),
          SwitchRow(
            label: '联网 TTS',
            subtitle: '远端语音合成，需授权；关闭时使用本地 TTS',
            value: settings.remoteTts,
            onChanged: (bool v) =>
                onSettingsChanged(settings.copyWith(remoteTts: v)),
          ),
        ],
      ),
    );
  }

  // ---------- 4a. 桌面端 ----------
  Widget _desktopCard() {
    return SectionCard(
      title: '桌面端常驻载体',
      subtitle: '透明置顶窗口 + ${kind == DeviceKind.macos ? '菜单栏' : '系统托盘'}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('唤起次数：${bundle.desktop?.wakeCount ?? 0}',
              style:
                  const TextStyle(fontSize: 12.5, color: PetTokens.textSub)),
          const SizedBox(height: 8),
          const NoticeBar(
            text: '托盘/菜单栏提供 唤起、投喂、打盹、点击穿透、设置面板 入口；'
                '全局热键 Ctrl/Cmd+Alt+P 可唤起。',
          ),
        ],
      ),
    );
  }

  // ---------- 4b. Android ----------
  Widget _androidCard(BuildContext context) {
    return SectionCard(
      title: 'Android 悬浮窗与保活',
      subtitle: '权限引导 + 前台服务 + 厂商白名单',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              FilledButton.icon(
                onPressed: () => _requestOverlay(context),
                icon: const Icon(Icons.layers, size: 18),
                label: const Text('授权悬浮窗'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => bundle.android?.showOverlay(),
                icon: const Icon(Icons.push_pin, size: 18),
                label: const Text('开启悬浮'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => bundle.android?.closeOverlay(),
                icon: const Icon(Icons.close_fullscreen, size: 18),
                label: const Text('关闭悬浮'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const NoticeBar(
            kind: NoticeKind.warn,
            text: '需 SYSTEM_ALERT_WINDOW 权限与前台服务；Android 11+ 后台麦克风受限、'
                'Android 14+ 需声明前台服务类型。语音热词默认关闭。',
          ),
          const SizedBox(height: 12),
          const Text('厂商后台白名单引导',
              style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: PetTokens.textSub)),
          const SizedBox(height: 6),
          ...kVendorGuides.map((VendorGuide g) => Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: const EdgeInsets.only(left: 4, bottom: 8),
                  title: Text(g.vendor,
                      style: const TextStyle(
                          fontSize: 12.5, color: PetTokens.text)),
                  children: g.steps
                      .map((String s) => Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text('· $s',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: PetTokens.textSub,
                                      height: 1.4)),
                            ),
                          ))
                      .toList(),
                ),
              )),
        ],
      ),
    );
  }

  Future<void> _requestOverlay(BuildContext context) async {
    final bool ok = await (bundle.android?.ensurePermission() ?? Future<bool>.value(false));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok ? '悬浮窗权限已授予，可开启悬浮宠物' : '未授予悬浮窗权限，将降级为 App 前台互动'),
    ));
  }

  // ---------- 4c. iOS ----------
  Widget _iosCard() {
    return SectionCard(
      title: 'iOS 灵动岛与锁屏卡片',
      subtitle: '跳转式：岛仅展示与入口，互动在 App 前台',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ...kIslandForms.map((IslandForm f) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: <Widget>[
                    _islandPreview(f.key),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text('${f.label} · ${f.size}',
                              style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: PetTokens.text)),
                          Text(f.note,
                              style: const TextStyle(
                                  fontSize: 11.5,
                                  color: PetTokens.textSub,
                                  height: 1.4)),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 4),
          Row(
            children: <Widget>[
              FilledButton.icon(
                onPressed: () => bundle.ios?.renew(),
                icon: const Icon(Icons.autorenew, size: 18),
                label: const Text('续期实时活动'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          NoticeBar(
            kind: NoticeKind.warn,
            text: '实时活动活跃期上限 ${LiveActivityLimits.activeHours} 小时，'
                '锁屏最多再保留 ${LiveActivityLimits.lockScreenExtraHours} 小时；'
                '本端已按 ${LiveActivityLimits.renewInterval.inHours} 小时定时重启续期。'
                '更新按秒级节流，避免刷新限流。素材须小尺寸，否则活动无法启动。',
          ),
          const SizedBox(height: 8),
          NoticeBar(
            text: '实时活动状态：${bundle.ios?.activityRunning ?? false ? '运行中' : '未启动'}',
          ),
        ],
      ),
    );
  }

  Widget _islandPreview(String key) {
    final (double w, double h) = switch (key) {
      'minimal' => (46, 18),
      'compact' => (78, 20),
      _ => (96, 44),
    };
    return Container(
      width: 108,
      alignment: Alignment.centerLeft,
      child: Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(PetTokens.radiusPill),
        ),
        child: key == 'expanded'
            ? const Padding(
                padding: EdgeInsets.all(6),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('我在呢…',
                      style: TextStyle(fontSize: 9, color: Colors.white)),
                ),
              )
            : Center(
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                      color: PetTokens.primary, shape: BoxShape.circle),
                ),
              ),
      ),
    );
  }

  // ---------- 5. 目标应用 ----------
  Widget _launcherCard(BuildContext context) {
    return SectionCard(
      title: '唤起其他应用',
      subtitle: '可选扩展 · ${bundle.launcher.capabilityNote}',
      trailing: bundle.launcher.canEnumerateTargets
          ? TextButton(
              onPressed: () => _loadTargets(context),
              child: const Text('枚举'),
            )
          : null,
      child: _LauncherList(bundle: bundle),
    );
  }

  Future<void> _loadTargets(BuildContext context) async {
    final List<AppTarget> targets = await bundle.launcher.listTargets();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('枚举到 ${targets.length} 个可唤起目标')),
    );
  }

  // ---------- 6. 素材 ----------
  Widget _assetCard() {
    final PetAssetPackage? pkg = assets;
    final List<String> issues = pkg?.validate() ?? <String>['素材包未加载'];
    return SectionCard(
      title: '素材与状态配置',
      subtitle: 'pet_asset.json · 四端共享',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (issues.isEmpty)
            const NoticeBar(text: '素材包校验通过：五个状态齐备，可用于四端渲染。')
          else
            NoticeBar(
              kind: NoticeKind.error,
              text: '素材问题：${issues.join('；')}',
            ),
          const SizedBox(height: 10),
          ...kPetStates.map((PetStateMeta m) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SizedBox(
                      width: 56,
                      child: Text(pkg?.textOf(m.state) ?? kLineOf(m.state),
                          style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: PetTokens.text)),
                    ),
                    Expanded(
                      child: Text('${m.animation} · ${m.asset}',
                          style: const TextStyle(
                              fontSize: 12,
                              color: PetTokens.textSub,
                              height: 1.4)),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  // ---------- 7. 唤起记录 ----------
  Widget _historyCard() {
    final List<WakeResult> history = controller.history;
    return SectionCard(
      title: '唤起记录',
      subtitle: '最新在前 · 共 ${history.length} 条',
      child: history.isEmpty
          ? const Text('暂无记录，点击「唤起」体验完整闭环。',
              style: TextStyle(fontSize: 12.5, color: PetTokens.textSub))
          : Column(
              children: history.map((WakeResult r) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: PetTokens.secondarySoft,
                          borderRadius:
                              BorderRadius.circular(PetTokens.radiusPill),
                        ),
                        child: Text(r.trigger.label,
                            style: const TextStyle(
                                fontSize: 11, color: PetTokens.secondary)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          r.inPlace ? '就地发声 + 状态回写' : '打开 App 并前台发声',
                          style: const TextStyle(
                              fontSize: 12, color: PetTokens.textSub),
                        ),
                      ),
                      if (r.appOpened)
                        const Icon(Icons.open_in_new,
                            size: 13, color: PetTokens.textMute),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }
}

/// 目标应用列表：进入页面时按能力加载（iOS 为预配置）。
class _LauncherList extends StatelessWidget {
  const _LauncherList({required this.bundle});

  final PetPlatformBundle bundle;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<AppTarget>>(
      future: bundle.launcher.listTargets(),
      builder: (BuildContext context, AsyncSnapshot<List<AppTarget>> snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: LinearProgressIndicator(minHeight: 3),
          );
        }
        final List<AppTarget> targets = snap.data ?? const <AppTarget>[];
        if (targets.isEmpty) {
          return const Text('无可唤起目标（iOS 仅支持预配置 Scheme 目标）。',
              style: TextStyle(fontSize: 12.5, color: PetTokens.textSub));
        }
        return Column(
          children: targets.take(6).map((AppTarget t) {
            return ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.apps, size: 18),
              title: Text(t.name, style: const TextStyle(fontSize: 13)),
              subtitle: Text(t.id,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11)),
              trailing: const Icon(Icons.arrow_outward, size: 16),
              onTap: () => bundle.launcher.launch(t),
            );
          }).toList(),
        );
      },
    );
  }
}
