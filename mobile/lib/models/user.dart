class UserModel {
  final String id;
  final String username;
  final String displayName;
  final String? email;
  final String? avatarUrl;

  UserModel({
    required this.id,
    required this.username,
    required this.displayName,
    this.email,
    this.avatarUrl,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      username: json['username'] ?? '',
      displayName: json['display_name'] ?? json['displayName'] ?? 'User',
      email: json['email'],
      avatarUrl: json['avatar_url'] ?? json['avatarUrl'],
    );
  }
}
