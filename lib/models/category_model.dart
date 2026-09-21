import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

enum TransactionType { income, expense, transfer }

/// Fixed key <-> icon lookup for [CategoryModel] persistence.
///
/// Release builds tree-shake icon fonts by statically analyzing which
/// `IconData` *constants* are referenced in code — a dynamically built
/// `IconData(codePoint, fontFamily: ...)` breaks that analysis and fails
/// the build. Storing/loading by a stable string key (which resolves to
/// one of these literal constants) keeps every icon a compile-time
/// constant while still letting categories round-trip through JSON.
class AppCategoryIcons {
  AppCategoryIcons._();

  static const String fallbackKey = 'other';

  static const Map<String, IconData> byKey = {
    'restaurant': Icons.restaurant_rounded,
    'transport': Icons.directions_bus_filled_rounded,
    'shopping': Icons.shopping_bag_rounded,
    'bills': Icons.receipt_long_rounded,
    'healthcare': Icons.local_hospital_rounded,
    'education': Icons.school_rounded,
    'entertainment': Icons.movie_rounded,
    'travel': Icons.flight_takeoff_rounded,
    'housing': Icons.home_rounded,
    'subscriptions': Icons.subscriptions_rounded,
    'other': Icons.category_rounded,
    'salary': Icons.account_balance_wallet_rounded,
    'freelance': Icons.laptop_mac_rounded,
    'business': Icons.storefront_rounded,
    'investment': Icons.trending_up_rounded,
  };

  static IconData resolve(String? key) => byKey[key] ?? byKey[fallbackKey]!;

  static String keyFor(IconData icon) {
    for (final entry in byKey.entries) {
      if (entry.value.fontFamily == icon.fontFamily && entry.value.codePoint == icon.codePoint) {
        return entry.key;
      }
    }
    return fallbackKey;
  }
}

/// A spending/income category. Built-in categories ship with the app;
/// authenticated users may add custom ones.
class CategoryModel {
  final String id;
  final String name;
  final IconData icon;
  final TransactionType type;
  final Color color;
  final bool isActive;
  final bool isCustom;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.type,
    required this.color,
    this.isActive = true,
    this.isCustom = false,
  });

  CategoryModel copyWith({
    String? id,
    String? name,
    IconData? icon,
    TransactionType? type,
    Color? color,
    bool? isActive,
    bool? isCustom,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      type: type ?? this.type,
      color: color ?? this.color,
      isActive: isActive ?? this.isActive,
      isCustom: isCustom ?? this.isCustom,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'iconKey': AppCategoryIcons.keyFor(icon),
        'type': type.name,
        'color': color.value,
        'isActive': isActive,
        'isCustom': isCustom,
      };

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: AppCategoryIcons.resolve(json['iconKey'] as String?),
      type: TransactionType.values.firstWhere((t) => t.name == json['type']),
      color: Color(json['color'] as int),
      isActive: json['isActive'] as bool? ?? true,
      isCustom: json['isCustom'] as bool? ?? false,
    );
  }

  /// Default category catalog. Colors are assigned deterministically by
  /// index into [AppColors.categoryPalette] — never randomly.
  static List<CategoryModel> defaults() {
    const expenseDefs = <String, IconData>{
      'Food': Icons.restaurant_rounded,
      'Transport': Icons.directions_bus_filled_rounded,
      'Shopping': Icons.shopping_bag_rounded,
      'Bills': Icons.receipt_long_rounded,
      'Healthcare': Icons.local_hospital_rounded,
      'Education': Icons.school_rounded,
      'Entertainment': Icons.movie_rounded,
      'Travel': Icons.flight_takeoff_rounded,
      'Housing': Icons.home_rounded,
      'Subscriptions': Icons.subscriptions_rounded,
      'Other': Icons.category_rounded,
    };
    const incomeDefs = <String, IconData>{
      'Salary': Icons.account_balance_wallet_rounded,
      'Freelance': Icons.laptop_mac_rounded,
      'Business': Icons.storefront_rounded,
      'Investment': Icons.trending_up_rounded,
      'Other': Icons.category_rounded,
    };

    final list = <CategoryModel>[];
    var i = 0;
    for (final entry in expenseDefs.entries) {
      list.add(CategoryModel(
        id: 'exp_${entry.key.toLowerCase()}',
        name: entry.key,
        icon: entry.value,
        type: TransactionType.expense,
        color: AppColors.categoryPalette[i % AppColors.categoryPalette.length],
      ));
      i++;
    }
    for (final entry in incomeDefs.entries) {
      list.add(CategoryModel(
        id: 'inc_${entry.key.toLowerCase()}',
        name: entry.key,
        icon: entry.value,
        type: TransactionType.income,
        color: AppColors.categoryPalette[i % AppColors.categoryPalette.length],
      ));
      i++;
    }
    return list;
  }
}
