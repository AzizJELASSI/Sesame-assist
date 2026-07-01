import '../enums/department_filiere.dart';

// ─── SEASAME Assist-Pro — Profile Model ───────────────────────────────────────
class Profile {
  final String id;
  final String? fullName;
  final String role; // 'student' | 'teacher' | 'agent' | 'admin'
  final Department? department;
  final String? avatarUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Profile({
    required this.id,
    this.fullName,
    required this.role,
    this.department,
    this.avatarUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      fullName: json['full_name'] as String?,
      role: json['role'] as String? ?? 'student',
      department: Department.fromString(json['department_id'] as String?),
      avatarUrl: json['avatar_url'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'full_name': fullName,
        'role': role,
        'department_id': department?.name,
        'avatar_url': avatarUrl,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  Profile copyWith({
    String? fullName,
    String? role,
    Department? department,
    String? avatarUrl,
  }) {
    return Profile(
      id: id,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      department: department ?? this.department,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  bool get isStudent => role == 'student';
  bool get isTeacher => role == 'teacher';
  bool get isAgent => role == 'agent';
  bool get isAdmin => role == 'admin';
  bool get canManageTickets => isAgent || isAdmin;
  bool get canAccessAdmin => isAdmin;

  String get displayName => fullName ?? 'User';
  String get initials {
    final parts = displayName.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';
  }
}
