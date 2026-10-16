import 'package:flutter/material.dart';

import '../core/pet_state.dart';
import '../core/pet_theme.dart';
import '../core/pet_wake.dart';

/// 通用卡片容器。
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: PetTokens.surface,
        borderRadius: BorderRadius.circular(PetTokens.radiusMd),
        border: Border.all(color: PetTokens.border),
        boxShadow: PetTokens.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(title,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: PetTokens.text)),
                    if (subtitle != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(subtitle!,
                            style: const TextStyle(
                                fontSize: 12, color: PetTokens.textSub)),
                      ),
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

/// 设置开关行。
class SwitchRow extends StatelessWidget {
  const SwitchRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.disabled = false,
  });

  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(label,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: disabled ? PetTokens.textMute : PetTokens.text)),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(subtitle!,
                        style: const TextStyle(
                            fontSize: 11.5,
                            color: PetTokens.textSub,
                            height: 1.4)),
                  ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: disabled ? null : onChanged,
          ),
        ],
      ),
    );
  }
}

/// 触发源标签组：只展示本端可用触发源（能力降级）。
class TriggerChips extends StatelessWidget {
  const TriggerChips({super.key, required this.capabilities});

  final PetWakeCapabilities capabilities;

  @override
  Widget build(BuildContext context) {
    final Set<WakeTrigger> available = capabilities.availableTriggers;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: WakeTrigger.values.map((WakeTrigger t) {
        final bool on = available.contains(t);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: on ? PetTokens.secondarySoft : PetTokens.surface2,
            borderRadius: BorderRadius.circular(PetTokens.radiusPill),
            border: Border.all(
                color: on ? PetTokens.secondary : PetTokens.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(on ? Icons.check_circle : Icons.remove_circle_outline,
                  size: 13,
                  color: on ? PetTokens.secondary : PetTokens.textMute),
              const SizedBox(width: 5),
              Text(t.label,
                  style: TextStyle(
                      fontSize: 11.5,
                      color: on ? PetTokens.secondary : PetTokens.textMute)),
            ],
          ),
        );
      }).toList(),
    );
  }
}

/// 状态机演示：五个状态按钮。
class StateSelector extends StatelessWidget {
  const StateSelector({
    super.key,
    required this.current,
    required this.onSelect,
  });

  final PetState current;
  final ValueChanged<PetState> onSelect;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: kPetStates.map((PetStateMeta meta) {
        final bool on = meta.state == current;
        return GestureDetector(
          onTap: () => onSelect(meta.state),
          child: AnimatedContainer(
            duration: PetTokens.fast,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: on ? PetTokens.primary : PetTokens.surface2,
              borderRadius: BorderRadius.circular(PetTokens.radiusPill),
              border:
                  Border.all(color: on ? PetTokens.primary : PetTokens.border),
            ),
            child: Text(
              meta.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: on ? Colors.white : PetTokens.textSub,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// 键值表（能力对照 / 合规清单）。
class InfoTable extends StatelessWidget {
  const InfoTable({super.key, required this.rows});

  final List<List<String>> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: rows.map((List<String> row) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(
                width: 92,
                child: Text(row.first,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: PetTokens.textSub)),
              ),
              Expanded(
                child: Text(row.length > 1 ? row[1] : '',
                    style: const TextStyle(
                        fontSize: 12.5, color: PetTokens.text, height: 1.5)),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

/// 指标小卡。
class MetricTile extends StatelessWidget {
  const MetricTile({
    super.key,
    required this.label,
    required this.value,
    this.hint,
  });

  final String label;
  final String value;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: PetTokens.surface2,
        borderRadius: BorderRadius.circular(PetTokens.radiusSm),
        border: Border.all(color: PetTokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label,
              style: const TextStyle(fontSize: 11, color: PetTokens.textMute)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: PetTokens.text)),
          if (hint != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(hint!,
                  style: const TextStyle(
                      fontSize: 10.5, color: PetTokens.textSub)),
            ),
        ],
      ),
    );
  }
}

/// 提示条（降级说明 / 风险提示）。
class NoticeBar extends StatelessWidget {
  const NoticeBar({
    super.key,
    required this.text,
    this.kind = NoticeKind.info,
  });

  final String text;
  final NoticeKind kind;

  Color get _bg => switch (kind) {
        NoticeKind.info => PetTokens.secondarySoft,
        NoticeKind.warn => PetTokens.warningSoft,
        NoticeKind.error => PetTokens.dangerSoft,
      };

  Color get _fg => switch (kind) {
        NoticeKind.info => PetTokens.secondary,
        NoticeKind.warn => PetTokens.warning,
        NoticeKind.error => PetTokens.danger,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(PetTokens.radiusSm),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            switch (kind) {
              NoticeKind.info => Icons.info_outline,
              NoticeKind.warn => Icons.warning_amber_rounded,
              NoticeKind.error => Icons.error_outline,
            },
            size: 15,
            color: _fg,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: TextStyle(fontSize: 12, color: _fg, height: 1.5)),
          ),
        ],
      ),
    );
  }
}

enum NoticeKind { info, warn, error }
