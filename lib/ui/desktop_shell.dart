import 'package:flutter/material.dart';

import '../adapters/pet_adapter_factory.dart';
import '../core/pet_asset.dart';
import '../core/pet_character.dart';
import '../core/pet_controller.dart';
import '../core/pet_settings.dart';
import '../core/pet_state.dart';
import '../core/pet_theme.dart';
import '../core/pet_wake.dart';
import 'pet_console.dart';
import 'pet_home.dart';
import 'pet_view.dart';

/// 桌面端外壳：同一窗口内两种形态。
/// - 紧凑态：透明、无边框、置顶的宠物窗（常驻载体，只放宠物 + 几个动作按钮）
/// - 面板态：萌宠主页（选择宠物、互动、权限引导），可再进入高级设置
class DesktopShell extends StatefulWidget {
  const DesktopShell({
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
  State<DesktopShell> createState() => _DesktopShellState();
}

enum _PanelView { home, console }

class _DesktopShellState extends State<DesktopShell> {
  bool _panel = false;
  _PanelView _view = _PanelView.home;
  bool _hover = false;
  DateTime? _lastHover;

  Future<void> _setPanel(bool value) async {
    setState(() {
      _panel = value;
      if (!value) _view = _PanelView.home;
    });
    await widget.bundle.desktop?.setPanelMode(value);
  }

  /// 悬停唤起：节流 30 秒，避免频繁打扰。
  void _onHover() {
    if (!widget.controller.capabilities.availableTriggers
        .contains(WakeTrigger.hover)) {
      return;
    }
    final DateTime now = DateTime.now();
    final DateTime? last = _lastHover;
    if (last != null && now.difference(last) < const Duration(seconds: 30)) {
      return;
    }
    _lastHover = now;
    widget.controller.wake(WakeTrigger.hover);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _panel ? PetTokens.bg : Colors.transparent,
      body: _panel ? _panelView() : _compact(),
    );
  }

  Widget _panelView() {
    return _view == _PanelView.home
        ? Stack(
            children: <Widget>[
              PetHomeBody(
                controller: widget.controller,
                bundle: widget.bundle,
                settings: widget.settings,
                onSettingsChanged: widget.onSettingsChanged,
                onOpenSettings: () => setState(() => _view = _PanelView.console),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  onPressed: () => _setPanel(false),
                  tooltip: '收起为宠物窗',
                  icon: const Icon(Icons.close, size: 20),
                ),
              ),
            ],
          )
        : PetConsolePanel(
            controller: widget.controller,
            bundle: widget.bundle,
            settings: widget.settings,
            assets: widget.assets,
            onSettingsChanged: widget.onSettingsChanged,
            onClose: () => setState(() => _view = _PanelView.home),
          );
  }

  Widget _compact() {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (BuildContext context, Widget? _) {
        final PetCharacter c = widget.controller.character;
        return MouseRegion(
          onEnter: (_) {
            setState(() => _hover = true);
            _onHover();
          },
          onExit: (_) => setState(() => _hover = false),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => widget.controller.wake(WakeTrigger.tap),
            onPanStart: (_) => widget.bundle.desktop?.startWindowDrag(),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  SpeechBubble(
                    text: widget.controller.bubble.isEmpty
                        ? c.lineOf(widget.controller.state)
                        : widget.controller.bubble,
                    visible: widget.controller.bubble.isNotEmpty ||
                        widget.controller.state != PetState.idle,
                    maxWidth: 170,
                  ),
                  const SizedBox(height: 8),
                  AnimatedScale(
                    scale: _hover ? 1.06 : 1,
                    duration: PetTokens.fast,
                    child: PetAvatar(
                      state: widget.controller.state,
                      character: c,
                      size: 104,
                    ),
                  ),
                  const SizedBox(height: 6),
                  PetWaveform(speaking: widget.controller.speaking, height: 16),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      _miniButton(Icons.notifications_active, PetTokens.primary,
                          () => widget.controller.wake(WakeTrigger.tap)),
                      _miniButton(Icons.set_meal, PetTokens.warning,
                          widget.controller.feed),
                      _miniButton(Icons.bedtime, PetTokens.secondary,
                          widget.controller.nap),
                      _miniButton(Icons.battery_charging_full, PetTokens.success,
                          widget.controller.charge),
                      const SizedBox(width: 2),
                      _miniButton(Icons.tune, PetTokens.textSub,
                          () => _setPanel(true), size: 18),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _miniButton(IconData icon, Color color, VoidCallback onTap,
      {double size = 20}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: InkResponse(
        onTap: onTap,
        radius: 18,
        child: Icon(icon, size: size, color: color),
      ),
    );
  }
}
