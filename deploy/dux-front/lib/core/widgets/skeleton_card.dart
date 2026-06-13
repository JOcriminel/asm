import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_sizes.dart';

class SkeletonCard extends StatelessWidget {
  final double height;
  
  const SkeletonCard({super.key, this.height = 140});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.m),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      color: Colors.transparent,
      child: Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: Colors.white, // Needs a solid color for shimmer to work
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(AppSpacing.l),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(width: 120, height: 20, color: Colors.white),
                  Container(
                    width: 80,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ],
              ),
              AppSpacing.gapL,
              Container(width: double.infinity, height: 16, color: Colors.white),
              AppSpacing.gapS,
              Container(width: 200, height: 16, color: Colors.white),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(width: 100, height: 14, color: Colors.white),
                  Container(width: 60, height: 20, color: Colors.white),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
