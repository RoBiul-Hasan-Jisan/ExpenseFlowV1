import 'category_model.dart';
export 'category_model.dart';

/// Immutable transaction record. Amount is always stored positive;
/// [type] determines sign in calculations.
class TransactionModel {
  final String id;
  final TransactionType type;
  final double amount;
  final String categoryId;
  final String title;
  final String? description;
  final DateTime date;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> tags;
  final String? receiptUrl;
  final bool isRecurring;
  final String? recurringId;

  const TransactionModel({
    required this.id,
    required this.type,
    required this.amount,
    required this.categoryId,
    required this.title,
    this.description,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
    this.tags = const [],
    this.receiptUrl,
    this.isRecurring = false,
    this.recurringId,
  });

  /// Signed amount for cash-flow math: income positive, expense negative,
  /// transfer treated as neutral (0) for net worth purposes.
  double get signedAmount {
    switch (type) {
      case TransactionType.income:
        return amount;
      case TransactionType.expense:
        return -amount;
      case TransactionType.transfer:
        return 0;
    }
  }

  TransactionModel copyWith({
    String? id,
    TransactionType? type,
    double? amount,
    String? categoryId,
    String? title,
    String? description,
    DateTime? date,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? tags,
    String? receiptUrl,
    bool? isRecurring,
    String? recurringId,
    bool clearReceipt = false,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      tags: tags ?? this.tags,
      receiptUrl: clearReceipt ? null : (receiptUrl ?? this.receiptUrl),
      isRecurring: isRecurring ?? this.isRecurring,
      recurringId: recurringId ?? this.recurringId,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'amount': amount,
        'categoryId': categoryId,
        'title': title,
        'description': description,
        'date': date.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'tags': tags,
        'receiptUrl': receiptUrl,
        'isRecurring': isRecurring,
        'recurringId': recurringId,
      };

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as String,
      type: TransactionType.values.firstWhere((t) => t.name == json['type']),
      amount: (json['amount'] as num).toDouble(),
      categoryId: json['categoryId'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      date: DateTime.parse(json['date'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      tags: (json['tags'] as List?)?.map((e) => e as String).toList() ?? const [],
      receiptUrl: json['receiptUrl'] as String?,
      isRecurring: json['isRecurring'] as bool? ?? false,
      recurringId: json['recurringId'] as String?,
    );
  }
}
