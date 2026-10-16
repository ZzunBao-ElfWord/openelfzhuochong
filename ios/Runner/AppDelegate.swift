import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    // 注册实时活动原生桥（见 LiveActivityBridge.swift）。
    if #available(iOS 16.2, *) {
      if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "PetWakeLiveActivityBridge") {
        LiveActivityBridge.register(with: registrar)
      }
    }
    // 注册第三方应用唤起桥（对齐 Dart 侧 IosAppLauncher 的 openUrl）。
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "PetWakeAppLauncher") {
      AppLauncherBridge.register(with: registrar)
    }
  }

  /// 点按灵动岛 / 锁屏卡片时，系统以 petwake://wake 打开 App，回传唤起事件。
  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    if url.scheme == "petwake" {
      if #available(iOS 16.2, *) {
        LiveActivityBridge.notifyIslandTapped()
      }
      return true
    }
    return super.application(app, open: url, options: options)
  }
}

/// 第三方应用唤起桥：实现 Dart 侧 `petwake/apps` 通道的 openUrl 调用。
/// iOS 无法枚举已安装应用，仅能唤起 Info.plist 白名单中的预配置 Scheme。
final class AppLauncherBridge: NSObject, FlutterPlugin {
  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "petwake/apps",
      binaryMessenger: registrar.messenger()
    )
    registrar.addMethodCallDelegate(AppLauncherBridge(), channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard call.method == "openUrl",
          let args = call.arguments as? [String: Any],
          let urlString = args["url"] as? String,
          let url = URL(string: urlString) else {
      result(false)
      return
    }
    UIApplication.shared.open(url, options: [:]) { ok in
      result(ok)
    }
  }
}
