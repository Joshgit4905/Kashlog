class PlannedPaymentModel {
  final int? id;
  final String title;
  final double amount;
  final DateTime dueDate;
  final bool isPaid;
  final String category;

  PlannedPaymentModel({
    this.id,
    required this.title,
    required this.amount,
    required this.dueDate,
    this.isPaid = false,
    required this.category,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'dueDate': dueDate.toIso8601String(),
      'isPaid': isPaid ? 1 : 0,
      'category': category,
    };
  }

  factory PlannedPaymentModel.fromMap(Map<String, dynamic> map) {
    return PlannedPaymentModel(
      id: map['id'],
      title: map['title'],
      amount: map['amount'],
      dueDate: DateTime.parse(map['dueDate']),
      isPaid: map['isPaid'] == 1,
      category: map['category'],
    );
  }
}
