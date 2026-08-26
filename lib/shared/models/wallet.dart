class Wallet {
  final String id;
  final String name;
  final String color;
  final String icon;
  final double balance;

  Wallet({
    required this.id,
    required this.name,
    required this.color,
    required this.icon,
    required this.balance,
  });

  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      id: json['id'] as String,
      name: json['name'] as String,
      color: json['color'] as String,
      icon: json['icon'] as String,
      balance: (json['balance'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'color': color,
        'icon': icon,
        'balance': balance,
      };
}
