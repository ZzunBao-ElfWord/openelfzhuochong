import '../core/capability_matrix.dart';
import '../core/pet_app_launcher.dart';
import '../core/pet_wake.dart';
import 'android/android_overlay_adapter.dart';
import 'desktop/desktop_pet_adapter.dart';
import 'ios/ios_live_activity_adapter.dart';
import 'preview/preview_pet_adapter.dart';

/// 当前端的完整能力集合：唤起适配器 + 可选的应用唤起器。
///
/// 保留具体适配器引用，供设置面板调用端特有操作
/// （点击穿透、悬浮窗权限引导、实时活动续期等）。
class PetPlatformBundle {
  const PetPlatformBundle({
    required this.kind,
    required this.wake,
    required this.launcher,
    this.desktop,
    this.android,
    this.ios,
  });

  final DeviceKind kind;
  final PetWake wake;
  final PetAppLauncher launcher;
  final DesktopPetAdapter? desktop;
  final AndroidOverlayAdapter? android;
  final IosLiveActivityAdapter? ios;

  PlatformCapability? get capability => capabilityFor(kind);
}

/// 按端创建适配器：业务层只拿到 [PetWake] 抽象，平台差异在此收敛。
PetPlatformBundle createPlatformBundle({
  required DeviceKind kind,
  bool hotkeyEnabled = true,
}) {
  switch (kind) {
    case DeviceKind.windows:
    case DeviceKind.macos:
      final DesktopPetAdapter desktop =
          DesktopPetAdapter(hotkeyEnabled: hotkeyEnabled);
      return PetPlatformBundle(
        kind: kind,
        wake: desktop,
        launcher: DesktopAppLauncher(),
        desktop: desktop,
      );
    case DeviceKind.android:
      final AndroidOverlayAdapter android = AndroidOverlayAdapter();
      return PetPlatformBundle(
        kind: kind,
        wake: android,
        launcher: AndroidAppLauncher(),
        android: android,
      );
    case DeviceKind.ios:
      final IosLiveActivityAdapter ios = IosLiveActivityAdapter();
      return PetPlatformBundle(
        kind: kind,
        wake: ios,
        launcher: IosAppLauncher(),
        ios: ios,
      );
    case DeviceKind.unknown:
      return PetPlatformBundle(
        kind: kind,
        wake: PreviewPetAdapter(),
        launcher: NoopAppLauncher(),
      );
  }
}
