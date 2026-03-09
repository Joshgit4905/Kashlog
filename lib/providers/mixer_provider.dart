import 'package:flutter/foundation.dart';
import '../models/transaction.dart';

class MixerCategory {
  final String name;
  double percentage; // 0.0 to 1.0
  double amount;

  MixerCategory({required this.name, this.percentage = 0.0, this.amount = 0.0});
}

class MixerProvider with ChangeNotifier {
  List<MixerCategory> _categories = [];
  List<String> _availableCategories = [];
  double _totalBalance = 0.0;
  bool _isLocked = false;
  bool _isInitialized = false;

  List<MixerCategory> get categories => _categories;
  List<String> get availableCategories => _availableCategories;
  double get totalBalance => _totalBalance;
  bool get isLocked => _isLocked;
  bool get isInitialized => _isInitialized;

  void setLocked(bool value) {
    _isLocked = value;
    notifyListeners();
  }

  static const List<String> _defaultExpenseCategories = [
    'Comida',
    'Transporte',
    'Salud',
    'Ocio',
    'Hogar',
    'Renta',
    'Educación',
    'Regalos',
    'Otros',
  ];

  void initialize(double balance, List<TransactionModel> transactions) {
    _totalBalance = balance;

    // Group transactions by category to get initial distribution
    final Map<String, double> categoryTotals = {};
    double totalSpent = 0;

    for (var tx in transactions) {
      if (tx.type == 'Gasto') {
        categoryTotals[tx.category] =
            (categoryTotals[tx.category] ?? 0) + tx.amount;
        totalSpent += tx.amount;
      }
    }

    // Available categories should always include defaults plus any found in history
    final Set<String> allCategoriesPool = Set.from(_defaultExpenseCategories);
    allCategoriesPool.addAll(categoryTotals.keys);
    _availableCategories = allCategoriesPool.toList()..sort();

    if (totalSpent == 0) {
      // Default initial categories if no data
      _categories = [
        MixerCategory(name: 'Comida', percentage: 0.2, amount: balance * 0.2),
        MixerCategory(
          name: 'Transporte',
          percentage: 0.2,
          amount: balance * 0.2,
        ),
        MixerCategory(name: 'Renta', percentage: 0.4, amount: balance * 0.4),
        MixerCategory(name: 'Ocio', percentage: 0.2, amount: balance * 0.2),
      ];
    } else {
      _categories = categoryTotals.entries.map((e) {
        final p = e.value / totalSpent;
        return MixerCategory(name: e.key, percentage: p, amount: balance * p);
      }).toList();
    }
    _isInitialized = true;
    notifyListeners();
  }

  void addCategory(String name) {
    if (_categories.any((c) => c.name == name)) return;

    // Initial percentage for new category is 0%
    _categories.add(MixerCategory(name: name, percentage: 0.0, amount: 0.0));
    notifyListeners();
  }

  void removeCategory(int index) {
    if (_categories.length <= 1) return;

    final removedPercentage = _categories[index].percentage;
    _categories.removeAt(index);

    // Redistribute the removed percentage to others
    if (_categories.isNotEmpty) {
      double sumRemaining = _categories.fold(
        0,
        (sum, item) => sum + item.percentage,
      );
      if (sumRemaining > 0) {
        for (var cat in _categories) {
          cat.percentage +=
              (removedPercentage * (cat.percentage / sumRemaining));
          cat.amount = _totalBalance * cat.percentage;
        }
      } else {
        // If all others were 0, share equally
        double equalShare = removedPercentage / _categories.length;
        for (var cat in _categories) {
          cat.percentage = equalShare;
          cat.amount = _totalBalance * cat.percentage;
        }
      }
    }
    notifyListeners();
  }

  void updateFader(int index, double newValue) {
    if (_isLocked || _categories.isEmpty) return;

    newValue = newValue.clamp(0.0, 1.0);
    final double oldValue = _categories[index].percentage;
    final double delta = newValue - oldValue;

    // The sum of other percentages
    double sumOthers = 0;
    for (int i = 0; i < _categories.length; i++) {
      if (i != index) sumOthers += _categories[i].percentage;
    }

    _categories[index].percentage = newValue;
    _categories[index].amount = _totalBalance * newValue;

    if (sumOthers > 0) {
      for (int i = 0; i < _categories.length; i++) {
        if (i != index) {
          final double pOld = _categories[i].percentage;
          // Proportionally subtract the delta from others
          final double pNew = (pOld - (delta * (pOld / sumOthers))).clamp(
            0.0,
            1.0,
          );
          _categories[i].percentage = pNew;
          _categories[i].amount = _totalBalance * pNew;
        }
      }
    } else {
      // Redistribute delta equally if others are all zero
      final int othersCount = _categories.length - 1;
      for (int i = 0; i < _categories.length; i++) {
        if (i != index) {
          final double pNew = (0.0 - (delta / othersCount)).clamp(0.0, 1.0);
          _categories[i].percentage = pNew;
          _categories[i].amount = _totalBalance * pNew;
        }
      }
    }

    // Normalize to ensure exact 1.0 sum (floating point drift correction)
    double total = _categories.fold(0, (sum, item) => sum + item.percentage);
    if (total > 0) {
      for (var cat in _categories) {
        cat.percentage /= total;
        cat.amount = _totalBalance * cat.percentage;
      }
    }

    notifyListeners();
  }
}
