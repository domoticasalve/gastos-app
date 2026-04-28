class BudgetItem {
  final String category;
  final double target;
  final double actual;

  BudgetItem({
    required this.category,
    required this.target,
    required this.actual,
  });

  factory BudgetItem.fromJson(Map<String, dynamic> json) {
    return BudgetItem(
      category: json['category'] ?? '',
      target: _parseAmount(json['target']),
      actual: _parseAmount(json['actual']),
    );
  }

  double get percentage => target > 0 ? (actual / target) * 100 : 0;
  bool get isOverBudget => actual > target && target > 0;
  bool get isWarning => percentage >= 80 && !isOverBudget;

  static double _parseAmount(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString().replaceAll(',', '.')) ?? 0.0;
  }
}

class DashboardData {
  final double totalIncome;
  final double totalExpenses;
  final double savings;
  final double savingsRate;
  final List<MonthlyData> monthly;
  final Map<String, double> byCategory;

  DashboardData({
    required this.totalIncome,
    required this.totalExpenses,
    required this.savings,
    required this.savingsRate,
    required this.monthly,
    required this.byCategory,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    final monthlyRaw = (json['monthly'] as List? ?? []);
    final byCategoryRaw = (json['by_category'] as Map? ?? {});

    return DashboardData(
      totalIncome: _parseAmount(json['total_income']),
      totalExpenses: _parseAmount(json['total_expenses']),
      savings: _parseAmount(json['savings']),
      savingsRate: _parseAmount(json['savings_rate']),
      monthly: monthlyRaw.map((e) => MonthlyData.fromJson(e)).toList(),
      byCategory: byCategoryRaw.map(
        (k, v) => MapEntry(k.toString(), _parseAmount(v)),
      ),
    );
  }

  static double _parseAmount(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString().replaceAll(',', '.')) ?? 0.0;
  }
}

class MonthlyData {
  final String month;
  final double income;
  final double expenses;

  MonthlyData({
    required this.month,
    required this.income,
    required this.expenses,
  });

  factory MonthlyData.fromJson(Map<String, dynamic> json) {
    return MonthlyData(
      month: json['month']?.toString() ?? '',
      income: _parseAmount(json['income']),
      expenses: _parseAmount(json['expenses']),
    );
  }

  static double _parseAmount(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString().replaceAll(',', '.')) ?? 0.0;
  }
}
