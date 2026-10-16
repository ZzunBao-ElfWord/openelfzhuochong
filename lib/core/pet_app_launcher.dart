import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// 可唤起目标：桌面与 Android 从系统枚举，iOS 仅预配置。
@immutable
class AppTarget {
  const AppTarget({required this.id, required this.name, this.scheme});

  /// 包名 / bundleId / AUMID / 应用路径。
  final String id;

  /// 显示名。
  final String name;

  /// iOS / macOS 预配置的 URL Scheme。
  final String? scheme;

  @override
  bool operator ==(Object other) =>
      other is AppTarget && other.id == id && other.name == name;

  @override
  int get hashCode => Object.hash(id, name);
}

/// 可选能力：桌宠唤起其他应用。
///
/// 与「唤起—给声音」主链路解耦；通过 [canEnumerateTargets] 驱动界面降级。
abstract class PetAppLauncher {
  /// 是否能枚举已安装应用（iOS 恒为 false）。
  bool get canEnumerateTargets;

  /// 枚举可唤起目标；iOS 返回预配置列表。
  Future<List<AppTarget>> listTargets();

  /// 唤起目标应用。
  Future<bool> launch(AppTarget target);

  /// 供界面展示的能力说明。
  String get capabilityNote;
}

/// 桌面实现：Windows / macOS 通过系统启动接口，枚举本机应用。
class DesktopAppLauncher implements PetAppLauncher {
  @override
  bool get canEnumerateTargets => true;

  @override
  String get capabilityNote => '可枚举本机应用，自由选择唤起目标。';

  @override
  Future<List<AppTarget>> listTargets() async {
    try {
      if (Platform.isMacOS) return await _scanMacApplications();
      if (Platform.isWindows) return await _scanWindowsStartMenu();
    } catch (_) {/* 枚举失败时回退空列表 */}
    return const <AppTarget>[];
  }

  Future<List<AppTarget>> _scanMacApplications() async {
    final Directory dir = Directory('/Applications');
    if (!await dir.exists()) return const <AppTarget>[];
    final List<AppTarget> targets = <AppTarget>[];
    await for (final FileSystemEntity entity in dir.list(followLinks: false)) {
      final String name = entity.path.split('/').last;
      if (name.endsWith('.app')) {
        targets.add(AppTarget(
          id: entity.path,
          name: name.substring(0, name.length - 4),
        ));
      }
    }
    targets.sort((AppTarget a, AppTarget b) => a.name.compareTo(b.name));
    return targets.take(40).toList();
  }

  Future<List<AppTarget>> _scanWindowsStartMenu() async {
    final String? appData = Platform.environment['APPDATA'];
    if (appData == null) return const <AppTarget>[];
    final Directory dir = Directory(
        '$appData\\Microsoft\\Windows\\Start Menu\\Programs');
    if (!await dir.exists()) return const <AppTarget>[];
    final List<AppTarget> targets = <AppTarget>[];
    await for (final FileSystemEntity entity
        in dir.list(recursive: true, followLinks: false)) {
      final String name = entity.path.split('\\').last;
      if (name.endsWith('.lnk')) {
        targets.add(AppTarget(
          id: entity.path,
          name: name.substring(0, name.length - 4),
        ));
      }
    }
    targets.sort((AppTarget a, AppTarget b) => a.name.compareTo(b.name));
    return targets.take(40).toList();
  }

  @override
  Future<bool> launch(AppTarget target) async {
    try {
      if (Platform.isMacOS) {
        await Process.start('open', <String>['-a', target.id]);
        return true;
      }
      if (Platform.isWindows) {
        await Process.start('cmd', <String>['/c', 'start', '', target.id],
            runInShell: true);
        return true;
      }
    } catch (_) {/* 启动失败返回 false */}
    return false;
  }
}

/// Android 实现：通过原生 PackageManager 枚举与启动（见 MainActivity.kt）。
///
/// 注意包可见性：Android 11+ 需为候选包声明 `<queries>`；
/// 申请 QUERY_ALL_PACKAGES 属敏感权限，Google Play 审核严格。
class AndroidAppLauncher implements PetAppLauncher {
  static const MethodChannel _channel = MethodChannel('petwake/apps');

  @override
  bool get canEnumerateTargets => true;

  @override
  String get capabilityNote =>
      '可枚举已安装应用；Android 11+ 需声明 <queries> 包可见性。';

  @override
  Future<List<AppTarget>> listTargets() async {
    try {
      final List<dynamic>? raw =
          await _channel.invokeMethod<List<dynamic>>('listTargets');
      if (raw == null) return const <AppTarget>[];
      return raw
          .cast<Map<dynamic, dynamic>>()
          .map((Map<dynamic, dynamic> m) => AppTarget(
                id: m['id'] as String? ?? '',
                name: m['name'] as String? ?? '',
              ))
          .where((AppTarget t) => t.id.isNotEmpty)
          .toList();
    } catch (_) {
      return const <AppTarget>[];
    }
  }

  @override
  Future<bool> launch(AppTarget target) async {
    try {
      final bool? ok = await _channel
          .invokeMethod<bool>('launch', <String, dynamic>{'id': target.id});
      return ok ?? false;
    } catch (_) {
      return false;
    }
  }
}

/// iOS 实现：无枚举接口，只能唤起预先声明了 Scheme 的目标。
///
/// 需在 Info.plist 的 `LSApplicationQueriesSchemes` 白名单声明目标 scheme
/// （iOS 15 起上限 50 条）；未声明一律返回 false。
class IosAppLauncher implements PetAppLauncher {
  static const MethodChannel _channel = MethodChannel('petwake/apps');

  @override
  bool get canEnumerateTargets => false;

  @override
  String get capabilityNote =>
      '无法枚举已安装应用，仅可唤起预配置 Scheme 目标（白名单上限 50 条）。';

  /// 预配置目标：产品内置常用入口，用户可在设置中编辑。
  static const List<AppTarget> presetTargets = <AppTarget>[
    AppTarget(id: 'weixin://', name: '微信', scheme: 'weixin'),
    AppTarget(id: 'qqmusic://', name: 'QQ 音乐', scheme: 'qqmusic'),
    AppTarget(id: 'iosamap://', name: '高德地图', scheme: 'iosamap'),
    AppTarget(id: 'mqq://', name: 'QQ', scheme: 'mqq'),
  ];

  @override
  Future<List<AppTarget>> listTargets() async => presetTargets;

  @override
  Future<bool> launch(AppTarget target) async {
    final String url = target.id;
    try {
      final bool? ok = await _channel
          .invokeMethod<bool>('openUrl', <String, dynamic>{'url': url});
      return ok ?? false;
    } catch (_) {
      return false;
    }
  }
}

/// 未知端（Linux 预览 / 测试）：不提供唤起能力。
class NoopAppLauncher implements PetAppLauncher {
  @override
  bool get canEnumerateTargets => false;

  @override
  String get capabilityNote => '当前端不支持唤起第三方应用。';

  @override
  Future<List<AppTarget>> listTargets() async => const <AppTarget>[];

  @override
  Future<bool> launch(AppTarget target) async => false;
}
