import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Paleta Blue & Gold Premium
  static const Color primaryBlue = Color(
    0xFFA0BEDA,
  ); // Light Sky Blue (Book Cover)
  static const Color accentGold = Color(0xFFD4AF37); // Classic Gold
  static const Color background = Color(0xFF758DA3); // Mesa / Fundo

  static const Color notebookFrame = primaryBlue;
  static const Color notebookPage = Color(0xFFFFF9E5); // Ivory/Cream Paper

  // Monster Sheet - Temática Bestiário
  static const Color monsterSheetBackground = Color(0xFFFDF1DC);
  static const Color monsterSheetAccent = Color(0xFF58180D);
  static const Color monsterSheetText = Color(0xFF58180D);

  // Cores das Abas
  static const Color tabActive = accentGold;
  static const Color tabInactive = Color(0xFF5E7A91);

  // Cores de texto
  static const Color textDark = Color(0xFF2C3E50);
  static const Color textLight = Color(0xFF7F8C8D);
  static const Color textGold = accentGold;

  // Cores das Abas (Mapeamento Unificado)
  static const Color tabMonster = Color(0xFF7B9AB0);
  static const Color tabStory = Color(0xFF5E7A91);
  static const Color tabSessions = Color(0xFF7B9AB0);
  static const Color tabCharacters = Color(0xFF5E7A91);
  static const Color tabItems = Color(0xFF7B9AB0);
  static const Color tabSpells = Color(0xFF5E7A91); // Cor para Magia
  static const Color tabRules = Color(0xFF5E7A91);

  // Semantics for Tabs
  static const Color tabAction = Color(0xFFD32F2F); // Red
  static const Color tabWorld = Color(0xFF388E3C); // Green
  static const Color tabPeople = Color(0xFF1976D2); // Blue
  static const Color tabHistory = Color(0xFF795548); // Brown

  // Page Gradient
  static const Color pageGradientStart = Color(0xFFE5DECF);
  static const Color pageGradientMid1 = Color(0xFFF5F0E1);
  static const Color pageGradientMid2 = Color(0xFFF1EAD8);

  // More Monster Sheet Colors
  static const Color monsterStatBackground = Color(0xFFF7F2E0);
  static const Color monsterStatGreen = Color(0xFF2E7D32);
}

class AppTheme {
  static ThemeData get theme {
    return ThemeData(
      primaryColor: AppColors.primaryBlue,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: GoogleFonts.libreBaskerville().fontFamily,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryBlue,
        primary: AppColors.primaryBlue,
        secondary: AppColors.accentGold,
        surface: AppColors.notebookPage,
      ),
      useMaterial3: true,
      textTheme: GoogleFonts.libreBaskervilleTextTheme().copyWith(
        bodyLarge: const TextStyle(color: AppColors.textDark, fontSize: 16),
        bodyMedium: const TextStyle(color: AppColors.textDark, fontSize: 14),
        titleLarge: const TextStyle(
          color: AppColors.textDark,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
