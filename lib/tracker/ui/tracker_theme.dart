import 'package:flutter/material.dart';

import '../models/case_record.dart';

const trackerPrimary = Color(0xFF0B5E63);
const trackerPrimaryContainer = Color(0xFFD9F1EF);
const trackerInk = Color(0xFF101828);
const trackerMuted = Color(0xFF4F5F69);
const trackerBackground = Color(0xFFF7F9F8);
const trackerSurface = Color(0xFFFFFFFF);
const trackerSurfaceContainer = Color(0xFFEEF3F2);
const trackerBorder = Color(0xFFD4DEDC);
const trackerSuccess = Color(0xFF205F3B);
const trackerWarning = Color(0xFF7A4B00);
const trackerEvidence = Color(0xFFA93A2E);
const trackerBlue = Color(0xFF2F66D0);
const trackerViolet = Color(0xFF6F4AA8);

class TrackerStageColors extends ThemeExtension<TrackerStageColors> {
  const TrackerStageColors({
    required this.intake,
    required this.biometrics,
    required this.review,
    required this.evidence,
    required this.interview,
    required this.decision,
    required this.closed,
  });

  final Color intake;
  final Color biometrics;
  final Color review;
  final Color evidence;
  final Color interview;
  final Color decision;
  final Color closed;

  Color colorFor(CaseStage stage) {
    switch (stage) {
      case CaseStage.intake:
        return intake;
      case CaseStage.biometrics:
        return biometrics;
      case CaseStage.review:
        return review;
      case CaseStage.evidence:
        return evidence;
      case CaseStage.interview:
        return interview;
      case CaseStage.decision:
        return decision;
      case CaseStage.closed:
        return closed;
    }
  }

  @override
  TrackerStageColors copyWith({
    Color? intake,
    Color? biometrics,
    Color? review,
    Color? evidence,
    Color? interview,
    Color? decision,
    Color? closed,
  }) {
    return TrackerStageColors(
      intake: intake ?? this.intake,
      biometrics: biometrics ?? this.biometrics,
      review: review ?? this.review,
      evidence: evidence ?? this.evidence,
      interview: interview ?? this.interview,
      decision: decision ?? this.decision,
      closed: closed ?? this.closed,
    );
  }

  @override
  TrackerStageColors lerp(ThemeExtension<TrackerStageColors>? other, double t) {
    if (other is! TrackerStageColors) {
      return this;
    }
    return TrackerStageColors(
      intake: Color.lerp(intake, other.intake, t)!,
      biometrics: Color.lerp(biometrics, other.biometrics, t)!,
      review: Color.lerp(review, other.review, t)!,
      evidence: Color.lerp(evidence, other.evidence, t)!,
      interview: Color.lerp(interview, other.interview, t)!,
      decision: Color.lerp(decision, other.decision, t)!,
      closed: Color.lerp(closed, other.closed, t)!,
    );
  }
}

ThemeData buildTrackerTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final scheme = isDark
      ? const ColorScheme.dark(
          primary: Color(0xFF8DDAD7),
          onPrimary: Color(0xFF003638),
          primaryContainer: Color(0xFF104B4F),
          onPrimaryContainer: Color(0xFFE6FAF8),
          secondary: Color(0xFFFFB6AA),
          tertiary: Color(0xFFF1C56B),
          surface: Color(0xFF111918),
          onSurface: Color(0xFFE6ECEB),
          surfaceContainerHighest: Color(0xFF263231),
          outline: Color(0xFF4B5B59),
          error: Color(0xFFFFB4A9),
        )
      : const ColorScheme.light(
          primary: trackerPrimary,
          onPrimary: Colors.white,
          primaryContainer: trackerPrimaryContainer,
          onPrimaryContainer: Color(0xFF073D41),
          secondary: trackerEvidence,
          tertiary: trackerWarning,
          surface: trackerSurface,
          onSurface: trackerInk,
          surfaceContainerHighest: trackerSurfaceContainer,
          outline: trackerBorder,
          error: trackerEvidence,
        );

  final textTheme = Typography.material2021().black.apply(
        bodyColor: isDark ? const Color(0xFFE6ECEB) : trackerInk,
        displayColor: isDark ? Colors.white : trackerInk,
      );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor:
        isDark ? const Color(0xFF0B1110) : trackerBackground,
    textTheme: textTheme.copyWith(
      headlineSmall: textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: 0,
      ),
      titleLarge: textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: 0,
      ),
      titleMedium: textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      ),
      bodySmall: textTheme.bodySmall?.copyWith(
        color: isDark ? const Color(0xFFAEBDBA) : trackerMuted,
      ),
      labelLarge: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: isDark ? const Color(0xFF111918) : trackerSurface,
      foregroundColor: isDark ? Colors.white : trackerInk,
      elevation: 0,
      centerTitle: false,
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: isDark ? const Color(0xFF111918) : trackerSurface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: scheme.outline.withValues(alpha: .7)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: isDark ? const Color(0xFF151F1E) : trackerSurface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: scheme.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: scheme.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: scheme.primary, width: 1.6),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        textStyle: const TextStyle(fontWeight: FontWeight.w800),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        textStyle: const TextStyle(fontWeight: FontWeight.w800),
      ),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      side: BorderSide(color: scheme.outline.withValues(alpha: .7)),
      labelStyle: TextStyle(
        color: isDark ? const Color(0xFFE6ECEB) : trackerInk,
        fontWeight: FontWeight.w700,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 72,
      backgroundColor: isDark ? const Color(0xFF111918) : trackerSurface,
      indicatorColor: scheme.primaryContainer,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontSize: 12,
          fontWeight:
              states.contains(WidgetState.selected) ? FontWeight.w800 : null,
        ),
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: isDark ? const Color(0xFF111918) : trackerSurface,
      indicatorColor: scheme.primaryContainer,
      selectedIconTheme: IconThemeData(color: scheme.primary),
      selectedLabelTextStyle: TextStyle(
        color: scheme.primary,
        fontSize: 12,
        fontWeight: FontWeight.w800,
      ),
      unselectedLabelTextStyle: TextStyle(
        color: isDark ? const Color(0xFFAEBDBA) : trackerMuted,
        fontSize: 12,
      ),
    ),
    dividerTheme:
        DividerThemeData(color: scheme.outline.withValues(alpha: .45)),
    checkboxTheme: CheckboxThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      side: BorderSide(color: scheme.outline),
    ),
    extensions: const [
      TrackerStageColors(
        intake: trackerPrimary,
        biometrics: trackerBlue,
        review: trackerWarning,
        evidence: trackerEvidence,
        interview: trackerViolet,
        decision: trackerSuccess,
        closed: trackerMuted,
      ),
    ],
  );
}

Color stageColorOf(BuildContext context, CaseStage stage) {
  final colors = Theme.of(context).extension<TrackerStageColors>();
  return colors?.colorFor(stage) ?? trackerPrimary;
}

IconData stageIcon(CaseStage stage) {
  switch (stage) {
    case CaseStage.intake:
      return Icons.inventory_2_outlined;
    case CaseStage.biometrics:
      return Icons.fingerprint;
    case CaseStage.review:
      return Icons.rate_review_outlined;
    case CaseStage.evidence:
      return Icons.assignment_late_outlined;
    case CaseStage.interview:
      return Icons.groups_2_outlined;
    case CaseStage.decision:
      return Icons.task_alt;
    case CaseStage.closed:
      return Icons.lock_outline;
  }
}
