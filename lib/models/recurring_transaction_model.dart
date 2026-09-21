import 'category_model.dart';

enum RecurringFrequency { daily, weekly, monthly, yearly }

class RecurringTransactionModel {
  final String id;
  final String name;
  final double amount;
  final String categoryId;
  final TransactionType type;
  final RecurringFrequency frequency;
  final DateTime startDate;
  final DateTime nextDate;
  final bool isActive;

  const RecurringTransactionModel({
    required this.id,
    required this.name,
    required this.amount,
    required this.categoryId,
    required this.type,
    required this.frequency,
    required this.startDate,
    required this.nextDate,
    this.isActive = true,
  });

  /// Returns the next occurrence after [from] the current nextDate,
  /// per the configured frequency. Pure function — deterministic.
  DateTime computeNextOccurrence() {
    switch (frequency) {
      case RecurringFrequency.daily:
        return nextDate.add(const Duration(days: 1));
      case RecurringFrequency.weekly:
        return nextDate.add(const Duration(days: 7));
      case RecurringFrequency.monthly:
        final m = nextDate.month == 12 ? 1 : nextDate.month + 1;
        final y = nextDate.month == 12 ? nextDate.year + 1 : nextDate.year;
        final lastDay = DateTime(y, m + 1, 0).day;
        return DateTime(y, m, nextDate.day > lastDay ? lastDay : nextDate.day);
      case RecurringFrequency.yearly:
        return DateTime(nextDate.year + 1, nextDate.month, nextDate.day);
    }
  }

  int get daysUntilNext => nextDate.difference(DateTime.now()).inDays;

  RecurringTransactionModel copyWith({
    String? id,
    String? name,
    double? amount,
    String? categoryId,
    TransactionType? type,
    RecurringFrequency? frequency,
    DateTime? startDate,
    DateTime? nextDate,
    bool? isActive,
  }) {
    return RecurringTransactionModel(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      type: type ?? this.type,
      frequency: frequency ?? this.frequency,
      startDate: startDate ?? this.startDate,
      nextDate: nextDate ?? this.nextDate,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'amount': amount,
        'categoryId': categoryId,
        'type': type.name,
        'frequency': frequency.name,
        'startDate': startDate.toIso8601String(),
        'nextDate': nextDate.toIso8601String(),
        'isActive': isActive,
      };

  factory RecurringTransactionModel.fromJson(Map<String, dynamic> json) {
    return RecurringTransactionModel(
      id: json['id'] as String,
      name: json['name'] as String,
      amount: (json['amount'] as num).toDouble(),
      categoryId: json['categoryId'] as String,
      type: TransactionType.values.firstWhere((t) => t.name == json['type']),
      frequency: RecurringFrequency.values.firstWhere((f) => f.name == json['frequency']),
      startDate: DateTime.parse(json['startDate'] as String),
      nextDate: DateTime.parse(json['nextDate'] as String),
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}
