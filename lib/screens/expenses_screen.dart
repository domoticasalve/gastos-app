import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../models/category.dart';
import '../services/api_service.dart';
import '../widgets/error_view.dart';
import '../widgets/amount_field.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final _api = ApiService();
  List<Expense> _expenses = [];
  List<Category> _categories = [];
  bool _loading = true;
  String? _error;

  int _selectedYear = DateTime.now().year;
  int? _selectedMonth;
  String? _selectedCategory;

  final _months = [
    'Todos', 'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        _api.getExpenses(year: _selectedYear, month: _selectedMonth, category: _selectedCategory),
        _api.getCategories(),
      ]);
      setState(() {
        _expenses = results[0] as List<Expense>;
        final cats = results[1] as List<Category>;
        _categories = cats.where((c) => c.isExpense).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'No se pudo cargar los gastos.\n$e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gastos'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(context),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? ErrorView(message: _error!, onRetry: _load)
                    : _buildList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    final years = List.generate(5, (i) => DateTime.now().year - i);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: Theme.of(context).colorScheme.surfaceVariant,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _filterDropdown<int>(
              label: 'Año',
              value: _selectedYear,
              items: years.map((y) => DropdownMenuItem(value: y, child: Text('$y'))).toList(),
              onChanged: (v) { setState(() => _selectedYear = v!); _load(); },
            ),
            const SizedBox(width: 8),
            _filterDropdown<int?>(
              label: 'Mes',
              value: _selectedMonth,
              items: [
                const DropdownMenuItem(value: null, child: Text('Todos')),
                ...List.generate(12, (i) =>
                    DropdownMenuItem(value: i + 1, child: Text(_months[i + 1]))),
              ],
              onChanged: (v) { setState(() => _selectedMonth = v); _load(); },
            ),
            const SizedBox(width: 8),
            _filterDropdown<String?>(
              label: 'Categoría',
              value: _selectedCategory,
              items: [
                const DropdownMenuItem(value: null, child: Text('Todas')),
                ..._categories.map((c) =>
                    DropdownMenuItem(value: c.name, child: Text(c.name))),
              ],
              onChanged: (v) { setState(() => _selectedCategory = v); _load(); },
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterDropdown<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$label: ', style: const TextStyle(fontSize: 12)),
        DropdownButton<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          style: const TextStyle(fontSize: 13),
          underline: const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildList() {
    if (_expenses.isEmpty) {
      return const Center(child: Text('Sin gastos en este período'));
    }

    final fmt = NumberFormat.currency(locale: 'es_ES', symbol: '€');
    final total = _expenses.fold(0.0, (s, e) => s + e.amount);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.red.withOpacity(0.1),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${_expenses.length} gastos', style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('Total: ${fmt.format(total)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            child: ListView.separated(
              itemCount: _expenses.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final e = _expenses[i];
                return ListTile(
                  title: Text(e.description),
                  subtitle: Text('${e.date}  ·  ${e.category}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(fmt.format(e.amount),
                          style: const TextStyle(
                              color: Colors.red, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 18),
                        onPressed: () => _showForm(context, expense: e),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                        onPressed: () => _confirmDelete(e),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(Expense e) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar gasto'),
        content: Text('¿Eliminar "${e.description}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok == true) {
      try {
        await _api.deleteExpense(e.row);
        _load();
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Error al eliminar')));
        }
      }
    }
  }

  Future<void> _showForm(BuildContext context, {Expense? expense}) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ExpenseForm(
        expense: expense,
        categories: _categories,
        onSaved: _load,
      ),
    );
  }
}

class _ExpenseForm extends StatefulWidget {
  final Expense? expense;
  final List<Category> categories;
  final VoidCallback onSaved;

  const _ExpenseForm({this.expense, required this.categories, required this.onSaved});

  @override
  State<_ExpenseForm> createState() => _ExpenseFormState();
}

class _ExpenseFormState extends State<_ExpenseForm> {
  final _api = ApiService();
  final _formKey = GlobalKey<FormState>();
  final _descCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String? _category;
  DateTime _date = DateTime.now();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.expense != null) {
      final e = widget.expense!;
      _descCtrl.text = e.description;
      _amountCtrl.text = e.amount.toStringAsFixed(2);
      _notesCtrl.text = e.notes ?? '';
      _category = e.category;
      try {
        _date = DateFormat('yyyy-MM-dd').parse(e.date);
      } catch (_) {}
    }
    if (_category == null && widget.categories.isNotEmpty) {
      _category = widget.categories.first.name;
    }
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final expense = Expense(
        row: widget.expense?.row ?? 0,
        date: DateFormat('yyyy-MM-dd').format(_date),
        description: _descCtrl.text.trim(),
        amount: double.parse(_amountCtrl.text.replaceAll(',', '.')),
        category: _category ?? '',
        notes: _notesCtrl.text.trim(),
      );
      if (widget.expense == null) {
        await _api.addExpense(expense);
      } else {
        await _api.updateExpense(widget.expense!.row, expense);
      }
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16, right: 16, top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.expense == null ? 'Nuevo gasto' : 'Editar gasto',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: Text(DateFormat('dd/MM/yyyy').format(_date)),
                contentPadding: EdgeInsets.zero,
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (d != null) setState(() => _date = d);
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              AmountField(controller: _amountCtrl),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(
                  labelText: 'Categoría',
                  border: OutlineInputBorder(),
                ),
                items: widget.categories
                    .map((c) => DropdownMenuItem(value: c.name, child: Text(c.name)))
                    .toList(),
                onChanged: (v) => setState(() => _category = v),
                validator: (v) => v == null ? 'Selecciona categoría' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Notas (opcional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Guardar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
