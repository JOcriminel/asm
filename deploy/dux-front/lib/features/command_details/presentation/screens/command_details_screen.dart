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
import 'package:dux_front/core/widgets/primary_button.dart';
import '../controllers/command_details_controller.dart';
import '../utils/pdf_generation_helper.dart';
import 'package:dux_front/features/commands/domain/models/command.dart';
import '../widgets/timeline_widget.dart';

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
        title: const DuxAppBarTitle(title: 'Détails Commande'),
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
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            tooltip: 'Copier le lien',
            onPressed: () {
              final url = 'duxapp://commands/details/$commandId';
              Clipboard.setData(ClipboardData(text: url));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Lien copié dans le presse-papiers !')),
              );
            },
          ),
        ],
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
                  TimelineWidget(command: command),
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
                  AppSpacing.gapL,
                  PrimaryButton(
                    text: 'Imprimer le Bon de Commande',
                    icon: Icons.print_rounded,
                    onPressed: () => PdfGenerationHelper.printCommand(command),
                  ),
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


  Widget _buildInfoSection(ThemeData theme, Command command) {
    return Column(
      children: [
        _buildCommandInfoCard(theme, command),
        AppSpacing.gapL,
        _buildClientInfoCard(theme, command),
      ],
    );
  }

  Widget _buildCommandInfoCard(ThemeData theme, Command command) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final formattedDocDate = dateFormat.format(command.date);
    final formattedDelivDate = command.timeline.delivered != null
        ? dateFormat.format(command.timeline.delivered!)
        : 'N/A';
    final exchangeRateStr = command.exchangeRate != null
        ? command.exchangeRate!.toStringAsFixed(3)
        : '1.000';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'Détails du Document'),
        InfoCard(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l, vertical: AppSpacing.s),
          child: Column(
            children: [
              _buildInfoRow(theme, Icons.calendar_today_outlined, 'Date document', formattedDocDate),
              const Divider(),
              _buildInfoRow(theme, Icons.receipt_long_outlined, 'Pièce', command.codePiece ?? command.documentCode),
              const Divider(),
              _buildInfoRow(theme, Icons.info_outline, 'Etat Document', command.status),
              const Divider(),
              _buildInfoRow(theme, Icons.person_outline, 'Préparé par', command.preparedBy ?? 'N/A'),
              const Divider(),
              _buildInfoRow(theme, Icons.assignment_turned_in_outlined, 'Concrétisé Par', command.concretizedBy ?? 'N/A'),
              const Divider(),
              _buildInfoRow(theme, Icons.badge_outlined, 'Représentant', command.representative),
              const Divider(),
              _buildInfoRow(theme, Icons.handshake, 'Apporteur', command.apporteur ?? 'N/A'),
              const Divider(),
              _buildInfoRow(theme, Icons.monetization_on_outlined, 'Devise', command.currency),
              const Divider(),
              _buildInfoRow(theme, Icons.currency_exchange_outlined, 'Taux de change', exchangeRateStr),
              const Divider(),
              _buildInfoRow(theme, Icons.local_shipping_outlined, 'Date livraison', formattedDelivDate),
              const Divider(),
              _buildInfoRow(theme, Icons.storefront_outlined, 'Station', command.stationName.isNotEmpty ? command.stationName : 'N/A'),
              const Divider(),
              _buildInfoRow(theme, Icons.swap_horiz_outlined, 'Affecter sur', command.affecterSur ?? 'N/A'),
              const Divider(),
              _buildInfoRow(theme, Icons.person_pin_outlined, 'Client', command.customerName),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildClientInfoCard(ThemeData theme, Command command) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'Détails du Client'),
        InfoCard(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l, vertical: AppSpacing.s),
          child: Column(
            children: [
              _buildInfoRow(theme, Icons.business_outlined, 'Raison sociale', command.clientRaisonSociale ?? command.customerName),
              const Divider(),
              _buildInfoRow(theme, Icons.gavel_outlined, 'Matricule fiscale', command.clientTaxNumber ?? 'N/A'),
              const Divider(),
              _buildInfoRow(theme, Icons.location_on_outlined, 'Adresse', command.clientAddress ?? command.deliveryAddress),
              const Divider(),
              _buildInfoRow(theme, Icons.phone_outlined, 'Téléphone', command.clientPhone ?? (command.phone.isNotEmpty ? command.phone : 'N/A')),
              const Divider(),
              _buildInfoRow(theme, Icons.contact_phone_outlined, 'Personne à contacter', command.clientContactPerson ?? 'N/A'),
              const Divider(),
              _buildInfoRow(theme, Icons.perm_identity_outlined, 'état personnalisé', command.clientCustomStatus ?? 'N/A'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummarySection(ThemeData theme, Command command) {
    final currencyFormat = NumberFormat.currency(
      locale: 'fr_TN',
      symbol: 'DT',
      decimalDigits: 3,
    );
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

  Widget _buildArticlesList(ThemeData theme, List<ArticleItem> articles) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 700;
        final currencyFormat = NumberFormat.currency(
          locale: 'fr_TN',
          symbol: 'DT',
          decimalDigits: 3,
        );

        if (isWide) {
          return InfoCard(
            padding: EdgeInsets.zero,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 20,
                columns: const [
                  DataColumn(label: Text('Code')),
                  DataColumn(label: Text('Désignation')),
                  DataColumn(label: Text('Stock')),
                  DataColumn(label: Text('Quantité')),
                  DataColumn(label: Text('Unité')),
                  DataColumn(label: Text('PUHT/U')),
                  DataColumn(label: Text('R. %')),
                  DataColumn(label: Text('Mnt Net HT')),
                  DataColumn(label: Text('TVA %')),
                  DataColumn(label: Text('PUTTC')),
                  DataColumn(label: Text('TTC')),
                  DataColumn(label: Text('Action')),
                ],
                rows: List.generate(articles.length, (index) {
                  final item = articles[index];
                  final isStockable = item.stock == '1' || item.stock == 'true';
                  
                  return DataRow(
                    cells: [
                      DataCell(Text(item.code, style: const TextStyle(fontFamily: 'monospace'))),
                      DataCell(SizedBox(width: 150, child: Text(item.name, overflow: TextOverflow.ellipsis))),
                      DataCell(Icon(
                        isStockable ? Icons.check_circle_outline : Icons.highlight_off,
                        color: isStockable ? Colors.green : Colors.red,
                        size: 18,
                      )),
                      DataCell(Text('${item.quantity}')),
                      DataCell(Text(item.unite ?? 'Pièce')),
                      DataCell(Text(currencyFormat.format(item.unitPrice))),
                      DataCell(Text('${item.discountPercent ?? 0.0} %')),
                      DataCell(Text(currencyFormat.format(item.netHT ?? item.total))),
                      DataCell(Text('${item.tvaPercent ?? 19.0} %')),
                      DataCell(Text(currencyFormat.format(item.puTTC ?? (item.unitPrice * 1.19)))),
                      DataCell(Text(currencyFormat.format(item.totalTTC ?? (item.total * 1.19)))),
                      DataCell(IconButton(
                        icon: const Icon(Icons.info_outline, size: 18),
                        onPressed: () {
                          _showItemDetailDialog(context, item);
                        },
                      )),
                    ],
                  );
                }),
              ),
            ),
          );
        }

        // Mobile list of cards
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: articles.length,
          itemBuilder: (context, index) {
            final item = articles[index];
            final isStockable = item.stock == '1' || item.stock == 'true';
            
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.m),
              child: InfoCard(
                padding: const EdgeInsets.all(AppSpacing.l),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.info_outline),
                          onPressed: () => _showItemDetailDialog(context, item),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    _buildMobileDetailRow('Code', item.code),
                    _buildMobileDetailRow('Stockable', isStockable ? 'Oui' : 'Non'),
                    _buildMobileDetailRow('Quantité', '${item.quantity} ${item.unite ?? 'Pièce'}'),
                    _buildMobileDetailRow('PUHT/U', currencyFormat.format(item.unitPrice)),
                    _buildMobileDetailRow('Remise', '${item.discountPercent ?? 0.0} %'),
                    _buildMobileDetailRow('Mnt Net HT', currencyFormat.format(item.netHT ?? item.total)),
                    _buildMobileDetailRow('TVA', '${item.tvaPercent ?? 19.0} %'),
                    _buildMobileDetailRow('PUTTC', currencyFormat.format(item.puTTC ?? (item.unitPrice * 1.19))),
                    _buildMobileDetailRow('Total TTC', currencyFormat.format(item.totalTTC ?? (item.total * 1.19)), isHighlight: true),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMobileDetailRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(
            value,
            style: TextStyle(
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
              color: isHighlight ? Colors.blue : null,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  void _showItemDetailDialog(BuildContext context, ArticleItem item) {
    final currencyFormat = NumberFormat.currency(
      locale: 'fr_TN',
      symbol: 'DT',
      decimalDigits: 3,
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item.name),
        content: SingleChildScrollView(
          child: ListBody(
            children: [
              Text('Code: ${item.code}'),
              Text('Unité: ${item.unite ?? 'Pièce'}'),
              Text('Quantité: ${item.quantity}'),
              Text('PUHT/U: ${currencyFormat.format(item.unitPrice)}'),
              Text('Remise: ${item.discountPercent ?? 0.0} %'),
              Text('Net HT: ${currencyFormat.format(item.netHT ?? item.total)}'),
              Text('TVA: ${item.tvaPercent ?? 19.0} %'),
              Text('PUTTC: ${currencyFormat.format(item.puTTC ?? (item.unitPrice * 1.19))}'),
              Text('Total TTC: ${currencyFormat.format(item.totalTTC ?? (item.total * 1.19))}'),
              Text('Stockable: ${item.stock == '1' || item.stock == 'true' ? 'Oui' : 'Non'}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Fermer'),
            onPressed: () => Navigator.of(context).pop(),
          ),
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
