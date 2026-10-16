import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 用户设置：默认值遵循合规要求（联网能力默认关闭）。
@immutable
class PetSettings {
  const PetSettings({
    this.sound = true,
    this.hotword = false,
    this.clickThrough = false,
    this.autoStart = true,
    this.remoteTts = false,
    this.characterId = 'cat',
  });

  /// 声音开关：关闭后仅保留视觉反馈。
  final bool sound;

  /// 语音热词（Android / 桌面可选增强，默认关闭）。
  final bool hotword;

  /// 点击穿透（桌宠休眠或后台时让点击落到下层窗口）。
  final bool clickThrough;

  /// 开机自启（桌面端）。
  final bool autoStart;

  /// 联网 TTS：需用户授权，默认关闭，符合「本地优先」数据策略。
  final bool remoteTts;

  /// 当前选中的萌宠 id（对应 kCharacters）。
  final String characterId;

  PetSettings copyWith({
    bool? sound,
    bool? hotword,
    bool? clickThrough,
    bool? autoStart,
    bool? remoteTts,
    String? characterId,
  }) {
    return PetSettings(
      sound: sound ?? this.sound,
      hotword: hotword ?? this.hotword,
      clickThrough: clickThrough ?? this.clickThrough,
      autoStart: autoStart ?? this.autoStart,
      remoteTts: remoteTts ?? this.remoteTts,
      characterId: characterId ?? this.characterId,
    );
  }
}

/// 设置持久化：本地存储，离线优先。
class PetSettingsStore {
  static const String _kSound = 'pw.sound';
  static const String _kHotword = 'pw.hotword';
  static const String _kClickThrough = 'pw.clickThrough';
  static const String _kAutoStart = 'pw.autoStart';
  static const String _kRemoteTts = 'pw.remoteTts';
  static const String _kCharacterId = 'pw.characterId';

  Future<PetSettings> load() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      return PetSettings(
        sound: prefs.getBool(_kSound) ?? true,
        hotword: prefs.getBool(_kHotword) ?? false,
        clickThrough: prefs.getBool(_kClickThrough) ?? false,
        autoStart: prefs.getBool(_kAutoStart) ?? true,
        remoteTts: prefs.getBool(_kRemoteTts) ?? false,
        characterId: prefs.getString(_kCharacterId) ?? 'cat',
      );
    } catch (error) {
      debugPrint('[PetWake/settings] load failed, using defaults: $error');
      return const PetSettings();
    }
  }

  Future<void> save(PetSettings settings) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kSound, settings.sound);
      await prefs.setBool(_kHotword, settings.hotword);
      await prefs.setBool(_kClickThrough, settings.clickThrough);
      await prefs.setBool(_kAutoStart, settings.autoStart);
      await prefs.setBool(_kRemoteTts, settings.remoteTts);
      await prefs.setString(_kCharacterId, settings.characterId);
    } catch (error) {
      debugPrint('[PetWake/settings] save failed: $error');
    }
  }
}
