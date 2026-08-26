class Category {
  final String id;
  final String name;
  final String color;
  final String icon;
  final String type; // income | expense

  Category({
    required this.id,
    required this.name,
    required this.color,
    required this.icon,
    required this.type,
  });

  bool get isIncome => type == 'income';
  bool get isExpense => type == 'expense';

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      name: json['name'] as String,
      color: json['color'] as String,
      icon: json['icon'] as String,
      type: json['type'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'color': color,
        'icon': icon,
        'type': type,
      };
}
