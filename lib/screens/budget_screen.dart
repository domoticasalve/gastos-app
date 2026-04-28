import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/budget.dart';
import '../services/api_service.dart';
import '../widgets/error_view.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final _api = ApiService();
  List<BudgetItem> _budget = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await _api.getBudget();
      setState(() { _budget = data; _loading = false; });
    } catch (e) {
      setState(() {
        _error = 'No se pudo cargar el presupuesto.\n$e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Presupuesto'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? ErrorView(message: _error!, onRetry: _load)
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_budget.isEmpty) {
      return const Center(child: Text('No hay datos de presupuesto'));
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _budget.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) => _BudgetCard(
          item: _budget[i],
          onEdit: () => _showEditDialog(_budget[i]),
        ),
      ),
    );
  }

  Future<void> _showEditDialog(BudgetItem item) async {
    final ctrl = TextEditingController(text: item.target.toStringAsFixed(2));
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Presupuesto: ${item.category}'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            labelText: 'Objetivo mensual (€)',
            prefixText: '€ ',
            border: OutlineInputBorder(),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (ok == true) {
      final value = double.tryParse(ctrl.text.replaceAll(',', '.'));
      if (value != null && value >= 0) {
        try {
          await _api.saveBudget(item.category, value);
          _load();
        } catch (_) {
          if (mounted) {
            ScaffoldMessenger.of(context)
                .showSnackBar(const SnackBar(content: Text('Error al guardar')));
          }
        }
      }
    }
  }
}

class _BudgetCard extends StatelessWidget {
  final BudgetItem item;
  final VoidCallback onEdit;

  const _BudgetCard({required this.item, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'es_ES', symbol: '€');
    final pct = item.percentage.clamp(0.0, 100.0) / 100;

    Color barColor;
    if (item.isOverBudget) {
      barColor = Colors.red;
    } else if (item.isWarning) {
      barColor = Colors.orange;
    } else {
      barColor = Colors.green;
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item.category,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 18),
                  onPressed: onEdit,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  fmt.format(item.actual),
                  style: TextStyle(color: barColor, fontWeight: FontWeight.w600),
                ),
                Text(
                  item.target > 0
                      ? '/ ${fmt.format(item.target)}'
                      : 'Sin objetivo',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: item.target > 0 ? pct : 0,
                minHeight: 10,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(barColor),
              ),
            ),
            const SizedBox(height: 4),
            if (item.target > 0)
              Text(
                item.isOverBudget
                    ? '${item.percentage.toStringAsFixed(0)}% — Presupuesto superado'
                    : '${item.percentage.toStringAsFixed(0)}% utilizado',
                style: TextStyle(fontSize: 12, color: barColor),
              ),
          ],
        ),
      ),
    );
  }
}
