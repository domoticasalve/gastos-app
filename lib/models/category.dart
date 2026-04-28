class Category {
  final String name;
  final String type; // 'expense' o 'income'

  Category({required this.name, required this.type});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      name: json['name'] ?? '',
      type: json['type'] ?? 'expense',
    );
  }

  bool get isExpense => type == 'expense';
  bool get isIncome => type == 'income';
}
