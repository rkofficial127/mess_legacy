class User {
  final String id;
  final String email;
  final String fullName;
  final String? username;
  final String phone;
  final String? avatarUrl;
  final String role;
  final bool isActive;
  final bool hasPassword;
  final DateTime createdAt;
  final DateTime updatedAt;

  const User({
    required this.id,
    required this.email,
    required this.fullName,
    this.username,
    required this.phone,
    this.avatarUrl,
    required this.role,
    required this.isActive,
    this.hasPassword = true,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isAdmin => role == 'ADMIN';

  String get displayName => username ?? fullName;

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as String,
        email: json['email'] as String,
        fullName: json['full_name'] as String,
        username: json['username'] as String?,
        phone: json['phone'] as String,
        avatarUrl: json['avatar_url'] as String?,
        role: json['role'] as String,
        isActive: json['is_active'] as bool,
        hasPassword: json['has_password'] as bool? ?? true,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );
}
