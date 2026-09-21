/// A monthly budget — either the overall budget (categoryId == null)
/// or a per-category budget.
class BudgetModel {
  final String id;
  final String? categoryId; // null => overall monthly budget
  final double limit;
  final int month; // 1-12
  final int year;
  final DateTime createdAt;

  const BudgetModel({
    required this.id,
    this.categoryId,
    required this.limit,
    required this.month,
    required this.year,
    required this.createdAt,
  });

  bool get isOverall => categoryId == null;

  BudgetModel copyWith({
    String? id,
    String? categoryId,
    double? limit,
    int? month,
    int? year,
    DateTime? createdAt,
  }) {
    return BudgetModel(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      limit: limit ?? this.limit,
      month: month ?? this.month,
      year: year ?? this.year,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'categoryId': categoryId,
        'limit': limit,
        'month': month,
        'year': year,
        'createdAt': createdAt.toIso8601String(),
      };

  factory BudgetModel.fromJson(Map<String, dynamic> json) {
    return BudgetModel(
      id: json['id'] as String,
      categoryId: json['categoryId'] as String?,
      limit: (json['limit'] as num).toDouble(),
      month: json['month'] as int,
      year: json['year'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

/// Computed (not stored) view of a budget's current standing.
class BudgetProgress {
  final BudgetModel budget;
  final double spent;

  const BudgetProgress({required this.budget, required this.spent});

  double get remaining => budget.limit - spent;
  double get fraction => budget.limit <= 0 ? 0 : (spent / budget.limit).clamp(0, double.infinity);

  BudgetStatus get status {
    if (fraction >= 1.0) return BudgetStatus.exceeded;
    if (fraction >= 0.90) return BudgetStatus.critical;
    if (fraction >= 0.70) return BudgetStatus.warning;
    return BudgetStatus.onTrack;
  }
}

enum BudgetStatus { onTrack, warning, critical, exceeded }
