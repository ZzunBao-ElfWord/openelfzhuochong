import 'package:flutter/material.dart';

import '../adapters/pet_adapter_factory.dart';
import '../core/capability_matrix.dart';
import '../core/pet_asset.dart';
import '../core/pet_controller.dart';
import '../core/pet_settings.dart';
import '../core/pet_theme.dart';
import 'pet_console.dart';
import 'pet_home.dart';

/// 移动端主界面（Android / iOS）。
///
/// 主页 = 萌宠主页体（选择 + 互动 + 权限引导），高级设置收进二级。
class MobileHome extends StatefulWidget {
  const MobileHome({
    super.key,
    required this.controller,
    required this.bundle,
    required this.settings,
    required this.assets,
    required this.onSettingsChanged,
  });

  final PetController controller;
  final PetPlatformBundle bundle;
  final PetSettings settings;
  final PetAssetPackage? assets;
  final ValueChanged<PetSettings> onSettingsChanged;

  @override
  State<MobileHome> createState() => _MobileHomeState();
}

class _MobileHomeState extends State<MobileHome> {
  bool _console = false;

  @override
  Widget build(BuildContext context) {
    final DeviceKind kind = widget.bundle.kind;
    final String subtitle = switch (kind) {
      DeviceKind.android => '全局悬浮窗常驻 · 就地互动',
      DeviceKind.ios => '灵动岛与锁屏卡片 · 点按打开 App',
      _ => '移动端预览',
    };

    return Scaffold(
      backgroundColor: PetTokens.bg,
      appBar: AppBar(
        backgroundColor: PetTokens.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text('PetWake 桌宠',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: PetTokens.text)),
            Text(subtitle,
                style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w400,
                    color: PetTokens.textSub)),
          ],
        ),
        actions: <Widget>[
          IconButton(
            onPressed: () => setState(() => _console = !_console),
            tooltip: '更多设置',
            icon: const Icon(Icons.settings, color: PetTokens.textSub),
          ),
        ],
      ),
      body: _console
          ? PetConsolePanel(
              controller: widget.controller,
              bundle: widget.bundle,
              settings: widget.settings,
              assets: widget.assets,
              onSettingsChanged: widget.onSettingsChanged,
              onClose: () => setState(() => _console = false),
            )
          : PetHomeBody(
              controller: widget.controller,
              bundle: widget.bundle,
              settings: widget.settings,
              onSettingsChanged: widget.onSettingsChanged,
            ),
    );
  }
}
