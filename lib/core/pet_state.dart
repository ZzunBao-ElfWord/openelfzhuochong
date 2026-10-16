import 'package:flutter/foundation.dart';

/// 宠物状态。四端共用同一状态集合，适配器只决定如何呈现。
///
/// 与原型 `mock.js` 的 `states` 保持一致：idle / talking / sleep / eat / charge。
enum PetState { idle, talking, sleep, eat, charge }

/// 状态的展示元数据：标签、图标、动画名、素材说明。
@immutable
class PetStateMeta {
  const PetStateMeta({
    required this.state,
    required this.label,
    required this.icon,
    required this.animation,
    required this.asset,
    required this.note,
  });

  final PetState state;
  final String label;
  final String icon;
  final String animation;
  final String asset;
  final String note;
}

/// 台词库：四端共用，默认本地存储，不依赖网络。
const Map<PetState, String> kPetLines = <PetState, String>{
  PetState.idle: '待机中',
  PetState.talking: '我在呢，今天也要加油哦',
  PetState.sleep: '我先打个盹',
  PetState.eat: '吃饱啦，谢谢',
  PetState.charge: '充电中，能量满满',
};

/// 取某个状态的台词，缺失时回退为空串。
String kLineOf(PetState state) => kPetLines[state] ?? '';

/// 状态元数据列表（顺序与原型一致，供状态面板与状态机演示使用）。
const List<PetStateMeta> kPetStates = <PetStateMeta>[
  PetStateMeta(
    state: PetState.idle,
    label: '待机',
    icon: 'cat',
    animation: 'blink 呼吸',
    asset: 'pet_cat 睁眼',
    note: '常驻默认态，轻微呼吸位移',
  ),
  PetStateMeta(
    state: PetState.talking,
    label: '对话',
    icon: 'volume-2',
    animation: 'talkBounce',
    asset: 'pet_cat 发声口型',
    note: '唤起后进入，播放语音问候',
  ),
  PetStateMeta(
    state: PetState.sleep,
    label: '打盹',
    icon: 'moon',
    animation: 'none 帧静止',
    asset: 'pet_cat_sleep 蜷缩',
    note: '静置 15 分钟自动进入',
  ),
  PetStateMeta(
    state: PetState.eat,
    label: '进食',
    icon: 'fish',
    animation: 'munch 咀嚼',
    asset: 'pet_cat 低头帧',
    note: '投喂触发，持续 3 秒',
  ),
  PetStateMeta(
    state: PetState.charge,
    label: '充电',
    icon: 'battery-charging',
    animation: 'chargeFloat',
    asset: 'pet_cat 静帧',
    note: '接电源触发，状态回写优先',
  ),
];

/// 是否为「蜷缩」形态（用于选择素材：打盹与充电共用静帧）。
bool kUsesSleepAsset(PetState state) =>
    state == PetState.sleep || state == PetState.charge;
