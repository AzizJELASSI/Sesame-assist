import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Primary (Indigo)
  static const Color primary50 = Color(0xFFEEF2FF);
  static const Color primary100 = Color(0xFFE0E7FF);
  static const Color primary500 = Color(0xFF6366F1);
  static const Color primary600 = Color(0xFF4F46E5); // Main Brand Color
  static const Color primary700 = Color(0xFF4338CA);
  static const Color primary900 = Color(0xFF312E81);

  // Neutrals (Slate)
  static const Color slate50 = Color(0xFFF8FAFC);  // App Background
  static const Color slate100 = Color(0xFFF1F5F9); // Borders
  static const Color slate200 = Color(0xFFE2E8F0); // Darker Borders
  static const Color slate400 = Color(0xFF94A3B8); // Muted Icons/Text
  static const Color slate500 = Color(0xFF64748B); // Secondary Text
  static const Color slate800 = Color(0xFF1E293B); // Sidebar Hover
  static const Color slate900 = Color(0xFF0F172A); // Main Text & Sidebar BG

  // Semantics / Status
  static const Color success = Color(0xFF10B981); // Emerald
  static const Color successBg = Color(0xFFECFDF5);
  static const Color warning = Color(0xFFF59E0B); // Amber
  static const Color warningBg = Color(0xFFFFFBEB);
  static const Color danger = Color(0xFFEF4444);  // Rose
  static const Color dangerBg = Color(0xFFFEF2F2);
}

class AppTheme {
  AppTheme._();

  // ── Component Patterns ───────────────────────────────────────────────────────
  static BoxDecoration cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.slate100),
      boxShadow: const [
        BoxShadow(
          color: Color.fromRGBO(6, 81, 237, 0.1), // Distinct bluish shadow
          blurRadius: 10,
          spreadRadius: -3,
          offset: Offset(0, 2),
        ),
      ],
    );
  }

  static InputDecoration defaultInputDecoration({String? hintText}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: AppColors.slate400),
      filled: true,
      fillColor: AppColors.slate50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.slate200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.slate200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primary500, width: 2),
      ),
    );
  }

  // ── Global ThemeData Setup ───────────────────────────────────────────────────
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.slate50,
      primaryColor: AppColors.primary600,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary600,
        secondary: AppColors.primary500,
        surface: Colors.white,
        error: AppColors.danger,
        onPrimary: Colors.white,
        onSurface: AppColors.slate900,
      ),
      // Typography using Google Fonts 'Inter'
      textTheme: GoogleFonts.interTextTheme().apply(
        bodyColor: AppColors.slate900,
        displayColor: AppColors.slate900,
      ),
      dividerColor: AppColors.slate200,

      // Component Themes
      cardTheme: CardThemeData(
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.slate100),
        ),
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary600,
          foregroundColor: Colors.white,
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary600,
          backgroundColor: Colors.white,
          side: const BorderSide(color: AppColors.primary100),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30), // full pill shape
          ),
          elevation: 1,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.slate50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        hintStyle: const TextStyle(color: AppColors.slate400),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.slate200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.slate200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary500, width: 2),
        ),
      ), // Base theme

      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.slate900,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.slate900,
        ),
      ),
    );
  }

  // Define dark theme as light for now to prevent breaking if app toggles it, 
  // since the spec only provided one theme.
  static ThemeData get dark => light;

  // ── Priority colors ──────────────────────────────────────────────────────────
  static Color priorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return AppColors.danger;
      case 'medium':
        return AppColors.warning;
      case 'low':
        return AppColors.success;
      default:
        return AppColors.slate400;
    }
  }

  // ── Status colors ─────────────────────────────────────────────────────────────
  static Color statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return AppColors.primary500;
      case 'in_progress':
      case 'in progress':
        return AppColors.warning;
      case 'waiting_on_user':
      case 'waiting on user':
        return AppColors.primary700;
      case 'resolved':
        return AppColors.success;
      case 'closed':
        return AppColors.slate500;
      default:
        return AppColors.slate400;
    }
  }

  // ── Role colors ───────────────────────────────────────────────────────────────
  static Color roleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return AppColors.danger;
      case 'agent':
        return AppColors.warning;
      case 'teacher':
        return AppColors.primary500;
      case 'student':
        return AppColors.success;
      default:
        return AppColors.slate500;
    }
  }

  // ── Attachment color ──────────────────────────────────────────────────────────
  static const Color attachmentColor = AppColors.primary500;
}
