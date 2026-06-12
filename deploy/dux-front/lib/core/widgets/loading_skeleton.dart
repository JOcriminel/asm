import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_sizes.dart';

class LoadingSkeleton extends StatelessWidget {
  final double height;
  final double width;
  final BorderRadius? borderRadius;
  final BoxShape shape;

  const LoadingSkeleton({
    super.key,
    required this.height,
    required this.width,
    this.borderRadius,
    this.shape = BoxShape.rectangle,
  });

  const LoadingSkeleton.circular({
    super.key,
    required double size,
  })  : height = size,
        width = size,
        borderRadius = null,
        shape = BoxShape.circle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: baseColor,
          shape: shape,
          borderRadius: shape == BoxShape.circle
              ? null
              : (borderRadius ?? AppBorderRadius.roundedM),
        ),
      ),
    );
  }
}
