import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../models/planned_payment.dart';
import '../services/database_helper.dart';
import '../services/notification_service.dart';
import '../services/home_widget_service.dart';
import '../services/log_stream_service.dart';

class TransactionProvider with ChangeNotifier {
  List<TransactionModel> _transactions = [];
  List<PlannedPaymentModel> _plannedPayments = [];
  Map<String, double> _budgets = {};
  double _emergencyFundTarget = 0;
  double _emergencyFundCurrent = 0;
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final NotificationService _notifService = NotificationService();

  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  List<TransactionModel> get transactions => _transactions;
  List<PlannedPaymentModel> get plannedPayments => _plannedPayments;
  Map<String, double> get budgets => _budgets;
  DateTime get selectedMonth => _selectedMonth;
  double get emergencyFundTarget => _emergencyFundTarget;
  double get emergencyFundCurrent => _emergencyFundCurrent;

  TransactionProvider() {
    _initNotifications();
    fetchTransactions();
  }

  Future<void> _initNotifications() async {
    await _notifService.init();
  }

  List<TransactionModel> get filteredTransactions {
    return _transactions.where((tx) {
      return tx.date.year == _selectedMonth.year &&
          tx.date.month == _selectedMonth.month;
    }).toList();
  }

  double get totalBalance {
    double total = 0;
    for (var tx in _transactions) {
      if (tx.type == 'Ingreso') {
        total += tx.amount;
      } else {
        total -= tx.amount;
      }
    }
    return total;
  }

  double get monthlyIncome {
    return filteredTransactions
        .where((tx) => tx.type == 'Ingreso')
        .fold(0.0, (sum, tx) => sum + tx.amount);
  }

  double get monthlyExpenses {
    return filteredTransactions
        .where((tx) => tx.type == 'Gasto')
        .fold(0.0, (sum, tx) => sum + tx.amount);
  }

  double get totalIncome => _transactions
      .where((tx) => tx.type == 'Ingreso')
      .fold(0.0, (sum, tx) => sum + tx.amount);
  double get totalExpenses => _transactions
      .where((tx) => tx.type == 'Gasto')
      .fold(0.0, (sum, tx) => sum + tx.amount);

  Map<DateTime, double> get lastSixMonthsExpenses {
    Map<DateTime, double> data = {};
    final now = DateTime.now();
    for (int i = 5; i >= 0; i--) {
      final date = DateTime(now.year, now.month - i);
      final monthData = _transactions
          .where((tx) {
            return tx.type == 'Gasto' &&
                tx.date.year == date.year &&
                tx.date.month == date.month;
          })
          .fold(0.0, (sum, tx) => sum + tx.amount);
      data[date] = monthData;
    }
    return data;
  }

  Future<void> fetchTransactions() async {
    _transactions = await _dbHelper.getTransactions();
    _plannedPayments = await _dbHelper.getPlannedPayments();
    final budgetData = await _dbHelper.getBudgets();
    _budgets = {
      for (var b in budgetData)
        b['category'] as String: b['limit_amount'] as double,
    };

    final savingsData = await _dbHelper.getSavingsGoals();
    if (savingsData.isNotEmpty) {
      _emergencyFundTarget = savingsData.first['target_amount'] as double;
      _emergencyFundCurrent = savingsData.first['current_amount'] as double;
    }

    // Update Home Widget
    _updateWidget();

    notifyListeners();
    LogStreamService.log(
      '[PROVIDER] Data Refresh: Balance is \$${totalBalance.toStringAsFixed(2)}',
    );
  }

  void _updateWidget() {
    final balanceStr = '\$${totalBalance.toStringAsFixed(2)}';
    HomeWidgetService.updateWidget(balance: balanceStr);
  }

  void setSelectedMonth(DateTime month) {
    _selectedMonth = DateTime(month.year, month.month);
    notifyListeners();
  }

  Future<void> addTransaction(TransactionModel transaction) async {
    LogStreamService.log(
      '[UI] Action: Adding Transaction - ${transaction.type}',
    );
    await _dbHelper.insertTransaction(transaction);
    await fetchTransactions();
  }

  Future<void> deleteTransaction(int id) async {
    LogStreamService.log('[UI] Action: Deleting Transaction ID $id');
    await _dbHelper.deleteTransaction(id);
    await fetchTransactions();
  }

  Future<void> clearAllTransactions() async {
    await _dbHelper.deleteAllTransactions();
    await fetchTransactions();
  }

  // Planned Payments Logic
  Future<void> addPlannedPayment(PlannedPaymentModel payment) async {
    LogStreamService.log(
      '[UI] Action: Adding Planned Payment - ${payment.title}',
    );
    final id = await _dbHelper.insertPlannedPayment(payment);
    // Schedule notification for the due date (morning)
    try {
      await _notifService.scheduleNotification(
        id,
        'Recordatorio de Pago: ${payment.title}',
        'Hoy vence tu pago de ${payment.category} por un monto de ${payment.amount}',
        payment.dueDate.add(const Duration(hours: 9)), // 9 AM of due date
      );
    } catch (e) {
      LogStreamService.log(
        '[ERROR] Failed to schedule notification: $e',
        type: 'EXCEPTION',
      );
      debugPrint('Error scheduling notification: $e');
    }
    await fetchTransactions();
  }

  Future<void> deletePlannedPayment(int id) async {
    LogStreamService.log('[UI] Action: Deleting Planned Payment ID $id');
    try {
      await _notifService.cancelNotification(id);
    } catch (e) {
      LogStreamService.log(
        '[ERROR] Failed to cancel notification: $e',
        type: 'EXCEPTION',
      );
      debugPrint('Error cancelling notification: $e');
    }
    await _dbHelper.deletePlannedPayment(id);
    await fetchTransactions();
  }

  Future<void> togglePaymentStatus(int id, bool isPaid) async {
    await _dbHelper.updatePlannedPaymentStatus(id, isPaid);
    if (isPaid) {
      try {
        await _notifService.cancelNotification(id);
      } catch (e) {
        debugPrint('Error cancelling notification: $e');
      }
    }
    await fetchTransactions();
  }

  // Budget Logic
  Future<void> setBudget(String category, double limit) async {
    await _dbHelper.setBudget(category, limit);
    await fetchTransactions();
  }

  Future<void> updateEmergencyFund(double target, double current) async {
    await _dbHelper.updateSavingsGoal('Fondo de Emergencia', target, current);
    await fetchTransactions();
  }

  // CSV Export Logic
  Future<void> exportToCSV() async {
    List<List<dynamic>> rows = [];

    // Header
    rows.add(["ID", "Tipo", "Monto", "Categoría", "Descripción", "Fecha"]);

    for (var tx in _transactions) {
      rows.add([
        tx.id,
        tx.type,
        tx.amount,
        tx.category,
        tx.description ?? '',
        DateFormat('yyyy-MM-dd').format(tx.date),
      ]);
    }

    String csvData = const ListToCsvConverter().convert(rows);
    final dateStr = DateFormat('yyyyMMdd').format(DateTime.now());

    await Share.shareXFiles([
      XFile.fromData(
        Uint8List.fromList(csvData.codeUnits),
        name: 'KashLog_Backup_$dateStr.csv',
        mimeType: 'text/csv',
      ),
    ], subject: 'Exportación de Datos KashLog');
  }
}
