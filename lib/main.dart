import 'package:flutter/material.dart';

import 'app.dart';
import 'ui/pet_overlay.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PetWakeApp());
}

/// Android 悬浮窗入口（独立 isolate）。
///
/// 入口名 `overlayMain` 由 flutter_overlay_window 约定调用，
/// 必须标注 `vm:entry-point` 以保留符号。
@pragma('vm:entry-point')
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  // 悬浮窗 isolate 没有宿主 WidgetsApp，必须自带 Directionality/MediaQuery，
  // 否则 Text/Row/Column 会抛「No Directionality widget found」导致整窗空白。
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: PetOverlayApp(),
    ),
  );
}
