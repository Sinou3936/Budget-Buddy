import 'package:flutter/material.dart';

class AppTheme {
  // Brand Colors - Blue & Teal Gradient (Style 1)
  static const Color primaryBlue = Color(0xFF1565C0);
  static const Color primaryTeal = Color(0xFF00897B);
  static const Color accentBlue = Color(0xFF42A5F5);
  static const Color accentTeal = Color(0xFF26C6DA);
  static const Color backgroundLight = Color(0xFFF5F7FA);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textLight = Color(0xFF9CA3AF);
  static const Color dividerColor = Color(0xFFE5E7EB);
  static const Color successGreen = Color(0xFF10B981);
  static const Color warningOrange = Color(0xFFF59E0B);
  static const Color dangerRed = Color(0xFFEF4444);
  static const Color incomeGreen = Color(0xFF059669);

  // Category Colors
  static const Map<String, Color> categoryColors = {
    '식비': Color(0xFFFF6B6B),
    '교통': Color(0xFF4ECDC4),
    '쇼핑': Color(0xFFFFE66D),
    '문화/여가': Color(0xFFA78BFA),
    '의료': Color(0xFFF472B6),
    '통신': Color(0xFF60A5FA),
    '주거': Color(0xFF34D399),
    '교육': Color(0xFFFBBF24),
    '저축': Color(0xFF818CF8),
    '기타': Color(0xFF9CA3AF),
  };

  static const Map<String, IconData> categoryIcons = {
    '식비': Icons.restaurant,
    '교통': Icons.directions_transit,
    '쇼핑': Icons.shopping_bag,
    '문화/여가': Icons.movie,
    '의료': Icons.local_hospital,
    '통신': Icons.phone_android,
    '주거': Icons.home,
    '교육': Icons.school,
    '저축': Icons.savings,
    '기타': Icons.more_horiz,
  };

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        primary: primaryBlue,
        secondary: primaryTeal,
        surface: backgroundLight,
      ),
      scaffoldBackgroundColor: backgroundLight,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        color: cardWhite,
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: cardWhite,
        selectedItemColor: primaryBlue,
        unselectedItemColor: textLight,
        type: BottomNavigationBarType.fixed,
        elevation: 12,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 8,
        shape: CircleBorder(),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryBlue, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
