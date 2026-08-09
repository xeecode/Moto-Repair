class Expense {
  int? id;
  String title;
  double amount;
  String category; // Rent, Electricity, Salary, Other
  String note;
  DateTime date;

  Expense({
    this.id,
    required this.title,
    required this.amount,
    required this.category,
    this.note = '',
    DateTime? date,
  }) : date = date ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'category': category,
      'note': note,
      'date': date.toIso8601String(),
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as int?,
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      category: map['category'] as String,
      note: map['note'] as String? ?? '',
      date: DateTime.parse(map['date'] as String),
    );
  }
}
