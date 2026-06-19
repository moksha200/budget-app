// lib/views/settings_view.dart

import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import '../core/constants.dart';
import 'custom_header_priv.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({Key? key}) : super(key: key);

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  bool _isLoading = true;
  bool _isSubmittingProfile = false;
  bool _isSubmittingPassword = false;

  // Données utilisateur
  String _name = '';
  String _email = '';
  String _profilePicture = '';
  bool _hasPassword = true;

  // Contrôleurs Profil
  final _whatsappCtrl = TextEditingController();
  File? _selectedImage; // Stocke l'image choisie avant l'upload
  final ImagePicker _picker = ImagePicker();

  // Contrôleurs Sécurité
  final _pwdFormKey = GlobalKey<FormState>();
  final _currentPwdCtrl = TextEditingController();
  final _newPwdCtrl = TextEditingController();
  final _confirmPwdCtrl = TextEditingController();

  // Visibilité mots de passe
  bool _obsCurrent = true;
  bool _obsNew = true;
  bool _obsConfirm = true;

  @override
  void initState() {
    super.initState();
    _fetchSettings();
  }

  @override
  void dispose() {
    _whatsappCtrl.dispose();
    _currentPwdCtrl.dispose();
    _newPwdCtrl.dispose();
    _confirmPwdCtrl.dispose();
    super.dispose();
  }

  // ==========================================
  // RÉCUPÉRATION DES DONNÉES
  // ==========================================
  Future<void> _fetchSettings() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final response = await ApiService().get('settings.php');
      if (mounted && response != null) {
        setState(() {
          if (response is Map && response.containsKey('data') && response['data'] is Map) {
            final data = response['data'];
            _name = data['name'] ?? '';
            _email = data['email'] ?? '';
            _whatsappCtrl.text = data['whatsapp_number'] ?? '';
            _profilePicture = data['profile_picture'] ?? '';
            _hasPassword = data['has_password'] == true;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnack("Erreur de chargement : ${e.toString()}", isError: true);
      }
    }
  }

  // ==========================================
  // SELECTION D'IMAGE
  // ==========================================
  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800, // Compression de base
        maxHeight: 800,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      _showSnack("Erreur lors de la sélection de l'image.", isError: true);
    }
  }

  // ==========================================
  // ACTIONS API
  // ==========================================
  Future<void> _submitProfile() async {
    setState(() => _isSubmittingProfile = true);
    try {
      // On utilise postMultipart au lieu de post pour gérer le fichier
      final response = await ApiService().postMultipart(
        'settings.php',
        fields: {
          'action': 'update_profile',
          'whatsapp_number': _whatsappCtrl.text.trim(),
        },
        file: _selectedImage, // L'image est attachée ici
      );

      if (mounted && response != null && response['success'] == true) {
        if (response['new_profile_picture'] != null) {
          setState(() {
            _profilePicture = response['new_profile_picture'];
            _selectedImage = null; // On nettoie la sélection locale
          });
        }
        _showSnack(response['message'] ?? "Profil mis à jour avec succès !");
      }
    } catch (e) {
      if (mounted) _showSnack("Erreur : ${e.toString()}", isError: true);
    } finally {
      if (mounted) setState(() => _isSubmittingProfile = false);
    }
  }

  Future<void> _submitPassword() async {
    if (!_pwdFormKey.currentState!.validate()) return;
    setState(() => _isSubmittingPassword = true);
    try {
      final response = await ApiService().post('settings.php', {
        'action': 'update_password',
        'current_password': _currentPwdCtrl.text,
        'new_password': _newPwdCtrl.text,
        'confirm_password': _confirmPwdCtrl.text,
      });
      if (mounted && response != null && response['success'] == true) {
        _currentPwdCtrl.clear();
        _newPwdCtrl.clear();
        _confirmPwdCtrl.clear();
        setState(() => _hasPassword = true); 
        _showSnack(response['message'] ?? "Mot de passe sauvegardé !");
      }
    } catch (e) {
      if (mounted) _showSnack("Erreur : ${e.toString()}", isError: true);
    } finally {
      if (mounted) setState(() => _isSubmittingPassword = false);
    }
  }

  void _logout() async {
    await context.read<AuthProvider>().logout();
    if (mounted) Navigator.pushReplacementNamed(context, '/login');
  }

  // ==========================================
  // HELPERS
  // ==========================================
  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppColors.danger : const Color(0xFF059669),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  ImageProvider _getAvatarImage() {
    // Si l'utilisateur vient de choisir une image, on l'affiche localement
    if (_selectedImage != null) {
      return FileImage(_selectedImage!);
    }
    
    // Sinon on charge depuis le réseau
    if (_profilePicture.isNotEmpty && _profilePicture.startsWith('http')) {
      return NetworkImage(_profilePicture);
    } else if (_profilePicture.isNotEmpty) {
      return NetworkImage("https://budgets.alwaysdata.net$_profilePicture"); 
    }
    
    // Avatar par défaut généré avec ses initiales
    final encodedName = Uri.encodeComponent(_name.isNotEmpty ? _name : 'User');
    return NetworkImage("https://ui-avatars.com/api/?name=$encodedName&background=4f46e5&color=fff&size=128");
  }

  // ==========================================
  // BUILD PRINCIPAL
  // ==========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      extendBody: true,
      bottomNavigationBar: const CustomHeaderPriv(currentRoute: '/app/settings'),
      body: Stack(
        children: [
          _buildAnimatedMesh(),

          RefreshIndicator(
            onRefresh: _fetchSettings,
            color: AppColors.primary,
            backgroundColor: Colors.white,
            edgeOffset: 40,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 48),

                  _buildHeader(),
                  const SizedBox(height: 24),

                  if (_isLoading)
                    const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 40), child: CircularProgressIndicator(color: AppColors.primary)))
                  else ...[
                    _buildProfileCard(),
                    const SizedBox(height: 24),
                    _buildSecurityCard(),
                  ],

                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // COMPOSANTS UI
  // ==========================================
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Paramètres", style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: AppColors.backgroundDark, letterSpacing: -0.5)),
              SizedBox(height: 4),
              Text("Gérez votre profil et votre sécurité.", style: TextStyle(fontSize: 14, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        GestureDetector(
          onTap: _logout,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1F2),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFECDD3)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
            ),
            child: Row(children: const [
              Icon(Icons.logout_rounded, size: 18, color: AppColors.danger),
              SizedBox(width: 8),
              Text('Déconnexion', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.danger)),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          width: double.infinity, padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.65), borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.9), width: 1.5),
            boxShadow: [BoxShadow(color: const Color(0xFF6C5CE7).withOpacity(0.08), blurRadius: 30, offset: const Offset(0, 8))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.person_outline_rounded, size: 20, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  const Text('Profil Personnel', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.backgroundDark)),
                ],
              ),
              const SizedBox(height: 24),

              // Avatar & Nom
              Row(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      children: [
                        Container(
                          width: 80, height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)],
                            image: DecorationImage(image: _getAvatarImage(), fit: BoxFit.cover),
                          ),
                        ),
                        Positioned(
                          bottom: 0, right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(color: AppColors.backgroundDark, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                            child: const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
                          ),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_name.isNotEmpty ? _name : 'Utilisateur', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.backgroundDark)),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(6)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.verified_rounded, size: 12, color: Color(0xFF059669)),
                              SizedBox(width: 4),
                              Text('Compte vérifié', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF059669))),
                            ],
                          ),
                        )
                      ],
                    ),
                  )
                ],
              ),
              const SizedBox(height: 24),
              Divider(color: Colors.blueGrey.withOpacity(0.12), height: 1),
              const SizedBox(height: 24),

              // Champs
              _fieldLabel('Adresse Email'),
              const SizedBox(height: 6),
              _glassInput(
                controller: TextEditingController(text: _email),
                enabled: false,
              ),
              const Padding(
                padding: EdgeInsets.only(top: 4, left: 4),
                child: Text('Non modifiable pour des raisons de sécurité.', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
              ),
              const SizedBox(height: 16),

              _fieldLabel('Numéro WhatsApp'),
              const SizedBox(height: 6),
              _glassInput(
                controller: _whatsappCtrl,
                hintText: '+229 XX XX XX XX',
              ),
              const Padding(
                padding: EdgeInsets.only(top: 4, left: 4),
                child: Text("Utile pour les alertes ou l'assistance.", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmittingProfile ? null : _submitProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white, foregroundColor: AppColors.backgroundDark,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    side: const BorderSide(color: Color(0xFFE2E8F0)), elevation: 0,
                  ),
                  child: _isSubmittingProfile
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: AppColors.backgroundDark, strokeWidth: 2))
                      : const Text("Enregistrer le profil", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSecurityCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          width: double.infinity, padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.65), borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.9), width: 1.5),
            boxShadow: [BoxShadow(color: const Color(0xFF6C5CE7).withOpacity(0.08), blurRadius: 30, offset: const Offset(0, 8))],
          ),
          child: Form(
            key: _pwdFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(color: const Color(0xFFFFF1F2), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.shield_outlined, size: 20, color: AppColors.danger),
                    ),
                    const SizedBox(width: 12),
                    const Text('Sécurité & Accès', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.backgroundDark)),
                  ],
                ),
                const SizedBox(height: 24),

                if (!_hasPassword)
                  Container(
                    margin: const EdgeInsets.only(bottom: 24), padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE0E7FF))),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Icon(Icons.info_outline_rounded, size: 20, color: AppColors.primary),
                      const SizedBox(width: 12),
                      const Expanded(child: Text("Vous êtes inscrit via Google. Créez un mot de passe ci-dessous si vous souhaitez pouvoir vous connecter avec votre adresse email classique.", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF3730A3)))),
                    ]),
                  ),

                if (_hasPassword) ...[
                  _fieldLabel('Mot de passe actuel'),
                  const SizedBox(height: 6),
                  _glassInput(
                    controller: _currentPwdCtrl, hintText: '••••••••', obscureText: _obsCurrent,
                    validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
                    suffix: IconButton(
                      icon: Icon(_obsCurrent ? Icons.visibility_off : Icons.visibility, color: AppColors.textSecondary, size: 20),
                      onPressed: () => setState(() => _obsCurrent = !_obsCurrent),
                    )
                  ),
                  const SizedBox(height: 16),
                  Divider(color: Colors.blueGrey.withOpacity(0.12), height: 1),
                  const SizedBox(height: 16),
                ],

                _fieldLabel(_hasPassword ? 'Nouveau mot de passe' : 'Créer un mot de passe'),
                const SizedBox(height: 6),
                _glassInput(
                  controller: _newPwdCtrl, hintText: '••••••••', obscureText: _obsNew,
                  validator: (v) => (v == null || v.length < 8) ? 'Min. 8 caractères' : null,
                  suffix: IconButton(
                    icon: Icon(_obsNew ? Icons.visibility_off : Icons.visibility, color: AppColors.textSecondary, size: 20),
                    onPressed: () => setState(() => _obsNew = !_obsNew),
                  )
                ),
                const SizedBox(height: 16),

                _fieldLabel('Confirmer le mot de passe'),
                const SizedBox(height: 6),
                _glassInput(
                  controller: _confirmPwdCtrl, hintText: '••••••••', obscureText: _obsConfirm,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Requis';
                    if (v != _newPwdCtrl.text) return 'Les mots de passe diffèrent';
                    return null;
                  },
                  suffix: IconButton(
                    icon: Icon(_obsConfirm ? Icons.visibility_off : Icons.visibility, color: AppColors.textSecondary, size: 20),
                    onPressed: () => setState(() => _obsConfirm = !_obsConfirm),
                  )
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmittingPassword ? null : _submitPassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.backgroundDark, foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 6, shadowColor: AppColors.backgroundDark.withOpacity(0.3),
                    ),
                    child: _isSubmittingPassword
                        ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(_hasPassword ? "Changer le mot de passe" : "Créer mon mot de passe", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // WIDGETS RÉUTILISABLES & FOND
  // ==========================================
  Widget _buildAnimatedMesh() {
    return Positioned.fill(
      child: Stack(children: [
        Positioned(top: -100, left: -50, child: Container(width: 400, height: 400, decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFFFF6B9D).withOpacity(0.08)))),
        Positioned(top: 200, right: -100, child: Container(width: 350, height: 350, decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFFFFD32A).withOpacity(0.05)))),
        Positioned(bottom: -50, right: -50, child: Container(width: 400, height: 400, decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF00D2FF).withOpacity(0.06)))),
        BackdropFilter(filter: ImageFilter.blur(sigmaX: 90, sigmaY: 90), child: Container(color: Colors.transparent)),
      ]),
    );
  }

  Widget _glassInput({required TextEditingController controller, String? hintText, bool obscureText = false, bool enabled = true, String? Function(String?)? validator, Widget? suffix}) {
    return TextFormField(
      controller: controller, obscureText: obscureText, enabled: enabled, validator: validator,
      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: enabled ? AppColors.backgroundDark : AppColors.textSecondary),
      decoration: InputDecoration(
        hintText: hintText, hintStyle: const TextStyle(color: AppColors.textSecondary), suffixIcon: suffix,
        filled: true, fillColor: enabled ? Colors.white.withOpacity(0.8) : const Color(0xFFF1F5F9).withOpacity(0.8),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.primary.withOpacity(0.2))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.primary.withOpacity(0.2))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.danger)),
        disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.primary.withOpacity(0.1))),
      ),
    );
  }

  Widget _fieldLabel(String text) => Text(text.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.textSecondary, letterSpacing: 0.8));
}