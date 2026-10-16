// 构造函数以「公开命名参数 → 私有字段」方式赋值，无法改为初始化形参
// （命名参数不允许以下划线开头），此处忽略该提示。
// ignore_for_file: prefer_initializing_formals

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';

/// 语音服务抽象：四端统一调用，具体实现按平台接入。
abstract class PetTtsService {
  /// 播放一句台词；[awaitCompletion] 为 true 时等待播放结束。
  Future<void> speak(String line, {bool awaitCompletion = false});

  Future<void> stop();
}

/// 默认实现：系统本地 TTS（离线可用，四端内建）。
///
/// 静音键 / 专注模式 / 未安装语音包时可能无声；此时按风险 R10 的对策
/// **静默降级为视觉反馈**，不抛异常、不阻断主链路。
class LocalTtsService implements PetTtsService {
  LocalTtsService({FlutterTts? engine}) : _engine = engine ?? FlutterTts();

  final FlutterTts _engine;
  bool _configured = false;
  bool _available = true;

  Future<void> _configure() async {
    if (_configured) return;
    _configured = true;
    try {
      await _engine.setLanguage('zh-CN');
      await _engine.setSpeechRate(1.05);
      await _engine.setPitch(1.15);
      await _engine.setVolume(1.0);
    } catch (_) {
      _available = false;
    }
  }

  @override
  Future<void> speak(String line, {bool awaitCompletion = false}) async {
    if (line.isEmpty) return;
    await _configure();
    if (!_available) return;
    try {
      await _engine.stop();
      if (!awaitCompletion) {
        await _engine.speak(line);
        return;
      }
      final Completer<void> done = Completer<void>();
      _engine.setCompletionHandler(() {
        if (!done.isCompleted) done.complete();
      });
      await _engine.speak(line);
      await done.future.timeout(const Duration(seconds: 8), onTimeout: () {});
    } catch (_) {
      // 无声时降级为视觉反馈。
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _engine.stop();
    } catch (_) {/* ignore */}
  }
}

/// 联网实现：OpenAI 兼容 TTS，返回音频后由本地播放器播放。
///
/// 按合规要求「联网能力需用户授权且可关闭」：仅当 [enabled] 为 true 时发起请求，
/// 失败自动降级到 [fallback]（默认本地 TTS）。
class RemoteTtsService implements PetTtsService {
  RemoteTtsService({
    required this.baseUrl,
    required this.apiKey,
    this.model = 'tts-1',
    this.voice = 'alloy',
    this.enabled = false,
    PetTtsService? fallback,
    AudioPlayer? player,
  })  : _fallback = fallback,
        _player = player ?? AudioPlayer();

  final String baseUrl;
  final String apiKey;
  final String model;
  final String voice;

  /// 是否允许联网（需用户授权，默认关闭，符合本地优先策略）。
  bool enabled;

  final PetTtsService? _fallback;
  final AudioPlayer _player;

  @override
  Future<void> speak(String line, {bool awaitCompletion = false}) async {
    if (line.isEmpty) return;
    if (!enabled) {
      await _fallback?.speak(line, awaitCompletion: awaitCompletion);
      return;
    }
    try {
      final Uint8List bytes = await _fetch(line);
      final Directory dir = await getTemporaryDirectory();
      final File file = File('${dir.path}/petwake_tts.mp3');
      await file.writeAsBytes(bytes, flush: true);
      await _player.stop();
      if (awaitCompletion) {
        final Completer<void> done = Completer<void>();
        final StreamSubscription<void> sub =
            _player.onPlayerComplete.listen((_) {
          if (!done.isCompleted) done.complete();
        });
        await _player.play(DeviceFileSource(file.path));
        await done.future.timeout(const Duration(seconds: 12), onTimeout: () {});
        await sub.cancel();
      } else {
        await _player.play(DeviceFileSource(file.path));
      }
    } catch (_) {
      // 联网失败 → 降级本地，保证「唤起必有声音反馈」。
      await _fallback?.speak(line, awaitCompletion: awaitCompletion);
    }
  }

  Future<Uint8List> _fetch(String line) async {
    final HttpClient client = HttpClient();
    try {
      final HttpClientRequest req =
          await client.postUrl(Uri.parse('$baseUrl/audio/speech'));
      req.headers
        ..set(HttpHeaders.contentTypeHeader, 'application/json')
        ..set(HttpHeaders.authorizationHeader, 'Bearer $apiKey');
      req.add(utf8.encode(jsonEncode(<String, dynamic>{
        'model': model,
        'voice': voice,
        'input': line,
      })));
      final HttpClientResponse res = await req.close();
      if (res.statusCode != 200) {
        throw HttpException('TTS HTTP ${res.statusCode}');
      }
      final BytesBuilder builder = BytesBuilder(copy: false);
      await for (final List<int> chunk in res) {
        builder.add(chunk);
      }
      return builder.takeBytes();
    } finally {
      client.close(force: true);
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _player.stop();
    } catch (_) {/* ignore */}
    await _fallback?.stop();
  }
}

/// 无声音实现：用于集成测试与无音频环境（含 Linux 预览），仅保留视觉反馈。
class SilentTtsService implements PetTtsService {
  SilentTtsService();

  /// 记录被播放过的台词，便于测试断言「唤起后确实发声」。
  final List<String> spoken = <String>[];

  @override
  Future<void> speak(String line, {bool awaitCompletion = false}) async {
    spoken.add(line);
  }

  @override
  Future<void> stop() async {}
}

/// 便于业务层在「联网 TTS 不可用」时统一回退。
PetTtsService resolveTtsService({
  required bool remoteEnabled,
  String? baseUrl,
  String? apiKey,
}) {
  final PetTtsService local = LocalTtsService();
  if (!remoteEnabled || baseUrl == null || apiKey == null) return local;
  return RemoteTtsService(
    baseUrl: baseUrl,
    apiKey: apiKey,
    enabled: true,
    fallback: local,
  );
}

/// 供 UI 展示的语音服务类型名。
String describeTts(PetTtsService service) => switch (service) {
      LocalTtsService() => '本地 TTS',
      RemoteTtsService() => '联网 TTS（可关闭）',
      SilentTtsService() => '静音（视觉反馈）',
      _ => '未知',
    };

/// 仅在调试构建下输出，避免 release 包打印敏感信息。
void logTts(String message) {
  if (kDebugMode) debugPrint('[PetWake/TTS] $message');
}
