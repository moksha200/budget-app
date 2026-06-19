import 'package:flutter/material.dart';

// ==========================================
// 1. CONFIGURATION RÉSEAU
// ==========================================
class ApiConstants {
  // Modifie cette URL en production si ton domaine change
  static const String baseUrl = 'https://budgets.alwaysdata.net/api/v1';
  static const int timeoutSeconds = 15;
}

// ==========================================
// 2. DESIGN SYSTEM (Couleurs)
// ==========================================
class AppColors {
  // Couleurs principales (Tirées de ton interface web)
  static const Color backgroundDark = Color(0xFF1A1A2E);
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surfaceWhite = Color(0xFFFFFFFF);

  // Couleurs sémantiques (Revenus, Dépenses, Dettes)
  static const Color success = Color(0xFF10B981); // Emerald 500
  static const Color danger = Color(0xFFF43F5E);  // Rose 500
  static const Color warning = Color(0xFFF59E0B); // Amber 500

  // Accents et Dégradés (Boutons, icônes)
  static const Color primary = Color(0xFF6366F1); // Indigo 500
  static const Color secondary = Color(0xFFEC4899); // Pink 500

  // Textes
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF64748B); // Slate 500
}

// ==========================================
// 3. STYLES ET FORMES (UI/UX)
// ==========================================
class AppStyles {
  // Espacements standards
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXLarge = 32.0;

  // Arrondis (Pour matcher parfaitement ton CSS "rounded-[2rem]")
  static const double borderRadiusSmall = 12.0;
  static const double borderRadiusMedium = 16.0;
  static const double borderRadiusLarge = 32.0;

  // Ombrage standard pour le Glassmorphism mobile
  static List<BoxShadow> glassShadow = [
    BoxShadow(
      color: AppColors.primary.withOpacity(0.15),
      blurRadius: 40.0,
      offset: const Offset(0, 10),
      spreadRadius: -10.0,
    )
  ];
}

// ==========================================
// 4. CLÉS DE STOCKAGE SÉCURISÉ
// ==========================================
class StorageKeys {
  // Centralisation des clés pour éviter les fautes de frappe
  static const String apiToken = 'api_token';
  static const String userPrefs = 'user_preferences';
}