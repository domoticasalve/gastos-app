import 'package:flutter/material.dart';
import '../models/category.dart';
import '../services/api_service.dart';
import '../widgets/error_view.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen>
    with SingleTickerProviderStateMixin {
  final _api = ApiService();
  List<Category> _categories = [];
  bool _loading = true;
  String? _error;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await _api.getCategories();
      setState(() { _categories = data; _loading = false; });
    } catch (e) {
      setState(() {
        _error = 'No se pudo cargar las categorías.\n$e';
        _loading = false;
      });
    }
  }

  List<Category> get _expenses => _categories.where((c) => c.isExpense).toList();
  List<Category> get _incomes => _categories.where((c) => c.isIncome).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categorías'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Gastos'),
            Tab(text: 'Ingresos'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? ErrorView(message: _error!, onRetry: _load)
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildList(_expenses, 'expense'),
                    _buildList(_incomes, 'income'),
                  ],
                ),
    );
  }

  Widget _buildList(List<Category> cats, String type) {
    if (cats.isEmpty) {
      return Center(
        child: Text(
          type == 'expense' ? 'Sin categorías de gastos' : 'Sin categorías de ingresos',
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: cats.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final cat = cats[i];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor:
                  cat.isExpense ? Colors.red.withOpacity(0.15) : Colors.green.withOpacity(0.15),
              child: Icon(
                cat.isExpense ? Icons.remove_circle_outline : Icons.add_circle_outline,
                color: cat.isExpense ? Colors.red : Colors.green,
                size: 20,
              ),
            ),
            title: Text(cat.name),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _confirmDelete(cat),
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(Category cat) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar categoría'),
        content: Text('¿Eliminar "${cat.name}"?\nSe perderá la referencia en los registros existentes.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
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
        await _api.deleteCategory(cat.name);
        _load();
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Error al eliminar')));
        }
      }
    }
  }

  Future<void> _showAddDialog() async {
    final nameCtrl = TextEditingController();
    String type = 'expense';

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Nueva categoría'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'expense', label: Text('Gasto'), icon: Icon(Icons.remove_circle_outline)),
                  ButtonSegment(value: 'income', label: Text('Ingreso'), icon: Icon(Icons.add_circle_outline)),
                ],
                selected: {type},
                onSelectionChanged: (s) => setDialogState(() => type = s.first),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Añadir'),
            ),
          ],
        ),
      ),
    );

    if (ok == true && nameCtrl.text.trim().isNotEmpty) {
      try {
        await _api.addCategory(nameCtrl.text.trim(), type);
        _load();
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Error al añadir')));
        }
      }
    }
  }
}
