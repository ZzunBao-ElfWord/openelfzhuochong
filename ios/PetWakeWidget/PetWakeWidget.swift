import ActivityKit
import SwiftUI
import WidgetKit

/// 实时活动 Widget Bundle。
///
/// ⚠️ 新建 Widget Extension target 时，把本文件加入该 target 的 Compile Sources，
/// 并将 `Runner/PetActivityAttributes.swift` 一并加入，使 App 与 Widget 共享类型。
/// 宠物头像素材 `pet_cat` 需放入该 target 的 Asset Catalog（或用 SF Symbol 兜底）。
@main
struct PetWakeWidgetBundle: WidgetBundle {
  var body: some Widget {
    PetWakeLiveActivity()
  }
}

struct PetWakeLiveActivity: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: PetActivityAttributes.self) { context in
      // 锁屏 / 通知中心卡片（跳转式：点按由系统打开 App）。
      HStack(spacing: 12) {
        PetAvatarImage(size: 44)
        VStack(alignment: .leading, spacing: 2) {
          Text(context.attributes.petName)
            .font(.headline)
          Text(context.state.text)
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        Spacer(minLength: 0)
      }
      .padding()
      .activityBackgroundTint(Color(red: 0.99, green: 0.95, blue: 0.90))
      .activitySystemActionForegroundColor(Color(red: 0.96, green: 0.62, blue: 0.16))
      // 点按卡片时以 petwake://wake 打开 App，回传唤起事件（见 AppDelegate）。
      .widgetURL(URL(string: "petwake://wake"))
    } dynamicIsland: { context in
      DynamicIsland {
        // 展开态（长按岛展开）。
        DynamicIslandExpandedRegion(.leading) {
          PetAvatarImage(size: 40)
        }
        DynamicIslandExpandedRegion(.trailing) {
          Text(context.state.state)
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        DynamicIslandExpandedRegion(.center) {
          Text(context.state.text)
            .font(.callout)
            .lineLimit(2)
        }
      } compactLeading: {
        // 紧凑态左：宠物头像。
        PetAvatarImage(size: 20)
      } compactTrailing: {
        // 紧凑态右：状态点。
        Circle()
          .fill(Color(red: 0.96, green: 0.62, blue: 0.16))
          .frame(width: 10, height: 10)
      } minimal: {
        // 最小态：仅一个呼吸点。
        Circle()
          .fill(Color(red: 0.96, green: 0.62, blue: 0.16))
          .frame(width: 8, height: 8)
      }
    }
  }
}

/// 宠物头像：优先用 Asset Catalog 的 `pet_cat`，缺失时回退 SF Symbol，保证不空白。
private struct PetAvatarImage: View {
  let size: CGFloat

  var body: some View {
    Group {
      if UIImage(named: "pet_cat") != nil {
        Image("pet_cat").resizable().scaledToFill()
      } else {
        Image(systemName: "pawprint.fill")
          .resizable()
          .scaledToFit()
          .padding(size * 0.18)
          .foregroundStyle(Color(red: 0.96, green: 0.62, blue: 0.16))
      }
    }
    .frame(width: size, height: size)
    .clipShape(Circle())
  }
}
