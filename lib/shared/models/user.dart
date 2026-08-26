class User {
  final String id;
  final String name;
  final String email;
  final String? telegramId;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.telegramId,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      telegramId: json['telegramId'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'telegramId': telegramId,
      };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User &&
        other.id == id &&
        other.name == name &&
        other.email == email &&
        other.telegramId == telegramId;
  }

  @override
  int get hashCode {
    return id.hashCode ^ name.hashCode ^ email.hashCode ^ telegramId.hashCode;
  }
}
