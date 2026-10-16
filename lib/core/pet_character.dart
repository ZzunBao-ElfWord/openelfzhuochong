import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import 'pet_state.dart';

/// 一只萌宠的视觉与性格设定。
///
/// 主页只提供少量选择（几只），让用户一眼挑中陪伴者，而不是在选项海里迷失。
@immutable
class PetCharacter {
  const PetCharacter({
    required this.id,
    required this.name,
    required this.emoji,
    required this.accent,
    required this.accentSoft,
    required this.lines,
  });

  final String id;
  final String name;

  /// 头像用的 emoji（统一形象，四端无需额外素材）。
  final String emoji;

  /// 强调色：选中态描边 / 光环 / 按钮点缀。
  final Color accent;

  /// 强调色的浅底。
  final Color accentSoft;

  /// 每个状态的台词，缺省回退到 [kLineOf]。
  final Map<PetState, String> lines;

  String lineOf(PetState state) => lines[state] ?? kLineOf(state);

  static PetCharacter byId(String? id) {
    for (final PetCharacter c in kCharacters) {
      if (c.id == id) return c;
    }
    return kCharacters.first;
  }
}

/// 主页展示的萌宠清单（少即是多，4 只足够）。
const List<PetCharacter> kCharacters = <PetCharacter>[
  PetCharacter(
    id: 'cat',
    name: '橘喵',
    emoji: '🐱',
    accent: Color(0xFFE0662F),
    accentSoft: Color(0xFFFBE7DB),
    lines: <PetState, String>{
      PetState.idle: '喵～在等你陪我玩',
      PetState.talking: '在呢在呢，今天也要好好吃饭哦',
      PetState.sleep: '困困，先眯一会儿',
      PetState.eat: '小鱼干真好吃，喵呜',
      PetState.charge: '能量满满，喵！',
    },
  ),
  PetCharacter(
    id: 'bunny',
    name: '奶糖兔',
    emoji: '🐰',
    accent: Color(0xFFD886C9),
    accentSoft: Color(0xFFF8E6F3),
    lines: <PetState, String>{
      PetState.idle: '蹦蹦跳跳，等你来摸头',
      PetState.talking: '嗨呀～今天有什么开心事呀',
      PetState.sleep: '耳朵耷拉，呼呼大睡',
      PetState.eat: '胡萝卜最棒啦',
      PetState.charge: '充电中，马上就能跳更高',
    },
  ),
  PetCharacter(
    id: 'dog',
    name: '旺财',
    emoji: '🐶',
    accent: Color(0xFFC98A2B),
    accentSoft: Color(0xFFFAEFD8),
    lines: <PetState, String>{
      PetState.idle: '汪！主人去哪我去哪',
      PetState.talking: '我来啦！想不想出去走走',
      PetState.sleep: '趴着睡，尾巴还在摇',
      PetState.eat: '骨头！是骨头！',
      PetState.charge: '充电完毕，随时待命',
    },
  ),
  PetCharacter(
    id: 'bear',
    name: '团团熊',
    emoji: '🐻',
    accent: Color(0xFF2E6E62),
    accentSoft: Color(0xFFDDEBE7),
    lines: <PetState, String>{
      PetState.idle: '稳稳坐着，给你靠',
      PetState.talking: '我在这儿，累了就抱抱我',
      PetState.sleep: '冬眠模式，呼噜呼噜',
      PetState.eat: '蜂蜜甜甜，心情好好',
      PetState.charge: '能量恢复中，慢慢来',
    },
  ),
];
