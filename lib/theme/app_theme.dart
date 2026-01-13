import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design System "Dark Casino" - Tema Cyberpunk per Blackjack Gestionale
class AppTheme {
  // ═══════════════════════════════════════════════════════════════════════════
  // COLORI PRINCIPALI
  // ═══════════════════════════════════════════════════════════════════════════

  /// Sfondo principale - Nero profondo
  static const Color backgroundPrimary = Color(0xFF0A0A0A);

  /// Sfondo card - Grigio scuro
  static const Color backgroundCard = Color(0xFF1A1A1A);

  /// Accento primario - Verde Neon Cyberpunk (Call/Hit)
  static const Color accentPrimary = Color(0xFF00FF9D);

  /// Accento secondario - Rosso Neon (Fold/Stand)
  static const Color accentSecondary = Color(0xFFFF0055);

  /// Testo primario - Bianco puro
  static const Color textPrimary = Color(0xFFFFFFFF);

  /// Testo secondario - Grigio chiaro
  static const Color textSecondary = Color(0xFFEEEEEE);

  /// Bordo card
  static const Color borderColor = Color(0xFF333333);

  /// Colore di superficie per elementi UI
  static const Color surfaceColor = Color(0xFF1A1A1A);

  /// Colore warning - Giallo/Oro
  static const Color warningColor = Color(0xFFFFD700);

  // ═══════════════════════════════════════════════════════════════════════════
  // TEMA SCURO PRINCIPALE
  // ═══════════════════════════════════════════════════════════════════════════

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: backgroundPrimary,
      primaryColor: accentPrimary,
      colorScheme: const ColorScheme.dark(
        primary: accentPrimary,
        secondary: accentSecondary,
        surface: surfaceColor,
        error: accentSecondary,
        onPrimary: backgroundPrimary,
        onSecondary: textPrimary,
        onSurface: textPrimary,
        onError: textPrimary,
      ),

      // ─────────────────────────────────────────────────────────────────────────
      // TIPOGRAFIA
      // ─────────────────────────────────────────────────────────────────────────
      textTheme: TextTheme(
        // Titoli - Orbitron (Futuristico)
        displayLarge: GoogleFonts.orbitron(
          fontSize: 48,
          fontWeight: FontWeight.bold,
          color: textPrimary,
          letterSpacing: 2,
        ),
        displayMedium: GoogleFonts.orbitron(
          fontSize: 36,
          fontWeight: FontWeight.bold,
          color: textPrimary,
          letterSpacing: 1.5,
        ),
        displaySmall: GoogleFonts.orbitron(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: 1,
        ),
        headlineLarge: GoogleFonts.orbitron(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        headlineMedium: GoogleFonts.orbitron(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        headlineSmall: GoogleFonts.orbitron(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        // Titoli sezioni
        titleLarge: GoogleFonts.orbitron(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleMedium: GoogleFonts.orbitron(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textSecondary,
        ),
        titleSmall: GoogleFonts.orbitron(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textSecondary,
        ),
        // Testo normale - Roboto
        bodyLarge: GoogleFonts.roboto(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: textPrimary,
        ),
        bodyMedium: GoogleFonts.roboto(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: textSecondary,
        ),
        bodySmall: GoogleFonts.roboto(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: textSecondary,
        ),
        // Label
        labelLarge: GoogleFonts.roboto(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        labelMedium: GoogleFonts.roboto(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textSecondary,
        ),
        labelSmall: GoogleFonts.roboto(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: textSecondary,
        ),
      ),

      // ─────────────────────────────────────────────────────────────────────────
      // APPBAR
      // ─────────────────────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundPrimary,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.orbitron(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: textPrimary,
          letterSpacing: 2,
        ),
      ),

      // ─────────────────────────────────────────────────────────────────────────
      // CARD
      // ─────────────────────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: backgroundCard,
        elevation: 8,
        shadowColor: Colors.black54,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: borderColor, width: 1),
        ),
      ),

      // ─────────────────────────────────────────────────────────────────────────
      // BOTTONI ELEVATI (Stile Primario - Verde Neon)
      // ─────────────────────────────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentPrimary,
          foregroundColor: backgroundPrimary,
          elevation: 8,
          shadowColor: accentPrimary.withValues(alpha: 0.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.orbitron(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ),

      // ─────────────────────────────────────────────────────────────────────────
      // BOTTONI OUTLINED
      // ─────────────────────────────────────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accentPrimary,
          side: const BorderSide(color: accentPrimary, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.orbitron(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ),

      // ─────────────────────────────────────────────────────────────────────────
      // BOTTONI TESTO
      // ─────────────────────────────────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accentPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: GoogleFonts.roboto(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // ─────────────────────────────────────────────────────────────────────────
      // INPUT DECORATION
      // ─────────────────────────────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: backgroundCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accentPrimary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accentSecondary),
        ),
        labelStyle: GoogleFonts.roboto(color: textSecondary),
        hintStyle: GoogleFonts.roboto(color: textSecondary.withValues(alpha: 0.6)),
      ),

      // ─────────────────────────────────────────────────────────────────────────
      // FLOATING ACTION BUTTON
      // ─────────────────────────────────────────────────────────────────────────
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accentPrimary,
        foregroundColor: backgroundPrimary,
        elevation: 8,
      ),

      // ─────────────────────────────────────────────────────────────────────────
      // DIALOG
      // ─────────────────────────────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: backgroundCard,
        elevation: 16,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderColor),
        ),
        titleTextStyle: GoogleFonts.orbitron(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        contentTextStyle: GoogleFonts.roboto(
          fontSize: 14,
          color: textSecondary,
        ),
      ),

      // ─────────────────────────────────────────────────────────────────────────
      // SNACKBAR
      // ─────────────────────────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: backgroundCard,
        contentTextStyle: GoogleFonts.roboto(color: textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: borderColor),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // ─────────────────────────────────────────────────────────────────────────
      // DIVIDER
      // ─────────────────────────────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: borderColor,
        thickness: 1,
      ),

      // ─────────────────────────────────────────────────────────────────────────
      // ICON
      // ─────────────────────────────────────────────────────────────────────────
      iconTheme: const IconThemeData(
        color: textPrimary,
        size: 24,
      ),

      // ─────────────────────────────────────────────────────────────────────────
      // BOTTOM NAVIGATION BAR
      // ─────────────────────────────────────────────────────────────────────────
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: backgroundCard,
        selectedItemColor: accentPrimary,
        unselectedItemColor: textSecondary,
        selectedLabelStyle: GoogleFonts.roboto(fontSize: 12),
        unselectedLabelStyle: GoogleFonts.roboto(fontSize: 12),
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STILI BOTTONI PERSONALIZZATI
  // ═══════════════════════════════════════════════════════════════════════════

  /// Stile bottone primario (Verde Neon - Call/Hit)
  static ButtonStyle get primaryButtonStyle {
    return ElevatedButton.styleFrom(
      backgroundColor: accentPrimary,
      foregroundColor: backgroundPrimary,
      elevation: 8,
      shadowColor: accentPrimary.withValues(alpha: 0.6),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      textStyle: GoogleFonts.orbitron(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        letterSpacing: 1,
      ),
    );
  }

  /// Stile bottone secondario (Rosso Neon - Fold/Stand)
  static ButtonStyle get secondaryButtonStyle {
    return ElevatedButton.styleFrom(
      backgroundColor: accentSecondary,
      foregroundColor: textPrimary,
      elevation: 8,
      shadowColor: accentSecondary.withValues(alpha: 0.6),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      textStyle: GoogleFonts.orbitron(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        letterSpacing: 1,
      ),
    );
  }

  /// Stile bottone warning (Giallo/Oro)
  static ButtonStyle get warningButtonStyle {
    return ElevatedButton.styleFrom(
      backgroundColor: warningColor,
      foregroundColor: backgroundPrimary,
      elevation: 8,
      shadowColor: warningColor.withValues(alpha: 0.6),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      textStyle: GoogleFonts.orbitron(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        letterSpacing: 1,
      ),
    );
  }

  /// Stile bottone ghost (Outline)
  static ButtonStyle get ghostButtonStyle {
    return OutlinedButton.styleFrom(
      foregroundColor: textSecondary,
      side: const BorderSide(color: borderColor, width: 1),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      textStyle: GoogleFonts.roboto(
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DECORAZIONI BOX
  // ═══════════════════════════════════════════════════════════════════════════

  /// Decorazione card standard
  static BoxDecoration get cardDecoration {
    return BoxDecoration(
      color: backgroundCard,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: borderColor),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.3),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  /// Decorazione card con glow verde
  static BoxDecoration get glowCardDecorationPrimary {
    return BoxDecoration(
      color: backgroundCard,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: accentPrimary.withValues(alpha: 0.5)),
      boxShadow: [
        BoxShadow(
          color: accentPrimary.withValues(alpha: 0.3),
          blurRadius: 16,
          spreadRadius: 2,
        ),
      ],
    );
  }

  /// Decorazione card con glow rosso
  static BoxDecoration get glowCardDecorationSecondary {
    return BoxDecoration(
      color: backgroundCard,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: accentSecondary.withValues(alpha: 0.5)),
      boxShadow: [
        BoxShadow(
          color: accentSecondary.withValues(alpha: 0.3),
          blurRadius: 16,
          spreadRadius: 2,
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GRADIENTI
  // ═══════════════════════════════════════════════════════════════════════════

  /// Gradiente sfondo principale
  static LinearGradient get backgroundGradient {
    return const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF0a0a0a),
        Color(0xFF0f0f0f),
        Color(0xFF0a0a0a),
      ],
    );
  }

  /// Gradiente verde neon
  static LinearGradient get primaryGradient {
    return const LinearGradient(
      colors: [
        Color(0xFF00FF9D),
        Color(0xFF00CC7D),
      ],
    );
  }

  /// Gradiente rosso neon
  static LinearGradient get secondaryGradient {
    return const LinearGradient(
      colors: [
        Color(0xFFFF0055),
        Color(0xFFCC0044),
      ],
    );
  }
}
