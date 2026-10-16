import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

/// 端类型。四端产品 + 未知端（用于 Linux 预览与测试）。
enum DeviceKind { windows, macos, android, ios, unknown }

extension DeviceKindLabel on DeviceKind {
  String get label => switch (this) {
        DeviceKind.windows => 'Windows',
        DeviceKind.macos => 'macOS',
        DeviceKind.android => 'Android',
        DeviceKind.ios => 'iOS',
        DeviceKind.unknown => '未知端',
      };

  bool get isDesktop => this == DeviceKind.windows || this == DeviceKind.macos;
  bool get isMobile => this == DeviceKind.android || this == DeviceKind.ios;
}

/// 解析当前运行端。业务层据此选择适配器与界面形态。
DeviceKind resolveDeviceKind() {
  if (kIsWeb) return DeviceKind.unknown;
  if (Platform.isWindows) return DeviceKind.windows;
  if (Platform.isMacOS) return DeviceKind.macos;
  if (Platform.isAndroid) return DeviceKind.android;
  if (Platform.isIOS) return DeviceKind.ios;
  return DeviceKind.unknown;
}

/// 平台能力对照条目（与原型 `mock.js` 的 `capabilities` 一致）。
@immutable
class PlatformCapability {
  const PlatformCapability({
    required this.kind,
    required this.form,
    required this.triggers,
    required this.sound,
    required this.inPlace,
    required this.hotword,
    required this.limits,
  });

  final DeviceKind kind;

  /// 常驻形态。
  final String form;

  /// 唤起方式。
  final String triggers;

  /// 声音能力。
  final String sound;

  /// 是否就地互动。
  final bool inPlace;

  /// 语音热词支持情况。
  final String hotword;

  /// 主要限制。
  final String limits;
}

const List<PlatformCapability> kPlatformCapabilities = <PlatformCapability>[
  PlatformCapability(
    kind: DeviceKind.ios,
    form: '灵动岛与锁屏卡片',
    triggers: '点按岛或卡片（唯一触发，系统行为为打开 App）',
    sound: 'App 前台可播放，受静音键与专注模式影响',
    inPlace: false,
    hotword: '不支持',
    limits: '无交互按钮；活动 8 小时上限；刷新限流；素材尺寸受限',
  ),
  PlatformCapability(
    kind: DeviceKind.android,
    form: '全局悬浮窗',
    triggers: '点按、长按菜单、通知、可选语音热词',
    sound: '悬浮窗内就地播放',
    inPlace: true,
    hotword: '受限，需前台服务与厂商适配',
    limits: '需悬浮窗权限；后台麦克风受政策限制',
  ),
  PlatformCapability(
    kind: DeviceKind.windows,
    form: '透明置顶窗口与系统托盘',
    triggers: '点击、悬停、拖拽、托盘、全局热键、可选语音热词',
    sound: '完全可控',
    inPlace: true,
    hotword: '支持，需麦克风授权',
    limits: '无显著限制',
  ),
  PlatformCapability(
    kind: DeviceKind.macos,
    form: '透明置顶窗口与菜单栏',
    triggers: '点击、悬停、拖拽、菜单栏、全局热键、可选语音热词',
    sound: '完全可控',
    inPlace: true,
    hotword: '支持，需麦克风授权',
    limits: '无显著限制',
  ),
];

PlatformCapability? capabilityFor(DeviceKind kind) {
  for (final PlatformCapability c in kPlatformCapabilities) {
    if (c.kind == kind) return c;
  }
  return null;
}

/// 灵动岛三态（规格源自 Apple HIG：最小态 / 紧凑态 / 展开态）。
@immutable
class IslandForm {
  const IslandForm({
    required this.key,
    required this.label,
    required this.size,
    required this.note,
  });

  final String key;
  final String label;
  final String size;
  final String note;
}

const List<IslandForm> kIslandForms = <IslandForm>[
  IslandForm(key: 'minimal', label: '最小态', size: '78 × 30', note: '仅一个呼吸点，静置时收敛'),
  IslandForm(key: 'compact', label: '紧凑态', size: '210 × 36', note: '宠物头像 + 当前状态文案'),
  IslandForm(key: 'expanded', label: '展开态', size: '340 × 132', note: '长按岛后展开，展示台词与进度'),
];

/// Android 厂商后台保活白名单引导（真机多厂商适配所需）。
@immutable
class VendorGuide {
  const VendorGuide({required this.vendor, required this.steps});

  final String vendor;
  final List<String> steps;
}

const List<VendorGuide> kVendorGuides = <VendorGuide>[
  VendorGuide(
    vendor: '小米 / HyperOS',
    steps: <String>[
      '设置 → 应用设置 → 宠物 → 悬浮窗 → 允许',
      '电池 → 无限制（关闭智能省电）',
      '自启动管理 → 允许后台运行',
    ],
  ),
  VendorGuide(
    vendor: '华为 / HarmonyOS',
    steps: <String>[
      '设置 → 应用 → 宠物 → 权限 → 悬浮窗 → 允许',
      '应用启动管理 → 手动管理 → 允许自启动',
      '电池优化 → 不受限制',
    ],
  ),
  VendorGuide(
    vendor: 'OPPO / ColorOS',
    steps: <String>[
      '设置 → 应用管理 → 宠物 → 悬浮窗权限 → 允许',
      '电池 → 应用耗电管理 → 允许后台运行',
      '自启动 → 允许',
    ],
  ),
  VendorGuide(
    vendor: 'vivo / OriginOS',
    steps: <String>[
      '设置 → 应用与权限 → 权限管理 → 悬浮窗 → 允许',
      '电池 → 后台高耗电 → 允许',
      '自启动 → 允许',
    ],
  ),
  VendorGuide(
    vendor: '三星 / One UI',
    steps: <String>[
      '设置 → 应用程序 → 宠物 → 特殊访问 → 显示在其他应用上层',
      '电池 → 后台使用限制 → 不受限制',
      '自动启动 → 开启',
    ],
  ),
  VendorGuide(
    vendor: '原生 / Pixel',
    steps: <String>[
      '设置 → 应用 → 宠物 → 显示在其他应用上层 → 允许',
      '电池 → 不受限制',
      '无需厂商白名单',
    ],
  ),
];

/// iOS 实时活动关键限制（风险对策依据）。
class LiveActivityLimits {
  const LiveActivityLimits._();

  /// 活跃期上限（小时），到期系统自动结束。
  static const int activeHours = 8;

  /// 锁屏额外保留时长（小时）。
  static const int lockScreenExtraHours = 4;

  /// 续期间隔：每 6 小时重启一次以规避 8 小时上限。
  static const Duration renewInterval = Duration(hours: 6);

  /// 更新节流：按秒级设计，避免高频刷新被系统丢弃。
  static const Duration updateThrottle = Duration(seconds: 1);
}
