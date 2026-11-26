import 'package:material_ui/material_ui.dart';

/// Design tokens mirrored 1:1 from the ekor.tj web CSS (`:root` variables),
/// so the app and the website stay visually consistent.
abstract final class AppColors {
  static const brand700 = Color(0xFF1F3BB8);
  static const brand600 = Color(0xFF2647D9);
  static const brand600Busy = Color(0xFF7D90E8);
  static const brand300 = Color(0xFF9AAEF0);
  static const brand100 = Color(0xFFEAEEFC);
  static const brand50 = Color(0xFFF7F9FF);

  static const ink900 = Color(0xFF0F1B2A);
  static const ink900Hover = Color(0xFF1C2B3E);
  static const ink700 = Color(0xFF3B4756);
  static const ink500 = Color(0xFF5B6878);
  static const ink400 = Color(0xFF6B7787);

  static const line300 = Color(0xFFC9D1DB);
  static const line200 = Color(0xFFE1E6EC);
  static const line100 = Color(0xFFEEF1F4);

  static const surface50 = Color(0xFFF5F7F9);
  static const white = Color(0xFFFFFFFF);

  static const success700 = Color(0xFF0B6E5E);
  static const success600 = Color(0xFF12A37F);
  static const success100 = Color(0xFFE3F4F0);
  static const success50 = Color(0xFFF1FAF7);

  static const warn800 = Color(0xFF8A4B0D);
  static const warn600 = Color(0xFFD9822B);
  static const warn100 = Color(0xFFFBEBDA);

  static const danger700 = Color(0xFFA5281B);
  static const danger600 = Color(0xFFB03A2E);
  static const danger200 = Color(0xFFE8C4BE);
  static const danger100 = Color(0xFFFBE3E0);
  static const danger50 = Color(0xFFFFF1EF);

  static const disabledBg = Color(0xFFEEF1F4);
  static const disabledFg = Color(0xFF9AA5B4);
  static const skeleton = Color(0xFFE6EAEF);
  static const overlay = Color(0x730F1B2A); // rgba(15,27,42,.45)
}

abstract final class AppSpace {
  static const s1 = 4.0;
  static const s2 = 8.0;
  static const s3 = 12.0;
  static const s4 = 16.0;
  static const s5 = 20.0;
  static const s6 = 24.0;
  static const s8 = 32.0;
  static const s10 = 40.0;

  /// Horizontal page padding on mobile.
  static const pageX = 16.0;
}

abstract final class AppRadius {
  static const xs = 6.0;
  static const sm = 8.0;
  static const md = 10.0;
  static const lg = 12.0;
  static const xl = 14.0;
  static const sheet = 20.0;
  static const pill = 999.0;
}

abstract final class AppSizes {
  static const tapMin = 44.0;
  static const btnLg = 52.0;
  static const btnMd = 48.0;
  static const btnSm = 44.0;
  static const inputH = 48.0;
  static const inputHLg = 56.0;
  static const appBarH = 56.0;
  static const tabBarH = 64.0;
}

abstract final class AppShadows {
  static const pop = [
    BoxShadow(color: Color(0x290F1B2A), blurRadius: 32, offset: Offset(0, 12)),
  ];
  static const sheet = [
    BoxShadow(color: Color(0x4D0F1B2A), blurRadius: 40, offset: Offset(0, 16)),
  ];
}

/// Typography. Golos Text is bundled as a variable font, so every style sets
/// the `wght` axis explicitly to make weights render correctly on all platforms.
abstract final class AppText {
  static const fontFamily = 'GolosText';

  static TextStyle style(
    double size, {
    FontWeight weight = FontWeight.w400,
    double height = 1.45,
    Color color = AppColors.ink900,
    double? letterSpacing,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: size,
      fontWeight: weight,
      fontVariations: [FontVariation.weight(weight.value.toDouble())],
      height: height,
      color: color,
      letterSpacing: letterSpacing,
    );
  }

  static final display = style(44, weight: FontWeight.w700, height: 1.1);
  static final h1 = style(28, weight: FontWeight.w700, height: 1.2);
  static final h2 = style(24, weight: FontWeight.w700, height: 1.25);
  static final h3 = style(20, weight: FontWeight.w600, height: 1.3);
  static final bodyLg = style(16);
  static final body = style(15);
  static final label = style(15, weight: FontWeight.w600, height: 1.3);
  static final caption = style(13, height: 1.4);
  static final overline = style(13, weight: FontWeight.w600, height: 1.3);
  static final badge = style(12, weight: FontWeight.w600, height: 1.2);
}
