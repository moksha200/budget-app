import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// ==========================================
// 1. CLASSE D'EXCEPTION PERSONNALISÉE
// ==========================================
class ApiException implements Exception {
  final String message;
  final int statusCode;
  final String? errorCode;

  ApiException({
    required this.message,
    required this.statusCode,
    this.errorCode,
  });

  @override
  String toString() => message;
}

// ==========================================
// 2. LE SERVICE API PRINCIPAL
// ==========================================
class ApiService {
  // L'URL de base de ton backend (à adapter si tu utilises des sous-dossiers)
  static const String _baseUrl = 'https://budgets.alwaysdata.net/api/v1/';
  
  // Instance du stockage sécurisé natif (Keychain iOS / Keystore Android)
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  // Clés pour le Double Token
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';

  // Temps maximum d'attente pour une requête
  static const int _timeoutSeconds = 15;

  // --------------------------------------------------------
  // A. CONSTRUCTEUR DES EN-TÊTES (Injection de l'Access Token)
  // --------------------------------------------------------
  Future<Map<String, String>> _getHeaders() async {
    // Récupération de l'access token courte durée
    String? token = await _storage.read(key: _accessTokenKey);
    
    Map<String, String> headers = {
      'Content-Type': 'application/json; charset=UTF-8',
      'Accept': 'application/json',
    };

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  // --------------------------------------------------------
  // B. MÉTHODES CRUD STANDARDS (Avec Intercepteur intégré)
  // --------------------------------------------------------

  /// Requête GET
  Future<Map<String, dynamic>> get(String endpoint) async {
    return _requestWithRetry(() async {
      final headers = await _getHeaders();
      return await http.get(Uri.parse('$_baseUrl$endpoint'), headers: headers);
    });
  }

  /// Requête POST
  Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> data) async {
    return _requestWithRetry(() async {
      final headers = await _getHeaders();
      return await http.post(
        Uri.parse('$_baseUrl$endpoint'),
        headers: headers,
        body: jsonEncode(data),
      );
    });
  }

  /// Requête PUT
  Future<Map<String, dynamic>> put(String endpoint, Map<String, dynamic> data) async {
    return _requestWithRetry(() async {
      final headers = await _getHeaders();
      return await http.put(
        Uri.parse('$_baseUrl$endpoint'),
        headers: headers,
        body: jsonEncode(data),
      );
    });
  }

  /// Requête DELETE
  Future<Map<String, dynamic>> delete(String endpoint) async {
    return _requestWithRetry(() async {
      final headers = await _getHeaders();
      return await http.delete(Uri.parse('$_baseUrl$endpoint'), headers: headers);
    });
  }

  /// Requête POST Multipart (Upload de fichiers & données textuelles)
  Future<Map<String, dynamic>> postMultipart(
    String endpoint, {
    Map<String, String>? fields,
    File? file,
    String fileField = 'profile_picture',
  }) async {
    return _requestWithRetry(() async {
      final headers = await _getHeaders();
      
      // On retire le Content-Type JSON car le MultipartRequest va générer 
      // le sien avec un boundary dynamique obligatoire pour l'upload.
      headers.remove('Content-Type');

      var request = http.MultipartRequest('POST', Uri.parse('$_baseUrl$endpoint'));
      request.headers.addAll(headers);

      if (fields != null) {
        request.fields.addAll(fields);
      }

      if (file != null) {
        var multipartFile = await http.MultipartFile.fromPath(fileField, file.path);
        request.files.add(multipartFile);
      }

      var streamedResponse = await request.send();
      // On convertit le StreamedResponse en Response classique pour _handleResponse
      return await http.Response.fromStream(streamedResponse);
    });
  }

  // --------------------------------------------------------
  // C. LOGIQUE D'INTERCEPTION ET DE RAFRAÎCHISSEMENT
  // --------------------------------------------------------
  
  /// Exécute la requête, gère les exceptions réseau et intercepte le 401
  Future<Map<String, dynamic>> _requestWithRetry(Future<http.Response> Function() requestFunc) async {
    try {
      final response = await requestFunc().timeout(const Duration(seconds: _timeoutSeconds));
      return _handleResponse(response);
    } on TimeoutException {
      throw ApiException(message: "Délai d'attente dépassé. Vérifiez votre connexion.", statusCode: 408);
    } on SocketException {
      throw ApiException(message: "Impossible de se connecter au serveur.", statusCode: 0);
    } on ApiException catch (e) {
      // Interception stricte du 401 (Access Token invalide/expiré)
      if (e.statusCode == 401) {
        bool isRefreshed = await _refreshToken();
        
        if (isRefreshed) {
          // Les tokens ont été renouvelés, on rejoue la requête originale
          try {
            final retryResponse = await requestFunc().timeout(const Duration(seconds: _timeoutSeconds));
            return _handleResponse(retryResponse);
          } on TimeoutException {
            throw ApiException(message: "Délai d'attente dépassé lors de la nouvelle tentative.", statusCode: 408);
          } on SocketException {
            throw ApiException(message: "Impossible de se connecter au serveur.", statusCode: 0);
          }
        } else {
          // Le Refresh Token est invalide, la session est morte
          await logout();
          throw ApiException(
            message: "Session expirée. Veuillez vous reconnecter.", 
            statusCode: 401, 
            errorCode: 'SESSION_EXPIRED'
          );
        }
      }
      // On fait remonter toutes les autres API Exceptions (400, 403, 404, 429...)
      rethrow;
    }
  }

  /// Tentative silencieuse de renouvellement des tokens
  Future<bool> _refreshToken() async {
    String? refreshToken = await _storage.read(key: _refreshTokenKey);
    if (refreshToken == null || refreshToken.isEmpty) return false;

    try {
      final response = await http.post(
        Uri.parse('${_baseUrl}refresh.php'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Accept': 'application/json',
        },
        body: jsonEncode({'refresh_token': refreshToken}),
      ).timeout(const Duration(seconds: _timeoutSeconds));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          // Sauvegarde des nouveaux jetons
          await saveTokens(data['access_token'], data['refresh_token']);
          return true;
        }
      }
      return false;
    } catch (e) {
      // Toute erreur réseau ou autre lors du refresh provoque un échec du maintien de session
      return false;
    }
  }

  // --------------------------------------------------------
  // D. GESTIONNAIRE DE RÉPONSES ET SÉCURITÉ
  // --------------------------------------------------------
  Map<String, dynamic> _handleResponse(http.Response response) {
    Map<String, dynamic> responseBody = {};
    
    // Tentative de décodage du JSON renvoyé par le PHP
    try {
      if (response.body.isNotEmpty) {
        responseBody = jsonDecode(response.body);
      }
    } catch (e) {
      throw ApiException(
        message: "Erreur de communication avec le serveur (Format invalide).",
        statusCode: response.statusCode,
      );
    }

    final int statusCode = response.statusCode;
    final String message = responseBody['message'] ?? 'Une erreur inattendue est survenue.';
    final String? errorCode = responseBody['error_code'];

    // Succès (200 OK ou 201 Created)
    if (statusCode >= 200 && statusCode < 300) {
      return responseBody;
    } 
    
    if (statusCode == 401) {
      // On lève l'exception. Le wrapper _requestWithRetry l'attrapera pour tenter un refresh.
      // NOTE: Ne supprime PLUS le token ici, logout() s'en chargera si le refresh échoue.
      throw ApiException(message: message, statusCode: statusCode, errorCode: errorCode);
    } 
    
    if (statusCode == 429) {
      // 429 Too Many Requests : Protection Brute Force (Lockout)
      throw ApiException(message: message, statusCode: statusCode, errorCode: errorCode);
    }

    // Autres erreurs (400, 403, 404, 500)
    throw ApiException(message: message, statusCode: statusCode, errorCode: errorCode);
  }

  // --------------------------------------------------------
  // E. UTILITAIRES DE SESSION
  // --------------------------------------------------------
  
  /// Sauvegarde des tokens après un login ou un refresh réussi
  Future<void> saveTokens(String accessToken, String refreshToken) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  /// Déconnexion globale et nettoyage sécurisé
  Future<void> logout() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }
}