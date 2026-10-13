import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'models.dart';
import 'firebase_service.dart';

class StatisticsScreen extends StatefulWidget {
  final String carId;

  const StatisticsScreen({super.key, required this.carId});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final FirebaseService _firebase = FirebaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Статистика витрат'),
      ),
      body: StreamBuilder<List<ServiceLog>>(
        stream: _firebase.streamLogs(widget.carId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final logs = snapshot.data!;

          if (logs.isEmpty) {
            return const Center(
              child: Text('Немає даних про витрати'),
            );
          }

          final totalCost = logs.fold<double>(0.0, (sum, log) => sum + log.cost);
          final costByMonth = _groupCostByMonth(logs);
          final costByCategory = _groupCostByCategory(logs);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Total cost card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Загальні витрати',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${totalCost.toStringAsFixed(2)} ₴',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${logs.length} записів',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Monthly cost chart
                const Text(
                  'Витрати по місяцях',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: costByMonth.values.isEmpty
                          ? 100
                          : costByMonth.values.reduce((a, b) => a > b ? a : b) * 1.2,
                      barGroups: costByMonth.entries.map((entry) {
                        return BarChartGroupData(
                          x: entry.key,
                          barRods: [
                            BarChartRodData(
                              toY: entry.value,
                              color: Colors.blue,
                              width: 16,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ],
                        );
                      }).toList(),
                      borderData: FlBorderData(show: false),
                      gridData: const FlGridData(show: false),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final monthNames = [
                                'Січ', 'Лют', 'Бер', 'Кві', 'Тра', 'Чер',
                                'Лип', 'Сер', 'Вер', 'Жов', 'Лис', 'Гру'
                              ];
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  monthNames[value.toInt() - 1],
                                  style: const TextStyle(fontSize: 10),
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Category breakdown
                const Text(
                  'Розподіл по категоріях',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: PieChart(
                    PieChartData(
                      sections: costByCategory.entries.map((entry) {
                        final percentage = (entry.value / totalCost * 100);
                        final colors = [
                          Colors.blue,
                          Colors.green,
                          Colors.orange,
                          Colors.purple,
                          Colors.red,
                          Colors.teal,
                        ];
                        final colorIndex = costByCategory.keys.toList().indexOf(entry.key) % colors.length;

                        return PieChartSectionData(
                          value: entry.value,
                          title: '${percentage.toStringAsFixed(1)}%',
                          color: colors[colorIndex],
                          radius: 80,
                          titleStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        );
                      }).toList(),
                      borderData: FlBorderData(show: false),
                      sectionsSpace: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Legend
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: costByCategory.entries.map((entry) {
                    final colors = [
                      Colors.blue,
                      Colors.green,
                      Colors.orange,
                      Colors.purple,
                      Colors.red,
                      Colors.teal,
                    ];
                    final colorIndex = costByCategory.keys.toList().indexOf(entry.key) % colors.length;
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: colors[colorIndex],
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(entry.key),
                      ],
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Recent expenses list
                const Text(
                  'Останні витрати',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: logs.take(5).length,
                  itemBuilder: (context, index) {
                    final log = logs[index];
                    return Card(
                      child: ListTile(
                        title: Text(log.partName),
                        subtitle: Text(
                          '${log.dateAtChange.day}.${log.dateAtChange.month}.${log.dateAtChange.year}',
                        ),
                        trailing: Text(
                          '${log.cost.toStringAsFixed(2)} ₴',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Map<int, double> _groupCostByMonth(List<ServiceLog> logs) {
    final Map<int, double> monthlyCosts = {};
    for (var log in logs) {
      final month = log.dateAtChange.month;
      monthlyCosts[month] = (monthlyCosts[month] ?? 0) + log.cost;
    }
    return monthlyCosts;
  }

  Map<String, double> _groupCostByCategory(List<ServiceLog> logs) {
    final Map<String, double> categoryCosts = {};
    for (var log in logs) {
      final category = _categorizeExpense(log.partName);
      categoryCosts[category] = (categoryCosts[category] ?? 0) + log.cost;
    }
    return categoryCosts;
  }

  String _categorizeExpense(String partName) {
    final lowerName = partName.toLowerCase();

    if (lowerName.contains('олив') || lowerName.contains('масло')) {
      return 'Масло та фільтри';
    }
    if (lowerName.contains('шин') || lowerName.contains('колес') || lowerName.contains('гума')) {
      return 'Шини';
    }
    if (lowerName.contains('гальм') || lowerName.contains('колодк')) {
      return 'Гальмівна система';
    }
    if (lowerName.contains('акумулятор') || lowerName.contains('батарей')) {
      return 'Акумулятор';
    }
    if (lowerName.contains('ремонт') || lowerName.contains('діагностик')) {
      return 'Ремонт';
    }
    if (lowerName.contains('мийк') || lowerName.contains('чистк')) {
      return 'Миття та чистка';
    }

    return 'Інше';
  }
}
