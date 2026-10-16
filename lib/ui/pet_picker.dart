import 'package:flutter/material.dart';

import '../core/pet_character.dart';
import '../core/pet_theme.dart';

/// 主页的宠物选择条：几只候选，选中态用强调色描边 + 名字。
///
/// 设计取舍：横向少量选项（而非大网格），让「挑一只」成本最低；
/// 选中态直接反映在下方大宠物形象上。
class PetPicker extends StatelessWidget {
  const PetPicker({
    super.key,
    required this.characters,
    required this.selectedId,
    required this.onSelect,
  });

  final List<PetCharacter> characters;
  final String selectedId;
  final ValueChanged<PetCharacter> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 76,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: characters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (BuildContext context, int i) {
          final PetCharacter c = characters[i];
          final bool on = c.id == selectedId;
          return GestureDetector(
            onTap: () => onSelect(c),
            child: AnimatedContainer(
              duration: PetTokens.fast,
              width: 64,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: on ? c.accentSoft : PetTokens.surface,
                borderRadius: BorderRadius.circular(PetTokens.radiusMd),
                border: Border.all(
                  color: on ? c.accent : PetTokens.border,
                  width: on ? 2.2 : 1,
                ),
                boxShadow: on
                    ? <BoxShadow>[
                        BoxShadow(
                          color: c.accent.withValues(alpha: 0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(c.emoji, style: const TextStyle(fontSize: 28)),
                  const SizedBox(height: 2),
                  Text(
                    c.name,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: on ? c.accent : PetTokens.textSub,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
