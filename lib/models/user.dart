// lib/models/user.dart

class User {
  // 1. IMMUABILITÉ (final)
  // Une fois l'utilisateur créé en mémoire, ses données ne peuvent plus 
  // être modifiées par erreur dans l'application.
  final int id;
  final String name;
  final String email;
  final String? role; // Optionnel (utile si tu ajoutes un espace admin plus tard)

  const User({
    required this.id,
    required this.name,
    required this.email,
    this.role,
  });

  // ==========================================
  // 2. LE BOUCLIER : DE JSON VERS OBJET DART
  // ==========================================
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      // Sécurité : Conversion automatique et gestion des valeurs nulles
      id: json['id'] is int 
          ? json['id'] 
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
          
      // Fallback (valeur par défaut) au cas où le champ est manquant
      name: json['name']?.toString() ?? 'Utilisateur',
      email: json['email']?.toString() ?? 'email@inconnu.com',
      role: json['role']?.toString(),
    );
  }

  // ==========================================
  // 3. EXPORT : DE OBJET DART VERS JSON
  // ==========================================
  // Très utile si tu veux sauvegarder le profil dans le stockage local (cache)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      if (role != null) 'role': role,
    };
  }

  // Petite méthode bonus pour cloner l'utilisateur en modifiant un seul champ
  // (Exemple: si l'utilisateur met à jour son nom dans les paramètres)
  User copyWith({
    int? id,
    String? name,
    String? email,
    String? role,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
    );
  }
}