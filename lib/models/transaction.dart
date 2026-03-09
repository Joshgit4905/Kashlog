class TransactionModel {
  final int? id;
  final double amount;
  final String type; // 'income' or 'expense'
  final String category;
  final DateTime date;
  final String? description;
  final double? originalAmount;
  final String? originalCurrency;
  final double? exchangeRate;

  TransactionModel({
    this.id,
    required this.amount,
    required this.type,
    required this.category,
    required this.date,
    this.description,
    this.originalAmount,
    this.originalCurrency,
    this.exchangeRate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'type': type,
      'category': category,
      'date': date.toIso8601String(),
      'description': description,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'],
      amount: map['amount'],
      type: map['type'],
      category: map['category'],
      date: DateTime.parse(map['date']),
      description: map['description'],
      originalAmount: map['originalAmount'],
      originalCurrency: map['originalCurrency'],
      exchangeRate: map['exchangeRate'],
    );
  }
}
