import 'package:flutter/material.dart';
import 'package:dux_front/core/theme/app_sizes.dart';

class DuxFooter extends StatelessWidget {
  const DuxFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.l),
      child: Center(
        child: Text(
          'All Soft Multimedia © 2026 · Propulsé par DUX',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.secondary,
              ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
