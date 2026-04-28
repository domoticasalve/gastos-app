import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/expense.dart';
import '../models/income.dart';
import '../models/category.dart';
import '../models/budget.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final _headers = {'Content-Type': 'application/json'};
  final _timeout = const Duration(seconds: 15);

  // ─── Dashboard ───────────────────────────────────────────────────────────

  Future<DashboardData> getDashboard({int? year, int? month}) async {
    final params = <String, String>{};
    if (year != null) params['year'] = year.toString();
    if (month != null) params['month'] = month.toString();

    final uri = Uri.parse(ApiConfig.dashboard).replace(queryParameters: params);
    final res = await http.get(uri).timeout(_timeout);
    _checkStatus(res);
    return DashboardData.fromJson(jsonDecode(res.body));
  }

  // ─── Gastos ──────────────────────────────────────────────────────────────

  Future<List<Expense>> getExpenses({int? year, int? month, String? category}) async {
    final params = <String, String>{};
    if (year != null) params['year'] = year.toString();
    if (month != null) params['month'] = month.toString();
    if (category != null) params['category'] = category;

    final uri = Uri.parse(ApiConfig.expenses).replace(queryParameters: params);
    final res = await http.get(uri).timeout(_timeout);
    _checkStatus(res);

    final data = jsonDecode(res.body);
    final list = data is List ? data : (data['expenses'] as List? ?? []);
    return list.map((e) => Expense.fromJson(e)).toList();
  }

  Future<void> addExpense(Expense expense) async {
    final res = await http
        .post(Uri.parse(ApiConfig.expenses),
            headers: _headers, body: jsonEncode(expense.toJson()))
        .timeout(_timeout);
    _checkStatus(res);
  }

  Future<void> updateExpense(int row, Expense expense) async {
    final body = {...expense.toJson(), 'row': row};
    final res = await http
        .put(Uri.parse(ApiConfig.expenses),
            headers: _headers, body: jsonEncode(body))
        .timeout(_timeout);
    _checkStatus(res);
  }

  Future<void> deleteExpense(int row) async {
    final res = await http
        .delete(Uri.parse(ApiConfig.expenses),
            headers: _headers, body: jsonEncode({'row': row}))
        .timeout(_timeout);
    _checkStatus(res);
  }

  // ─── Ingresos ────────────────────────────────────────────────────────────

  Future<List<Income>> getIncome({int? year, int? month, String? category}) async {
    final params = <String, String>{};
    if (year != null) params['year'] = year.toString();
    if (month != null) params['month'] = month.toString();
    if (category != null) params['category'] = category;

    final uri = Uri.parse(ApiConfig.income).replace(queryParameters: params);
    final res = await http.get(uri).timeout(_timeout);
    _checkStatus(res);

    final data = jsonDecode(res.body);
    final list = data is List ? data : (data['income'] as List? ?? []);
    return list.map((e) => Income.fromJson(e)).toList();
  }

  Future<void> addIncome(Income income) async {
    final res = await http
        .post(Uri.parse(ApiConfig.income),
            headers: _headers, body: jsonEncode(income.toJson()))
        .timeout(_timeout);
    _checkStatus(res);
  }

  Future<void> updateIncome(int row, Income income) async {
    final body = {...income.toJson(), 'row': row};
    final res = await http
        .put(Uri.parse(ApiConfig.income),
            headers: _headers, body: jsonEncode(body))
        .timeout(_timeout);
    _checkStatus(res);
  }

  Future<void> deleteIncome(int row) async {
    final res = await http
        .delete(Uri.parse(ApiConfig.income),
            headers: _headers, body: jsonEncode({'row': row}))
        .timeout(_timeout);
    _checkStatus(res);
  }

  // ─── Categorías ──────────────────────────────────────────────────────────

  Future<List<Category>> getCategories() async {
    final res = await http.get(Uri.parse(ApiConfig.categories)).timeout(_timeout);
    _checkStatus(res);

    final data = jsonDecode(res.body);
    final list = data is List ? data : (data['categories'] as List? ?? []);
    return list.map((e) => Category.fromJson(e)).toList();
  }

  Future<void> addCategory(String name, String type) async {
    final res = await http
        .post(Uri.parse(ApiConfig.categories),
            headers: _headers,
            body: jsonEncode({'name': name, 'type': type}))
        .timeout(_timeout);
    _checkStatus(res);
  }

  Future<void> deleteCategory(String name) async {
    final res = await http
        .delete(Uri.parse(ApiConfig.categories),
            headers: _headers, body: jsonEncode({'name': name}))
        .timeout(_timeout);
    _checkStatus(res);
  }

  // ─── Presupuesto ─────────────────────────────────────────────────────────

  Future<List<BudgetItem>> getBudget() async {
    final res = await http.get(Uri.parse(ApiConfig.budget)).timeout(_timeout);
    _checkStatus(res);

    final data = jsonDecode(res.body);
    final list = data is List ? data : (data['budget'] as List? ?? []);
    return list.map((e) => BudgetItem.fromJson(e)).toList();
  }

  Future<void> saveBudget(String category, double target) async {
    final res = await http
        .post(Uri.parse(ApiConfig.budget),
            headers: _headers,
            body: jsonEncode({'category': category, 'target': target}))
        .timeout(_timeout);
    _checkStatus(res);
  }

  // ─── Resumen anual ───────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getYearly() async {
    final res = await http.get(Uri.parse(ApiConfig.yearly)).timeout(_timeout);
    _checkStatus(res);

    final data = jsonDecode(res.body);
    final list = data is List ? data : (data['yearly'] as List? ?? []);
    return list.cast<Map<String, dynamic>>();
  }

  // ─── Utilidades ──────────────────────────────────────────────────────────

  void _checkStatus(http.Response res) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ApiException(res.statusCode, res.body);
    }
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String body;
  ApiException(this.statusCode, this.body);

  @override
  String toString() => 'ApiException($statusCode): $body';

  String get userMessage {
    switch (statusCode) {
      case 404:
        return 'Recurso no encontrado';
      case 500:
        return 'Error en el servidor';
      default:
        return 'Error de conexión ($statusCode)';
    }
  }
}
