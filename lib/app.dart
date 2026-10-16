import 'dart:async';

import 'package:flutter/material.dart';

import 'adapters/android/android_overlay_adapter.dart';
import 'adapters/pet_adapter_factory.dart';
import 'core/capability_matrix.dart';
import 'core/pet_asset.dart';
import 'core/pet_character.dart';
import 'core/pet_controller.dart';
import 'core/pet_settings.dart';
import 'core/pet_theme.dart';
import 'core/pet_tts_service.dart';
import 'core/pet_wake.dart';
import 'ui/desktop_shell.dart';
import 'ui/mobile_home.dart';

/// 联网 TTS 配置（留空则始终回退本地 TTS，符合「本地优先 + 用户授权」策略）。
const String kRemoteTtsBaseUrl = 'https://api.openai.com/v1';
const String kRemoteTtsApiKey = '';

/// 应用根组件：装配端适配器、状态机、设置与素材，并按端选择外壳。
class PetWakeApp extends StatefulWidget {
  const PetWakeApp({super.key});

  @override
  State<PetWakeApp> createState() => _PetWakeAppState();
}

class _PetWakeAppState extends State<PetWakeApp> {
  late final DeviceKind _kind;
  late final PetPlatformBundle _bundle;
  late final PetController _controller;
  final PetSettingsStore _store = PetSettingsStore();

  PetSettings _settings = const PetSettings();
  PetAssetPackage? _assets;
  StreamSubscription<dynamic>? _overlaySub;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _kind = resolveDeviceKind();
    _bundle = createPlatformBundle(kind: _kind);
    _controller = PetController(
      wake: _bundle.wake,
      tts: LocalTtsService(),
      soundEnabled: true,
    );
    _boot();
  }

  Future<void> _boot() async {
    final PetSettings settings = await _store.load();
    final PetAssetPackage? assets = await _loadAssets();
    if (!mounted) return;
    setState(() {
      _settings = settings;
      _assets = assets;
      _ready = true;
    });
    _controller.setSoundEnabled(settings.sound);
    _controller.setCharacter(PetCharacter.byId(settings.characterId));
    _applyTts(settings);
    _bundle.android?.setVoiceHotwordEnabled(settings.hotword);
    _listenOverlayMessages();
    // 初始化常驻载体（透明置顶窗 / 悬浮窗 / 实时活动）。
    await _controller.boot();
  }

  Future<PetAssetPackage?> _loadAssets() async {
    try {
      return await PetAssetPackage.load();
    } catch (error) {
      debugPrint('[PetWake] 素材加载失败：$error');
      return null;
    }
  }

  /// 主 App 与 Android 悬浮窗 isolate 的消息通道。
  void _listenOverlayMessages() {
    if (_bundle.android == null) return;
    _overlaySub = AndroidOverlayAdapter.overlayMessages.listen((dynamic message) {
      if (message is Map && message['action'] == 'wake') {
        _controller.wake(WakeTrigger.tap);
      }
    });
  }

  void _applyTts(PetSettings settings) {
    _controller.setTtsService(resolveTtsService(
      remoteEnabled: settings.remoteTts,
      baseUrl: kRemoteTtsBaseUrl,
      apiKey: kRemoteTtsApiKey.isEmpty ? null : kRemoteTtsApiKey,
    ));
  }

  Future<void> _updateSettings(PetSettings next) async {
    setState(() => _settings = next);
    _controller.setSoundEnabled(next.sound);
    _applyTts(next);
    _bundle.android?.setVoiceHotwordEnabled(next.hotword);
    await _bundle.desktop?.setHotkeyEnabled(next.autoStart);
    await _store.save(next);
  }

  @override
  void dispose() {
    _overlaySub?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PetWake',
      debugShowCheckedModeBanner: false,
      theme: PetTokens.light(),
      home: !_ready
          ? Scaffold(
              backgroundColor:
                  _kind.isDesktop ? Colors.transparent : PetTokens.bg,
              body: const Center(child: CircularProgressIndicator()),
            )
          : _kind.isDesktop
              ? DesktopShell(
                  controller: _controller,
                  bundle: _bundle,
                  settings: _settings,
                  assets: _assets,
                  onSettingsChanged: _updateSettings,
                )
              : MobileHome(
                  controller: _controller,
                  bundle: _bundle,
                  settings: _settings,
                  assets: _assets,
                  onSettingsChanged: _updateSettings,
                ),
    );
  }
}
