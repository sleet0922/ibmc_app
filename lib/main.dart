import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const IBMCApp());
}

class IBMCApp extends StatelessWidget {
  const IBMCApp({super.key});

  // Material Design 3 色调 — 深色主题
  static const _primary = Color(0xFF90CAF9);
  static const _onPrimary = Color(0xFF0D2137);
  static const _surface = Color(0xFF111318);
  static const _surfaceContainer = Color(0xFF1A1D23);
  static const _surfaceContainerHigh = Color(0xFF22252C);
  static const _onSurface = Color(0xFFE3E2E6);
  static const _onSurfaceVariant = Color(0xFFC4C6D0);
  static const _outline = Color(0xFF3D404A);
  static const _outlineVariant = Color(0xFF2A2D35);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'iBMC 管理',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _primary,
          brightness: Brightness.dark,
          surface: _surface,
        ).copyWith(
          primary: _primary,
          onPrimary: _onPrimary,
          surface: _surface,
          surfaceContainerLowest: const Color(0xFF0D0E12),
          surfaceContainerLow: const Color(0xFF14161A),
          surfaceContainer: _surfaceContainer,
          surfaceContainerHigh: _surfaceContainerHigh,
          surfaceContainerHighest: const Color(0xFF2A2D35),
          onSurface: _onSurface,
          onSurfaceVariant: _onSurfaceVariant,
          outline: _outline,
          outlineVariant: _outlineVariant,
        ),

        // Typography
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            height: 1.2,
          ),
          headlineMedium: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.25,
            height: 1.3,
          ),
          titleLarge: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
            height: 1.4,
          ),
          titleMedium: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.15,
            height: 1.4,
          ),
          bodyLarge: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.5,
            height: 1.5,
          ),
          bodyMedium: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.25,
            height: 1.5,
          ),
          labelLarge: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
            height: 1.4,
          ),
          labelMedium: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
            height: 1.3,
          ),
          labelSmall: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.5,
            height: 1.3,
          ),
        ),

        // Scaffold
        scaffoldBackgroundColor: const Color(0xFF0D0E12),

        // AppBar — 极简透明
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0D0E12),
          foregroundColor: _onSurface,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: _onSurface,
            letterSpacing: -0.25,
          ),
        ),

        // Card — 轻微阴影 + 圆角
        cardTheme: CardThemeData(
          color: _surfaceContainer,
          elevation: 0,
          shadowColor: Colors.black.withValues(alpha: 0.4),
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          margin: EdgeInsets.zero,
        ),

        // Input — 简约描边风格
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: _surfaceContainer,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _outline),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _outline),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFEF5350)),
          ),
          hintStyle: TextStyle(color: _onSurfaceVariant.withValues(alpha: 0.5), fontSize: 15),
          labelStyle: const TextStyle(color: _onSurfaceVariant, fontSize: 15),
          floatingLabelStyle: const TextStyle(color: _primary, fontSize: 13),
          prefixIconColor: _onSurfaceVariant,
        ),

        // FilledButton — 主按钮
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: _primary,
            foregroundColor: _onPrimary,
            disabledBackgroundColor: _primary.withValues(alpha: 0.12),
            disabledForegroundColor: _onSurface.withValues(alpha: 0.38),
            elevation: 2,
            shadowColor: _primary.withValues(alpha: 0.25),
            minimumSize: const Size(double.infinity, 54),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.5),
            padding: const EdgeInsets.symmetric(vertical: 6),
          ),
        ),

        // OutlinedButton
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 54),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            side: const BorderSide(color: _outline),
            foregroundColor: _onSurface,
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.5),
            padding: const EdgeInsets.symmetric(vertical: 6),
          ),
        ),

        // Divider
        dividerTheme: const DividerThemeData(
          color: _outlineVariant,
          thickness: 1,
          space: 1,
        ),

        // IconButton
        iconButtonTheme: IconButtonThemeData(
          style: IconButton.styleFrom(
            foregroundColor: _onSurfaceVariant,
          ),
        ),

        // Chip
        chipTheme: ChipThemeData(
          backgroundColor: _surfaceContainerHigh,
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          side: const BorderSide(color: _outline),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        ),
      ),
      home: const LoginScreen(),
    );
  }
}