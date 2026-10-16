// 构造函数以「公开命名参数 → 私有字段」方式赋值，无法改为初始化形参
// （命名参数不允许以下划线开头），此处忽略该提示。
// ignore_for_file: prefer_initializing_formals

import 'dart:async';

import 'package:flutter/foundation.dart';

import 'pet_character.dart';
import 'pet_state.dart';
import 'pet_tts_service.dart';
import 'pet_wake.dart';

/// 宠物状态机：内核层，平台无关。
///
/// 承载「唤起—给声音—状态回写」闭环：适配器负责让宠物可见并回传 [WakeResult]，
/// 状态机负责切换状态、播放台词，最后把状态写回常驻载体。
class PetController extends ChangeNotifier implements PetWakeHandler {
  PetController({
    required PetWake wake,
    required PetTtsService tts,
    bool soundEnabled = true,
  })  : _wake = wake,
        _tts = tts,
        _soundEnabled = soundEnabled;

  final PetWake _wake;
  PetTtsService _tts;

  PetState _state = PetState.idle;
  PetState get state => _state;

  bool _soundEnabled;
  bool get soundEnabled => _soundEnabled;

  String _bubble = '';
  String get bubble => _bubble;

  bool _speaking = false;
  bool get speaking => _speaking;

  bool _busy = false;

  /// 互动进行中（唤起后到状态回写完成之间为 true）。
  bool get busy => _busy;

  bool _disposed = false;

  PetCharacter _character = kCharacters.first;
  PetCharacter get character => _character;

  final List<WakeResult> _history = <WakeResult>[];

  /// 最近的唤起记录（最新在前，最多 12 条）。
  List<WakeResult> get history => List<WakeResult>.unmodifiable(_history);

  PetWakeCapabilities get capabilities => _wake.capabilities;

  /// 当前状态的元数据。
  PetStateMeta get meta =>
      kPetStates.firstWhere((PetStateMeta m) => m.state == _state,
          orElse: () => kPetStates.first);

  /// 启动：把处理句柄交给适配器，完成常驻载体初始化。
  Future<void> boot() => _wake.init(this);

  /// 切换萌宠形象（主页选择）。
  void setCharacter(PetCharacter next) {
    if (_character.id == next.id) return;
    _character = next;
    _notify();
  }

  void setSoundEnabled(bool value) {
    if (_soundEnabled == value) return;
    _soundEnabled = value;
    _notify();
  }

  /// 切换语音服务实现（本地 / 联网），由设置项驱动。
  void setTtsService(PetTtsService service) {
    _tts = service;
    _notify();
  }

  /// 手动切换到某个状态（状态机演示 / 系统事件触发）。
  void select(PetState next) {
    if (_state == next) return;
    _state = next;
    _bubble = kLineOf(next);
    _notify();
  }

  /// 完整闭环：唤起 → 发声 → 状态回写。
  Future<void> wake(WakeTrigger trigger) async {
    if (_busy) return;
    final WakeResult result = await _wake.wake(trigger);
    await _runWakeSequence(result);
  }

  /// 投喂：进入进食态，随后回到待机并回写。
  Future<void> feed() async {
    if (_busy) return;
    _busy = true;
    select(PetState.eat);
    await _say(kLineOf(PetState.eat));
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    select(PetState.idle);
    await _wake.writeBack(PetState.idle, kLineOf(PetState.idle),
        characterId: _character.id);
    _busy = false;
    _notify();
  }

  /// 打盹：静置 15 分钟后自动进入。
  void nap() {
    if (_busy) return;
    select(PetState.sleep);
  }

  /// 充电：接电源触发，状态回写优先。
  void charge() {
    if (_busy) return;
    select(PetState.charge);
  }

  @override
  Future<void> onWake(WakeResult result) => _runWakeSequence(result);

  @override
  Future<void> onDismiss() async {
    select(PetState.idle);
  }

  Future<void> _runWakeSequence(WakeResult result) async {
    if (_busy) return;
    _busy = true;
    _history.insert(0, result);
    if (_history.length > 12) _history.removeLast();
    select(PetState.talking);
    await _say(kLineOf(PetState.talking));
    await Future<void>.delayed(const Duration(seconds: 2));
    select(PetState.idle);
    // 状态回写：写回灵动岛 / 悬浮窗 / 托盘提示。
    await _wake.writeBack(PetState.idle, kLineOf(PetState.idle),
        characterId: _character.id);
    await _wake.dismiss();
    _busy = false;
    _notify();
  }

  Future<void> _say(String line) async {
    _bubble = line;
    _speaking = true;
    _notify();
    if (_soundEnabled) {
      await _tts.speak(line);
    }
    await Future<void>.delayed(const Duration(milliseconds: 900));
    _speaking = false;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _tts.stop();
    super.dispose();
  }
}
