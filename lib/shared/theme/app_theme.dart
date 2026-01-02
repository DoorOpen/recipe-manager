import 'package:flutter/material.dart';
import 'dart:ui';

/// App theme configuration - Premium Glassmorphism Design
class AppTheme {
  // Private constructor to prevent instantiation
  AppTheme._();

  // Minimal Color Palette - Refined & Subtle
  static const Color primaryColor = Color(0xFF2C3E50); // Dark slate blue
  static const Color primaryLight = Color(0xFF34495E); // Light slate
  static const Color primaryDark = Color(0xFF1A252F); // Deep slate

  static const Color secondaryColor = Color(0xFF3498DB); // Soft blue
  static const Color secondaryLight = Color(0xFF5DADE2); // Light blue

  static const Color accentColor = Color(0xFF16A085); // Teal
  static const Color accentLight = Color(0xFF1ABC9C); // Light teal

  static const Color successColor = Color(0xFF27AE60); // Green
  static const Color errorColor = Color(0xFFE74C3C); // Red
  static const Color warningColor = Color(0xFFF39C12); // Orange

  // Minimal Background Colors
  static const Color backgroundGradientStart = Color(0xFFFAFAFA); // Very light gray
  static const Color backgroundGradientEnd = Color(0xFFF5F5F5); // Light gray
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color glassColor = Color(0xCCFFFFFF); // More opaque white

  // Text colors
  static const Color textPrimary = Color(0xFF2C3E50);
  static const Color textSecondary = Color(0xFF7F8C8D);
  static const Color textOnGlass = Color(0xFF2C3E50);

  /// Light theme - Premium Glassmorphism
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      // Color scheme - vibrant and modern
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        tertiary: accentColor,
        error: errorColor,
        surface: surfaceColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
      ),

      // Scaffold background with subtle gradient
      scaffoldBackgroundColor: backgroundGradientStart,

      // App bar theme - frosted glass effect
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        backgroundColor: glassColor,
        foregroundColor: textPrimary,
        titleTextStyle: const TextStyle(
          color: textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        iconTheme: const IconThemeData(
          color: textPrimary,
          size: 24,
        ),
      ),

      // Card theme - glass effect with gradient border
      cardTheme: CardThemeData(
        elevation: 8,
        shadowColor: primaryColor.withValues(alpha: 0.15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        clipBehavior: Clip.antiAlias,
        color: Colors.white.withValues(alpha: 0.7),
      ),

      // Elevated button theme - gradient with glass effect
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 4,
          shadowColor: primaryColor.withValues(alpha: 0.3),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // Filled button theme - for primary actions
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 4,
          shadowColor: primaryColor.withValues(alpha: 0.3),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // Text button theme - subtle with gradient on hover
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          foregroundColor: primaryColor,
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Input decoration theme - glass effect
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: primaryLight.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: primaryLight.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: primaryColor,
            width: 2.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: errorColor,
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),

      // Chip theme - glass pills
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white.withValues(alpha: 0.7),
        selectedColor: primaryLight.withValues(alpha: 0.3),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        labelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: primaryLight.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),

      // Bottom navigation bar theme - frosted glass
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        elevation: 0,
        backgroundColor: Colors.white.withValues(alpha: 0.8),
        selectedItemColor: primaryColor,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),

      // Floating action button theme - vibrant with shadow
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 8,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        extendedPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),

      // Dialog theme - glass effect
      dialogTheme: DialogThemeData(
        elevation: 16,
        backgroundColor: Colors.white.withValues(alpha: 0.95),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),

      // Bottom sheet theme - frosted glass
      bottomSheetTheme: BottomSheetThemeData(
        elevation: 16,
        backgroundColor: Colors.white.withValues(alpha: 0.95),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(28),
          ),
        ),
        clipBehavior: Clip.antiAlias,
      ),
    );
  }

  /// Dark theme - Premium Glassmorphism Dark Mode
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      colorScheme: const ColorScheme.dark(
        primary: primaryLight,
        secondary: secondaryLight,
        tertiary: accentLight,
        error: errorColor,
        surface: Color(0xFF1F2937),
        onPrimary: Color(0xFF111827),
        onSecondary: Color(0xFF111827),
        onSurface: Colors.white,
      ),

      scaffoldBackgroundColor: const Color(0xFF0F172A),

      // App bar theme - dark frosted glass
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        backgroundColor: const Color(0xFF1F2937).withValues(alpha: 0.8),
        foregroundColor: Colors.white,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
      ),

      // Card theme - dark glass
      cardTheme: CardThemeData(
        elevation: 8,
        shadowColor: primaryLight.withValues(alpha: 0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        clipBehavior: Clip.antiAlias,
        color: const Color(0xFF1F2937).withValues(alpha: 0.7),
      ),

      // Bottom navigation bar - dark frosted glass
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        elevation: 0,
        backgroundColor: const Color(0xFF1F2937).withValues(alpha: 0.8),
        selectedItemColor: primaryLight,
        unselectedItemColor: const Color(0xFF9CA3AF),
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
      ),

      // Floating action button theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 8,
        backgroundColor: primaryLight,
        foregroundColor: const Color(0xFF111827),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}

/// Helper widget for creating glass morphism containers
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final double blur;
  final Color? color;
  final Border? border;

  const GlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius,
    this.blur = 10.0,
    this.color,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultColor = isDark
        ? const Color(0xFF1F2937).withValues(alpha: 0.5)
        : Colors.white.withValues(alpha: 0.5);

    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: color ?? defaultColor,
        borderRadius: borderRadius ?? BorderRadius.circular(20),
        border: border ?? Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.white.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.1),
                  Colors.white.withValues(alpha: 0.05),
                ],
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
