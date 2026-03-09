import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/transaction_provider.dart';
import '../providers/user_provider.dart';
import '../utils/constants.dart';
import 'neumorphic_container.dart';

class BarChartWidget extends StatefulWidget {
  const BarChartWidget({super.key});

  @override
  State<BarChartWidget> createState() => _BarChartWidgetState();
}

class _BarChartWidgetState extends State<BarChartWidget> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TransactionProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    final txs = provider.filteredTransactions;

    if (txs.isEmpty) {
      return NeumorphicContainer(
        borderRadius: 20,
        padding: const EdgeInsets.all(40),
        child: Center(
          child: Text(
            'Sin movimientos este mes',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ),
      ).animate().fadeIn();
    }

    // Group by category, handle Income vs Expense
    Map<String, double> categories = {};
    for (var tx in txs) {
      final key = tx.type == 'Ingreso' ? '[I] ${tx.category}' : tx.category;
      categories[key] = (categories[key] ?? 0) + tx.amount;
    }

    final List<String> sortedCategories = categories.keys.toList();
    final maxVal = categories.values.fold(0.0, (max, v) => v > max ? v : max);

    return NeumorphicContainer(
      borderRadius: 24,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'COMPARATIVA',
                style: TextStyle(
                  color: primaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              if (touchedIndex != -1)
                Text(
                  _formatLabel(sortedCategories[touchedIndex]),
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 220,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxVal * 1.3,
                barTouchData: BarTouchData(
                  touchCallback: (FlTouchEvent event, barTouchResponse) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          barTouchResponse == null ||
                          barTouchResponse.spot == null) {
                        touchedIndex = -1;
                        return;
                      }
                      touchedIndex =
                          barTouchResponse.spot!.touchedBarGroupIndex;
                    });
                  },
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (group) =>
                        isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    tooltipRoundedRadius: 12,
                    tooltipPadding: const EdgeInsets.all(12),
                    tooltipBorder: isDark
                        ? BorderSide(
                            color: Colors.white.withValues(alpha: 0.1),
                            width: 1,
                          )
                        : BorderSide(
                            color: Colors.black.withValues(alpha: 0.05),
                            width: 1,
                          ),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final label = sortedCategories[groupIndex];
                      final isIncome = label.startsWith('[I] ');
                      final displayLabel = _formatLabel(label);

                      return BarTooltipItem(
                        '$displayLabel\n',
                        TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        children: [
                          TextSpan(
                            text: userProvider.isSteganographyMode
                                ? '***'
                                : '${userProvider.currencySymbol}${rod.toY.toStringAsFixed(0)}',
                            style: TextStyle(
                              color: isIncome
                                  ? Colors.green
                                  : AppColors.lightAlert,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < sortedCategories.length) {
                          final label = _formatLabel(sortedCategories[index]);
                          final isSelected = index == touchedIndex;

                          return SideTitleWidget(
                            meta: meta,
                            space: 8,
                            child: Text(
                              label.length > 3
                                  ? '${label.substring(0, 3)}.'
                                  : label,
                              style: TextStyle(
                                color: isSelected ? primaryColor : Colors.grey,
                                fontSize: 10,
                                fontWeight: isSelected
                                    ? FontWeight.w900
                                    : FontWeight.bold,
                              ),
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(sortedCategories.length, (i) {
                  final isIncome = sortedCategories[i].startsWith('[I] ');
                  final isSelected = i == touchedIndex;

                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: categories[sortedCategories[i]]!,
                        gradient: LinearGradient(
                          colors: isIncome
                              ? [Colors.green.shade700, Colors.greenAccent]
                              : [AppColors.lightAlert, const Color(0xFFFF8A80)],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        width: isSelected ? 24 : 18,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(8),
                        ),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: maxVal * 1.3,
                          color: isDark
                              ? Colors.black.withValues(alpha: 0.2)
                              : Colors.black.withValues(alpha: 0.05),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendItem('INGRESOS', Colors.green, isDark),
              const SizedBox(width: 20),
              _LegendItem('GASTOS', AppColors.lightAlert, isDark),
            ],
          ),
        ],
      ),
    ).animate().fadeIn().moveY(begin: 20, end: 0);
  }

  String _formatLabel(String raw) {
    if (raw.startsWith('[I] ')) return raw.substring(4).toUpperCase();
    return raw.toUpperCase();
  }

  Widget _LegendItem(String label, Color color, bool isDark) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey,
            fontSize: 9,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
