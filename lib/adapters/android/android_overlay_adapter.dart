import 'package:flutter/foundation.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

import '../../core/pet_state.dart';
import '../../core/pet_wake.dart';

/// Android 适配器：全局悬浮窗常驻 + 就地互动。
///
/// 悬浮窗权限与前台服务配置见 `AndroidManifest.xml` 与
/// `flutter.overlay.window.flutter_overlay_window.OverlayService`；
/// 主流厂商需在系统设置中单独授权「显示在其他应用上层」，并加入后台白名单。
class AndroidOverlayAdapter implements PetWake {
  AndroidOverlayAdapter({
    this.overlayWidth = 180,
    this.overlayHeight = 220,
  });

  /// 悬浮窗逻辑尺寸（dp）。实际窗口按设备像素比换算成物理像素后传给插件。
  final int overlayWidth;
  final int overlayHeight;

  /// 语音热词默认关闭（Android 11+ 后台麦克风受限、Android 14+ 需声明
  /// 前台服务类型，且属敏感权限）—— 见风险 R6。开启需用户显式授权。
  bool voiceHotwordEnabled = false;

  bool get overlayActive => _active;
  bool _active = false;

  @override
  PetWakeCapabilities get capabilities => PetWakeCapabilities(
        inPlaceInteraction: true,
        voiceHotword: voiceHotwordEnabled,
        soundOnWake: true,
      );

  @override
  Future<void> init(PetWakeHandler handler) async {
    // 常驻载体为悬浮窗，由用户从 App 内触发开启（见 ensurePermission + wake）。
    // 悬浮窗侧的互动事件经数据通道回传主 isolate，由 App 层转发到状态机
    // （见 app.dart 的 _listenOverlayMessages），故此处无需保存 handler。
  }

  /// 仅查询悬浮窗权限是否已授予，不弹窗。
  Future<bool> isPermissionGranted() async {
    try {
      return await FlutterOverlayWindow.isPermissionGranted();
    } catch (_) {
      return false;
    }
  }

  /// 权限引导：未授权时拉起系统「显示在其他应用上层」设置页。
  /// 返回最终是否已授权。
  Future<bool> ensurePermission() async {
    try {
      if (await FlutterOverlayWindow.isPermissionGranted()) return true;
      final bool? granted = await FlutterOverlayWindow.requestPermission();
      return granted ?? false;
    } catch (error) {
      debugPrint('[PetWake/android] permission error: $error');
      return false;
    }
  }

  @override
  Future<WakeResult> wake(WakeTrigger trigger) async {
    if (!await FlutterOverlayWindow.isPermissionGranted()) {
      // 能力降级：无悬浮窗权限时不就地互动，改由 App 前台承接。
      return WakeResult(trigger: trigger, inPlace: false);
    }
    await showOverlay();
    return WakeResult(trigger: trigger, inPlace: true);
  }

  /// 展示悬浮窗（常驻载体）。
  Future<void> showOverlay({
    String title = 'PetWake 正在陪伴你',
    String? content,
  }) async {
    try {
      // 插件把 width/height 直接当作物理像素用于 WindowManager，高 DPI 屏
      // 若不换算会导致窗口过小、宠物被裁切。此处按设备像素比换算。
      final double dpr = PlatformDispatcher.instance.views.isEmpty
          ? 1.0
          : PlatformDispatcher.instance.views.first.devicePixelRatio;
      await FlutterOverlayWindow.showOverlay(
        width: (overlayWidth * dpr).round(),
        height: (overlayHeight * dpr).round(),
        alignment: OverlayAlignment.centerLeft,
        enableDrag: true,
        flag: OverlayFlag.defaultFlag,
        visibility: NotificationVisibility.visibilitySecret,
        overlayTitle: title,
        overlayContent: content,
        positionGravity: PositionGravity.auto,
      );
      _active = true;
    } catch (error) {
      debugPrint('[PetWake/android] showOverlay failed: $error');
    }
  }

  @override
  Future<void> dismiss() async {
    // 就地互动：互动结束不关闭悬浮窗，仅回到常驻形态。
  }

  /// 关闭悬浮窗并结束前台服务。
  Future<void> closeOverlay() async {
    try {
      await FlutterOverlayWindow.closeOverlay();
    } catch (_) {/* ignore */}
    _active = false;
  }

  /// 点击穿透（悬浮窗休眠时使用）。
  Future<void> setClickThrough(bool enable) async {
    try {
      await FlutterOverlayWindow.updateFlag(
        enable ? OverlayFlag.clickThrough : OverlayFlag.defaultFlag,
      );
    } catch (_) {/* ignore */}
  }

  @override
  Future<void> writeBack(PetState state, String text, {String? characterId}) async {
    // 状态回写：更新前台通知文案，并广播给悬浮窗 isolate。
    try {
      await FlutterOverlayWindow.updateNotification(content: text);
      await FlutterOverlayWindow.shareData(<String, dynamic>{
        'state': state.name,
        'text': text,
        // ignore: use_null_aware_elements
        if (characterId != null) 'characterId': characterId,
      });
    } catch (_) {/* 悬浮窗未激活时忽略 */}
  }

  /// 悬浮窗与主 App 之间的数据通道（悬浮窗侧监听）。
  static Stream<dynamic> get overlayMessages =>
      FlutterOverlayWindow.overlayListener;

  /// 语音热词开关；开启时需确保前台服务已声明麦克风类型。
  void setVoiceHotwordEnabled(bool value) {
    voiceHotwordEnabled = value;
  }
}
