import 'package:flutter/foundation.dart';

import '../../core/pet_state.dart';
import '../../core/pet_wake.dart';

/// 预览 / 未知端适配器。
///
/// 用于 Linux 开发机预览与集成测试：不依赖任何平台插件，
/// 但完整实现 [PetWake] 契约，保证内核可独立验证。
class PreviewPetAdapter implements PetWake, PetWakeRenewable {
  PetWakeHandler? _handler;

  /// 记录状态回写历史，便于测试断言「闭环」成立。
  final List<String> writeBackLog = <String>[];

  /// 是否已 init（常驻载体是否就绪）。
  bool get ready => _handler != null;

  @override
  PetWakeCapabilities get capabilities => const PetWakeCapabilities(
        inPlaceInteraction: true,
        voiceHotword: false,
        soundOnWake: true,
      );

  @override
  Future<void> init(PetWakeHandler handler) async {
    _handler = handler;
  }

  @override
  Future<WakeResult> wake(WakeTrigger trigger) async {
    if (kDebugMode) {
      debugPrint('[PetWake/preview] wake by ${trigger.label}');
    }
    return WakeResult(trigger: trigger, inPlace: true);
  }

  @override
  Future<void> dismiss() async {}

  @override
  Future<void> writeBack(PetState state, String text, {String? characterId}) async {
    writeBackLog.add('${state.name}:$text');
  }

  @override
  Future<void> renew() async {
    writeBackLog.add('renew');
  }
}
