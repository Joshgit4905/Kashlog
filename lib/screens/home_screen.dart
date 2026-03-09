import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import '../providers/transaction_provider.dart';
import '../providers/user_provider.dart';
import '../utils/constants.dart';
import '../widgets/balance_card.dart';
import '../widgets/donut_chart.dart';
import '../widgets/bar_chart_widget.dart';
import '../widgets/transaction_item.dart';
import '../models/planned_payment.dart';
import 'add_transaction_screen.dart';
import 'settings_screen.dart';
import 'mixer_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../widgets/trend_chart.dart';
import '../services/tutorial_manager.dart';
import '../widgets/tutorial_overlay.dart';
import '../widgets/neumorphic_container.dart';
import '../services/log_stream_service.dart';
import '../services/memory_monitor_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _chartIndex = 0; // 0: Donut, 1: Bar, 2: Trend
  bool _showTutorial = false;
  bool _isTerminalMinimized = false;

  @override
  void initState() {
    super.initState();
    _checkTutorial();
  }

  Future<void> _checkTutorial() async {
    final completed = await TutorialManager.isCompleted();
    if (!completed && mounted) {
      setState(() => _showTutorial = true);
    }
  }

  Future<void> _completeTutorial() async {
    await TutorialManager.markAsCompleted();
    if (mounted) {
      setState(() => _showTutorial = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final transactionProvider = Provider.of<TransactionProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);

    return Stack(
      children: [
        Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 120,
                floating: false,
                pinned: true,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                  title: Text(
                    userProvider.name.isEmpty
                        ? 'KashLog'
                        : 'Hola, ${userProvider.name}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.lightPrimary.withOpacity(0.1),
                          Theme.of(context).scaffoldBackgroundColor,
                        ],
                      ),
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.tune_rounded),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MixerScreen()),
                    ),
                  ).animate().fadeIn(delay: 500.ms).scale(),
                  IconButton(
                    icon: const Icon(Icons.settings_outlined)
                        .animate(
                          onPlay: (controller) =>
                              controller.repeat(reverse: true),
                        )
                        .rotate(begin: -0.05, end: 0.05, duration: 2.seconds),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    ),
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMonthSelector(transactionProvider),
                      const SizedBox(height: 20),
                      const BalanceCard(),
                      const SizedBox(height: 32),
                      _buildPlannedSection(transactionProvider),
                      const SizedBox(height: 32),
                      _buildEmergencyFund(transactionProvider, userProvider),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Flexible(
                            child: Text(
                              'Análisis Mensual',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          NeumorphicContainer(
                            borderRadius: 12,
                            padding: EdgeInsets.zero,
                            child: Row(
                              children: [
                                _buildChartToggleButton(
                                  Icons.pie_chart_outline,
                                  _chartIndex == 0,
                                  () => setState(() => _chartIndex = 0),
                                ),
                                _buildChartToggleButton(
                                  Icons.bar_chart_outlined,
                                  _chartIndex == 1,
                                  () => setState(() => _chartIndex = 1),
                                ),
                                _buildChartToggleButton(
                                  Icons.show_chart_rounded,
                                  _chartIndex == 2,
                                  () => setState(() => _chartIndex = 2),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: AnimatedSwitcher(
                              duration: 400.ms,
                              child: _chartIndex == 0
                                  ? DonutChart(
                                      key: const ValueKey(0),
                                      categories: transactionProvider
                                          .filteredTransactions
                                          .fold<Map<String, double>>({}, (
                                            map,
                                            tx,
                                          ) {
                                            final key = tx.type == 'Ingreso'
                                                ? '[I] ${tx.category}'
                                                : tx.category;
                                            map[key] =
                                                (map[key] ?? 0.0) + tx.amount;
                                            return map;
                                          }),
                                    )
                                  : _chartIndex == 1
                                  ? const BarChartWidget(key: ValueKey(1))
                                  : TrendChart(
                                      key: const ValueKey(2),
                                      data: transactionProvider
                                          .lastSixMonthsExpenses,
                                    ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      _buildBudgetSection(transactionProvider, userProvider),
                      const SizedBox(height: 32),
                      const Text(
                        'Movimientos del Mes',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ).animate().fadeIn(delay: 400.ms),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: userProvider.isDeveloperMode
                      ? (_isTerminalMinimized ? 80 : 280)
                      : 40,
                ),
              ),
              transactionProvider.filteredTransactions.isEmpty
                  ? SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                                  Icons.receipt_long_outlined,
                                  size: 64,
                                  color: Colors.grey.withOpacity(0.5),
                                )
                                .animate(
                                  onPlay: (controller) =>
                                      controller.repeat(reverse: true),
                                )
                                .moveY(begin: -5, end: 5, duration: 2.seconds),
                            const SizedBox(height: 16),
                            const Text(
                              'No hay movimientos en este mes',
                              style: TextStyle(color: Colors.grey),
                            ).animate().fadeIn(),
                          ],
                        ),
                      ),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          return Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: TransactionItem(
                                  transaction: transactionProvider
                                      .filteredTransactions[index],
                                ),
                              )
                              .animate()
                              .fadeIn(delay: (index * 50).ms)
                              .slideX(begin: 0.1);
                        },
                        childCount:
                            transactionProvider.filteredTransactions.length,
                      ),
                    ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
            ),
            child: const Icon(Icons.add_rounded, color: Colors.white),
          ),
        ),
        if (_showTutorial) TutorialOverlay(onComplete: _completeTutorial),
        if (userProvider.isDeveloperMode)
          NeumorphicTerminal(
            isMinimized: _isTerminalMinimized,
            onToggle: () =>
                setState(() => _isTerminalMinimized = !_isTerminalMinimized),
          ),
      ],
    );
  }

  Widget _buildMonthSelector(TransactionProvider provider) {
    return NeumorphicContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      borderRadius: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 18,
                color: AppColors.lightPrimary,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    DateFormat(
                      'MMMM',
                    ).format(provider.selectedMonth).toUpperCase(),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Text(
                    provider.selectedMonth.year.toString(),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
          ElevatedButton.icon(
            onPressed: () => _showMonthPicker(context, provider),
            icon: const Icon(Icons.unfold_more_rounded, size: 18),
            label: const Text('Cambiar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.lightPrimary.withOpacity(0.1),
              foregroundColor: AppColors.lightPrimary,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMonthPicker(BuildContext context, TransactionProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Seleccionar Mes',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.5,
                ),
                itemCount: 84, // Show from 2024 to 2030 (7 years * 12)
                itemBuilder: (context, index) {
                  // Index 0 will be Dec 2030, going backwards
                  final month = DateTime(2030, 12 - index);
                  final isSelected =
                      month.year == provider.selectedMonth.year &&
                      month.month == provider.selectedMonth.month;

                  return InkWell(
                    onTap: () {
                      provider.setSelectedMonth(month);
                      Navigator.pop(context);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.lightPrimary
                            : Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.lightPrimary
                              : Colors.grey.withOpacity(0.1),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            DateFormat('MMM').format(month),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : null,
                            ),
                          ),
                          Text(
                            month.year.toString(),
                            style: TextStyle(
                              fontSize: 10,
                              color: isSelected ? Colors.white70 : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlannedSection(TransactionProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Próximos Pagos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ).animate().fadeIn(),
            IconButton(
              icon: const Icon(Icons.add_circle_outline, size: 20),
              onPressed: () => _showAddPlannedDialog(context),
            ),
          ],
        ),
        const SizedBox(height: 12),
        provider.plannedPayments.isEmpty
            ? Text(
                'No hay pagos pendientes',
                style: TextStyle(color: Colors.grey[500], fontSize: 13),
              )
            : SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: provider.plannedPayments.length,
                  itemBuilder: (context, index) => _buildPlannedCard(
                    provider.plannedPayments[index],
                    provider,
                  ),
                ),
              ),
      ],
    );
  }

  Widget _buildPlannedCard(
    PlannedPaymentModel payment,
    TransactionProvider provider,
  ) {
    final userProvider = Provider.of<UserProvider>(context);
    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: NeumorphicContainer(
        padding: const EdgeInsets.all(12),
        borderRadius: 16,
        child: SizedBox(
          width: 136, // Adjust width to account for padding
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      payment.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  InkWell(
                    onTap: () => provider.deletePlannedPayment(payment.id!),
                    child: const Icon(
                      Icons.close,
                      size: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                userProvider.isSteganographyMode
                    ? '---'
                    : '${userProvider.currencySymbol}${payment.amount.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: AppColors.lightAlert,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                DateFormat('dd MMM').format(payment.dueDate),
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmergencyFund(
    TransactionProvider provider,
    UserProvider userProvider,
  ) {
    final target = provider.emergencyFundTarget;
    final current = provider.emergencyFundCurrent;
    final percent = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;

    return GestureDetector(
      onTap: () => _showEmergencyFundDialog(context, provider),
      child: NeumorphicContainer(
        padding: const EdgeInsets.all(20),
        borderRadius: 24,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.shield_outlined, color: AppColors.lightPrimary),
                    SizedBox(width: 8),
                    Text(
                      'Ahorro',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${(percent * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                    color: AppColors.lightPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: percent,
                backgroundColor: AppColors.lightPrimary.withOpacity(0.1),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.lightPrimary,
                ),
                minHeight: 12,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              userProvider.isSteganographyMode
                  ? 'Ahorrado: --- / ---'
                  : 'Ahorrado: ${userProvider.currencySymbol}${current.toStringAsFixed(0)} / ${userProvider.currencySymbol}${target.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  void _showEmergencyFundDialog(
    BuildContext context,
    TransactionProvider provider,
  ) {
    final targetController = TextEditingController(
      text: provider.emergencyFundTarget.toStringAsFixed(0),
    );
    final currentController = TextEditingController(
      text: provider.emergencyFundCurrent.toStringAsFixed(0),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Configurar Fondo de Emergencia'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: targetController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Meta de Ahorro'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: currentController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Monto Actual'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.updateEmergencyFund(
                double.parse(targetController.text),
                double.parse(currentController.text),
              );
              Navigator.pop(context);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetSection(
    TransactionProvider provider,
    UserProvider userProvider,
  ) {
    final categories = {
      ...provider.filteredTransactions
          .where((tx) => tx.type == 'Gasto')
          .map((tx) => tx.category),
      ...provider.budgets.keys,
    }.toList();

    if (categories.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Presupuestos por Categoría',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ).animate().fadeIn(),
        const SizedBox(height: 16),
        ...categories.map((cat) {
          final spent = provider.filteredTransactions
              .where((tx) => tx.category == cat && tx.type == 'Gasto')
              .fold(0.0, (sum, tx) => sum + tx.amount);
          final limit = provider.budgets[cat] ?? 0.0;
          final percent = limit > 0 ? spent / limit : 0.0;
          final isOver = limit > 0 && spent > limit;

          return Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: GestureDetector(
              onTap: () => _showSetBudgetDialog(context, cat, limit),
              child: NeumorphicContainer(
                padding: const EdgeInsets.all(16),
                borderRadius: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            cat,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          userProvider.isSteganographyMode
                              ? '--- / ---'
                              : '${userProvider.currencySymbol}${spent.toStringAsFixed(0)} / ${limit > 0 ? '${userProvider.currencySymbol}${limit.toStringAsFixed(0)}' : 'Sin límite'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isOver ? AppColors.lightAlert : Colors.grey,
                            fontWeight: isOver
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: limit > 0 ? (percent > 1 ? 1 : percent) : 0,
                        backgroundColor: Colors.grey.withOpacity(0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isOver
                              ? AppColors.lightAlert
                              : (percent > 0.8
                                    ? Colors.orange
                                    : AppColors.lightPrimary),
                        ),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  void _showSetBudgetDialog(
    BuildContext context,
    String category,
    double currentLimit,
  ) {
    final controller = TextEditingController(
      text: currentLimit > 0 ? currentLimit.toStringAsFixed(0) : '',
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Presupuesto: $category'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Monto Límite Mensual',
            hintText: 'Ej. 500',
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final limit = double.tryParse(controller.text) ?? 0;
              Provider.of<TransactionProvider>(
                context,
                listen: false,
              ).setBudget(category, limit);
              Navigator.pop(context);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _showAddPlannedDialog(BuildContext context) {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Nuevo Pago Pendiente'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Concepto'),
                textCapitalization: TextCapitalization.sentences,
              ),
              TextField(
                controller: amountController,
                decoration: const InputDecoration(labelText: 'Monto'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Vencimiento'),
                subtitle: Text(DateFormat('dd/MM/yyyy').format(selectedDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    setDialogState(() => selectedDate = picked);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final amount = double.tryParse(amountController.text) ?? 0;
                if (titleController.text.isNotEmpty && amount > 0) {
                  Provider.of<TransactionProvider>(
                    context,
                    listen: false,
                  ).addPlannedPayment(
                    PlannedPaymentModel(
                      title: titleController.text,
                      amount: amount,
                      dueDate: selectedDate,
                      category: 'Otros',
                    ),
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text('Añadir'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartToggleButton(
    IconData icon,
    bool active,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10), // Support tap feedback
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active
              ? AppColors.lightPrimary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 20,
          color: active ? AppColors.lightPrimary : Colors.grey,
        ),
      ),
    );
  }
}

class NeumorphicTerminal extends StatefulWidget {
  final bool isMinimized;
  final VoidCallback onToggle;

  const NeumorphicTerminal({
    super.key,
    required this.isMinimized,
    required this.onToggle,
  });

  @override
  State<NeumorphicTerminal> createState() => _NeumorphicTerminalState();
}

class _NeumorphicTerminalState extends State<NeumorphicTerminal> {
  final ScrollController _scrollController = ScrollController();
  final List<LogEntry> _logs = List.from(LogStreamService.currentLogs);
  late final StreamSubscription<LogEntry> _subscription;
  final MemoryMonitorService _memoryService = MemoryMonitorService();

  @override
  void initState() {
    super.initState();
    _memoryService.start();
    _subscription = LogStreamService.logStream.listen((entry) {
      if (mounted) {
        setState(() {
          if (entry.message == 'CLEARED') {
            _logs.clear();
          } else {
            _logs.add(entry);
          }
        });
        _scrollToBottom();
      }
    });
    // Initial scroll
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    _memoryService.stop();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Positioned(
      bottom: 20,
      left: 16,
      right: 90, // Clear the FAB area
      child: Material(
        color: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header Row: RAM Monitor + Buttons (Minimized/Delete)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildMemoryMonitor(),
                  Row(
                    children: [
                      _buildTerminalButton(
                        icon: widget.isMinimized
                            ? Icons.unfold_more
                            : Icons.unfold_less,
                        onTap: widget.onToggle,
                      ),
                      if (!widget.isMinimized) ...[
                        const SizedBox(width: 8),
                        _buildTerminalButton(
                          icon: Icons.delete_outline,
                          onTap: () => LogStreamService.clear(),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            // Main Console Body
            if (!widget.isMinimized)
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    height: 200,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Theme.of(
                              context,
                            ).colorScheme.surface.withOpacity(0.8)
                          : AppColors.lightCard.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark
                            ? Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.1)
                            : AppColors.lightPrimary.withOpacity(0.1),
                        width: 0.5,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: ListView.builder(
                        controller: _scrollController,
                        itemCount: _logs.length,
                        itemBuilder: (context, index) {
                          final log = _logs[index];
                          Color textColor = Theme.of(
                            context,
                          ).colorScheme.primary;
                          if (log.type == 'EXCEPTION' || log.type == 'ERROR') {
                            textColor = Colors.redAccent;
                          } else if (log.type == 'SYSTEM') {
                            textColor = Colors.blueAccent;
                          }

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              '[${DateFormat('HH:mm:ss').format(log.timestamp)}] ${log.message}',
                              style: TextStyle(
                                color: textColor,
                                fontFamily: 'monospace',
                                fontSize: 11,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemoryMonitor() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ValueListenableBuilder<double>(
      valueListenable: _memoryService.memoryUsageMB,
      builder: (context, usage, _) {
        const double limitMB = 250.0; // Increased limit for visibility
        final double progress = (usage / limitMB).clamp(0.0, 1.0);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1B2E1B) : AppColors.lightCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.05)
                  : AppColors.lightPrimary.withOpacity(0.1),
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.4)
                    : Colors.black.withOpacity(0.15),
                offset: const Offset(1, 1),
                blurRadius: 2,
              ),
              BoxShadow(
                color: isDark ? Colors.white.withOpacity(0.01) : Colors.white,
                offset: const Offset(-1, -1),
                blurRadius: 1,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'RAM USAGE',
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.6),
                      fontFamily: 'monospace',
                      fontSize: 7,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${usage.toStringAsFixed(1)} MB',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontFamily: 'monospace',
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 10),
              Container(
                width: 40,
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Stack(
                  children: [
                    FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: progress,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(0.5),
                              Theme.of(context).colorScheme.primary,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTerminalButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isDark
              ? Theme.of(context).colorScheme.surface
              : AppColors.lightCard,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.5)
                  : Colors.black.withOpacity(0.15),
              offset: const Offset(2, 2),
              blurRadius: 4,
            ),
            BoxShadow(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
              offset: const Offset(-2, -2),
              blurRadius: 4,
            ),
          ],
        ),
        child: Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
          size: 16,
        ),
      ),
    );
  }
}
