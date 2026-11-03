import '../../core/utils/json_utils.dart';
import 'enums.dart';

/// Utilisateur de la plateforme (locataire, propriétaire ou administrateur).
class UserModel {
  const UserModel({
    required this.id,
    required this.nom,
    required this.prenoms,
    required this.email,
    required this.telephone,
    required this.role,
    this.actif = true,
    this.identityVerified = false,
  });

  final String id;
  final String nom;
  final String prenoms;
  final String email;
  final String telephone;
  final UserRole role;
  final bool actif;

  /// Propriétaire dont l'identité a été validée par un administrateur (badge « Vérifié »).
  final bool identityVerified;

  /// « Prénoms Nom », pour l'affichage.
  String get fullName => '$prenoms $nom'.trim();

  /// Initiales pour l'avatar (ex. « PA »).
  String get initials {
    final a = prenoms.trim().isEmpty ? '' : prenoms.trim()[0];
    final b = nom.trim().isEmpty ? '' : nom.trim()[0];
    return '$a$b'.toUpperCase();
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: '${json['id'] ?? ''}',
      nom: '${json['nom'] ?? ''}',
      prenoms: '${json['prenoms'] ?? ''}',
      email: '${json['email'] ?? ''}',
      telephone: '${json['telephone'] ?? ''}',
      role: _parseRole(json['role']),
      actif: json['actif'] is bool ? json['actif'] as bool : true,
      identityVerified: json['identity_verified'] == true,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'nom': nom,
        'prenoms': prenoms,
        'email': email,
        'telephone': telephone,
        'role': role.name,
        'actif': actif,
        'identity_verified': identityVerified,
      };

  /// Accepte « TENANT », « tenant », et quelques équivalents français.
  static UserRole _parseRole(Object? raw) {
    final v = '${raw ?? ''}'.trim().toUpperCase();
    switch (v) {
      case 'OWNER':
      case 'PROPRIETAIRE':
      case 'PROPRIÉTAIRE':
      case 'BAILLEUR':
        return UserRole.OWNER;
      case 'ADMIN':
      case 'ADMINISTRATEUR':
        return UserRole.ADMIN;
      default:
        return UserRole.TENANT;
    }
  }
}

/// Aide pour lire une liste d'utilisateurs, si besoin.
List<UserModel> usersFromJson(Object? raw) =>
    asJsonList(raw).map((e) => UserModel.fromJson(asJsonMap(e))).toList();
