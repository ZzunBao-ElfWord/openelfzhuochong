import 'package:flutter_test/flutter_test.dart';

import 'package:petwake/core/pet_controller.dart';
import 'package:petwake/core/pet_state.dart';
import 'package:petwake/core/pet_tts_service.dart';
import 'package:petwake/core/pet_wake.dart';

/// 假适配器：不依赖任何平台插件，用于验证内核状态机闭环
/// 「常驻展示 → 唤起 → 发声 → 状态回写」。
class _FakeWake implements PetWake {
  PetWakeHandler? handler;
  final List<WakeResult> wakeCalls = <WakeResult>[];
  final List<String> writeBacks = <String>[];
  int dismissCount = 0;

  @override
  PetWakeCapabilities get capabilities => const PetWakeCapabilities(
        inPlaceInteraction: true,
        voiceHotword: false,
        soundOnWake: true,
      );

  @override
  Future<void> init(PetWakeHandler h) async => handler = h;

  @override
  Future<WakeResult> wake(WakeTrigger trigger) async {
    final WakeResult result = WakeResult(trigger: trigger, inPlace: true);
    wakeCalls.add(result);
    return result;
  }

  @override
  Future<void> dismiss() async => dismissCount++;

  @override
  Future<void> writeBack(PetState state, String text, {String? characterId}) async =>
      writeBacks.add(text);
}

void main() {
  late _FakeWake wake;
  late SilentTtsService tts;
  late PetController controller;

  setUp(() {
    wake = _FakeWake();
    tts = SilentTtsService();
    controller = PetController(wake: wake, tts: tts, soundEnabled: true);
  });

  tearDown(() => controller.dispose());

  test('boot 把处理句柄交给适配器', () async {
    await controller.boot();
    expect(wake.handler, same(controller));
  });

  test('能力声明透传到业务层（含触发源降级）', () {
    expect(controller.capabilities.inPlaceInteraction, isTrue);
    expect(controller.capabilities.availableTriggers, contains(WakeTrigger.tap));
    // 语音热词关闭时不暴露该入口。
    expect(controller.capabilities.availableTriggers,
        isNot(contains(WakeTrigger.voice)));
  });

  test('select 切换状态并同步台词', () {
    controller.select(PetState.sleep);
    expect(controller.state, PetState.sleep);
    expect(controller.bubble, kLineOf(PetState.sleep));
  });

  testWidgets('唤醒闭环：唤起 → 发声 → 回写 → 复位',
      (WidgetTester tester) async {
    await controller.boot();
    expect(controller.state, PetState.idle);

    final Future<void> running = controller.wake(WakeTrigger.tap);
    await tester.pump();
    expect(controller.busy, isTrue);
    // 推进 4 秒覆盖对话态 2 秒 + 停顿 0.9 秒的定时器。
    await tester.pump(const Duration(seconds: 4));
    await running;

    expect(controller.history.first.trigger, WakeTrigger.tap);
    expect(tts.spoken, contains(kLineOf(PetState.talking)));
    expect(wake.writeBacks, contains(kLineOf(PetState.idle)));
    expect(wake.dismissCount, 1);
    expect(controller.state, PetState.idle);
    expect(controller.busy, isFalse);
    expect(controller.speaking, isFalse);
  });

  testWidgets('互动进行中忽略重复唤起', (WidgetTester tester) async {
    await controller.boot();
    final Future<void> running = controller.wake(WakeTrigger.tap);
    await tester.pump();
    // busy 期间再次触发的唤起应被忽略。
    await controller.wake(WakeTrigger.hover);
    expect(wake.wakeCalls.length, 1);
    await tester.pump(const Duration(seconds: 4));
    await running;
  });
}
