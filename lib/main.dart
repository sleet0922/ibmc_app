import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const IBMCApp());
}

class IBMCApp extends StatelessWidget {
  const IBMCApp({super.key});

  static const _amoledBlack = Color(0xFF000000);
  static const _surfaceColor = Color(0xFF0D0D0D);
  static const _accentColor = Color(0xFF64B5F6);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'iBMC 管理',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: _accentColor,
          onPrimary: _amoledBlack,
          secondary: Color(0xFF4FC3F7),
          onSecondary: _amoledBlack,
          surface: _surfaceColor,
          onSurface: Color(0xFFE0E0E0),
          error: Color(0xFFEF5350),
          onError: _amoledBlack,
        ),
        scaffoldBackgroundColor: _amoledBlack,
        appBarTheme: const AppBarTheme(
          backgroundColor: _surfaceColor,
          foregroundColor: Color(0xFFE0E0E0),
          elevation: 0,
          scrolledUnderElevation: 1,
          centerTitle: true,
        ),
        cardTheme: CardThemeData(
          color: _surfaceColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF141414),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _accentColor, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFEF5350)),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: _accentColor,
            foregroundColor: _amoledBlack,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        dividerTheme: DividerThemeData(
          color: Colors.white.withValues(alpha: 0.06),
          thickness: 1,
        ),
      ),
      home: const LoginScreen(),
    );
  }
}