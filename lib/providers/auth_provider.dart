// lib/providers/auth_provider.dart

import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  // ==========================================
  // 1. ÉTAT DE LA SESSION
  // ==========================================
  User? _currentUser;
  bool _isLoading = false;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;

  // ==========================================
  // 2. ACTIONS D'AUTHENTIFICATION
  // ==========================================

  /// Connexion classique avec Email et Mot de passe
  Future<void> login(String email, String password) async {
    _setLoading(true);

    try {
      final response = await _apiService.post('login.php', {
        'email': email,
        'password': password,
      });

      // Sauvegarde du double token (Access + Refresh)
      if (response.containsKey('access_token') && response.containsKey('refresh_token')) {
        await _apiService.saveTokens(response['access_token'], response['refresh_token']);
      } else if (response.containsKey('token')) {
        // Fallback temporaire si l'API renvoie encore l'ancien format
        await _apiService.saveTokens(response['token'], '');
      }

      if (response.containsKey('user')) {
        _currentUser = User.fromJson(response['user']);
      }

      notifyListeners();

    } catch (e) {
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Connexion via le bouton Google
  Future<void> googleLogin(String idToken, String email, String username) async {
    _setLoading(true);

    try {
      final response = await _apiService.post('auth_google.php', {
        'idToken': idToken, 
        'email': email,
        'username': username,
      });

      // Sauvegarde du double token (Access + Refresh)
      if (response.containsKey('access_token') && response.containsKey('refresh_token')) {
        await _apiService.saveTokens(response['access_token'], response['refresh_token']);
      } else if (response.containsKey('token')) {
        await _apiService.saveTokens(response['token'], '');
      }

      if (response.containsKey('user')) {
        _currentUser = User.fromJson(response['user']);
      }

      notifyListeners();

    } catch (e) {
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Inscription d'un nouvel utilisateur
  Future<void> register(String username, String email, String password) async {
    _setLoading(true);

    try {
      await _apiService.post('register.php', {
        'username': username,
        'email': email,
        'password': password,
      });
    } catch (e) {
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Déconnexion globale
  Future<void> logout() async {
    _setLoading(true);
    try {
      // CORRECTION : Appel de la bonne méthode dans l'ApiService
      await _apiService.logout();
      _currentUser = null;
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // ==========================================
  // 3. AUTO-LOGIN (Au démarrage de l'app)
  // ==========================================
  Future<bool> checkAuthState() async {
    _setLoading(true);
    try {
      // L'ApiService gère désormais silencieusement les erreurs 401 et le Refresh Token
      final response = await _apiService.get('dashboard.php');
      
      if (response['success'] == true && response.containsKey('data')) {
        final userData = response['data']['user'];
        _currentUser = User(
          id: userData['id'] ?? 0, 
          name: userData['name'], 
          email: userData['email']
        );
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      // Échec critique ou Refresh Token invalide : purge de la session
      await logout();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    if (_isLoading != value) {
      _isLoading = value;
      notifyListeners();
    }
  }
}