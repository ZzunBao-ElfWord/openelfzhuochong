import ActivityKit
import Foundation

/// 实时活动（灵动岛 / 锁屏卡片）的属性定义。
///
/// ⚠️ 该文件需同时加入 Runner 与 PetWakeWidget 两个 target 的 Compile Sources，
/// 否则 App 与 Widget 无法共享同一 ActivityAttributes 类型。
///
/// 与 Dart 侧 [PetState] 一一对应：state 为状态名（idle/talking/sleep/eat/charge），
/// text 为当前台词（见 pet_state.dart 的 kPetLines）。
struct PetActivityAttributes: ActivityAttributes {
  /// 动态内容：随状态回写而变化。
  struct ContentState: Codable, Hashable {
    /// 状态名，对应 Dart 端 PetState.name。
    var state: String
    /// 当前台词 / 提示文案。
    var text: String
  }

  /// 活动启动时固定的静态信息。
  var petName: String = "PetWake"
}
