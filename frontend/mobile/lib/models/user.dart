class User {
  final int id;
  final String email;
  final String name;
  final String role;
  final String? profileImageUrl;
  final int restaurantId;
  final String restaurantName;

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.profileImageUrl,
    required this.restaurantId,
    required this.restaurantName,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      name: json['name'],
      role: json['role'],
      profileImageUrl: json['profileImageUrl'],
      restaurantId: json['restaurantId'],
      restaurantName: json['restaurantName'] ?? '',
    );
  }

  bool get isOwner => role == 'owner';
}
