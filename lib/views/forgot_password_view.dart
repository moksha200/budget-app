// lib/views/forgot_password_view.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../core/constants.dart';
import 'custom_header_pub.dart';

class ForgotPasswordView extends StatefulWidget {
  const ForgotPasswordView({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<ForgotPasswordView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  
  bool _isLoading = false;
  bool _isSuccess = false;
  String _statusMessage = "";

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    if (_formKey.currentState!.validate()) {
      FocusScope.of(context).unfocus();
      setState(() => _isLoading = true);

      try {
        // Appel direct à l'API via notre moteur HTTP
        final response = await ApiService().post('/forgot_password.php', {
          'email': _emailController.text.trim(),
        });

        // Si succès, on bascule l'UI
        if (mounted) {
          setState(() {
            _isSuccess = true;
            _statusMessage = response['message'] ?? 
                "Si une adresse email correspondante existe dans notre système, un lien de réinitialisation vient d'y être envoyé.";
          });
        }
      } catch (e) {
        // En cas d'erreur réseau ou API, on affiche la SnackBar
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
              backgroundColor: AppColors.danger,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      extendBody: true,
      bottomNavigationBar: const CustomHeaderPub(),
      body: Stack(
        children: [
          // 1. Arrière-plan orbes
          _buildBackgroundOrbs(),

          // 2. Le Contenu Glassmorphism
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(32.0),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 24.0, sigmaY: 24.0),
                      child: Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(maxWidth: 450), // Correction appliquée ici
                        padding: const EdgeInsets.all(32.0),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.65),
                          borderRadius: BorderRadius.circular(32.0),
                          border: Border.all(color: Colors.white.withOpacity(0.9), width: 1.5),
                          boxShadow: AppStyles.glassShadow,
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 400),
                          transitionBuilder: (Widget child, Animation<double> animation) {
                            return FadeTransition(opacity: animation, child: child);
                          },
                          child: _isSuccess ? _buildSuccessState() : _buildFormState(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 120), // Espace pour le dock public
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // ÉTAT: FORMULAIRE (AVANT ENVOI)
  // ==========================================
  Widget _buildFormState() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Icône d'en-tête
          Container(
            width: 56,
            height: 56,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFFEC4899)],
              ),
              boxShadow: [
                BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 6)),
              ],
            ),
            child: const Icon(Icons.key_rounded, color: Colors.white, size: 28),
          ),
          const Text(
            "Mot de passe oublié",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: AppColors.backgroundDark,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Saisissez votre email pour récupérer l'accès",
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 32),

          // Champ Email
          const Text("Email du compte", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.backgroundDark)),
          const SizedBox(height: 6),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            enabled: !_isLoading,
            style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.backgroundDark, fontSize: 15),
            validator: (value) {
              if (value == null || value.isEmpty) return "L'email est requis.";
              if (!value.contains('@')) return "Email invalide.";
              return null;
            },
            decoration: InputDecoration(
              hintText: "vous@domaine.com",
              hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w400),
              prefixIcon: const Icon(Icons.email_rounded, color: AppColors.primary, size: 22),
              filled: true,
              fillColor: Colors.white.withOpacity(0.8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: const Color(0xFF6C5CE7).withOpacity(0.2), width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.danger, width: 1),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            ),
          ),
          const SizedBox(height: 24),

          // Bouton de soumission
          ElevatedButton(
            onPressed: _isLoading ? null : _handleResetPassword,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.backgroundDark,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 8,
              shadowColor: AppColors.backgroundDark.withOpacity(0.3),
            ),
            child: _isLoading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : const Text("Envoyer le lien de récupération", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 24),

          // Lien de retour
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Vous vous en souvenez ? ", style: TextStyle(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w500)),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Text("Se connecter", style: TextStyle(color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // ÉTAT: SUCCÈS (APRÈS ENVOI)
  // ==========================================
  Widget _buildSuccessState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Icône de succès
        Container(
          width: 56,
          height: 56,
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFEEF2FF), // indigo-50
            border: Border.all(color: const Color(0xFFE0E7FF)), // indigo-100
          ),
          child: const Icon(Icons.mark_email_read_rounded, color: Color(0xFF4F46E5), size: 28), // indigo-600
        ),
        const Text(
          "Email envoyé",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: AppColors.backgroundDark,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 24),
        
        // Boîte d'information calquée sur bg-indigo-50 de ton PHP
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFEEF2FF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE0E7FF)),
          ),
          child: Text(
            _statusMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF4338CA), // indigo-700
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Bouton de retour à la connexion (Design contour blanc/gris)
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: AppColors.backgroundDark,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Color(0xFFE2E8F0)), // slate-200
            ),
            elevation: 0,
          ),
          child: const Text("Retour à la connexion", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  // ==========================================
  // ARRIÈRE-PLAN (ORBES)
  // ==========================================
  Widget _buildBackgroundOrbs() {
    return Positioned.fill(
      child: Stack(
        children: [
          Positioned(
            top: 50, right: -50,
            child: Container(
              width: 300, height: 300,
              decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [const Color(0xFF6C5CE7).withOpacity(0.15), Colors.transparent])),
            ),
          ),
          Positioned(
            bottom: 100, left: -50,
            child: Container(
              width: 350, height: 350,
              decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [const Color(0xFFFF6B9D).withOpacity(0.15), Colors.transparent])),
            ),
          ),
          BackdropFilter(filter: ImageFilter.blur(sigmaX: 70.0, sigmaY: 70.0), child: Container(color: Colors.transparent)),
        ],
      ),
    );
  }
}