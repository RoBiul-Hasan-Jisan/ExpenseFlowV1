class UserModel {
  final String uid;
  final String name;
  final String email;
  final String currency;
  final bool isDemo;
  final bool emailVerified;
  final DateTime createdAt;
  final String? avatarUrl;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.currency = 'USD',
    this.isDemo = false,
    this.emailVerified = false,
    required this.createdAt,
    this.avatarUrl,
  });

  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? currency,
    bool? isDemo,
    bool? emailVerified,
    DateTime? createdAt,
    String? avatarUrl,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      currency: currency ?? this.currency,
      isDemo: isDemo ?? this.isDemo,
      emailVerified: emailVerified ?? this.emailVerified,
      createdAt: createdAt ?? this.createdAt,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'name': name,
        'email': email,
        'currency': currency,
        'isDemo': isDemo,
        'emailVerified': emailVerified,
        'createdAt': createdAt.toIso8601String(),
        'avatarUrl': avatarUrl,
      };

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      currency: json['currency'] as String? ?? 'USD',
      isDemo: json['isDemo'] as bool? ?? false,
      emailVerified: json['emailVerified'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      avatarUrl: json['avatarUrl'] as String?,
    );
  }

  factory UserModel.demo() => UserModel(
        uid: 'demo-user',
        name: 'Robiul',
        email: 'demo@expenseflow.app',
        currency: 'USD',
        isDemo: true,
        emailVerified: true,
        createdAt: DateTime.now(),
      );
}
