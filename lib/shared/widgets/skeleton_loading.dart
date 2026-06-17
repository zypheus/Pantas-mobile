import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class SkeletonBox extends StatelessWidget {
  final double height;
  final double width;
  final BorderRadius borderRadius;
  final EdgeInsets margin;

  const SkeletonBox({
    super.key,
    required this.height,
    this.width = double.infinity,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.margin = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: borderRadius,
      ),
    );
  }
}

class SkeletonLine extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius borderRadius;
  final EdgeInsets margin;

  const SkeletonLine({
    super.key,
    this.width = double.infinity,
    this.height = 12,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
    this.margin = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return SkeletonBox(
      height: height,
      width: width,
      borderRadius: borderRadius,
      margin: margin,
    );
  }
}

class SkeletonCard extends StatelessWidget {
  final Widget child;

  const SkeletonCard({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class SkeletonList extends StatelessWidget {
  final int itemCount;
  final double itemHeight;
  final double spacing;
  final EdgeInsets padding;

  const SkeletonList({
    super.key,
    this.itemCount = 4,
    this.itemHeight = 22,
    this.spacing = 14,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: padding,
      itemBuilder: (_, index) => SkeletonCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonBox(
              height: itemHeight * 2.5,
              width: double.infinity,
              borderRadius: BorderRadius.circular(16),
              margin: const EdgeInsets.only(bottom: 12),
            ),
            SkeletonLine(width: double.infinity),
            const SizedBox(height: 8),
            SkeletonLine(width: 150),
          ],
        ),
      ),
      separatorBuilder: (_, __) => SizedBox(height: spacing),
      itemCount: itemCount,
    );
  }
}

class SkeletonPage extends StatelessWidget {
  final List<Widget> children;

  const SkeletonPage({
    super.key,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}
