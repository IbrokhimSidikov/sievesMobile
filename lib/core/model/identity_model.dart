import 'employee_model.dart';

class Identity {
  final int? id;
  final String authId;
  final String email;
  final String username;
  final String role;
  final String? phone;
  final int? allowance;
  final int? allowanceUpdatedAt;
  String? token;
  final Employee? employee;

  Identity({
    this.id,
    required this.authId,
    required this.email,
    required this.username,
    required this.role,
    this.phone,
    this.allowance,
    this.allowanceUpdatedAt,
    this.token,
    this.employee,
  });

  factory Identity.fromJson(Map<String, dynamic> json) {
    return Identity(
      id: json['id'],
      authId: json['auth_id'],
      email: json['email'],
      username: json['username'],
      role: json['role'],
      phone: json['phone'],
      allowance: json['allowance'],
      allowanceUpdatedAt: json['allowance_updated_at'],
      token: json['token'],
      employee: json['employee'] != null ? Employee.fromJson(json['employee']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'auth_id': authId,
      'email': email,
      'username': username,
      'role': role,
      'phone': phone,
      'allowance': allowance,
      'allowance_updated_at': allowanceUpdatedAt,
      'token': token,
      'employee': employee?.toJson(),
    };
  }
}

