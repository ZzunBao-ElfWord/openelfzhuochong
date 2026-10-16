import 'package:flutter/foundation.dart';

import 'pet_state.dart';

/// 唤起触发源。四端统一枚举，适配器自行决定哪些可用。
enum WakeTrigger { tap, hover, drag, tray, hotkey, voice, notification, systemEvent }

extension WakeTriggerLabel on WakeTrigger {
  /// 中文展示名，与原型「唤起方式」文案一致。
  String get label => switch (this) {
        WakeTrigger.tap => '点按',
        WakeTrigger.hover => '悬停',
        WakeTrigger.drag => '拖拽',
        WakeTrigger.tray => '托盘/菜单栏',
        WakeTrigger.hotkey => '全局热键',
        WakeTrigger.voice => '语音热词',
        WakeTrigger.notification => '通知',
        WakeTrigger.systemEvent => '系统事件',
      };

  /// 该触发源是否需要用户授予麦克风权限。
  bool get requiresMicrophone => this == WakeTrigger.voice;
}

/// 平台能力声明，用于业务层按能力降级，避免四端行为不一致。
@immutable
class PetWakeCapabilities {
  const PetWakeCapabilities({
    required this.inPlaceInteraction,
    required this.voiceHotword,
    required this.soundOnWake,
  });

  /// 是否可就地互动（不跳转 App）。
  final bool inPlaceInteraction;

  /// 是否支持语音热词唤醒。
  final bool voiceHotword;

  /// 唤起后是否可发声。
  final bool soundOnWake;

  /// 该端可用的触发源集合，界面据此隐藏不可用入口。
  Set<WakeTrigger> get availableTriggers {
    final Set<WakeTrigger> t = <WakeTrigger>{
      WakeTrigger.tap,
      WakeTrigger.systemEvent,
    };
    if (inPlaceInteraction) {
      t.addAll(<WakeTrigger>{
        WakeTrigger.hover,
        WakeTrigger.drag,
        WakeTrigger.tray,
        WakeTrigger.hotkey,
        WakeTrigger.notification,
      });
    }
    if (voiceHotword) t.add(WakeTrigger.voice);
    return t;
  }

  /// 能力降级说明：当某能力不可用时给出替代路径，写回常驻载体。
  String get degradationNote {
    if (inPlaceInteraction) {
      if (voiceHotword) return '就地互动 + 语音热词均可用，直接发声并回写状态。';
      return '就地互动可用，语音热词关闭，降级为点按/托盘触发。';
    }
    return '无就地互动：互动收敛到 App 前台，常驻载体仅做展示与入口。';
  }
}

/// 一次唤起的结果。
@immutable
class WakeResult {
  const WakeResult({
    required this.trigger,
    this.appOpened = false,
    this.inPlace = false,
  });

  final WakeTrigger trigger;

  /// 是否因此打开了 App（iOS 点按实时活动的场景）。
  final bool appOpened;

  /// 是否就地互动。
  final bool inPlace;
}

/// 唤起后由适配器回调的业务处理器。
abstract class PetWakeHandler {
  Future<void> onWake(WakeResult result);
  Future<void> onDismiss();
}

/// 统一唤起接口：所有平台的「唤起—给声音—状态回写」都走这一抽象。
/// 业务代码只依赖本接口，平台差异被完全隔离。
abstract class PetWake {
  /// 初始化常驻载体（透明置顶窗口 / 悬浮窗 / 实时活动）并注册回调。
  Future<void> init(PetWakeHandler handler);

  /// 触发一次唤起。适配器负责让宠物可见并返回结果。
  Future<WakeResult> wake(WakeTrigger trigger);

  /// 收起本次互动，恢复常驻展示。
  Future<void> dismiss();

  /// 状态回写：互动结束后把最新状态写回常驻载体，形成闭环。
  Future<void> writeBack(PetState state, String text, {String? characterId});

  /// 本端能力声明。
  PetWakeCapabilities get capabilities;
}

/// iOS 等端需要显式续期常驻载体时使用的可选能力。
/// 实时活动活跃期上限 8 小时，实现方负责定时重启以规避。
abstract class PetWakeRenewable {
  /// 续期常驻载体（结束旧活动并重新启动）。
  Future<void> renew();
}
