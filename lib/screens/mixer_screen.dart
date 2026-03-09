import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/mixer_provider.dart';
import '../providers/transaction_provider.dart';
import '../utils/constants.dart';
import 'dart:math' as math;

class MixerScreen extends StatefulWidget {
  const MixerScreen({super.key});

  @override
  State<MixerScreen> createState() => _MixerScreenState();
}

class _MixerScreenState extends State<MixerScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final mixerProvider = Provider.of<MixerProvider>(context, listen: false);
      if (!mixerProvider.isInitialized) {
        final txProvider = Provider.of<TransactionProvider>(
          context,
          listen: false,
        );
        mixerProvider.initialize(
          txProvider.totalBalance,
          txProvider.transactions,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final mixerProvider = Provider.of<MixerProvider>(context);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark
          ? Theme.of(context).colorScheme.surface
          : AppColors.lightCard,
      appBar: AppBar(
        title: const Text('STUDIO MIXER'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh_rounded,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
            ),
            onPressed: () => _showResetConfirmation(context, mixerProvider),
          ),
          IconButton(
            icon: Icon(
              Icons.add_chart_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
            onPressed: () => _showCategoryPicker(context, mixerProvider),
          ),
          IconButton(
            icon: Icon(
              mixerProvider.isLocked
                  ? Icons.lock_rounded
                  : Icons.lock_open_rounded,
              color: mixerProvider.isLocked
                  ? Colors.red
                  : Theme.of(context).colorScheme.primary,
            ),
            onPressed: () => mixerProvider.setLocked(!mixerProvider.isLocked),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(
        children: [
          // VU Meter (Left)
          _buildVuMeter(),

          // Faders Area
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              itemCount: mixerProvider.categories.length,
              itemBuilder: (context, index) {
                final category = mixerProvider.categories[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: NeumorphicFader(
                    index: index,
                    category: category,
                    isLocked: mixerProvider.isLocked,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showCategoryPicker(BuildContext context, MixerProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark
          ? Theme.of(context).colorScheme.surface
          : AppColors.lightCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'AÑADIR CANAL',
                style: TextStyle(
                  color: Color(0xFF66BB6A),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: provider.availableCategories.map((name) {
                  final isAlreadyAdded = provider.categories.any(
                    (c) => c.name == name,
                  );
                  return GestureDetector(
                    onTap: () {
                      if (!isAlreadyAdded) provider.addCategory(name);
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isAlreadyAdded
                            ? Colors.grey.withOpacity(0.1)
                            : const Color(0xFF66BB6A).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isAlreadyAdded
                              ? Colors.grey.withOpacity(0.2)
                              : const Color(0xFF66BB6A).withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        name,
                        style: TextStyle(
                          color: isAlreadyAdded
                              ? Colors.grey
                              : Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVuMeter() {
    return const VuMeter();
  }

  void _showResetConfirmation(BuildContext context, MixerProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark
            ? Theme.of(context).colorScheme.surface
            : AppColors.lightCard,
        title: Text(
          'REINICIAR MIXER',
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        content: const Text(
          '¿Estás seguro de que quieres reiniciar la mezcla? Se perderán todos los ajustes actuales.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'CANCELAR',
              style: TextStyle(color: Colors.grey.withOpacity(0.8)),
            ),
          ),
          TextButton(
            onPressed: () {
              final txProvider = Provider.of<TransactionProvider>(
                context,
                listen: false,
              );
              provider.initialize(
                txProvider.totalBalance,
                txProvider.transactions,
              );
              Navigator.pop(context);
            },
            child: Text(
              'REINICIAR',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class VuMeter extends StatefulWidget {
  const VuMeter({super.key});

  @override
  State<VuMeter> createState() => _VuMeterState();
}

class _VuMeterState extends State<VuMeter> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<double> _levels = List.generate(15, (_) => 0.0);
  double _peak = 0.0;
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..addListener(() {
            setState(() {
              final double t =
                  _controller.value * 2 * math.pi; // 0 to 2*pi over 2 seconds

              // Combine multiple sine waves for organic movement
              double signal =
                  0.5 + // Base level
                  0.3 * math.sin(t * 2) + // Main frequency
                  0.15 *
                      math.sin(
                        t * 5 + _random.nextDouble() * 0.5,
                      ) + // Higher frequency with slight phase shift
                  0.05 *
                      math.sin(
                        t * 10 + _random.nextDouble() * 0.8,
                      ); // Even higher frequency with more phase shift

              // Add some random noise for a more "live" feel
              signal +=
                  (_random.nextDouble() - 0.5) *
                  0.1; // Noise between -0.05 and 0.05

              // Clamp the signal between 0 and 1
              signal = signal.clamp(0.0, 1.0);

              // Simulate a peak hold effect
              if (signal > _peak) {
                _peak = signal;
              } else {
                _peak = math.max(0.0, _peak - 0.01); // Decay the peak slowly
              }

              // Determine how many segments should be active based on the signal
              final int activeSegments = (signal * _levels.length).floor();
              final int peakSegment = (_peak * _levels.length).floor().clamp(
                0,
                _levels.length - 1,
              );

              for (int i = 0; i < _levels.length; i++) {
                if (i == peakSegment) {
                  _levels[i] = 1.0; // Peak hold dot
                } else {
                  _levels[i] = (i < activeSegments) ? 1.0 : 0.0;
                }
              }
            });
          })
          ..repeat(); // Repeat without reverse for continuous signal
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 40,
      margin: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.black.withOpacity(0.3)
            : Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : AppColors.lightPrimary.withOpacity(0.1),
        ),
      ),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(15, (index) {
              final reverseIndex = 14 - index;
              final isActive = _levels[reverseIndex] > 0;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 50),
                height: 4,
                width: 20,
                decoration: BoxDecoration(
                  color: !isActive
                      ? Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.05)
                      : (index < 3)
                      ? Colors.red
                      : (index < 6)
                      ? Colors.orange
                      : Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: (index < 3)
                                ? Colors.red
                                : (index < 6)
                                ? Colors.orange
                                : Theme.of(context).colorScheme.primary,
                            blurRadius: 4,
                          ),
                        ]
                      : [],
                ),
              );
            }),
          ),
          // Subtle overall glow
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Theme.of(context).colorScheme.primary.withOpacity(0.05),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class NeumorphicFader extends StatelessWidget {
  final int index;
  final dynamic category;
  final bool isLocked;

  const NeumorphicFader({
    super.key,
    required this.index,
    required this.category,
    required this.isLocked,
  });

  @override
  Widget build(BuildContext context) {
    final mixerProvider = Provider.of<MixerProvider>(context, listen: false);
    final isActive = category.percentage > 0.01;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Category Name
        GestureDetector(
          onLongPress: isLocked
              ? null
              : () => mixerProvider.removeCategory(index),
          child: Column(
            children: [
              SizedBox(
                height: 40,
                child: Text(
                  category.name.toUpperCase(),
                  style: TextStyle(
                    color: isActive
                        ? Theme.of(context).colorScheme.onSurface
                        : Colors.grey.withOpacity(0.5),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              if (!isLocked)
                Icon(
                  Icons.remove_circle_outline_rounded,
                  size: 12,
                  color: Colors.red.withOpacity(0.3),
                ),
            ],
          ),
        ),

        // Fader Track & Knob
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double trackHeight = constraints.maxHeight;
              final double knobPosition =
                  trackHeight * (1 - category.percentage);

              return GestureDetector(
                onVerticalDragUpdate: isLocked
                    ? null
                    : (details) {
                        final double localY = details.localPosition.dy;
                        final double newPercentage =
                            (1 - (localY / trackHeight)).clamp(0.0, 1.0);
                        mixerProvider.updateFader(index, newPercentage);
                      },
                child: Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    // Track (Inner Shadow effect)
                    Container(
                      width: 12,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.black.withOpacity(0.3)
                            : Colors.black.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: isDark
                                ? Colors.black.withOpacity(0.5)
                                : Colors.black.withOpacity(0.1),
                            offset: const Offset(1, 1),
                            blurRadius: 1,
                          ),
                        ],
                      ),
                    ),

                    // Ruler markings
                    Positioned.fill(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(
                          10,
                          (i) => Container(
                            height: 1,
                            width: 20,
                            color: Colors.white.withOpacity(0.05),
                          ),
                        ),
                      ),
                    ),

                    // Knob
                    Positioned(
                      top: knobPosition - 20,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Theme.of(context).colorScheme.surface
                              : AppColors.lightCard,
                          borderRadius: BorderRadius.circular(8),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.1),
                              Colors.transparent,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isDark
                                  ? Colors.black.withOpacity(0.8)
                                  : Colors.black.withOpacity(0.2),
                              offset: const Offset(4, 4),
                              blurRadius: 6,
                            ),
                            BoxShadow(
                              color: isDark
                                  ? Colors.white.withOpacity(0.05)
                                  : Colors.white,
                              offset: const Offset(-2, -2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Container(
                            width: 32,
                            height: 6,
                            decoration: BoxDecoration(
                              color: isActive
                                  ? const Color(0xFF66BB6A)
                                  : Colors.grey.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(2),
                              boxShadow: isActive
                                  ? [
                                      BoxShadow(
                                        color: const Color(
                                          0xFF66BB6A,
                                        ).withOpacity(0.5),
                                        blurRadius: 8,
                                      ),
                                    ]
                                  : [],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 16),

        // Stats
        Text(
          '${(category.percentage * 100).toStringAsFixed(1)}%',
          style: TextStyle(
            color: isActive
                ? Theme.of(context).colorScheme.primary
                : Colors.grey,
            fontSize: 12,
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          '\$${category.amount.toStringAsFixed(0)}',
          style: TextStyle(
            color: isActive
                ? Theme.of(context).colorScheme.onSurface
                : Colors.grey,
            fontSize: 11,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}
