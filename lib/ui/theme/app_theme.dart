import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Modern agricultural design system for Asan Kissan app.
class AppTheme {
  static const Color primaryGreen = Color(0xFF1E5631);
  static const Color accentEmerald = Color(0xFF2E7D32);
  static const Color mintGreen = Color(0xFF4CAF50);
  static const Color lightMint = Color(0xFFE8F5E9);
  
  static const Color backgroundLight = Color(0xFFF6F8F6);
  static const Color surfaceWhite = Colors.white;
  static const Color textDark = Color(0xFF1C2D1F);
  static const Color textMuted = Color(0xFF5E6E60);
  
  // Severity Indicator Colors
  static const Color severityHigh = Color(0xFFD32F2F);
  static const Color severityModerate = Color(0xFFED6C02);
  static const Color severityHealthy = Color(0xFF2E7D32);

  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.interTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryGreen,
      scaffoldBackgroundColor: backgroundLight,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryGreen,
        primary: primaryGreen,
        secondary: accentEmerald,
        surface: surfaceWhite,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceWhite,
        elevation: 3,
        shadowColor: primaryGreen.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      textTheme: baseTextTheme.copyWith(
        headlineLarge: GoogleFonts.outfit(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: textDark,
        ),
        headlineMedium: GoogleFonts.outfit(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: textDark,
        ),
        titleLarge: GoogleFonts.outfit(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textDark,
        ),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(
          fontSize: 16,
          color: textDark,
          height: 1.5,
        ),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          fontSize: 14,
          color: textMuted,
          height: 1.4,
        ),
      ),
    );
  }
}
