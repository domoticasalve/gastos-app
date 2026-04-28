import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/budget.dart';
import '../services/api_service.dart';
import '../widgets/summary_card.dart';
import '../widgets/error_view.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _api = ApiService();
  DashboardData? _data;
  bool _loading = true;
  String? _error;

  int _selectedYear = DateTime.now().year;
  int? _selectedMonth;

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
      final data = await _api.getDashboard(
        year: _selectedYear,
        month: _selectedMonth,
      );
      setState(() { _data = data; _loading = false; });
    } catch (e) {
      setState(() {
        _error = 'No se pudo conectar al servidor.\nComprueba que Flask está corriendo en 192.168.50.25:5000';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? ErrorView(message: _error!, onRetry: _load)
                    : _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    final years = List.generate(5, (i) => DateTime.now().year - i);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).colorScheme.surfaceVariant,
      child: Row(
        children: [
          const Text('Año:'),
          const SizedBox(width: 8),
          DropdownButton<int>(
            value: _selectedYear,
            items: years
                .map((y) => DropdownMenuItem(value: y, child: Text('$y')))
                .toList(),
            onChanged: (v) {
              setState(() => _selectedYear = v!);
              _load();
            },
          ),
          const SizedBox(width: 16),
          const Text('Mes:'),
          const SizedBox(width: 8),
          DropdownButton<int?>(
            value: _selectedMonth,
            items: [
              const DropdownMenuItem(value: null, child: Text('Todos')),
              ...List.generate(
                12,
                (i) => DropdownMenuItem(value: i + 1, child: Text(_months[i + 1])),
              ),
            ],
            onChanged: (v) {
              setState(() => _selectedMonth = v);
              _load();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final d = _data!;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSummaryCards(d),
          const SizedBox(height: 24),
          _buildMonthlyChart(d),
          const SizedBox(height: 24),
          if (d.byCategory.isNotEmpty) _buildCategoryChart(d),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(DashboardData d) {
    final savingsColor = d.savings >= 0 ? Colors.green : Colors.red;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: SummaryCard(
                title: 'Ingresos',
                amount: d.totalIncome,
                icon: Icons.trending_up,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SummaryCard(
                title: 'Gastos',
                amount: d.totalExpenses,
                icon: Icons.trending_down,
                color: Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: SummaryCard(
                title: 'Ahorro',
                amount: d.savings,
                icon: Icons.savings,
                color: savingsColor,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.percent, color: savingsColor, size: 20),
                          const SizedBox(width: 8),
                          Text('Tasa ahorro',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                  )),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${d.savingsRate.toStringAsFixed(1)}%',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: savingsColor,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMonthlyChart(DashboardData d) {
    if (d.monthly.isEmpty) return const SizedBox.shrink();

    final barGroups = d.monthly.asMap().entries.map((entry) {
      final i = entry.key;
      final m = entry.value;
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: m.income,
            color: Colors.green.withOpacity(0.8),
            width: 8,
          ),
          BarChartRodData(
            toY: m.expenses,
            color: Colors.red.withOpacity(0.8),
            width: 8,
          ),
        ],
      );
    }).toList();

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ingresos vs Gastos por mes',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                _legend(Colors.green, 'Ingresos'),
                const SizedBox(width: 16),
                _legend(Colors.red, 'Gastos'),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  barGroups: barGroups,
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final i = value.toInt();
                          if (i < 0 || i >= d.monthly.length) {
                            return const SizedBox.shrink();
                          }
                          final month = d.monthly[i].month;
                          return Text(month.length > 3 ? month.substring(0, 3) : month,
                              style: const TextStyle(fontSize: 10));
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        getTitlesWidget: (value, meta) {
                          if (value >= 1000) {
                            return Text('${(value / 1000).toStringAsFixed(0)}k',
                                style: const TextStyle(fontSize: 10));
                          }
                          return Text(value.toStringAsFixed(0),
                              style: const TextStyle(fontSize: 10));
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: const FlGridData(show: true),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChart(DashboardData d) {
    final colors = [
      Colors.blue, Colors.orange, Colors.purple, Colors.teal,
      Colors.pink, Colors.indigo, Colors.amber, Colors.cyan,
    ];

    final entries = d.byCategory.entries.toList();
    final sections = entries.asMap().entries.map((e) {
      final color = colors[e.key % colors.length];
      final pct = d.totalExpenses > 0
          ? (e.value.value / d.totalExpenses * 100)
          : 0.0;
      return PieChartSectionData(
        value: e.value.value,
        title: '${pct.toStringAsFixed(0)}%',
        color: color,
        radius: 80,
        titleStyle: const TextStyle(fontSize: 11, color: Colors.white),
      );
    }).toList();

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Gastos por categoría',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(PieChartData(sections: sections)),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: entries.asMap().entries.map((e) {
                final color = colors[e.key % colors.length];
                return _legend(color, e.value.key);
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legend(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, color: color),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
