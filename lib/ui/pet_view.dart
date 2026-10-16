import 'package:flutter/material.dart';

import '../core/pet_character.dart';
import '../core/pet_state.dart';
import '../core/pet_theme.dart';

/// 宠物形象：emoji + 强调色光环，按状态切换动效。
///
/// 不依赖素材图，四端统一渲染。状态驱动动效：
/// - 待机：呼吸缩放 + 偶发眨眼
/// - 对话：上下弹跳
/// - 打盹：微微倾斜 + 飘浮「Zzz」
/// - 进食：冒爱心
/// - 充电：强调色光晕脉动
class PetAvatar extends StatefulWidget {
  const PetAvatar({
    super.key,
    required this.state,
    required this.character,
    this.size = 120,
  });

  final PetState state;
  final PetCharacter character;
  final double size;

  @override
  State<PetAvatar> createState() => _PetAvatarState();
}

class _PetAvatarState extends State<PetAvatar>
    with TickerProviderStateMixin {
  late final AnimationController _breath = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat(reverse: true);

  late final AnimationController _talk = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  )..repeat(reverse: true);

  late final AnimationController _glow = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _breath.dispose();
    _talk.dispose();
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final PetCharacter c = widget.character;
    final bool talking = widget.state == PetState.talking;
    final bool sleeping = widget.state == PetState.sleep;
    final bool charging = widget.state == PetState.charge;
    final bool eating = widget.state == PetState.eat;

    return AnimatedBuilder(
      animation: Listenable.merge(<Listenable>[_breath, _talk, _glow]),
      builder: (BuildContext context, Widget? _) {
        final double b = _breath.value;
        final double scale = 1 + b * 0.04;
        final double lift = talking ? -_talk.value * 10 : 0;
        final double rotate = sleeping ? -0.12 + b * 0.02 : 0;
        final double glow = charging ? 0.4 + _glow.value * 0.6 : 0;

        return Stack(
          alignment: Alignment.center,
          children: <Widget>[
            // 光晕（充电 / 通用外发光）
            if (glow > 0)
              Container(
                width: widget.size * 1.6,
                height: widget.size * 1.6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: <Color>[
                      c.accent.withValues(alpha: 0.35 * glow),
                      c.accent.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            // 主体圆盘
            Transform.translate(
              offset: Offset(0, lift),
              child: Transform.rotate(
                angle: rotate,
                child: Transform.scale(
                  scale: scale,
                  child: _Face(character: c, size: widget.size),
                ),
              ),
            ),
            // 状态浮层
            if (sleeping)
              Positioned(
                right: widget.size * 0.04,
                top: widget.size * 0.02,
                child: _FloatZzz(size: widget.size * 0.18, color: c.accent),
              ),
            if (eating)
              Positioned(
                top: -widget.size * 0.1,
                child: _FloatingHeart(size: widget.size * 0.22),
              ),
            if (charging)
              Positioned(
                bottom: 0,
                right: widget.size * 0.02,
                child: Icon(Icons.bolt,
                    size: widget.size * 0.26, color: c.accent),
              ),
          ],
        );
      },
    );
  }
}

/// 宠物脸：圆盘 + emoji。
class _Face extends StatelessWidget {
  const _Face({required this.character, required this.size});

  final PetCharacter character;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            character.accentSoft,
            PetTokens.surface,
          ],
        ),
        border: Border.all(
          color: character.accent.withValues(alpha: 0.35),
          width: 2,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: character.accent.withValues(alpha: 0.18),
            blurRadius: size * 0.35,
            offset: Offset(0, size * 0.08),
          ),
        ],
      ),
      child: Text(
        character.emoji,
        style: TextStyle(fontSize: size * 0.56),
      ),
    );
  }
}

/// 打盹时飘浮的 Zzz。
class _FloatZzz extends StatefulWidget {
  const _FloatZzz({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  State<_FloatZzz> createState() => _FloatZzzState();
}

class _FloatZzzState extends State<_FloatZzz>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2000),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (BuildContext context, Widget? _) {
        return Opacity(
          opacity: 0.5 + 0.5 * _c.value,
          child: Text('Zzz',
              style: TextStyle(
                fontSize: widget.size,
                fontWeight: FontWeight.w700,
                color: widget.color,
              )),
        );
      },
    );
  }
}

/// 进食时冒出的爱心。
class _FloatingHeart extends StatefulWidget {
  const _FloatingHeart({required this.size});

  final double size;

  @override
  State<_FloatingHeart> createState() => _FloatingHeartState();
}

class _FloatingHeartState extends State<_FloatingHeart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (BuildContext context, Widget? _) {
        final double t = _c.value;
        return Transform.translate(
          offset: Offset(0, -t * 28),
          child: Opacity(
            opacity: 1 - t,
            child: Text('❤️', style: TextStyle(fontSize: widget.size)),
          ),
        );
      },
    );
  }
}

/// 台词气泡。可见性由 [visible] 控制，带淡入位移。
class SpeechBubble extends StatelessWidget {
  const SpeechBubble({
    super.key,
    required this.text,
    this.visible = true,
    this.maxWidth = 240,
  });

  final String text;
  final bool visible;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      duration: PetTokens.normal,
      curve: PetTokens.ease,
      offset: visible ? Offset.zero : const Offset(0, 0.25),
      child: AnimatedOpacity(
        duration: PetTokens.normal,
        opacity: visible ? 1 : 0,
        child: Container(
          constraints: BoxConstraints(maxWidth: maxWidth),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: PetTokens.surface,
            borderRadius: BorderRadius.circular(PetTokens.radiusMd),
            border: Border.all(color: PetTokens.border),
            boxShadow: PetTokens.shadowMd,
          ),
          child: Text(
            text,
            style: const TextStyle(
              color: PetTokens.text,
              fontSize: 13,
              height: 1.45,
            ),
          ),
        ),
      ),
    );
  }
}

/// 发声波形：播放语音时跳动，其余时间静默。
class PetWaveform extends StatefulWidget {
  const PetWaveform({super.key, required this.speaking, this.bars = 5, this.height = 22});

  final bool speaking;
  final int bars;
  final double height;

  @override
  State<PetWaveform> createState() => _PetWaveformState();
}

class _PetWaveformState extends State<PetWaveform>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (BuildContext context, Widget? child) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List<Widget>.generate(widget.bars, (int i) {
              final double phase = (i + 1) / (widget.bars + 1);
              final double wave =
                  widget.speaking ? (0.35 + 0.65 * ((phase + _controller.value) % 1.0)) : 0.18;
              return Container(
                width: 3,
                height: widget.height * wave,
                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                decoration: BoxDecoration(
                  color: widget.speaking
                      ? PetTokens.primary
                      : PetTokens.borderStrong,
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

/// 状态标签（待机 / 对话 / 打盹 / 进食 / 充电）。
class StatePill extends StatelessWidget {
  const StatePill({super.key, required this.meta, this.compact = false});

  final PetStateMeta meta;
  final bool compact;

  IconData get _icon => switch (meta.state) {
        PetState.idle => Icons.pets,
        PetState.talking => Icons.graphic_eq,
        PetState.sleep => Icons.bedtime,
        PetState.eat => Icons.set_meal,
        PetState.charge => Icons.battery_charging_full,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: PetTokens.primarySoft,
        borderRadius: BorderRadius.circular(PetTokens.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(_icon, size: compact ? 12 : 14, color: PetTokens.primary),
          const SizedBox(width: 5),
          Text(
            meta.label,
            style: TextStyle(
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w600,
              color: PetTokens.primaryHover,
            ),
          ),
        ],
      ),
    );
  }
}
