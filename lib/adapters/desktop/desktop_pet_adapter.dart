// tray_manager 的 0.5.x 兼容 API（Menu / MenuItem / TrayListener）已标注
// deprecated，但仍为官方支持的桥接层；此处统一忽略该提示。
// ignore_for_file: deprecated_member_use

import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:tray_manager/legacy.dart';
import 'package:window_manager/window_manager.dart';

import '../../core/pet_state.dart';
import '../../core/pet_theme.dart';
import '../../core/pet_wake.dart';

/// Windows / macOS 适配器：透明无边框置顶窗口 + 系统托盘 / 菜单栏。
///
/// 就地式互动：宠物窗口内即可完成唤起与发声，无需离开当前场景。
class DesktopPetAdapter with TrayListener, WindowListener implements PetWake {
  DesktopPetAdapter({
    this.trayIconPath = 'assets/pets/tray_icon.png',
    this.hotkeyEnabled = true,
  });

  final String trayIconPath;

  /// 全局热键开关（设置项）。
  bool hotkeyEnabled;

  PetWakeHandler? _handler;
  bool _clickThrough = false;
  int _wakeCount = 0;

  @override
  PetWakeCapabilities get capabilities => const PetWakeCapabilities(
        inPlaceInteraction: true,
        voiceHotword: true,
        soundOnWake: true,
      );

  /// 累计唤起次数（托盘提示展示用）。
  int get wakeCount => _wakeCount;

  bool get clickThrough => _clickThrough;

  @override
  Future<void> init(PetWakeHandler handler) async {
    _handler = handler;

    // 1. 透明、无边框、置顶、不进任务栏的宠物窗口。
    await windowManager.ensureInitialized();
    const WindowOptions options = WindowOptions(
      size: PetTokens.compactWindow,
      backgroundColor: Colors.transparent,
      skipTaskbar: true,
      titleBarStyle: TitleBarStyle.hidden,
      alwaysOnTop: true,
      title: 'PetWake',
    );
    await windowManager.waitUntilReadyToShow(options, () async {
      await windowManager.setAsFrameless();
      await windowManager.setAlwaysOnTop(true);
      await windowManager.setSkipTaskbar(true);
      await windowManager.setIgnoreMouseEvents(false);
      await windowManager.show();
    });
    windowManager.addListener(this);

    // 2. 系统托盘（Windows） / 菜单栏（macOS）。
    await _setupTray();

    // 3. 全局热键（Ctrl/Cmd + Alt + P）。
    if (hotkeyEnabled) await _registerHotkey();
  }

  Future<void> _setupTray() async {
    try {
      await trayManager.setIcon(trayIconPath);
      await trayManager.setToolTip('PetWake · 常驻待机');
      await trayManager.setContextMenu(Menu(items: <MenuItem>[
        MenuItem(key: 'wake', label: '唤起宠物'),
        MenuItem(key: 'feed', label: '投喂'),
        MenuItem(key: 'sleep', label: '让它打盹'),
        MenuItem.separator(),
        MenuItem(key: 'panel', label: '设置面板'),
        MenuItem(key: 'clickThrough', label: '点击穿透'),
        MenuItem.separator(),
        MenuItem(key: 'quit', label: '退出'),
      ]));
      trayManager.addListener(this);
    } catch (error) {
      // 托盘在部分环境不可用（如无系统托盘服务的 Linux），不影响主链路。
      debugPrint('[PetWake/desktop] tray unavailable: $error');
    }
  }

  Future<void> _registerHotkey() async {
    try {
      await hotKeyManager.unregisterAll();
      final HotKey hotKey = HotKey(
        key: PhysicalKeyboardKey.keyP,
        modifiers: <HotKeyModifier>[
          Platform.isMacOS ? HotKeyModifier.meta : HotKeyModifier.control,
          HotKeyModifier.alt,
        ],
        scope: HotKeyScope.system,
      );
      await hotKeyManager.register(
        hotKey,
        keyDownHandler: (HotKey _) => _emit(WakeTrigger.hotkey),
      );
    } catch (error) {
      debugPrint('[PetWake/desktop] hotkey unavailable: $error');
    }
  }

  Future<void> setHotkeyEnabled(bool value) async {
    hotkeyEnabled = value;
    if (value) {
      await _registerHotkey();
    } else {
      await hotKeyManager.unregisterAll();
    }
  }

  Future<void> _emit(WakeTrigger trigger) async {
    _wakeCount++;
    await _handler?.onWake(WakeResult(trigger: trigger, inPlace: true));
  }

  @override
  Future<WakeResult> wake(WakeTrigger trigger) async {
    _wakeCount++;
    await windowManager.show();
    await windowManager.setIgnoreMouseEvents(false);
    _clickThrough = false;
    return WakeResult(trigger: trigger, inPlace: true);
  }

  /// 鼠标穿透：桌宠休眠或后台时调用，让点击落到下层窗口。
  Future<void> setClickThrough(bool enable) async {
    _clickThrough = enable;
    await windowManager.setIgnoreMouseEvents(enable, forward: true);
  }

  /// 在紧凑宠物窗与设置面板之间切换同一窗口的尺寸。
  Future<void> setPanelMode(bool panel) async {
    await windowManager.setSize(
        panel ? PetTokens.panelWindow : PetTokens.compactWindow);
    await windowManager.setResizable(panel);
    await windowManager.center();
  }

  /// 拖拽窗口：由界面在 onPanStart 时调用。
  Future<void> startWindowDrag() => windowManager.startDragging();

  @override
  Future<void> dismiss() async {
    // 就地互动：互动结束仅恢复常驻状态，不隐藏窗口。
    await windowManager.show();
  }

  @override
  Future<void> writeBack(PetState state, String text, {String? characterId}) async {
    // 状态回写：写回托盘提示，形成闭环。
    try {
      await trayManager.setToolTip('PetWake · $text');
    } catch (_) {/* 托盘不可用时忽略 */}
  }

  // ---------- TrayListener ----------
  @override
  void onTrayIconMouseDown() {
    _emit(WakeTrigger.tray);
  }

  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    switch (menuItem.key) {
      case 'wake':
        _emit(WakeTrigger.tray);
      case 'feed':
        _handler?.onWake(WakeResult(trigger: WakeTrigger.tray, inPlace: true));
      case 'sleep':
        _handler?.onDismiss();
      case 'panel':
        setPanelMode(true);
      case 'clickThrough':
        setClickThrough(!_clickThrough);
      case 'quit':
        _dispose();
      default:
        break;
    }
  }

  // ---------- WindowListener ----------
  @override
  void onWindowClose() {
    // 关闭窗口不退出，仅隐藏，保持常驻。
    windowManager.hide();
  }

  Future<void> _dispose() async {
    try {
      await hotKeyManager.unregisterAll();
      trayManager.removeListener(this);
      await trayManager.destroy();
    } catch (_) {/* ignore */}
    await windowManager.setPreventClose(false);
    await windowManager.close();
  }
}
