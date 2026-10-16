import 'package:flutter/material.dart';

/// 设计令牌：与原型 `styles.css` 的 `:root` 一一对应。
///
/// 唯一实现，所有界面组件只引用这里的常量，不写死颜色/圆角/阴影，
/// 保证四端视觉一致。
class PetTokens {
  const PetTokens._();

  // 主色 / 辅助色
  static const Color primary = Color(0xFFE0662F);
  static const Color primaryHover = Color(0xFFC9551F);
  static const Color primarySoft = Color(0xFFFBE7DB);
  static const Color secondary = Color(0xFF2E6E62);
  static const Color secondarySoft = Color(0xFFDDEBE7);

  // 背景 / 表面
  static const Color bg = Color(0xFFF7F2E9);
  static const Color bg2 = Color(0xFFEFE7DA);
  static const Color surface = Color(0xFFFFFDF9);
  static const Color surface2 = Color(0xFFFBF6EE);
  static const Color border = Color(0xFFE4D9C8);
  static const Color borderStrong = Color(0xFFD3C4AC);

  // 文本
  static const Color text = Color(0xFF2A2119);
  static const Color textSub = Color(0xFF7C7263);
  static const Color textMute = Color(0xFFA79B88);

  // 语义色
  static const Color success = Color(0xFF3E8F5C);
  static const Color successSoft = Color(0xFFE3F1E7);
  static const Color warning = Color(0xFFC98A2B);
  static const Color warningSoft = Color(0xFFFAEFD8);
  static const Color danger = Color(0xFFC8554E);
  static const Color dangerSoft = Color(0xFFF8E3E1);

  // 圆角
  static const double radiusSm = 8;
  static const double radiusMd = 14;
  static const double radiusLg = 22;
  static const double radiusPill = 999;

  // 间距
  static const double gapXs = 4;
  static const double gapSm = 8;
  static const double gapMd = 16;
  static const double gapLg = 24;
  static const double gapXl = 32;

  // 动效
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration normal = Duration(milliseconds: 320);
  static const Duration slow = Duration(milliseconds: 560);
  static const Curve ease = Curves.easeInOut;

  /// 桌面紧凑窗尺寸（透明置顶宠物窗）。
  static const Size compactWindow = Size(220, 260);

  /// 设置面板窗尺寸（同一窗口放大，避免多窗口复杂度）。
  static const Size panelWindow = Size(420, 620);

  static List<BoxShadow> get shadowSm => <BoxShadow>[
        BoxShadow(
          color: _ink(0.06),
          blurRadius: 3,
          offset: const Offset(0, 1),
        ),
      ];

  static List<BoxShadow> get shadowMd => <BoxShadow>[
        BoxShadow(
          color: _ink(0.08),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ];

  static List<BoxShadow> get shadowLg => <BoxShadow>[
        BoxShadow(
          color: _ink(0.14),
          blurRadius: 46,
          offset: const Offset(0, 18),
        ),
      ];

  static Color _ink(double opacity) =>
      const Color(0xFF3C2A14).withValues(alpha: opacity);

  /// 全局主题：四端共用（浅色、暖米底、宋体标题）。
  static ThemeData light() {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
    ).copyWith(
      surface: surface,
      primary: primary,
      secondary: secondary,
      error: danger,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      splashFactory: InkSparkle.splashFactory,
      textTheme: const TextTheme(
        displaySmall: TextStyle(fontWeight: FontWeight.w700, color: text),
        titleLarge: TextStyle(fontWeight: FontWeight.w700, color: text),
        titleMedium: TextStyle(fontWeight: FontWeight.w600, color: text),
        bodyMedium: TextStyle(color: text, height: 1.6),
        bodySmall: TextStyle(color: textSub, height: 1.5),
        labelSmall: TextStyle(color: textMute, letterSpacing: 0.4),
      ),
      dividerTheme: const DividerThemeData(color: border, thickness: 1, space: 1),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          side: const BorderSide(color: border),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface2,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusPill)),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: text,
          side: const BorderSide(color: borderStrong),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusPill)),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return surface;
        }),
        trackColor: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
          if (states.contains(WidgetState.selected)) return primary;
          return borderStrong;
        }),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: text,
        contentTextStyle: const TextStyle(color: surface),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSm)),
      ),
    );
  }
}
