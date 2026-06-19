// lib/views/reset_password_view.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../core/constants.dart';
import 'custom_header_pub.dart';

// Énumération pour gérer facilement les 3 états de la page
enum ResetViewState { form, success, error }

class ResetPasswordView extends StatefulWidget {
  final String token;

  const ResetPasswordView({
    Key? key,
    required this.token,
  }) : super(key: key);

  @override
  State<ResetPasswordView> createState() => _ResetPasswordViewState();
}

class _ResetPasswordViewState extends State<ResetPasswordView> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  
  bool _obscurePassword1 = true;
  bool _obscurePassword2 = true;
  bool _isLoading = false;
  
  ResetViewState _viewState = ResetViewState.form;
  String _message = "";

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    if (_formKey.currentState!.validate()) {
      FocusScope.of(context).unfocus();
      setState(() => _isLoading = true);

      try {
        // Appel à l'API en passant le token dans l'URL (comme ton $_GET['token'])
        // et les mots de passe dans le corps (POST)
        final response = await ApiService().post('/reset_password.php?token=${widget.token}', {
          'password': _passwordController.text,
          'password_confirm': _confirmController.text,
        });

        // Succès (Code 200)
        if (mounted) {
          setState(() {
            _viewState = ResetViewState.success;
            _message = response['message'] ?? "Ton mot de passe a été modifié avec succès !";
          });
        }
      } catch (e) {
        // Erreur API ou réseau
        if (mounted) {
          setState(() {
            _viewState = ResetViewState.error;
            _message = e.toString();
          });
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
                        constraints: const BoxConstraints(maxWidth: 450), // CORRECTION ICI
                        padding: const EdgeInsets.all(32.0),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.65),
                          borderRadius: BorderRadius.circular(32.0),
                          border: Border.all(color: Colors.white.withOpacity(0.9), width: 1.5),
                          boxShadow: AppStyles.glassShadow,
                        ),
                        // Transition fluide entre le formulaire, le succès et l'erreur
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 400),
                          transitionBuilder: (Widget child, Animation<double> animation) {
                            return FadeTransition(opacity: animation, child: child);
                          },
                          child: _buildCurrentState(),
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
  // ROUTEUR D'ÉTAT VISUEL
  // ==========================================
  Widget _buildCurrentState() {
    switch (_viewState) {
      case ResetViewState.success:
        return _buildSuccessState();
      case ResetViewState.error:
        return _buildErrorState();
      case ResetViewState.form:
      default:
        return _buildFormState();
    }
  }

  // ==========================================
  // ÉTAT 1: FORMULAIRE
  // ==========================================
  Widget _buildFormState() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // En-tête
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
            child: const Icon(Icons.lock_reset_rounded, color: Colors.white, size: 28),
          ),
          const Text(
            "Nouveau mot de passe",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.backgroundDark, letterSpacing: -0.5),
          ),
          const SizedBox(height: 8),
          const Text(
            "Sécurisez votre compte dès maintenant",
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 32),

          // Champ 1 : Nouveau mot de passe
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text("Nouveau mot de passe", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.backgroundDark)),
              Text("8 caractères min.", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 6),
          _buildPasswordField(
            controller: _passwordController,
            obscureText: _obscurePassword1,
            enabled: !_isLoading,
            onToggle: () => setState(() => _obscurePassword1 = !_obscurePassword1),
            validator: (value) {
              if (value == null || value.isEmpty) return "Ce champ est requis.";
              if (value.length < 8) return "Le mot de passe doit contenir 8 caractères.";
              return null;
            },
          ),
          const SizedBox(height: 20),

          // Champ 2 : Confirmer le mot de passe
          const Text("Confirmer le mot de passe", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.backgroundDark)),
          const SizedBox(height: 6),
          _buildPasswordField(
            controller: _confirmController,
            obscureText: _obscurePassword2,
            enabled: !_isLoading,
            onToggle: () => setState(() => _obscurePassword2 = !_obscurePassword2),
            validator: (value) {
              if (value == null || value.isEmpty) return "Ce champ est requis.";
              if (value != _passwordController.text) return "Les mots de passe ne correspondent pas.";
              return null;
            },
          ),
          const SizedBox(height: 32),

          // Bouton
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
                : const Text("Enregistrer et se connecter", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // ÉTAT 2: ERREUR (TOKEN INVALIDE / EXPIRÉ)
  // ==========================================
  Widget _buildErrorState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          "Lien expiré",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.backgroundDark, letterSpacing: -0.5),
        ),
        const SizedBox(height: 24),
        
        // Boîte d'erreur rouge
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF2F2), // red-50
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFEE2E2)), // red-100
          ),
          child: Column(
            children: [
              Container(
                width: 48, height: 48,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: const BoxDecoration(color: Color(0xFFFEE2E2), shape: BoxShape.circle),
                child: const Icon(Icons.close_rounded, color: Color(0xFFEF4444), size: 24), // red-500
              ),
              Text(
                _message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFFDC2626), fontSize: 14, fontWeight: FontWeight.w600, height: 1.5), // red-600
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Bouton refaire la demande
        ElevatedButton(
          onPressed: () => Navigator.pushReplacementNamed(context, '/forgot_password'),
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
          child: const Text("Refaire une demande", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  // ==========================================
  // ÉTAT 3: SUCCÈS
  // ==========================================
  Widget _buildSuccessState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          "Mot de passe mis à jour",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.backgroundDark, letterSpacing: -0.5),
        ),
        const SizedBox(height: 24),
        
        // Boîte de succès verte
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4), // green-50
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFDCFCE7)), // green-100
          ),
          child: Column(
            children: [
              Container(
                width: 48, height: 48,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: const BoxDecoration(color: Color(0xFFDCFCE7), shape: BoxShape.circle),
                child: const Icon(Icons.check_rounded, color: Color(0xFF16A34A), size: 24), // green-600
              ),
              Text(
                _message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF15803D), fontSize: 14, fontWeight: FontWeight.w600, height: 1.5), // green-700
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Bouton aller au login
        ElevatedButton(
          onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.backgroundDark,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 8,
            shadowColor: AppColors.backgroundDark.withOpacity(0.3),
          ),
          child: const Text("Accéder à la connexion", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  // ==========================================
  // COMPOSANTS RÉUTILISABLES
  // ==========================================
  Widget _buildPasswordField({
    required TextEditingController controller,
    required bool obscureText,
    required bool enabled,
    required VoidCallback onToggle,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      enabled: enabled,
      validator: validator,
      style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.backgroundDark, fontSize: 15),
      decoration: InputDecoration(
        hintText: "••••••••",
        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w400),
        suffixIcon: IconButton(
          icon: Icon(obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: const Color(0xFF94A3B8), size: 20),
          onPressed: onToggle,
          splashRadius: 20,
        ),
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
    );
  }

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