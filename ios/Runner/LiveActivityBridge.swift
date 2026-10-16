import ActivityKit
import Flutter
import UIKit

/// iOS 端原生桥：把 Dart 侧 `petwake/activity` 通道的 start/update/end
/// 映射到 ActivityKit 的实时活动生命周期，并在用户点按灵动岛 / 锁屏卡片
/// 打开 App 后回传 `onIslandTapped` 事件。
///
/// ⚠️ 需在 Xcode 中：
/// 1. 将本文件与 `PetActivityAttributes.swift` 加入 Runner target 的 Compile Sources；
/// 2. 新建 Widget Extension target（含 `PetWakeWidget/PetWakeWidget.swift`），
///    并把 `PetActivityAttributes.swift` 同时加入该 target；
/// 3. 在 Runner target 的 Signing & Capabilities 中开启 Live Activities
///    （Info.plist 已声明 NSSupportsLiveActivities）。
@available(iOS 16.2, *)
public class LiveActivityBridge: NSObject, FlutterPlugin {
  private var activity: Activity<PetActivityAttributes>?
  private static var channel: FlutterMethodChannel?

  /// 供 AppDelegate 注册（见 `didInitializeImplicitFlutterEngine`）。
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "petwake/activity",
      binaryMessenger: registrar.messenger()
    )
    let instance = LiveActivityBridge()
    registrar.addMethodCallDelegate(instance, channel: channel)
    LiveActivityBridge.channel = channel
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let args = call.arguments as? [String: Any] ?? [:]

    switch call.method {
    case "start":
      start(state: args["state"] as? String ?? "idle",
            text: args["text"] as? String ?? "待机中",
            result: result)
    case "update":
      update(state: args["state"] as? String ?? "idle",
             text: args["text"] as? String ?? "",
             result: result)
    case "end":
      end(result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  // MARK: - 生命周期

  private func start(state: String, text: String, result: @escaping FlutterResult) {
    guard ActivityAuthorizationInfo().areActivitiesEnabled else {
      // 用户关闭了实时活动：静默降级，不阻断主链路。
      result(nil)
      return
    }
    // 单例：先结束既有活动，避免重复。
    Task {
      for existing in Activity<PetActivityAttributes>.activities {
        await existing.end(nil, dismissalPolicy: .immediate)
      }
      do {
        let attributes = PetActivityAttributes(petName: "PetWake")
        let content = ActivityContent(
          state: PetActivityAttributes.ContentState(state: state, text: text),
          staleDate: nil
        )
        let started = try Activity.request(
          attributes: attributes,
          content: content,
          pushType: nil
        )
        self.activity = started
        result(started.id)
      } catch {
        result(nil)
      }
    }
  }

  private func update(state: String, text: String, result: @escaping FlutterResult) {
    Task {
      let content = ActivityContent(
        state: PetActivityAttributes.ContentState(state: state, text: text),
        staleDate: nil
      )
      await self.activity?.update(content)
      result(nil)
    }
  }

  private func end(result: @escaping FlutterResult) {
    Task {
      let content = ActivityContent(
        state: PetActivityAttributes.ContentState(state: "idle", text: "已收起"),
        staleDate: nil
      )
      await self.activity?.end(content, dismissalPolicy: .immediate)
      self.activity = nil
      result(nil)
    }
  }

  /// 由 App 在收到系统打开链接 / 前台化时调用，回传点按事件到 Dart。
  static func notifyIslandTapped() {
    channel?.invokeMethod("onIslandTapped", arguments: nil)
  }
}
