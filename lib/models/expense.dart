class Expense {
  final int row;
  final String date;
  final String description;
  final double amount;
  final String category;
  final String? notes;

  Expense({
    required this.row,
    required this.date,
    required this.description,
    required this.amount,
    required this.category,
    this.notes,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      row: json['row'] ?? 0,
      date: json['date'] ?? '',
      description: json['description'] ?? '',
      amount: _parseAmount(json['amount']),
      category: json['category'] ?? '',
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date,
        'description': description,
        'amount': amount,
        'category': category,
        'notes': notes ?? '',
      };

  static double _parseAmount(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString().replaceAll(',', '.')) ?? 0.0;
  }
}
