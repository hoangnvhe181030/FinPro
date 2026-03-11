import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors (Deep Purple - kept by user request)
  static const Color primary = Color(0xFF673AB7);
  static const Color primaryLight = Color(0xFF9575CD);
  static const Color primaryDark = Color(0xFF512DA8);
  static const Color primaryDeep = Color(0xFF311B92);

  // Accent Colors (Gold - premium feel)
  static const Color accent = Color(0xFFFFD700);
  static const Color accentLight = Color(0xFFFFE44D);
  static const Color accentDark = Color(0xFFC7A600);

  // Dark Backgrounds
  static const Color scaffoldDark = Color(0xFF0D0D1A);
  static const Color surfaceDark = Color(0xFF1A1A2E);
  static const Color cardDark = Color(0xFF16213E);
  static const Color cardDarkElevated = Color(0xFF1E2A4A);

  // Status Colors
  static const Color success = Color(0xFF00E676);
  static const Color warning = Color(0xFFFFAB00);
  static const Color error = Color(0xFFFF5252);
  static const Color info = Color(0xFF448AFF);

  // Auction Status Colors
  static const Color auctionActive = Color(0xFF00E676);
  static const Color auctionEnding = Color(0xFFFF6D00);
  static const Color auctionEnded = Color(0xFF546E7A);
  static const Color auctionWon = Color(0xFFFFD700);

  // Text Colors
  static const Color textPrimary = Color(0xFFE0E0E0);
  static const Color textSecondary = Color(0xFF9E9E9E);
  static const Color textMuted = Color(0xFF616161);
  static const Color textOnPrimary = Colors.white;

  // Neutral / Surface
  static const Color background = Color(0xFF0D0D1A);
  static const Color surface = Color(0xFF1A1A2E);
  static const Color onSurface = Color(0xFFE0E0E0);
  static const Color onSurfaceVariant = Color(0xFF9E9E9E);
  static const Color divider = Color(0xFF2A2A3E);
  static const Color border = Color(0xFF2E2E42);

  // Shimmer colors
  static const Color shimmerBase = Color(0xFF1A1A2E);
  static const Color shimmerHighlight = Color(0xFF2A2A3E);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF673AB7), Color(0xFF9C27B0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient walletGradient = LinearGradient(
    colors: [Color(0xFF512DA8), Color(0xFF311B92), Color(0xFF1A0E4A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF1E2A4A), Color(0xFF16213E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkOverlay = LinearGradient(
    colors: [Colors.transparent, Color(0xCC0D0D1A)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient bidGradient = LinearGradient(
    colors: [Color(0xFF673AB7), Color(0xFFFFD700)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}
