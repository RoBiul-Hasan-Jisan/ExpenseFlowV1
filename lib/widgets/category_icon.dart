import 'package:flutter/material.dart';
import '../models/category_model.dart';

class CategoryIcon extends StatelessWidget {
  final CategoryModel? category;
  final double size;

  const CategoryIcon({super.key, required this.category, this.size = 40});

  @override
  Widget build(BuildContext context) {
    final color = category?.color ?? Theme.of(context).colorScheme.primary;
    final icon = category?.icon ?? Icons.category_rounded;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: size * 0.5),
    );
  }
}
