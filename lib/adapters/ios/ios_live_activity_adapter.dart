import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../core/capability_matrix.dart';
import '../../core/pet_state.dart';
import '../../core/pet_wake.dart';

/// iOS 适配器：通过 MethodChannel 驱动原生 ActivityKit。
///
/// iOS 无系统悬浮窗 API，采用「跳转式」：点按实时活动由系统打开 App，
/// 声音互动在 App 前台完成；岛本身只做展示与入口，无交互按钮。
///
/// 原生侧见 `ios/Runner/LiveActivityBridge.swift`
/// 与 `ios/PetWakeWidget/PetActivityAttributes.swift`。
class IosLiveActivityAdapter implements PetWake, PetWakeRenewable {
  IosLiveActivityAdapter();

  static const MethodChannel _channel = MethodChannel('petwake/activity');

  PetWakeHandler? _handler;
  Timer? _renewTimer;
  DateTime? _lastUpdate;
  String? _activityId;

  @override
  PetWakeCapabilities get capabilities => const PetWakeCapabilities(
        inPlaceInteraction: false,
        voiceHotword: false,
        soundOnWake: true,
      );

  /// 是否已启动实时活动。
  bool get activityRunning => _activityId != null;

  @override
  Future<void> init(PetWakeHandler handler) async {
    _handler = handler;
    try {
      _channel.setMethodCallHandler(_onNativeCall);
    } catch (error) {
      debugPrint('[PetWake/ios] channel unavailable: $error');
      return;
    }
    await _start(state: PetState.idle, text: kLineOf(PetState.idle));
    _scheduleRenew();
  }

  /// 原生 → Dart：用户点按灵动岛/锁屏卡片，系统打开 App 后回传事件。
  Future<void> _onNativeCall(MethodCall call) async {
    if (call.method == 'onIslandTapped') {
      await _handler?.onWake(const WakeResult(
        trigger: WakeTrigger.tap,
        appOpened: true,
        inPlace: false,
      ));
    }
  }

  /// 每 6 小时重启一次实时活动，规避 8 小时活跃上限（见风险 R1）。
  void _scheduleRenew() {
    _renewTimer?.cancel();
    _renewTimer = Timer.periodic(LiveActivityLimits.renewInterval, (Timer _) {
      renew();
    });
  }

  @override
  Future<WakeResult> wake(WakeTrigger trigger) async {
    // 唤起已由系统完成（点按岛打开 App）；此处刷新活动内容。
    await _update(state: PetState.talking, text: kLineOf(PetState.talking));
    return const WakeResult(
      trigger: WakeTrigger.tap,
      appOpened: false,
      inPlace: false,
    );
  }

  @override
  Future<void> dismiss() async {}

  @override
  Future<void> writeBack(PetState state, String text, {String? characterId}) =>
      _update(state: state, text: text);

  @override
  Future<void> renew() async {
    try {
      await _channel.invokeMethod<void>('end');
      _activityId = null;
      await _start(state: PetState.idle, text: kLineOf(PetState.idle));
    } catch (error) {
      debugPrint('[PetWake/ios] renew failed: $error');
    }
  }

  Future<void> _start({required PetState state, required String text}) async {
    try {
      final String? id = await _channel.invokeMethod<String>('start', <String, dynamic>{
        'state': state.name,
        'text': text,
      });
      _activityId = id ?? 'running';
    } catch (error) {
      debugPrint('[PetWake/ios] start failed（素材尺寸超限或未开权限）: $error');
    }
  }

  Future<void> _update({required PetState state, required String text}) async {
    final DateTime now = DateTime.now();
    final DateTime? last = _lastUpdate;
    // 刷新节流：按秒级设计，避免被系统丢弃（见风险 R2）。
    if (last != null && now.difference(last) < LiveActivityLimits.updateThrottle) {
      return;
    }
    _lastUpdate = now;
    try {
      await _channel.invokeMethod<void>('update', <String, dynamic>{
        'state': state.name,
        'text': text,
      });
    } catch (_) {/* 活动未启动或已过期时忽略 */}
  }

  /// 结束时释放定时器。
  void dispose() {
    _renewTimer?.cancel();
    _renewTimer = null;
  }
}
