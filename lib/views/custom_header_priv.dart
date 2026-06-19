// lib/views/custom_header_priv.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/constants.dart';

class CustomHeaderPriv extends StatelessWidget {
  // Cette variable permet de savoir quelle page est active (comme ton $current_uri)
  final String currentRoute;

  const CustomHeaderPriv({
    Key? key,
    required this.currentRoute,
  }) : super(key: key);

  // Définition de tes routes et icônes (Les couleurs correspondent à ton CSS)
  static final List<Map<String, dynamic>> _navItems = [
    {'route': '/app/dashboard', 'icon': Icons.home_rounded, 'label': 'Accueil', 'color': const Color(0xFFFF6B9D)},
    {'route': '/app/add', 'icon': Icons.add_circle_outline_rounded, 'label': 'Ajouter', 'color': const Color(0xFFFF9F43)},
    {'route': '/app/goals', 'icon': Icons.track_changes_rounded, 'label': 'Objectifs', 'color': const Color(0xFF0BE881)},
    {'isSeparator': true},
    {'route': '/app/loans', 'icon': Icons.swap_horiz_rounded, 'label': 'Prêts', 'color': const Color(0xFF00D2FF)},
    {'route': '/app/history', 'icon': Icons.history_rounded, 'label': 'Historique', 'color': const Color(0xFF6C5CE7)},
    {'route': '/app/settings', 'icon': Icons.settings_rounded, 'label': 'Param.', 'color': const Color(0xFFE84393)},
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24.0, left: 16.0, right: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Le contour flouté du Dock
            ClipRRect(
              borderRadius: BorderRadius.circular(35.0),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 32.0, sigmaY: 32.0),
                child: Container(
                  padding: const EdgeInsets.all(6.0),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width - 32, // Évite de déborder
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.65),
                    borderRadius: BorderRadius.circular(35.0),
                    border: Border.all(color: Colors.white.withOpacity(0.95), width: 1.5),
                    boxShadow: [
                      BoxShadow(color: const Color(0xFF6C5CE7).withOpacity(0.18), blurRadius: 60.0, offset: const Offset(0, 20), spreadRadius: -10.0),
                      BoxShadow(color: const Color(0xFF1A1A2E).withOpacity(0.12), blurRadius: 80.0, offset: const Offset(0, 40), spreadRadius: -20.0),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      // La ligne arc-en-ciel (var(--rainbow))
                      Positioned(
                        top: 0, left: 20, right: 20,
                        child: Container(
                          height: 1.5,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2.0),
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF6B9D), Color(0xFFFF9F43), Color(0xFFFFD32A), Color(0xFF0BE881), Color(0xFF00D2FF), Color(0xFF6C5CE7), Color(0xFFE84393)],
                            ),
                          ),
                        ),
                      ),
                      
                      // Le contenu scrollable du dock (comme ton overflow-x: auto)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: _navItems.map((item) {
                            if (item.containsKey('isSeparator')) {
                              return _buildSeparator();
                            }
                            return _buildNavItem(context, item);
                          }).toList(),
                        ),
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

  // Séparateur vertical
  Widget _buildSeparator() {
    return Container(
      width: 1, height: 28,
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [Colors.transparent, const Color(0xFF6C5CE7).withOpacity(0.2), Colors.transparent],
        ),
      ),
    );
  }

  // Élément du menu (avec animation si actif)
  Widget _buildNavItem(BuildContext context, Map<String, dynamic> item) {
    bool isActive = currentRoute == item['route'];
    Color itemColor = item['color'];

    return GestureDetector(
      onTap: () {
        // Si on n'est pas déjà sur la page, on y va
        if (!isActive) {
          // Utilisation de pushReplacementNamed pour ne pas empiler les pages à l'infini
          Navigator.pushReplacementNamed(context, item['route']);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutBack, // Équivalent de ton cubic-bezier(--spring)
        margin: const EdgeInsets.symmetric(horizontal: 2.0),
        padding: EdgeInsets.symmetric(
          horizontal: isActive ? 14.0 : 10.0,
          vertical: 10.0,
        ),
        decoration: BoxDecoration(
          color: isActive ? Colors.white.withOpacity(0.85) : Colors.transparent,
          borderRadius: BorderRadius.circular(26.0),
          border: Border.all(
            color: isActive ? Colors.white : Colors.transparent,
            width: 1.0,
          ),
          boxShadow: isActive ? [
            BoxShadow(color: const Color(0xFF6C5CE7).withOpacity(0.25), blurRadius: 28, offset: const Offset(0, 8), spreadRadius: -6),
          ] : [],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                // Icône
                AnimatedTheme(
                  data: ThemeData(
                    iconTheme: IconThemeData(
                      color: isActive ? itemColor : AppColors.backgroundDark.withOpacity(0.45),
                      size: 24,
                    ),
                  ),
                  child: Icon(item['icon']),
                ),
                
                // Texte qui s'étend uniquement si actif
                AnimatedSize(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOutBack,
                  child: Container(
                    padding: isActive ? const EdgeInsets.only(left: 6.0) : EdgeInsets.zero,
                    child: isActive 
                      ? Text(
                          item['label'],
                          style: const TextStyle(
                            color: AppColors.backgroundDark,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                        )
                      : const SizedBox.shrink(), // Disparaît totalement si inactif
                  ),
                ),
              ],
            ),
            
            // Le petit point (dot) arc-en-ciel en dessous si actif
            if (isActive)
              Container(
                margin: const EdgeInsets.only(top: 4.0),
                width: 4.0, height: 4.0,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFFFF6B9D), Color(0xFF00D2FF)],
                  ),
                  boxShadow: [
                    BoxShadow(color: Color(0xFF6C5CE7), blurRadius: 4.0),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}