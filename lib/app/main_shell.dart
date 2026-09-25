import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../widgets/glass_surface.dart';

/// Bottom-nav shell wrapping the five primary sections, plus the
/// "Add Transaction" FAB shared across all of them.
class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  static const _tabs = ['/dashboard', '/transactions', '/analytics', '/budgets', '/profile'];

  static const _icons = [
    (Icons.home_outlined, Icons.home_rounded, 'Home'),
    (Icons.receipt_long_outlined, Icons.receipt_long_rounded, 'Activity'),
    (Icons.pie_chart_outline_rounded, Icons.pie_chart_rounded, 'Insights'),
    (Icons.savings_outlined, Icons.savings_rounded, 'Budget'),
    (Icons.person_outline_rounded, Icons.person_rounded, 'Profile'),
  ];

  int _indexFor(String location) {
    final idx = _tabs.indexWhere((t) => location.startsWith(t));
    return idx == -1 ? 0 : idx;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _indexFor(location);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBody: true,
      body: child,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Container(
        width: 62,
        height: 62,
        margin: const EdgeInsets.only(top: 26),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppColors.primaryGradient,
          boxShadow: [
            BoxShadow(color: AppColors.primary.withValues(alpha: 0.45), blurRadius: 20, offset: const Offset(0, 8)),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => context.push('/add-transaction'),
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        child: GlassSurface(
          borderRadius: AppTheme.radiusPill,
          blur: 24,
          opacity: isDark ? 0.55 : 0.75,
          tint: isDark ? AppColors.darkSurface : Colors.white,
          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, width: 1),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          child: SizedBox(
            height: 56,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (var i = 0; i < _tabs.length; i++) ...[
                  if (i == 2) const SizedBox(width: 54),
                  _NavItem(
                    outline: _icons[i].$1,
                    filled: _icons[i].$2,
                    label: _icons[i].$3,
                    selected: currentIndex == i,
                    onTap: () => context.go(_tabs[i]),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData outline;
  final IconData filled;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({required this.outline, required this.filled, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = selected ? theme.colorScheme.primary : theme.textTheme.bodySmall?.color;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: selected ? theme.colorScheme.primary.withValues(alpha: 0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radiusPill),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(selected ? filled : outline, color: color, size: 22),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(fontSize: 10, fontWeight: selected ? FontWeight.w700 : FontWeight.w500, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
