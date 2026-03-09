import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import 'neumorphic_container.dart';

class DonutChart extends StatefulWidget {
  final Map<String, double> categories;

  const DonutChart({super.key, required this.categories});

  @override
  State<DonutChart> createState() => _DonutChartState();
}

class _DonutChartState extends State<DonutChart> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    if (widget.categories.isEmpty) {
      return const NeumorphicContainer(
        borderRadius: 24,
        padding: EdgeInsets.all(40),
        child: Center(
          child: Text(
            'Sin datos este mes',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ),
      );
    }

    final userProvider = Provider.of<UserProvider>(context);
    // Calculate total for center display
    final double total = widget.categories.values.fold(
      0,
      (sum, val) => sum + val,
    );

    return NeumorphicContainer(
      borderRadius: 24,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'DISTRIBUCIÓN',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              if (touchedIndex != -1)
                IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  onPressed: () => setState(() => touchedIndex = -1),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          const SizedBox(height: 20),
          AspectRatio(
            aspectRatio: 1.2,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (FlTouchEvent event, pieTouchResponse) {
                        setState(() {
                          if (!event.isInterestedForInteractions ||
                              pieTouchResponse == null ||
                              pieTouchResponse.touchedSection == null) {
                            touchedIndex = -1;
                            return;
                          }
                          touchedIndex = pieTouchResponse
                              .touchedSection!
                              .touchedSectionIndex;
                        });
                      },
                    ),
                    borderData: FlBorderData(show: false),
                    sectionsSpace: 4,
                    centerSpaceRadius: 60,
                    sections: _showingSections(userProvider),
                  ),
                ),
                // Center hole content
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      touchedIndex == -1
                          ? 'TOTAL'
                          : _getCategoryName(touchedIndex),
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      userProvider.isSteganographyMode
                          ? '***'
                          : '${userProvider.currencySymbol}${_getDisplayValue(total).toStringAsFixed(0)}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  List<PieChartSectionData> _showingSections(UserProvider userProvider) {
    int i = 0;
    return widget.categories.entries.map((e) {
      final isTouched = i == touchedIndex;
      final double fontSize = isTouched ? 16.0 : 12.0;
      final double radius = isTouched ? 65.0 : 60.0;
      final double widgetSize = isTouched ? 45.0 : 35.0;
      const shadows = [Shadow(color: Colors.black, blurRadius: 4)];

      final color = _getCategoryColor(e.key, i);
      i++;

      return PieChartSectionData(
        color: color,
        value: e.value,
        title: userProvider.isSteganographyMode
            ? ''
            : '${((e.value / widget.categories.values.fold(0, (s, v) => s + v)) * 100).toStringAsFixed(0)}%',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: shadows,
        ),
        badgeWidget: isTouched
            ? _Badge(e.key, size: widgetSize, color: color)
            : null,
        badgePositionPercentageOffset: .98,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color, color.withValues(alpha: 0.7)],
        ),
      );
    }).toList();
  }

  Color _getCategoryColor(String name, int index) {
    final List<Color> palette = [
      const Color(0xFF66BB6A), // Emerald
      const Color(0xFF42A5F5), // Blue
      const Color(0xFFAB47BC), // Purple
      const Color(0xFFFFA726), // Amber
      const Color(0xFF26A69A), // Teal
      const Color(0xFFEF5350), // Red
      const Color(0xFF78909C), // Blue Grey
    ];

    if (name.contains('Comida')) return palette[0];
    if (name.contains('Transporte')) return palette[1];
    if (name.contains('Ocio')) return palette[3];
    if (name.contains('Renta')) return palette[2];
    if (name.contains('Salud')) return palette[5];

    return palette[index % palette.length];
  }

  String _getCategoryName(int index) {
    if (index < 0 || index >= widget.categories.length) return '';
    return widget.categories.keys.elementAt(index).toUpperCase();
  }

  double _getDisplayValue(double total) {
    if (touchedIndex == -1) return total;
    return widget.categories.values.elementAt(touchedIndex);
  }
}

class _Badge extends StatelessWidget {
  final String category;
  final double size;
  final Color color;

  const _Badge(this.category, {required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      padding: EdgeInsets.all(size * .15),
      child: Center(
        child: Icon(_getCategoryIcon(category), size: size * .6, color: color),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    if (category.contains('Comida')) return Icons.restaurant_rounded;
    if (category.contains('Transporte')) return Icons.directions_car_rounded;
    if (category.contains('Ocio')) return Icons.sports_esports_rounded;
    if (category.contains('Renta')) return Icons.home_rounded;
    if (category.contains('Salud')) return Icons.medical_services_rounded;
    if (category.contains('Educación')) return Icons.school_rounded;
    return Icons.category_rounded;
  }
}
