import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:dux_front/core/theme/app_sizes.dart';
import 'package:dux_front/core/widgets/info_card.dart';
import 'package:dux_front/core/widgets/section_header.dart';
import 'package:dux_front/core/widgets/dux_app_bar_title.dart';
import 'package:dux_front/core/widgets/status_badge.dart';
import 'package:dux_front/core/widgets/loading_skeleton.dart';
import 'package:dux_front/core/widgets/error_state_widget.dart';
import 'package:dux_front/core/routing/route_constants.dart';
import '../controllers/bon_sortie_detail_controller.dart';
import '../../domain/models/bon_sortie.dart';
import 'package:dux_front/core/services/screen_config_controller.dart';
import 'package:dux_front/core/theme/theme_helper.dart';

class BonSortieDetailScreen extends ConsumerWidget {
  final String sortieId;

  const BonSortieDetailScreen({
    super.key,
    required this.sortieId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(bonSortieDetailControllerProvider(sortieId));
    final configState = ref.watch(screenConfigControllerProvider);
    final bsConfig = configState.configs['BS'];
    final pageTitle = bsConfig?.detailPageTitle ?? 'BS-D';

    final dynamicTheme = getDynamicTheme(context, bsConfig?.primaryColor);

    return Theme(
      data: dynamicTheme,
      child: Scaffold(
      appBar: AppBar(
        title: DuxAppBarTitle(title: pageTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.goNamed(RouteNames.bonSortieList);
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Actualiser',
            onPressed: () =>
                ref.read(bonSortieDetailControllerProvider(sortieId).notifier).fetchDetails(),
          ),
          IconButton(
            icon: const Icon(Icons.wifi, color: Colors.green),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.home_outlined),
            onPressed: () => context.go('/dashboard'),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 768;

          if (state.isLoading && state.sortie == null) {
            return _buildLoadingState();
          }

          if (state.error != null && state.sortie == null) {
            return ErrorStateWidget(
              description: state.error!,
              onRetry: () => ref
                  .read(bonSortieDetailControllerProvider(sortieId).notifier)
                  .fetchDetails(),
            );
          }

          final sortie = state.sortie!;
          final formattedDate =
              DateFormat('MMMM dd, yyyy').format(sortie.date);

          Widget content = RefreshIndicator(
            onRefresh: () => ref
                .read(bonSortieDetailControllerProvider(sortieId).notifier)
                .fetchDetails(),
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
                            Expanded(
                              child: Text(
                                sortie.documentCode,
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Courier',
                                  fontSize: 32,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            AppSpacing.gapS,
                            StatusBadge(status: sortie.status),
                          ],
                        ),
                        AppSpacing.gapS,
                        Text(
                          sortie.customerName,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 26,
                          ),
                        ),
                        AppSpacing.gapXs,
                        Text(
                          'Sorti le $formattedDate',
                          style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.secondary),
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.gapL,

                  // Details Block (Responsive Layout)
                  isWide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                                child: _buildDocDetailsCard(theme, sortie)),
                            AppSpacing.gapL,
                            Expanded(
                                child: _buildClientDetailsCard(theme, sortie)),
                          ],
                        )
                      : Column(
                          children: [
                            _buildDocDetailsCard(theme, sortie),
                            AppSpacing.gapL,
                            _buildClientDetailsCard(theme, sortie),
                          ],
                        ),
                  AppSpacing.gapL,

                  // Articles Section
                  SectionHeader(title: 'Articles & Lignes de Sortie'),
                  _buildArticlesList(context, theme, sortie.articles),
                  AppSpacing.gapL,

                  // Summary Section at the bottom
                  _buildSummarySection(theme, sortie),
                  AppSpacing.gapXxl,
                ],
              ),
            ),
          );

          if (isWide) {
            return Center(
              child: SizedBox(
                width: 950,
                child: content,
              ),
            );
          }

          return content;
        },
      ),
    ),
  );
}

  Widget _buildDocDetailsCard(ThemeData theme, BonSortie sortie) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final formattedDocDate = dateFormat.format(sortie.date);
    final formattedDelivDate = sortie.timeline.delivered != null
        ? dateFormat.format(sortie.timeline.delivered!)
        : 'N/A';

    return Theme(
      data: theme.copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        initiallyExpanded: false,
        title: const SectionHeader(title: 'Détails du Document'),
        children: [
          InfoCard(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.l, vertical: AppSpacing.s),
            child: Column(
              children: [
                _buildInfoRow(theme, Icons.calendar_today_outlined,
                    'Date document', formattedDocDate),
                const Divider(),
                _buildInfoRow(theme, Icons.receipt_long_outlined, 'Pièce',
                    sortie.codePiece ?? sortie.documentCode),
                const Divider(),
                _buildInfoRow(theme, Icons.info_outline, 'Etat Document',
                    sortie.status),
                const Divider(),
                _buildInfoRow(theme, Icons.person_outline, 'Préparé par',
                    sortie.preparedBy ?? 'N/A'),
                const Divider(),
                _buildInfoRow(theme, Icons.badge_outlined, 'Représentant',
                    sortie.representative),
                const Divider(),
                _buildInfoRow(theme, Icons.local_shipping_outlined,
                    'Date livraison', formattedDelivDate),
                const Divider(),
                _buildInfoRow(
                    theme,
                    Icons.storefront_outlined,
                    'Station',
                    sortie.stationName.isNotEmpty
                        ? sortie.stationName
                        : 'N/A'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientDetailsCard(ThemeData theme, BonSortie sortie) {
    return Theme(
      data: theme.copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        initiallyExpanded: false,
        title: const SectionHeader(title: 'Détails du Client'),
        children: [
          InfoCard(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.l, vertical: AppSpacing.s),
            child: Column(
              children: [
                _buildInfoRow(
                    theme,
                    Icons.business_outlined,
                    'Raison sociale',
                    sortie.clientRaisonSociale ?? sortie.customerName),
                const Divider(),
                _buildInfoRow(theme, Icons.gavel_outlined, 'Matricule fiscale',
                    sortie.clientTaxNumber ?? 'N/A'),
                const Divider(),
                _buildInfoRow(
                    theme,
                    Icons.location_on_outlined,
                    'Adresse',
                    sortie.clientAddress ?? sortie.deliveryAddress),
                const Divider(),
                _buildInfoRow(
                    theme,
                    Icons.phone_outlined,
                    'Téléphone',
                    sortie.clientPhone ??
                        (sortie.phone.isNotEmpty ? sortie.phone : 'N/A')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection(ThemeData theme, BonSortie sortie) {
    final currencyFormat = NumberFormat.currency(
      locale: 'fr_TN',
      symbol: 'DT',
      decimalDigits: 3,
    );
    final ht = currencyFormat.format(sortie.totalHT);
    final vat = currencyFormat.format(sortie.vat);
    final ttc = currencyFormat.format(sortie.totalTTC);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'Récapitulatif Financier'),
        InfoCard(
          padding: const EdgeInsets.all(AppSpacing.l),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total HT',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: theme.colorScheme.secondary)),
                  Text(ht,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                ],
              ),
              AppSpacing.gapM,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('TVA',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: theme.colorScheme.secondary)),
                  Text(vat,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                ],
              ),
              AppSpacing.gapM,
              const Divider(),
              AppSpacing.gapM,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total TTC',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
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

  Widget _buildArticlesList(
    BuildContext context,
    ThemeData theme,
    List<SortieArticle> articles,
  ) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: articles.length,
      itemBuilder: (context, index) {
        final item = articles[index];
        final totalQte = item.quantity;

        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.m),
          child: InfoCard(
            padding: EdgeInsets.zero,
            child: Theme(
              data: theme.copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                title: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    AppSpacing.gapS,
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Qté: $totalQte',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
                childrenPadding:
                    const EdgeInsets.all(AppSpacing.l).copyWith(top: 0),
                children: [
                  const Divider(height: 20),
                  _buildFieldRow('Code Article', item.code),
                  _buildFieldRow(
                      'Quantité', '$totalQte ${item.unite ?? "U"}'),
                  if (item.netHT != null)
                    _buildFieldRow(
                        'Net HT',
                        NumberFormat.currency(
                                locale: 'fr_TN',
                                symbol: 'DT',
                                decimalDigits: 3)
                            .format(item.netHT)),
                  if (item.totalTTC != null)
                    _buildFieldRow(
                        'Total TTC',
                        NumberFormat.currency(
                                locale: 'fr_TN',
                                symbol: 'DT',
                                decimalDigits: 3)
                            .format(item.totalTTC)),
                  if (item.tvaPercent != null)
                    _buildFieldRow('TVA', '${item.tvaPercent}%'),
                  if (item.discountPercent != null &&
                      item.discountPercent! > 0)
                    _buildFieldRow('Remise', '${item.discountPercent}%'),
                  if (item.familyName != null && item.familyName!.isNotEmpty)
                    _buildFieldRow('Famille', item.familyName!),
                  // Serial Numbers Section
                  _buildSerialNumbersSection(theme, item),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSerialNumbersSection(ThemeData theme, SortieArticle item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 20),
        Row(
          children: [
            Icon(Icons.qr_code_2_rounded,
                size: 16, color: theme.colorScheme.primary),
            const SizedBox(width: 6),
            Text(
              'Numéros de Série',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: item.serialNumbers.isEmpty
                    ? theme.colorScheme.surfaceContainerHighest
                    : theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                item.serialNumbers.isEmpty ? '…' : '${item.serialNumbers.length}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: item.serialNumbers.isEmpty
                      ? theme.colorScheme.onSurfaceVariant
                      : theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (item.serialNumbers.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Aucun numéro de série',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          )
        else
          ...item.serialNumbers.asMap().entries.map((entry) {
            final idx = entry.key;
            final serial = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${idx + 1}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      serial,
                      style: const TextStyle(
                        fontFamily: 'Courier',
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    tooltip: 'Copier',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: serial));
                    },
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _buildFieldRow(String label, String? value) {
    if (value == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Flexible(
            child: Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.w500, fontSize: 13),
                textAlign: TextAlign.end),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
      ThemeData theme, IconData icon, String label, String value) {
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
                Text(label,
                    style: theme.textTheme.labelMedium
                        ?.copyWith(color: theme.colorScheme.secondary)),
                AppSpacing.gapXs,
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
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
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LoadingSkeleton(height: 120, width: double.infinity),
          AppSpacing.gapL,
          LoadingSkeleton(height: 24, width: 140),
          AppSpacing.gapM,
          LoadingSkeleton(height: 100, width: double.infinity),
          AppSpacing.gapL,
          LoadingSkeleton(height: 24, width: 180),
          AppSpacing.gapM,
          LoadingSkeleton(height: 200, width: double.infinity),
        ],
      ),
    );
  }
}
