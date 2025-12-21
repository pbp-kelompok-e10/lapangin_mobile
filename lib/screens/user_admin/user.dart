class User {
  final int id;
  final String username;
  final String? email;
  final String? name;
  final bool isAuthenticated;
  final bool isStaff;
  final bool isSuperuser;
  final bool isActive;
  final UserProfile? profile;
  final DateTime? dateJoined;
  final DateTime? lastLogin;

  User({
    required this.id,
    required this.username,
    this.email,
    this.name,
    required this.isAuthenticated,
    this.isStaff = false,
    this.isSuperuser = false,
    this.isActive = true,
    this.profile,
    this.dateJoined,
    this.lastLogin,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      email: json['email'],
      name: json['name'] ?? json['full_name'],
      isAuthenticated: json['is_authenticated'] ?? false,
      isStaff: json['is_staff'] ?? false,
      isSuperuser: json['is_superuser'] ?? false,
      isActive: json['is_active'] ?? true,
      profile: json['profile'] != null
          ? UserProfile.fromJson(json['profile'])
          : null,
      dateJoined: json['date_joined'] != null
          ? DateTime.parse(json['date_joined'])
          : null,
      lastLogin: json['last_login'] != null
          ? DateTime.parse(json['last_login'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'name': name,
      'is_authenticated': isAuthenticated,
      'is_staff': isStaff,
      'is_superuser': isSuperuser,
      'is_active': isActive,
      'profile': profile?.toJson(),
      'date_joined': dateJoined?.toIso8601String(),
      'last_login': lastLogin?.toIso8601String(),
    };
  }

  String get displayName => name ?? username;

  String get roleLabel {
    if (isSuperuser) return 'Superuser';
    if (isStaff) return 'Staff';
    return 'User';
  }
}

class UserProfile {
  final String? fullName;
  final String? phone;
  final String? address;
  final bool isActive;
  final DateTime? updatedAt;

  UserProfile({
    this.fullName,
    this.phone,
    this.address,
    this.isActive = true,
    this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      fullName: json['full_name'],
      phone: json['phone'],
      address: json['address'],
      isActive: json['is_active'] ?? true,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'full_name': fullName,
      'phone': phone,
      'address': address,
      'is_active': isActive,
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}