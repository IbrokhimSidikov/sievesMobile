import 'dart:convert';

class UserModel {
  final String id;
  final String auth_id;
  final String email;
  final String username;
  final String? code;
  final String? name;
  final String? type;
  final String? phone;
  final String? photo;
  final String? memberId;
  final String? organizationId;
  final String createdAt;
  final String updatedAt;

  UserModel({
    required this.id,
    required this.auth_id,
    required this.email,
    required this.username,
    this.name,
    this.code,
    this.type,
    this.phone,
    this.photo,
    this.memberId,
    this.organizationId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      auth_id: json['auth_id'] ?? '',
      email: json['email'] ?? '',
      username: json['username'] ?? '',
      name: json['name'],
      code: json['code'],
      type: json['type'],
      phone: json['phone'],
      photo: json['photo'],
      memberId: json['memberId']?.toString(),
      organizationId: json['organizationId']?.toString(),
      createdAt: json['createdAt'] ?? DateTime.now().toIso8601String(),
      updatedAt: json['updatedAt'] ?? DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'auth_id': auth_id,
      'email': email,
      'username': username,
      'name': name,
      'code': code,
      'type': type,
      'phone': phone,
      'photo': photo,
      'memberId': memberId,
      'organizationId': organizationId,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
