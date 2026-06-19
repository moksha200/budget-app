// lib/views/login_view.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../core/constants.dart';
import 'custom_header_pub.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  String _errorMessage = "";

  @override
  void initState() {
    super.initState();
    // Déclenchement de l'auto-login silencieux dès le chargement de la vue
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkSession();
    });
  }

  // ==========================================
  // VÉRIFICATION DE LA SESSION (AUTO-LOGIN)
  // ==========================================
  Future<void> _checkSession() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    // checkAuthState va tenter d'utiliser le Refresh Token via l'intercepteur si besoin
    bool isSessionValid = await context.read<AuthProvider>().checkAuthState();

    if (isSessionValid && mounted) {
      Navigator.pushReplacementNamed(context, '/app/dashboard');
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ==========================================
  // CONNEXION CLASSIQUE (EMAIL / MDP)
  // ==========================================
  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      FocusScope.of(context).unfocus();
      setState(() {
        _isLoading = true;
        _errorMessage = "";
      });

      try {
        await context.read<AuthProvider>().login(
          _emailController.text.trim(),
          _passwordController.text,
        );

        if (mounted) {
          Navigator.pushReplacementNamed(context, '/app/dashboard');
        }
      } on ApiException catch (e) {
        // Capture ciblée de l'exception pour extraire le message propre
        if (mounted) {
          setState(() {
            _errorMessage = e.message;
          });
        }
      } catch (e) {
        // Fallback générique
        if (mounted) {
          setState(() {
            _errorMessage = "Une erreur inattendue est survenue.";
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
                        constraints: const BoxConstraints(maxWidth: 450),
                        padding: const EdgeInsets.all(32.0),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(32.0),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.9), width: 1.5),
                          boxShadow: AppStyles.glassShadow,
                        ),
                        child: _buildFormState(),
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
            "Bon retour",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.backgroundDark, letterSpacing: -0.5),
          ),
          const SizedBox(height: 8),
          const Text(
            "Accédez à votre tableau de bord financier",
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
            children: [
              const Text("Mot de passe", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.backgroundDark)),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/forgot_password'),
                child: const Text("Oublié ?", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
              ),
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
              return null;
            },
          ),
          const SizedBox(height: 32),

          // Bouton Soumettre
          ElevatedButton(
            onPressed: _isLoading ? null : _handleLogin,
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
                : const Text("Se connecter", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 24),

          // Lien de création de compte
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Nouveau ici ? ", style: TextStyle(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w500)),
              GestureDetector(
                onTap: () => Navigator.pushReplacementNamed(context, '/register'),
                child: const Text("Créer un compte", style: TextStyle(color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.bold)),
              ),
            ],
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
          Positioned(
            top: -50, right: -50,
            child: Container(
              width: 300, height: 300,
              decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [const Color(0xFF6C5CE7).withValues(alpha: 0.15), Colors.transparent])),
            ),
          ),
          Positioned(
            bottom: 50, left: -50,
            child: Container(
              width: 350, height: 350,
              decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [const Color(0xFFFFD32A).withValues(alpha: 0.15), Colors.transparent])),
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