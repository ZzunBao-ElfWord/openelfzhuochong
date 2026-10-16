import 'package:flutter/material.dart';

import '../adapters/pet_adapter_factory.dart';
import '../core/pet_character.dart';
import '../core/pet_controller.dart';
import '../core/pet_settings.dart';
import '../core/pet_state.dart';
import '../core/pet_theme.dart';
import '../core/pet_wake.dart';
import 'permission_guide.dart';
import 'pet_picker.dart';
import 'pet_view.dart';

/// 萌宠主页体：选择条 + 大宠物 + 几个动作按钮 + 权限引导。
///
/// 桌面面板与移动主页共用，保持「简单、萌、可互动」的一致体验。
/// 高级设置（控制台）由 [onOpenSettings] 跳转，不在主页堆叠。
class PetHomeBody extends StatelessWidget {
  const PetHomeBody({
    super.key,
    required this.controller,
    required this.bundle,
    required this.settings,
    required this.onSettingsChanged,
    this.onOpenSettings,
  });

  final PetController controller;
  final PetPlatformBundle bundle;
  final PetSettings settings;
  final ValueChanged<PetSettings> onSettingsChanged;
  final VoidCallback? onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (BuildContext context, Widget? _) {
        final PetCharacter c = controller.character;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: <Widget>[
            PetPicker(
              characters: kCharacters,
              selectedId: c.id,
              onSelect: (PetCharacter next) {
                controller.setCharacter(next);
                onSettingsChanged(settings.copyWith(characterId: next.id));
              },
            ),
            const SizedBox(height: 14),
            Center(
              child: SpeechBubble(
                text: controller.bubble.isEmpty
                    ? c.lineOf(controller.state)
                    : controller.bubble,
                visible: controller.bubble.isNotEmpty ||
                    controller.state != PetState.idle,
                maxWidth: 220,
              ),
            ),
            const SizedBox(height: 10),
            Center(child: PetAvatar(state: controller.state, character: c, size: 132)),
            const SizedBox(height: 8),
            Center(child: PetWaveform(speaking: controller.speaking)),
            const SizedBox(height: 10),
            Center(child: StatePill(meta: controller.meta)),
            const SizedBox(height: 18),
            _Actions(controller: controller),
            const SizedBox(height: 18),
            PermissionGuideCard(bundle: bundle),
            const SizedBox(height: 14),
            if (onOpenSettings != null)
              Center(
                child: TextButton.icon(
                  onPressed: onOpenSettings,
                  icon: const Icon(Icons.settings, size: 16),
                  label: const Text('更多设置'),
                  style: TextButton.styleFrom(foregroundColor: PetTokens.textSub),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// 几个重要动作按钮：唤起 / 投喂 / 打盹 / 充电。
class _Actions extends StatelessWidget {
  const _Actions({required this.controller});

  final PetController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        _ActionButton(
          icon: Icons.notifications_active,
          label: '唤起',
          color: PetTokens.primary,
          filled: true,
          busy: controller.busy,
          onTap: () => controller.wake(WakeTrigger.tap),
        ),
        _ActionButton(
          icon: Icons.set_meal,
          label: '投喂',
          color: PetTokens.warning,
          busy: controller.busy,
          onTap: controller.feed,
        ),
        _ActionButton(
          icon: Icons.bedtime,
          label: '打盹',
          color: PetTokens.secondary,
          busy: controller.busy,
          onTap: controller.nap,
        ),
        _ActionButton(
          icon: Icons.battery_charging_full,
          label: '充电',
          color: PetTokens.success,
          busy: controller.busy,
          onTap: controller.charge,
        ),
      ],
    );
  }
}

/// 圆形动作按钮：图标 + 文字。
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.filled = false,
    this.busy = false,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool filled;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final bool disabled = busy;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        InkResponse(
          onTap: disabled ? null : onTap,
          radius: 30,
          child: Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: filled ? color : color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: filled ? null : Border.all(color: color.withValues(alpha: 0.4)),
            ),
            child: Icon(icon,
                size: 24, color: filled ? Colors.white : color),
          ),
        ),
        const SizedBox(height: 5),
        Text(label,
            style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: disabled ? PetTokens.textMute : PetTokens.text)),
      ],
    );
  }
}
