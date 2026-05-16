import 'package:flutter/material.dart';

/// Charte Al-Fakhir : rouge marque, surfaces douces, contraste lisible.
abstract final class AppColors {
  static const Color brandRed = Color(0xFFD62D20);
  static const Color background = Color(0xFFF0F2F5);
  static const Color surface = Colors.white;
  /// Accent secondaire (liens, survols discrets).
  static const Color accentTeal = Color(0xFF0D7377);
}

ThemeData buildAlFakhirTheme() {
  const seed = AppColors.brandRed;
  final colorScheme = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: Brightness.light,
    primary: AppColors.brandRed,
    surface: AppColors.surface,
    tertiary: AppColors.accentTeal,
  );

  final onBg = colorScheme.onSurface.withValues(alpha: 0.72);
  final titleStyle = TextStyle(
    color: colorScheme.onSurface,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    visualDensity: VisualDensity.standard,
    scaffoldBackgroundColor: AppColors.background,
    splashFactory: InkSparkle.splashFactory,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
      },
    ),
    textTheme: TextTheme(
      headlineLarge: titleStyle.copyWith(fontSize: 32, height: 1.15),
      headlineMedium: titleStyle.copyWith(fontSize: 26, height: 1.2),
      headlineSmall: titleStyle.copyWith(fontSize: 22, height: 1.25),
      titleLarge: titleStyle.copyWith(fontSize: 20, height: 1.25),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
        letterSpacing: -0.2,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        height: 1.45,
        color: colorScheme.onSurface,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        height: 1.45,
        color: colorScheme.onSurface.withValues(alpha: 0.92),
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        height: 1.35,
        color: onBg,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: colorScheme.onSurface,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.35)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.28)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: AppColors.surface,
      surfaceTintColor: colorScheme.surfaceTint.withValues(alpha: 0.06),
      shadowColor: colorScheme.shadow.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.45)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        visualDensity: VisualDensity.comfortable,
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    ),
    dialogTheme: DialogThemeData(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: AppColors.surface,
      surfaceTintColor: colorScheme.surfaceTint.withValues(alpha: 0.08),
    ),
    listTileTheme: ListTileThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    ),
    dividerTheme: DividerThemeData(
      color: colorScheme.outlineVariant.withValues(alpha: 0.55),
      space: 1,
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: colorScheme.surface,
      elevation: 0,
      indicatorColor: colorScheme.primaryContainer.withValues(alpha: 0.65),
      selectedIconTheme: IconThemeData(color: colorScheme.primary, size: 24),
      selectedLabelTextStyle: TextStyle(
        color: colorScheme.primary,
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
      unselectedIconTheme: IconThemeData(
        color: colorScheme.onSurfaceVariant,
        size: 22,
      ),
      unselectedLabelTextStyle: TextStyle(
        color: colorScheme.onSurfaceVariant,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      labelType: NavigationRailLabelType.all,
      useIndicator: true,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.surface,
      foregroundColor: colorScheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      surfaceTintColor: colorScheme.surfaceTint.withValues(alpha: 0.06),
      centerTitle: false,
      titleSpacing: 20,
      toolbarHeight: 64,
      shape: Border(
        bottom: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSecondaryContainer,
      ),
    ),
    tooltipTheme: TooltipThemeData(
      waitDuration: const Duration(milliseconds: 400),
      showDuration: const Duration(seconds: 4),
      decoration: BoxDecoration(
        color: colorScheme.inverseSurface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(10),
      ),
      textStyle: TextStyle(color: colorScheme.onInverseSurface, fontSize: 12),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      elevation: 2,
      highlightElevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: colorScheme.primary,
      unselectedLabelColor: colorScheme.onSurfaceVariant,
      indicatorSize: TabBarIndicatorSize.label,
      dividerColor: colorScheme.outlineVariant.withValues(alpha: 0.35),
      indicator: UnderlineTabIndicator(
        borderSide: BorderSide(color: colorScheme.primary, width: 3),
        insets: const EdgeInsets.symmetric(horizontal: 16),
      ),
      labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      unselectedLabelStyle: const TextStyle(
        fontWeight: FontWeight.w500,
        fontSize: 14,
      ),
    ),
    scrollbarTheme: ScrollbarThemeData(
      radius: const Radius.circular(8),
      thickness: WidgetStateProperty.all(6),
      thumbVisibility: WidgetStateProperty.resolveWith((s) {
        if (s.contains(WidgetState.hovered)) return true;
        return false;
      }),
    ),
  );
}

/// Padding horizontal standard des pages contenu (sous la barre latérale).
EdgeInsets get appPagePadding => const EdgeInsets.fromLTRB(28, 24, 28, 28);
