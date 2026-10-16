import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

import '../core/pet_character.dart';
import '../core/pet_state.dart';
import 'pet_view.dart';

/// Android 悬浮窗入口（独立 isolate）。
///
/// 由 flutter_overlay_window 在悬浮窗 isolate 中运行；与主 App 通过
/// `shareData` / `overlayListener` 双向通信：
/// - 悬浮窗 → 主 App：点按宠物发送 `{action: wake}`，由主 isolate 触发发声与状态回写
/// - 主 App → 悬浮窗：状态回写时广播 `{state, text}`，悬浮窗就地更新形象
///
/// 说明：发声统一由主 isolate 的 TTS 引擎执行（同一进程，听觉上仍是「就地发声」）。
class PetOverlayApp extends StatefulWidget {
  const PetOverlayApp({super.key});

  @override
  State<PetOverlayApp> createState() => _PetOverlayAppState();
}

class _PetOverlayAppState extends State<PetOverlayApp> {
  PetState _state = PetState.idle;
  String _text = kLineOf(PetState.idle);
  PetCharacter _character = kCharacters.first;

  @override
  void initState() {
    super.initState();
    FlutterOverlayWindow.overlayListener.listen(_onMessage);
  }

  void _onMessage(dynamic message) {
    if (message is! Map) return;
    final String? rawState = message['state'] as String?;
    final String? text = message['text'] as String?;
    if (!mounted) return;
    setState(() {
      if (rawState != null) _state = _parse(rawState);
      if (text != null) _text = text;
      final String? cid = message['characterId'] as String?;
      if (cid != null) _character = PetCharacter.byId(cid);
    });
  }

  PetState _parse(String name) {
    for (final PetState s in PetState.values) {
      if (s.name == name) return s;
    }
    return PetState.idle;
  }

  Future<void> _onTap() async {
    await FlutterOverlayWindow.shareData(<String, dynamic>{
      'action': 'wake',
      'trigger': 'tap',
    });
  }

  Future<void> _onPanUpdate(DragUpdateDetails details) async {
    try {
      final OverlayPosition pos = await FlutterOverlayWindow.getOverlayPosition();
      await FlutterOverlayWindow.moveOverlay(
        OverlayPosition(pos.x + details.delta.dx, pos.y + details.delta.dy),
      );
    } catch (_) {/* 移动失败不影响互动 */}
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _onTap,
        onPanUpdate: _onPanUpdate,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SpeechBubble(text: _text, visible: true, maxWidth: 150),
            const SizedBox(height: 6),
            PetAvatar(state: _state, character: _character, size: 92),
            const SizedBox(height: 4),
            PetWaveform(speaking: _state == PetState.talking),
          ],
        ),
      ),
    );
  }
}
