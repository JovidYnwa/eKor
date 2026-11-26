import 'package:cupertino_ui/cupertino_ui.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import 'tokens.dart';

abstract final class AppTheme {
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.brand600,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.brand600,
      onPrimary: AppColors.white,
      secondary: AppColors.ink900,
      onSecondary: AppColors.white,
      error: AppColors.danger600,
      onError: AppColors.white,
      surface: AppColors.white,
      onSurface: AppColors.ink900,
      outline: AppColors.line300,
      outlineVariant: AppColors.line200,
    );

    final textTheme = TextTheme(
      displayLarge: AppText.display,
      headlineLarge: AppText.h1,
      headlineMedium: AppText.h2,
      headlineSmall: AppText.h3,
      titleLarge: AppText.h3,
      titleMedium: AppText.label,
      titleSmall: AppText.label,
      bodyLarge: AppText.bodyLg,
      bodyMedium: AppText.body,
      bodySmall: AppText.caption,
      labelLarge: AppText.label,
      labelMedium: AppText.overline,
      labelSmall: AppText.badge,
    );

    final roundedLg = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.lg),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: AppText.fontFamily,
      textTheme: textTheme,
      scaffoldBackgroundColor: AppColors.white,
      splashFactory: InkSparkle.splashFactory,
      dividerColor: AppColors.line200,
      dividerTheme: const DividerThemeData(
        color: AppColors.line200,
        thickness: 1,
        space: 1,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.ink900,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        toolbarHeight: AppSizes.appBarH,
        titleTextStyle: AppText.style(17, weight: FontWeight.w600),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.brand600,
          foregroundColor: AppColors.white,
          disabledBackgroundColor: AppColors.disabledBg,
          disabledForegroundColor: AppColors.disabledFg,
          minimumSize: const Size.fromHeight(AppSizes.btnLg),
          padding: const EdgeInsets.symmetric(horizontal: 22),
          shape: roundedLg,
          textStyle: AppText.style(17, weight: FontWeight.w600, height: 1.2),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink900,
          minimumSize: const Size.fromHeight(AppSizes.btnLg),
          side: const BorderSide(color: AppColors.line300, width: 1.5),
          shape: roundedLg,
          textStyle: AppText.style(17, weight: FontWeight.w600, height: 1.2),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.brand600,
          minimumSize: const Size(AppSizes.tapMin, AppSizes.tapMin),
          textStyle: AppText.style(15, weight: FontWeight.w600, height: 1.2),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        hintStyle: AppText.style(16, color: AppColors.ink400),
        errorStyle: AppText.style(13, color: AppColors.danger600),
        border: _inputBorder(AppColors.line300),
        enabledBorder: _inputBorder(AppColors.line300),
        focusedBorder: _inputBorder(AppColors.ink900),
        errorBorder: _inputBorder(AppColors.danger600),
        focusedErrorBorder: _inputBorder(AppColors.danger600),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.white,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: AppColors.line300,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink900,
        contentTextStyle: AppText.style(15, color: AppColors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        titleTextStyle: AppText.h3,
        contentTextStyle: AppText.style(15, color: AppColors.ink700),
      ),
      progressIndicatorTheme:
          const ProgressIndicatorThemeData(color: AppColors.brand600),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  static OutlineInputBorder _inputBorder(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        borderSide: BorderSide(color: color, width: 1.5),
      );
}
