import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// Simple shimmer-free skeleton block used across loading states.
class SkeletonBox extends StatefulWidget {
  final double height;
  final double? width;
  final BorderRadius? borderRadius;

  const SkeletonBox({super.key, required this.height, this.width, this.borderRadius});

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.surfaceContainerHighest;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
            color: base.withValues(alpha: 0.4 + 0.3 * _controller.value),
            borderRadius: widget.borderRadius ?? BorderRadius.circular(AppTheme.radiusSm),
          ),
        );
      },
    );
  }
}

class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(AppTheme.space(2)),
      children: [
        const SkeletonBox(height: 150, borderRadius: BorderRadius.all(Radius.circular(20))),
        SizedBox(height: AppTheme.space(2)),
        Row(children: [
          Expanded(child: const SkeletonBox(height: 90)),
          SizedBox(width: AppTheme.space(2)),
          Expanded(child: const SkeletonBox(height: 90)),
          SizedBox(width: AppTheme.space(2)),
          Expanded(child: const SkeletonBox(height: 90)),
        ]),
        SizedBox(height: AppTheme.space(2)),
        const SkeletonBox(height: 220),
        SizedBox(height: AppTheme.space(2)),
        const SkeletonBox(height: 160),
      ],
    );
  }
}

class ListSkeleton extends StatelessWidget {
  final int count;
  const ListSkeleton({super.key, this.count = 6});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: EdgeInsets.all(AppTheme.space(2)),
      itemCount: count,
      separatorBuilder: (_, __) => SizedBox(height: AppTheme.space(1.5.round())),
      itemBuilder: (_, __) => const SkeletonBox(height: 64),
    );
  }
}
