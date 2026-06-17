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
import 'package:dux_front/features/bon_preparation/presentation/screens/serial_number_entry_screen.dart';
import 'package:dux_front/core/routing/route_constants.dart';
import '../controllers/bon_preparation_detail_controller.dart';
import '../../domain/models/bon_preparation.dart';

class BonPreparationDetailScreen extends ConsumerWidget {
  final String preparationId;

  const BonPreparationDetailScreen({
    super.key,
    required this.preparationId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    debugPrint('DetailScreen: build called for preparationId: $preparationId');
    final theme = Theme.of(context);
    final state = ref.watch(bonPreparationDetailControllerProvider(preparationId));
    debugPrint('DetailScreen: state (isLoading: ${state.isLoading}, error: ${state.error}, hasPrep: ${state.preparation != null})');

    return Scaffold(
      appBar: AppBar(
        title: const DuxAppBarTitle(title: 'BP-D'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.goNamed(RouteNames.bonPreparationList);
            }
          },
        ),
        actions: [
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

          if (state.isLoading && state.preparation == null) {
            return _buildLoadingState();
          }

          if (state.error != null && state.preparation == null) {
            return ErrorStateWidget(
              description: state.error!,
              onRetry: () => ref.read(bonPreparationDetailControllerProvider(preparationId).notifier).fetchDetails(),
            );
          }

          final preparation = state.preparation!;
          final formattedDate = DateFormat('MMMM dd, yyyy').format(preparation.date);

          Widget content = RefreshIndicator(
            onRefresh: () => ref.read(bonPreparationDetailControllerProvider(preparationId).notifier).fetchDetails(),
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
                                preparation.documentCode,
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Courier',
                                  fontSize: 32, // Make it bigger
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            AppSpacing.gapS,
                            StatusBadge(status: preparation.status),
                          ],
                        ),
                        AppSpacing.gapS,
                        Text(
                          preparation.customerName,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 26, // Make it bigger
                          ),
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

                  // Details Block (Responsive Layout)
                  isWide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildDocDetailsCard(theme, preparation)),
                            AppSpacing.gapL,
                            Expanded(child: _buildClientDetailsCard(theme, preparation)),
                          ],
                        )
                      : Column(
                          children: [
                            _buildDocDetailsCard(theme, preparation),
                            AppSpacing.gapL,
                            _buildClientDetailsCard(theme, preparation),
                          ],
                        ),
                  AppSpacing.gapL,

                  // Articles / Product Lines Section
                  SectionHeader(title: 'Articles & Lignes de Préparation'),
                  _buildArticlesList(context, ref, theme, preparation.articles),
                  AppSpacing.gapL,
                  
                  // Summary Section at the bottom
                  _buildSummarySection(theme, preparation),
                  AppSpacing.gapXxl,
                  
                  // Finaliser la préparation button
                  if (preparation.totalScannedSerialNumbers == preparation.totalRequiredSerialNumbers)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.l),
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.roundedM),
                        ),
                        onPressed: () {
                          context.pushNamed(
                            RouteNames.bonPreparationChecklist,
                            extra: {'preparationId': preparation.id},
                          );
                        },
                        child: const Text(
                          'Finaliser la préparation',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  if (preparation.totalScannedSerialNumbers < preparation.totalRequiredSerialNumbers)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.l),
                          backgroundColor: Colors.grey.shade400,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.roundedM),
                        ),
                        onPressed: null, // disabled
                        child: const Text(
                          'Scannez tous les SN pour finaliser',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  if (preparation.totalScannedSerialNumbers > preparation.totalRequiredSerialNumbers)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.l),
                          backgroundColor: theme.colorScheme.errorContainer,
                          foregroundColor: theme.colorScheme.onErrorContainer,
                          shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.roundedM),
                        ),
                        onPressed: null, // disabled
                        child: const Text(
                          'Trop de numéros de série scannés !',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
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
    );
  }

  Widget _buildDocDetailsCard(ThemeData theme, BonPreparation preparation) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final formattedDocDate = dateFormat.format(preparation.date);
    final formattedDelivDate = preparation.timeline.delivered != null
        ? dateFormat.format(preparation.timeline.delivered!)
        : 'N/A';

    return Theme(
      data: theme.copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        initiallyExpanded: false,
        title: const SectionHeader(title: 'Détails du Document'),
        children: [
          InfoCard(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l, vertical: AppSpacing.s),
            child: Column(
              children: [
                _buildInfoRow(theme, Icons.calendar_today_outlined, 'Date document', formattedDocDate),
                const Divider(),
                _buildInfoRow(theme, Icons.receipt_long_outlined, 'Pièce', preparation.codePiece ?? preparation.documentCode),
                const Divider(),
                _buildInfoRow(theme, Icons.info_outline, 'Etat Document', preparation.status),
                const Divider(),
                _buildInfoRow(theme, Icons.person_outline, 'Préparé par', preparation.preparedBy ?? 'N/A'),
                const Divider(),
                _buildInfoRow(theme, Icons.badge_outlined, 'Représentant', preparation.representative),
                const Divider(),
                _buildInfoRow(theme, Icons.local_shipping_outlined, 'Date livraison', formattedDelivDate),
                const Divider(),
                _buildInfoRow(theme, Icons.storefront_outlined, 'Station', preparation.stationName.isNotEmpty ? preparation.stationName : 'N/A'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientDetailsCard(ThemeData theme, BonPreparation preparation) {
    return Theme(
      data: theme.copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        initiallyExpanded: false,
        title: const SectionHeader(title: 'Détails du Client'),
        children: [
          InfoCard(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l, vertical: AppSpacing.s),
            child: Column(
              children: [
                _buildInfoRow(theme, Icons.business_outlined, 'Raison sociale', preparation.clientRaisonSociale ?? preparation.customerName),
                const Divider(),
                _buildInfoRow(theme, Icons.gavel_outlined, 'Matricule fiscale', preparation.clientTaxNumber ?? 'N/A'),
                const Divider(),
                _buildInfoRow(theme, Icons.location_on_outlined, 'Adresse', preparation.clientAddress ?? preparation.deliveryAddress),
                const Divider(),
                _buildInfoRow(theme, Icons.phone_outlined, 'Téléphone', preparation.clientPhone ?? (preparation.phone.isNotEmpty ? preparation.phone : 'N/A')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection(ThemeData theme, BonPreparation preparation) {
    final currencyFormat = NumberFormat.currency(
      locale: 'fr_TN',
      symbol: 'DT',
      decimalDigits: 3,
    );
    final ht = currencyFormat.format(preparation.totalHT);
    final vat = currencyFormat.format(preparation.vat);
    final ttc = currencyFormat.format(preparation.totalTTC);

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
                  Text('Total HT', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.secondary)),
                  Text(ht, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                ],
              ),
              AppSpacing.gapM,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('TVA', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.secondary)),
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

  Widget _buildArticlesList(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    List<PreparationArticle> articles,
  ) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: articles.length,
      itemBuilder: (context, index) {
        final item = articles[index];
        final count = item.serialNumbers.length;
        final totalQte = item.quantity;
        
        // Progress status logic
        Color snButtonColor;
        if (count == 0) {
          snButtonColor = const Color(0xFFEF5350); // Red
        } else if (count < totalQte) {
          snButtonColor = const Color(0xFFFF9800); // Orange
        } else if (count == totalQte) {
          snButtonColor = const Color(0xFF4CAF50); // Green
        } else {
          snButtonColor = const Color(0xFFD32F2F); // Dark Red for overscan
        }

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
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (item.hasSerialNumbers) ...[
                      AppSpacing.gapS,
                      SizedBox(
                        height: 36,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: snButtonColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                          ),
                          onPressed: () async {
                            final args = SerialNumberArgs(
                              documentId: preparationId,
                              lineId: item.id,
                              productCode: item.code,
                              productName: item.name,
                              quantity: totalQte,
                              initialSerialNumbers: item.serialNumbers,
                            );
                            final updated = await context.pushNamed<bool>(
                              RouteNames.bonPreparationSerialNumber,
                              extra: args,
                            );
                            if (updated == true) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const Icon(Icons.check_circle, color: Colors.white),
                                      AppSpacing.gapS,
                                      const Expanded(child: Text('Numéros de série enregistrés')),
                                    ],
                                  ),
                                  backgroundColor: Colors.green,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              );
                              ref.read(bonPreparationDetailControllerProvider(preparationId).notifier).fetchDetails();
                            }
                          },
                          child: Text(
                            'SN ($count/$totalQte)',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                subtitle: (item.hasSerialNumbers && item.serialNumbers.isNotEmpty)
                    ? Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.s),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Saisis:',
                              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary),
                            ),
                            AppSpacing.gapXs,
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: item.serialNumbers.map((sn) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
                                  ),
                                  child: Text(sn, style: const TextStyle(fontSize: 11, fontFamily: 'Courier')),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      )
                    : null,
                childrenPadding: const EdgeInsets.all(AppSpacing.l).copyWith(top: 0),
                children: [
                  const Divider(height: 20),
                  _buildFieldRow('Code Article', item.code),
                  _buildFieldRow('Quantité commandée', '$totalQte ${item.unite ?? "U"}'),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFieldRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
        ],
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
