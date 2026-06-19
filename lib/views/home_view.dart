// lib/views/home_view.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'custom_header_pub.dart';
import '../core/constants.dart';

class HomeView extends StatelessWidget {
  const HomeView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Récupération de la largeur pour le responsive
    final double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      extendBody: true, // Essentiel pour que le contenu glisse sous le Dock
      bottomNavigationBar: const CustomHeaderPub(),
      body: Stack(
        children: [
          // 1. LE FOND : ORBES LUMINEUSES ET FLOU
          _buildBackgroundOrbs(),

          // 2. LE CONTENU SCROLLABLE
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                const SizedBox(height: 80), // Espace en haut

                // --- SECTION HERO ---
                _buildHeroSection(context, screenWidth),

                // --- SECTION STATISTIQUES ---
                _buildStatsSection(screenWidth),

                // --- SECTION L'ARSENAL (FEATURES) ---
                _buildArsenalSection(screenWidth),

                // --- SECTION TEMOIGNAGES ---
                _buildTestimonialsSection(screenWidth),

                // --- SECTION CALL TO ACTION (CTA) ---
                _buildCtaSection(context),

                // --- FOOTER ---
                _buildFooter(),

                // Espace en bas pour ne pas que le contenu soit caché par le dock
                const SizedBox(height: 120), 
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // ARRIÈRE-PLAN (ORBES)
  // ==========================================
  Widget _buildBackgroundOrbs() {
    return Positioned.fill(
      child: Stack(
        children: [
          // Orbe Indigo/Violet en haut à gauche
          Positioned(
            top: -50,
            left: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF6C5CE7).withOpacity(0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Orbe Rose en bas à droite
          Positioned(
            bottom: 200,
            right: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFF6B9D).withOpacity(0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Filtre de flou global pour lisser les orbes
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 80.0, sigmaY: 80.0),
            child: Container(color: Colors.transparent),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // SECTION: HERO
  // ==========================================
  Widget _buildHeroSection(BuildContext context, double screenWidth) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Badge "Nouvelle version"
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.4),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white.withOpacity(0.8)),
              boxShadow: AppStyles.glassShadow,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Color(0xFF0BE881),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  "Nouvelle version 2.0 disponible",
                  style: TextStyle(
                    color: Color(0xFF4338CA), // Indigo 700
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Titre principal
          const Text(
            "Maîtrisez votre",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.w900,
              color: AppColors.backgroundDark,
              height: 1.1,
              letterSpacing: -1,
            ),
          ),
          
          // Texte en dégradé (ShaderMask)
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFFA855F7), Color(0xFFEC4899)], // Indigo -> Purple -> Pink
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ).createShader(bounds),
            child: const Text(
              "Destin Financier",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.w900,
                color: Colors.white, // Nécessaire pour que le masque fonctionne
                height: 1.1,
                letterSpacing: -1,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Description
          Text(
            "Oubliez les tableurs chaotiques. Code Arcanum transforme vos données brutes en une interface visuelle pure. Suivi en temps réel, IA prédictive et sécurité de grade bancaire.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 40),

          // Boutons d'action
          Column(
            children: [
              _buildGlowButton(
                text: "Démarrer gratuitement", 
                onPressed: () => Navigator.pushNamed(context, '/register'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.6),
                  foregroundColor: AppColors.backgroundDark,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                    side: BorderSide(color: Colors.white.withOpacity(0.8)),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  "Découvrir l'outil",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 48),

          // Image flottante
          Container(
            height: 300,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withOpacity(0.3),
                  blurRadius: 40,
                  spreadRadius: -10,
                  offset: const Offset(0, 20),
                )
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: Image.network(
                "https://images.unsplash.com/photo-1551288049-bebda4e38f71?q=80&w=2070&auto=format&fit=crop",
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // SECTION: STATISTIQUES
  // ==========================================
  Widget _buildStatsSection(double screenWidth) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 48),
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        border: Border.symmetric(horizontal: BorderSide(color: Colors.white.withOpacity(0.4))),
      ),
      child: Wrap(
        spacing: 32,
        runSpacing: 32,
        alignment: WrapAlignment.center,
        children: [
          _buildStatItem("10k+", "Utilisateurs Actifs", const [Color(0xFF6366F1), Color(0xFFA855F7)]),
          _buildStatItem("€2M+", "Gérés Mensuellement", const [Color(0xFFA855F7), Color(0xFFEC4899)]),
          _buildStatItem("AES-256", "Chiffrement Militaire", const [AppColors.backgroundDark, AppColors.backgroundDark]),
          _buildStatItem("99.9%", "Uptime Garanti", const [AppColors.backgroundDark, AppColors.backgroundDark]),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, List<Color> gradientColors) {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(colors: gradientColors).createShader(bounds),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  // ==========================================
  // SECTION: L'ARSENAL (FEATURES)
  // ==========================================
  Widget _buildArsenalSection(double screenWidth) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          const Text(
            "L'ARSENAL ARCANUM",
            style: TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 12),
          ),
          const SizedBox(height: 12),
          const Text(
            "Un écosystème conçu pour la croissance",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.backgroundDark, height: 1.2),
          ),
          const SizedBox(height: 16),
          const Text(
            "Six modules interconnectés pour analyser, prévoir et optimiser chaque centime qui traverse votre vie.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 40),

          // Grille des fonctionnalités
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _buildFeatureCard(Icons.sync_rounded, "Flux en Temps Réel", "Synchronisation instantanée de vos dépenses. Catégorisation intelligente.", const [Color(0xFF60A5FA), Color(0xFF4F46E5)], screenWidth),
              _buildFeatureCard(Icons.swap_horiz_rounded, "Gestion des Créances", "Fini les oublis. Enregistrez qui vous doit quoi et fixez des échéances.", const [Color(0xFFF472B6), Color(0xFFE11D48)], screenWidth),
              _buildFeatureCard(Icons.track_changes_rounded, "Objectifs Intelligents", "Définissez un but. L'algorithme calcule l'effort d'épargne mensuel.", const [Color(0xFFFBBF24), Color(0xFFF97316)], screenWidth),
              _buildFeatureCard(Icons.shield_rounded, "Coffre-fort Crypté", "Hachage strict et chiffrement AES-256 sur toutes vos informations.", const [Color(0xFF34D399), Color(0xFF16A34A)], screenWidth),
              _buildFeatureCard(Icons.auto_graph_rounded, "Rapports IA", "Générez des analyses prédictives sur la tendance de votre patrimoine.", const [Color(0xFFC084FC), Color(0xFF7E22CE)], screenWidth),
              _buildFeatureCard(Icons.currency_exchange_rounded, "Multi-Devises", "Convertit et harmonise vos soldes pour une vue globale sans frontière.", const [Color(0xFF22D3EE), Color(0xFF3B82F6)], screenWidth),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(IconData icon, String title, String desc, List<Color> colors, double screenWidth) {
    return Container(
      width: screenWidth > 600 ? (screenWidth / 2) - 32 : double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.8)),
        boxShadow: AppStyles.glassShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: colors.last.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 6))],
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 20),
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.backgroundDark)),
          const SizedBox(height: 8),
          Text(desc, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5)),
        ],
      ),
    );
  }

  // ==========================================
  // SECTION: TEMOIGNAGES
  // ==========================================
  Widget _buildTestimonialsSection(double screenWidth) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [Colors.white.withOpacity(0.6), Colors.white.withOpacity(0.2)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: Colors.white.withOpacity(0.8)),
        ),
        child: Column(
          children: [
            const Text("Ce que disent nos utilisateurs", textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.backgroundDark)),
            const SizedBox(height: 32),
            Wrap(
              spacing: 16, runSpacing: 16,
              children: [
                _buildTestimonialItem("L'interface est d'une fluidité incroyable. J'ai enfin une vue claire sur les dettes.", "M", "Marc Dubois", "Entrepreneur", const Color(0xFF4F46E5), screenWidth),
                _buildTestimonialItem("La sécurité cryptée me permet d'utiliser l'outil sereinement au quotidien.", "S", "Sophie Laurent", "Investisseuse", const Color(0xFFEC4899), screenWidth),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTestimonialItem(String text, String initial, String name, String role, Color color, double screenWidth) {
    return Container(
      width: screenWidth > 600 ? (screenWidth / 2) - 64 : double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('"$text"', style: const TextStyle(fontStyle: FontStyle.italic, color: Color(0xFF334155), height: 1.5)),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Text(initial, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16)),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.backgroundDark)),
                  Text(role, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              )
            ],
          )
        ],
      ),
    );
  }

  // ==========================================
  // SECTION: CALL TO ACTION
  // ==========================================
  Widget _buildCtaSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 24.0),
      child: Column(
        children: [
          const Text("Prêt à reprendre le contrôle ?", textAlign: TextAlign.center, style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.backgroundDark)),
          const SizedBox(height: 16),
          const Text("Rejoignez Code Arcanum aujourd'hui. L'inscription prend moins de 60 secondes.", textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: AppColors.textSecondary)),
          const SizedBox(height: 32),
          _buildGlowButton(text: "Créer mon compte sécurisé", onPressed: () => Navigator.pushNamed(context, '/register'), padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18)),
          const SizedBox(height: 16),
          const Text("Aucune carte de crédit requise.", style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  // ==========================================
  // FOOTER
  // ==========================================
  Widget _buildFooter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.4))),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 32, height: 32,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [Color(0xFF6366F1), Color(0xFFEC4899)]),
                ),
                alignment: Alignment.center,
                child: const Text('A', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              const Text("Code Arcanum", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.backgroundDark)),
            ],
          ),
          const SizedBox(height: 16),
          const Text("© 2026 Code Arcanum. Tous droits réservés.", style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  // ==========================================
  // COMPOSANT: BOUTON GLOW
  // ==========================================
  // Reproduit fidèlement le CSS .btn-glow avec le dégradé "Rainbow" en bordure
  Widget _buildGlowButton({required String text, required VoidCallback onPressed, EdgeInsetsGeometry? padding}) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(50),
          gradient: const LinearGradient(
            colors: [Color(0xFFFF6B9D), Color(0xFFFF9F43), Color(0xFF0BE881), Color(0xFF00D2FF), Color(0xFF6C5CE7)],
          ),
          boxShadow: [BoxShadow(color: const Color(0xFF6C5CE7).withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8))],
        ),
        // Le padding ici crée l'épaisseur de la bordure lumineuse (2px)
        padding: const EdgeInsets.all(2.0),
        child: Container(
          decoration: BoxDecoration(color: AppColors.backgroundDark, borderRadius: BorderRadius.circular(50)),
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          child: Text(
            text,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
      ),
    );
  }
}