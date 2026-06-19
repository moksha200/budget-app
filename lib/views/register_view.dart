// lib/views/register_view.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../core/constants.dart';
import 'custom_header_pub.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isSuccess = false;

  String _errorMessage = "";
  String _successMessage = "";

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ==========================================
  // INSCRIPTION CLASSIQUE (EMAIL / MDP)
  // ==========================================
  Future<void> _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      FocusScope.of(context).unfocus();
      setState(() {
        _isLoading = true;
        _errorMessage = "";
      });

      try {
        final response = await ApiService().post('/register.php', {
          'username': _usernameController.text.trim(),
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
        });

        if (mounted) {
          setState(() {
            _isSuccess = true;
            _successMessage = response['message'] ?? "Inscription réussie ! Un lien de vérification a été envoyé à ton adresse email.";
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _errorMessage = e.toString();
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
                        constraints: const BoxConstraints(maxWidth: 450), // Correction Analyzer
                        padding: const EdgeInsets.all(32.0),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.65), // Correction Deprecation
                          borderRadius: BorderRadius.circular(32.0),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.9), width: 1.5),
                          boxShadow: AppStyles.glassShadow,
                        ),
                        // Transition fluide entre le formulaire et le succès
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
  // ÉTAT 1: FORMULAIRE D'INSCRIPTION
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
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFFEC4899)],
              ),
              boxShadow: [
                BoxShadow(color: const Color(0xFF6366F1).withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 6)),
              ],
            ),
            alignment: Alignment.center,
            child: const Text("A", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24)),
          ),
          const Text(
            "Créer un compte",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.backgroundDark, letterSpacing: -0.5),
          ),
          const SizedBox(height: 8),
          const Text(
            "Rejoignez le Portail Budgets",
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 24),

          // Boîte d'erreur
          if (_errorMessage.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFEE2E2)),
              ),
              child: Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFFDC2626), fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),

          // Champ Username
          const Text("Nom d'utilisateur", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.backgroundDark)),
          const SizedBox(height: 6),
          _buildTextField(
            controller: _usernameController,
            placeholder: "Ton pseudo",
            icon: Icons.person_rounded,
            enabled: !_isLoading,
            validator: (value) {
              if (value == null || value.trim().isEmpty) return "Le nom d'utilisateur est requis.";
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Champ Email
          const Text("Adresse Email", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.backgroundDark)),
          const SizedBox(height: 6),
          _buildTextField(
            controller: _emailController,
            placeholder: "vous@domaine.com",
            icon: Icons.email_rounded,
            keyboardType: TextInputType.emailAddress,
            enabled: !_isLoading,
            validator: (value) {
              if (value == null || value.trim().isEmpty) return "L'email est requis.";
              if (!value.contains('@')) return "Email invalide.";
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Champ Mot de passe
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text("Mot de passe", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.backgroundDark)),
              Text("8 caractères min.", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 6),
          _buildTextField(
            controller: _passwordController,
            placeholder: "••••••••",
            icon: Icons.lock_rounded,
            isPassword: true,
            obscureText: _obscurePassword,
            enabled: !_isLoading,
            onTogglePassword: () => setState(() => _obscurePassword = !_obscurePassword),
            validator: (value) {
              if (value == null || value.isEmpty) return "Le mot de passe est requis.";
              if (value.length < 8) return "Doit contenir au moins 8 caractères.";
              return null;
            },
          ),
          const SizedBox(height: 32),

          // Bouton Soumettre
          ElevatedButton(
            onPressed: _isLoading ? null : _handleRegister,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.backgroundDark,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 8,
              shadowColor: AppColors.backgroundDark.withValues(alpha: 0.3),
            ),
            child: _isLoading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : const Text("S'inscrire et sécuriser le compte", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 24),

          // Lien de retour Login
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Déjà un compte ? ", style: TextStyle(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w500)),
              GestureDetector(
                onTap: () => Navigator.pushReplacementNamed(context, '/login'),
                child: const Text("Se connecter", style: TextStyle(color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // ÉTAT 2: SUCCÈS (APRÈS INSCRIPTION)
  // ==========================================
  Widget _buildSuccessState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: 56,
          height: 56,
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFF0FDF4),
            border: Border.all(color: const Color(0xFFDCFCE7)),
          ),
          child: const Icon(Icons.mark_email_read_rounded, color: Color(0xFF16A34A), size: 28),
        ),
        const Text(
          "Succès",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.backgroundDark, letterSpacing: -0.5),
        ),
        const SizedBox(height: 24),

        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFDCFCE7)),
          ),
          child: Text(
            _successMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF15803D), fontSize: 14, fontWeight: FontWeight.w600, height: 1.5),
          ),
        ),
        const SizedBox(height: 32),

        ElevatedButton(
          onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF16A34A),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 4,
          ),
          child: const Text("Aller à la page de connexion", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
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
              decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [const Color(0xFF6C5CE7).withValues(alpha: 0.15), Colors.transparent])),
            ),
          ),
          Positioned(
            bottom: 100, left: -50,
            child: Container(
              width: 350, height: 350,
              decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [const Color(0xFFFF6B9D).withValues(alpha: 0.15), Colors.transparent])),
            ),
          ),
          BackdropFilter(filter: ImageFilter.blur(sigmaX: 70.0, sigmaY: 70.0), child: Container(color: Colors.transparent)),
        ],
      ),
    );
  }

  // ==========================================
  // COMPOSANT: CHAMP DE TEXTE
  // ==========================================
  Widget _buildTextField({
    required TextEditingController controller,
    required String placeholder,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    bool enabled = true,
    VoidCallback? onTogglePassword,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      enabled: enabled,
      validator: validator,
      style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.backgroundDark, fontSize: 15),
      decoration: InputDecoration(
        hintText: placeholder,
        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w400),
        prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: const Color(0xFF94A3B8), size: 20),
                onPressed: onTogglePassword,
                splashRadius: 20,
              )
            : null,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: const Color(0xFF6C5CE7).withValues(alpha: 0.2), width: 1),
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
}