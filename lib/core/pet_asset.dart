import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show AssetBundle, rootBundle;

import 'pet_state.dart';

/// 单个状态的素材条目，对应 `pet_asset.json` 中 `states[state]`。
@immutable
class PetAssetState {
  const PetAssetState({
    required this.state,
    required this.emoji,
    required this.text,
    required this.animation,
  });

  final PetState state;
  final String emoji;
  final String text;
  final String animation;

  factory PetAssetState.fromJson(PetState state, Map<String, dynamic> json) {
    return PetAssetState(
      state: state,
      emoji: (json['emoji'] as String?) ?? 'cat',
      text: (json['text'] as String?) ?? kLineOf(state),
      animation: (json['animation'] as String?) ?? 'none',
    );
  }
}

/// 素材包：角色 + 各状态配置。四端共享同一份配置，差异只在渲染方式。
@immutable
class PetAssetPackage {
  const PetAssetPackage({required this.pet, required this.states});

  final String pet;
  final Map<PetState, PetAssetState> states;

  /// 素材配置文件路径（随 App 打包，离线可用）。
  static const String assetPath = 'assets/pets/pet_asset.json';

  /// iOS 实时活动图片资源的安全上限（真实活动展示区尺寸受限）。
  /// 超过该尺寸可能导致活动无法启动 —— 见风险 R3。
  static const int liveActivitySafeSidePx = 96;

  factory PetAssetPackage.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> raw =
        (json['states'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    final Map<PetState, PetAssetState> parsed = <PetState, PetAssetState>{};
    raw.forEach((String key, dynamic value) {
      final PetState? state = _parseState(key);
      if (state == null) return;
      parsed[state] =
          PetAssetState.fromJson(state, (value as Map<String, dynamic>?) ?? const <String, dynamic>{});
    });
    return PetAssetPackage(
      pet: (json['pet'] as String?) ?? 'cat',
      states: Map<PetState, PetAssetState>.unmodifiable(parsed),
    );
  }

  static PetState? _parseState(String key) => switch (key.toLowerCase()) {
        'idle' => PetState.idle,
        'talking' => PetState.talking,
        'sleep' || 'sleeping' => PetState.sleep,
        'eat' || 'fish' => PetState.eat,
        'charge' || 'battery' => PetState.charge,
        _ => null,
      };

  /// 从资源包加载；测试可注入自定义 [AssetBundle]。
  static Future<PetAssetPackage> load([AssetBundle? bundle]) async {
    final String raw = await (bundle ?? rootBundle).loadString(assetPath);
    return PetAssetPackage.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  /// 状态的展示文案（素材包优先，回退台词库）。
  String textOf(PetState state) => states[state]?.text ?? kLineOf(state);

  /// 校验素材包完整性与 iOS 实时活动合规约束。
  ///
  /// 返回问题列表；为空表示通过。
  List<String> validate() {
    final List<String> issues = <String>[];
    if (pet.isEmpty) issues.add('缺少 pet 角色名');
    for (final PetStateMeta meta in kPetStates) {
      final PetAssetState? entry = states[meta.state];
      if (entry == null) {
        issues.add('缺少状态配置：${meta.state.name}');
        continue;
      }
      if (entry.emoji.isEmpty) issues.add('状态 ${meta.state.name} 缺少 emoji');
      if (entry.text.isEmpty) issues.add('状态 ${meta.state.name} 缺少文案');
    }
    return issues;
  }

  /// 供 UI 展示的 json 文本。
  String toPrettyJson() => const JsonEncoder.withIndent('  ').convert(
        <String, dynamic>{
          'pet': pet,
          'states': <String, dynamic>{
            for (final MapEntry<PetState, PetAssetState> e in states.entries)
              e.key.name: <String, dynamic>{
                'emoji': e.value.emoji,
                'text': e.value.text,
                'animation': e.value.animation,
              },
          },
        },
      );
}
