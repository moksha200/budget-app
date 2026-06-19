// lib/views/custom_header_pub.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/constants.dart';

class CustomHeaderPub extends StatelessWidget {
  const CustomHeaderPub({super.key}); // Remplacement par super.key (Clean code)

  @override
  Widget build(BuildContext context) {
    // Calcul de la largeur de l'écran pour un affichage intelligent
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Si l'écran est très petit (moins de 380px, ex: anciens iPhone), on force un design ultra-compact
    final isSmallScreen = screenWidth < 380;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24.0, left: 16.0, right: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(35.0),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 32.0, sigmaY: 32.0),
                child: Container(
                  // Réduction du padding global du dock sur mobile
                  padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 4.0 : 8.0, vertical: 6.0),
                  constraints: const BoxConstraints(maxWidth: 400), // Empêche le dock de devenir trop large sur tablette
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.65), 
                    borderRadius: BorderRadius.circular(35.0),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.95),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6C5CE7).withValues(alpha: 0.18),
                        blurRadius: 60.0,
                        offset: const Offset(0, 20),
                        spreadRadius: -10.0,
                      ),
                      BoxShadow(
                        color: const Color(0xFF1A1A2E).withValues(alpha: 0.12),
                        blurRadius: 80.0,
                        offset: const Offset(0, 40),
                        spreadRadius: -20.0,
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      Positioned(
                        top: 0,
                        left: 20,
                        right: 20,
                        child: Container(
                          height: 1.5,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2.0),
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFFFF6B9D),
                                Color(0xFFFF9F43),
                                Color(0xFFFFD32A),
                                Color(0xFF0BE881),
                                Color(0xFF00D2FF),
                                Color(0xFF6C5CE7),
                                Color(0xFFE84393),
                              ],
                            ),
                          ),
                        ),
                      ),
                      
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // LOGO
                          GestureDetector(
                            onTap: () {},
                            child: Padding(
                              padding: EdgeInsets.only(left: isSmallScreen ? 2.0 : 4.0, right: 4.0),
                              child: Row(
                                children: [
                                  Container(
                                    width: isSmallScreen ? 28 : 32, // Plus petit sur petit écran
                                    height: isSmallScreen ? 28 : 32,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        begin: Alignment.topRight,
                                        end: Alignment.bottomLeft,
                                        colors: [Color(0xFF6366F1), Color(0xFFEC4899)],
                                      ),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      'A',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: isSmallScreen ? 14 : 16,
                                      ),
                                    ),
                                  ),
                                  
                                  // Le texte n'apparaît que s'il y a vraiment de la place (400px+)
                                  if (screenWidth > 400) ...[
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Code Arcanum',
                                      style: TextStyle(
                                        color: AppColors.backgroundDark,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                  ]
                                ],
                              ),
                            ),
                          ),

                          // SÉPARATEUR
                          Container(
                            width: 1,
                            height: 24, // Légèrement réduit
                            margin: EdgeInsets.symmetric(horizontal: isSmallScreen ? 2.0 : 6.0),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  const Color(0xFF6C5CE7).withValues(alpha: 0.2),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),

                          // BOUTON CONNEXION
                          TextButton(
                            onPressed: () => Navigator.pushNamed(context, '/login'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.backgroundDark,
                              padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 8.0 : 14.0, vertical: 12.0),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.0)),
                              minimumSize: Size.zero, // Évite les marges invisibles par défaut
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'Connexion',
                              style: TextStyle(
                                color: AppColors.backgroundDark.withValues(alpha: 0.7),
                                fontWeight: FontWeight.w700,
                                fontSize: isSmallScreen ? 12 : 13, // Ajustement de la police
                              ),
                            ),
                          ),

                          // BOUTON S'INSCRIRE
                          ElevatedButton(
                            onPressed: () => Navigator.pushNamed(context, '/register'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.backgroundDark,
                              foregroundColor: Colors.white,
                              elevation: 4,
                              shadowColor: AppColors.backgroundDark.withValues(alpha: 0.4),
                              padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 12.0 : 16.0, vertical: 10.0),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.0)),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              "S'inscrire",
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: isSmallScreen ? 12 : 13, // Ajustement de la police
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}