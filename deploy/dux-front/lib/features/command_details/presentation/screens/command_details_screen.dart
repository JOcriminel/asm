import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:dux_front/core/theme/app_sizes.dart';
import 'package:dux_front/core/widgets/info_card.dart';
import 'package:dux_front/core/widgets/section_header.dart';
import 'package:dux_front/core/widgets/status_badge.dart';
import 'package:dux_front/core/widgets/loading_skeleton.dart';
import 'package:dux_front/core/widgets/error_state_widget.dart';
import '../controllers/command_details_controller.dart';

class CommandDetailsScreen extends ConsumerWidget {
  final String commandId;

  const CommandDetailsScreen({
    super.key,
    required this.commandId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(commandDetailsControllerProvider(commandId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Command Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/commands');
            }
          },
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 768;

          if (state.isLoading && state.command == null) {
            return _buildLoadingState();
          }

          if (state.error != null && state.command == null) {
            return ErrorStateWidget(
              description: state.error!,
              onRetry: () => ref.read(commandDetailsControllerProvider(commandId).notifier).fetchDetails(commandId),
            );
          }

          final command = state.command!;
          final formattedDate = DateFormat('MMMM dd, yyyy').format(command.date);

          Widget content = RefreshIndicator(
            onRefresh: () => ref.read(commandDetailsControllerProvider(commandId).notifier).fetchDetails(commandId),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.l),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Block
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.l),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: AppBorderRadius.roundedL,
                      border: Border.all(color: theme.colorScheme.outline),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              command.documentCode,
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Courier',
                              ),
                            ),
                            StatusBadge(status: command.status),
                          ],
                        ),
                        AppSpacing.gapS,
                        Text(
                          command.customerName,
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        AppSpacing.gapXs,
                        Text(
                          'Ordered on $formattedDate',
                          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.secondary),
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.gapL,

                  // Timeline Stepper Block
                  SectionHeader(title: 'Order Timeline'),
                  _buildTimelineWidget(theme, command.timeline),
                  AppSpacing.gapL,

                  // Details Block (Responsive layout splitting)
                  isWide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildInfoSection(theme, command)),
                            AppSpacing.gapL,
                            Expanded(child: _buildSummarySection(theme, command)),
                          ],
                        )
                      : Column(
                          children: [
                            _buildInfoSection(theme, command),
                            AppSpacing.gapL,
                            _buildSummarySection(theme, command),
                          ],
                        ),
                  AppSpacing.gapL,

                  // Articles List Section
                  SectionHeader(title: 'Articles & Items'),
                  _buildArticlesList(theme, command.articles),
                  AppSpacing.gapXxl,
                ],
              ),
            ),
          );

          if (isWide) {
            return Center(
              child: SizedBox(
                width: 900,
                child: content,
              ),
            );
          }

          return content;
        },
      ),
    );
  }

  Widget _buildTimelineWidget(ThemeData theme, dynamic timeline) {
    final stages = [
      {'title': 'Created', 'date': timeline.created},
      {'title': 'Validated', 'date': timeline.validated},
      {'title': 'Delivered', 'date': timeline.delivered},
    ];

    return InfoCard(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.l, horizontal: AppSpacing.s),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(stages.length, (index) {
          final stage = stages[index];
          final date = stage['date'] as DateTime?;
          final isCompleted = date != null;

          return Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: index == 0
                            ? Colors.transparent
                            : (isCompleted ? theme.colorScheme.primary : theme.colorScheme.outline),
                        thickness: 2,
                      ),
                    ),
                    Icon(
                      isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: isCompleted ? theme.colorScheme.primary : theme.colorScheme.secondary,
                      size: 24,
                    ),
                    Expanded(
                      child: Divider(
                        color: index == stages.length - 1
                            ? Colors.transparent
                            : (stages[index + 1]['date'] != null
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outline),
                        thickness: 2,
                      ),
                    ),
                  ],
                ),
                AppSpacing.gapS,
                Text(
                  stage['title'] as String,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
                    color: isCompleted ? theme.colorScheme.onBackground : theme.colorScheme.secondary,
                  ),
                ),
                if (isCompleted) ...[
                  AppSpacing.gapXs,
                  Text(
                    DateFormat('MMM dd, HH:mm').format(date),
                    style: theme.textTheme.labelMedium?.copyWith(fontSize: 10, color: theme.colorScheme.secondary),
                  ),
                ],
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildInfoSection(ThemeData theme, dynamic command) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'Logistics Information'),
        InfoCard(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l, vertical: AppSpacing.s),
          child: Column(
            children: [
              _buildInfoRow(theme, Icons.trending_up, 'Customer Tier', command.tier),
              const Divider(),
              _buildInfoRow(theme, Icons.badge_outlined, 'Representative', command.representative),
              const Divider(),
              _buildInfoRow(theme, Icons.local_shipping_outlined, 'Delivery Address', command.deliveryAddress),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummarySection(ThemeData theme, dynamic command) {
    final currencyFormat = NumberFormat.currency(symbol: '€', decimalDigits: 2);
    final ht = currencyFormat.format(command.totalHT);
    final vat = currencyFormat.format(command.vat);
    final ttc = currencyFormat.format(command.totalTTC);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'Payment Summary'),
        InfoCard(
          padding: const EdgeInsets.all(AppSpacing.l),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total HT', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.secondary)),
                  Text(ht, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                ],
              ),
              AppSpacing.gapM,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('VAT (20%)', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.secondary)),
                  Text(vat, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                ],
              ),
              AppSpacing.gapM,
              const Divider(),
              AppSpacing.gapM,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total TTC', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  Text(
                    ttc,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildArticlesList(ThemeData theme, dynamic articles) {
    final currencyFormat = NumberFormat.currency(symbol: '€', decimalDigits: 2);

    return InfoCard(
      padding: EdgeInsets.zero,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: articles.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final item = articles[index];
          final price = currencyFormat.format(item.unitPrice);
          final total = currencyFormat.format(item.total);

          return Padding(
            padding: const EdgeInsets.all(AppSpacing.l),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      AppSpacing.gapXs,
                      Text(
                        'SKU: ${item.code} | Qty: ${item.quantity} x $price',
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.secondary),
                      ),
                    ],
                  ),
                ),
                Text(
                  total,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onBackground,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(ThemeData theme, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: theme.colorScheme.primary, size: 20),
          AppSpacing.gapM,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.secondary)),
                AppSpacing.gapXs,
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onBackground,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const LoadingSkeleton(height: 120, width: double.infinity),
          AppSpacing.gapL,
          const LoadingSkeleton(height: 24, width: 140),
          AppSpacing.gapM,
          const LoadingSkeleton(height: 100, width: double.infinity),
          AppSpacing.gapL,
          const LoadingSkeleton(height: 24, width: 180),
          AppSpacing.gapM,
          const LoadingSkeleton(height: 200, width: double.infinity),
        ],
      ),
    );
  }
}
