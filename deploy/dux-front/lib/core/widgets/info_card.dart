import 'package:flutter/material.dart';
import '../theme/app_sizes.dart';

class InfoCard extends StatelessWidget {
  final Widget child;
  final String? title;
  final IconData? icon;
  final List<Widget>? actions;
  final EdgeInsetsGeometry padding;

  const InfoCard({
    super.key,
    required this.child,
    this.title,
    this.icon,
    this.actions,
    this.padding = const EdgeInsets.all(AppSpacing.l),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: AppBorderRadius.roundedL, // 16px
        border: Border.all(
          color: theme.colorScheme.outline,
          width: 1,
        ),
        boxShadow: AppShadows.softShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null || icon != null || actions != null) ...[
            Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.l,
                right: AppSpacing.l,
                top: AppSpacing.l,
                bottom: AppSpacing.s,
              ),
              child: Row(
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                    AppSpacing.gapS,
                  ],
                  if (title != null)
                    Expanded(
                      child: Text(
                        title!,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ...?actions,
                ],
              ),
            ),
            const Divider(height: 1),
          ],
          Padding(
            padding: padding,
            child: child,
          ),
        ],
      ),
    );
  }
}
