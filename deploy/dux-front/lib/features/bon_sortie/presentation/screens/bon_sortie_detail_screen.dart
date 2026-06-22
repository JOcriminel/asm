import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dux_front/core/models/screen_config.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:dux_front/core/theme/app_sizes.dart';
import 'package:dux_front/core/widgets/info_card.dart';
import 'package:dux_front/core/widgets/section_header.dart';
import 'package:dux_front/core/widgets/dux_app_bar_title.dart';
import 'package:dux_front/core/widgets/status_badge.dart';
import 'package:dux_front/core/widgets/dux_loading_screen.dart';
import 'package:dux_front/core/widgets/error_state_widget.dart';
import 'package:dux_front/core/routing/route_constants.dart';
import '../controllers/bon_sortie_detail_controller.dart';
import '../../domain/models/bon_sortie.dart';
import 'package:dux_front/core/services/screen_config_controller.dart';
import 'package:dux_front/core/theme/theme_helper.dart';

import 'package:dux_front/features/bon_preparation/data/repositories/bon_preparation_repository_impl.dart';
import 'package:dux_front/features/bon_preparation/presentation/screens/serial_number_entry_screen.dart';
import 'package:dux_front/features/bon_preparation/domain/models/bon_preparation.dart';
import 'package:dux_front/features/command_details/presentation/utils/pdf_generation_helper.dart';
import 'package:dux_front/features/commands/domain/models/command.dart' as cmd;
import 'package:dux_front/core/widgets/signature_pad_dialog.dart';
import 'package:dux_front/core/widgets/photo_proof_overlay.dart';
import 'package:dux_front/features/auth/presentation/controllers/auth_controller.dart';
import 'package:dux_front/features/checklist/presentation/controllers/checklist_response_controller.dart';

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
    final authState = ref.watch(authControllerProvider);
    final userRole = authState.user?.role.toLowerCase() ?? '';
    final isOperator = userRole == 'operateur' || userRole == 'opérateur';
    final hidePrices = (bsConfig?.hidePrices ?? false) ||
                       ((bsConfig?.hidePricesForOperateurs ?? false) && isOperator) ||
                       (bsConfig?.hidePricesForRoles.any((r) => r.trim().toLowerCase() == userRole) ?? false);

    final isTrackingSN = bsConfig?.enableSerialNumberTracking ?? false;
    final isChecklistEnabled = bsConfig?.enableChecklistTracking ?? false;
    final enablePdfPrinting = bsConfig?.enablePdfPrinting ?? false;
    final requireSignature = bsConfig?.requireSignature ?? false;
    final requirePhoto = bsConfig?.requirePhoto ?? false;

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
            if (enablePdfPrinting && state.sortie != null)
              IconButton(
                icon: const Icon(Icons.print_rounded),
                tooltip: 'Imprimer',
                onPressed: () async {
                  final cmdDoc = _mapSortieToCommand(state.sortie!);
                  await PdfGenerationHelper.printCommand(cmdDoc);
                },
              ),
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

            if (state.isLoading) {
              return const DuxLoadingScreen(isFullScreen: false);
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
            final formattedDate = DateFormat('MMMM dd, yyyy').format(sortie.date);

            final authState = ref.watch(authControllerProvider);
            final userRole = authState.user?.role;
            final allowedRoles = bsConfig?.allowedRolesToFinalize ?? const ['admin', 'commercial', 'operateur', 'Administrateur', 'Commercial', 'Opérateur'];
            final isAllowed = allowedRoles.isEmpty || allowedRoles.contains(userRole);

            final totalRequiredSerialNumbers = sortie.articles.where((a) => a.hasSerialNumbers).fold(0, (sum, a) => sum + a.quantity);
            final totalScannedSerialNumbers = sortie.articles.where((a) => a.hasSerialNumbers).fold(0, (sum, a) => sum + a.serialNumbers.length);

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

                    // Details Block
                    isWide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: _buildDocDetailsCard(theme, sortie, bsConfig)),
                              AppSpacing.gapL,
                              Expanded(child: _buildClientDetailsCard(theme, sortie)),
                            ],
                          )
                        : Column(
                            children: [
                              _buildDocDetailsCard(theme, sortie, bsConfig),
                              AppSpacing.gapL,
                              _buildClientDetailsCard(theme, sortie),
                            ],
                          ),
                    AppSpacing.gapL,

                    // Articles Section
                    SectionHeader(title: 'Articles & Lignes de Sortie'),
                    _buildArticlesList(
                      context,
                      ref,
                      theme,
                      sortie.articles,
                      hidePrices,
                      isTrackingSN,
                      isChecklistEnabled,
                      sortie.id,
                    ),
                    AppSpacing.gapL,

                    // Summary Section
                    if (!hidePrices) ...[
                      _buildSummarySection(theme, sortie),
                      AppSpacing.gapXxl,
                    ],

                    // Finalizer Button
                    if (sortie.status != '12' && isAllowed) ...[
                      if (!isTrackingSN || totalScannedSerialNumbers == totalRequiredSerialNumbers)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: AppSpacing.l),
                              backgroundColor: theme.colorScheme.secondary,
                              foregroundColor: theme.colorScheme.onSecondary,
                              elevation: 4,
                              shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.roundedM),
                            ),
                            onPressed: () => _handleFinalize(
                              context,
                              ref,
                              sortie.id,
                              'BS',
                              requireSignature,
                              requirePhoto,
                              isChecklistEnabled,
                              bsConfig?.customFinalizeMessage,
                            ),
                            child: const Text(
                              'Finaliser la sortie',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      if (isTrackingSN && totalScannedSerialNumbers < totalRequiredSerialNumbers)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: AppSpacing.l),
                              backgroundColor: Colors.grey.shade400,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.roundedM),
                            ),
                            onPressed: null,
                            child: const Text(
                              'Scannez tous les SN pour finaliser',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      if (isTrackingSN && totalScannedSerialNumbers > totalRequiredSerialNumbers)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: AppSpacing.l),
                              backgroundColor: theme.colorScheme.errorContainer,
                              foregroundColor: theme.colorScheme.onErrorContainer,
                              shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.roundedM),
                            ),
                            onPressed: null,
                            child: const Text(
                              'Trop de numéros de série scannés !',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      AppSpacing.gapXxl,
                    ],
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

  cmd.Command _mapSortieToCommand(BonSortie sortie) {
    return cmd.Command(
      id: sortie.id,
      documentCode: sortie.documentCode,
      documentType: sortie.documentType,
      documentTypeCode: sortie.documentTypeCode,
      customerName: sortie.customerName,
      date: sortie.date,
      status: sortie.status,
      amount: sortie.amount,
      amountTTC: sortie.amountTTC,
      amountTVA: sortie.amountTVA,
      reste: sortie.reste,
      representative: sortie.representative,
      tier: sortie.tier,
      deliveryAddress: sortie.deliveryAddress,
      phone: sortie.phone,
      currency: sortie.currency,
      stationName: sortie.stationName,
      idStation: sortie.idStation,
      articles: sortie.articles.map((e) => cmd.ArticleItem(
        id: e.id,
        code: e.code,
        name: e.name,
        quantity: e.quantity,
        unitPrice: e.unitPrice,
        unite: e.unite,
        discountPercent: e.discountPercent,
        netHT: e.netHT,
        tvaPercent: e.tvaPercent,
        puTTC: e.puTTC,
        totalTTC: e.totalTTC,
        stock: e.stock,
        serialNumbers: e.serialNumbers,
        rawJson: e.rawJson,
        familyId: e.familyId,
        familyName: e.familyName,
        numSerie: e.numSerie,
      )).toList(),
      timeline: cmd.CommandTimeline(
        created: sortie.timeline.created,
        validated: sortie.timeline.validated,
        delivered: sortie.timeline.delivered,
      ),
      codePiece: sortie.codePiece,
      preparedBy: sortie.preparedBy,
      concretizedBy: sortie.concretizedBy,
      apporteur: sortie.apporteur,
      exchangeRate: sortie.exchangeRate,
      affecterSur: sortie.affecterSur,
      clientRaisonSociale: sortie.clientRaisonSociale,
      clientTaxNumber: sortie.clientTaxNumber,
      clientAddress: sortie.clientAddress,
      clientPhone: sortie.clientPhone,
      clientContactPerson: sortie.clientContactPerson,
      clientCustomStatus: sortie.clientCustomStatus,
    );
  }

  Future<void> _handleFinalize(
    BuildContext context,
    WidgetRef ref,
    String docId,
    String docType,
    bool requireSignature,
    bool requirePhoto,
    bool isChecklistEnabled,
    String? customFinalizeMessage,
  ) async {
    if (requireSignature) {
      final signature = await SignaturePadDialog.show(context);
      if (signature == null) return;
    }

    if (requirePhoto) {
      final photo = await PhotoProofOverlay.show(context);
      if (photo == null) return;
    }

    if (!context.mounted) return;

    if (isChecklistEnabled) {
      final updated = await context.pushNamed<bool>(
        RouteNames.bonPreparationChecklist,
        extra: {
          'preparationId': docId,
          'docType': docType,
        },
      );
      if (updated == true && context.mounted) {
        ref.read(bonSortieDetailControllerProvider(docId).notifier).fetchDetails();
      }
    } else {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Finaliser le document'),
          content: Text(customFinalizeMessage ?? 'Êtes-vous sûr de vouloir finaliser ce document ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Finaliser'),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      try {
        final repository = ref.read(bonPreparationRepositoryProvider);
        await repository.updateDocumentStatus(docId, '12', {});
        
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Expanded(child: Text('Document finalisé avec succès!')),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.read(bonSortieDetailControllerProvider(docId).notifier).fetchDetails();
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la finalisation: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Map<String, Map<String, dynamic>> _getDetailsFields(String? configStr) {
    final Map<String, Map<String, dynamic>> defaults = {
      'date': {'label': 'Date document', 'visible': true},
      'piece': {'label': 'Pièce', 'visible': true},
      'status': {'label': 'Etat Document', 'visible': true},
      'preparedBy': {'label': 'Préparé par', 'visible': true},
      'concretizedBy': {'label': 'Concrétisé Par', 'visible': true},
      'representative': {'label': 'Représentant', 'visible': true},
      'apporteur': {'label': 'Apporteur', 'visible': true},
      'currency': {'label': 'Devise', 'visible': true},
      'exchangeRate': {'label': 'Taux de change', 'visible': true},
      'deliveryDate': {'label': 'Date livraison', 'visible': true},
      'station': {'label': 'Station', 'visible': true},
      'affecterSur': {'label': 'Affecter sur', 'visible': true},
      'customer': {'label': 'Client', 'visible': true},
    };
    if (configStr == null || configStr.isEmpty) {
      return defaults;
    }
    try {
      final parsed = jsonDecode(configStr);
      if (parsed is Map<String, dynamic>) {
        final merged = <String, Map<String, dynamic>>{};
        defaults.forEach((key, defaultValue) {
          if (parsed.containsKey(key)) {
            final val = parsed[key];
            if (val is Map) {
              merged[key] = {
                'label': val['label']?.toString() ?? defaultValue['label']?.toString() ?? '',
                'visible': val['visible'] as bool? ?? defaultValue['visible'] as bool? ?? true,
              };
            } else {
              merged[key] = defaultValue;
            }
          } else {
            merged[key] = defaultValue;
          }
        });
        return merged;
      }
    } catch (_) {}
    return defaults;
  }

  Widget? _buildDynamicInfoRow(ThemeData theme, IconData icon, String key, String value, Map<String, Map<String, dynamic>> fields) {
    final config = fields[key];
    if (config == null || config['visible'] != true) {
      return null;
    }
    final label = config['label']?.toString() ?? key;
    return _buildInfoRow(theme, icon, label, value);
  }

  Widget _buildDocDetailsCard(ThemeData theme, BonSortie sortie, ScreenConfig? config) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final formattedDocDate = dateFormat.format(sortie.date);
    final formattedDelivDate = sortie.timeline.delivered != null
        ? dateFormat.format(sortie.timeline.delivered!)
        : 'N/A';

    final fields = _getDetailsFields(config?.detailsFieldsConfig);
    final List<Widget> rows = [];

    void addRow(IconData icon, String key, String value) {
      final row = _buildDynamicInfoRow(theme, icon, key, value, fields);
      if (row != null) {
        rows.add(row);
      }
    }

    addRow(Icons.calendar_today_outlined, 'date', formattedDocDate);
    addRow(Icons.receipt_long_outlined, 'piece', sortie.codePiece ?? sortie.documentCode);
    addRow(Icons.info_outline, 'status', sortie.status);
    addRow(Icons.person_outline, 'preparedBy', sortie.preparedBy ?? 'N/A');
    addRow(Icons.badge_outlined, 'representative', sortie.representative);
    addRow(Icons.local_shipping_outlined, 'deliveryDate', formattedDelivDate);
    addRow(Icons.storefront_outlined, 'station', sortie.stationName.isNotEmpty ? sortie.stationName : 'N/A');

    // Note: We also map remaining fields from the 13 fields if they are set on the document, to keep all 13 supported
    addRow(Icons.assignment_turned_in_outlined, 'concretizedBy', sortie.concretizedBy ?? 'N/A');
    addRow(Icons.handshake, 'apporteur', sortie.apporteur ?? 'N/A');
    addRow(Icons.monetization_on_outlined, 'currency', sortie.currency);
    addRow(Icons.currency_exchange_outlined, 'exchangeRate', sortie.exchangeRate != null ? sortie.exchangeRate!.toStringAsFixed(3) : '1.000');
    addRow(Icons.swap_horiz_outlined, 'affecterSur', sortie.affecterSur ?? 'N/A');
    addRow(Icons.person_pin_outlined, 'customer', sortie.customerName);

    final List<Widget> childrenWithDividers = [];
    for (int i = 0; i < rows.length; i++) {
      childrenWithDividers.add(rows[i]);
      if (i < rows.length - 1) {
        childrenWithDividers.add(const Divider());
      }
    }

    return Theme(
      data: theme.copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        initiallyExpanded: false,
        title: const SectionHeader(title: 'Détails du Document'),
        children: [
          if (childrenWithDividers.isNotEmpty)
            InfoCard(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.l, vertical: AppSpacing.s),
              child: Column(
                children: childrenWithDividers,
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
    WidgetRef ref,
    ThemeData theme,
    List<SortieArticle> articles,
    bool hidePrices,
    bool isTrackingSN,
    bool isChecklistEnabled,
    String sortieId,
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
                    if (isTrackingSN && item.hasSerialNumbers) ...[
                      AppSpacing.gapS,
                      SizedBox(
                        height: 36,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: item.serialNumbers.isEmpty
                                ? const Color(0xFFEF5350)
                                : (item.serialNumbers.length < item.quantity ? const Color(0xFFFF9800) : const Color(0xFF4CAF50)),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                          ),
                          onPressed: () async {
                            final args = SerialNumberArgs(
                              documentId: sortieId,
                              lineId: item.id,
                              productCode: item.code,
                              productName: item.name,
                              quantity: item.quantity,
                              initialSerialNumbers: item.serialNumbers,
                              docType: 'BS',
                              idClassedocument: '129',
                              rawArticleJson: item.rawJson,
                            );
                            final updated = await context.pushNamed<bool>(
                              RouteNames.bonPreparationSerialNumber,
                              extra: args,
                            );
                            if (updated == true) {
                              ref.read(bonSortieDetailControllerProvider(sortieId).notifier).fetchDetails();
                            }
                          },
                          child: Text(
                            'SN (${item.serialNumbers.length}/$totalQte)',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                    Consumer(
                      builder: (context, ref, child) {
                        if (!isChecklistEnabled) return const SizedBox.shrink();
                        final familyId = item.familyId ?? '';
                        final countAsync = ref.watch(articleChecklistCountProvider('${item.id}:$familyId:BS'));
                        return countAsync.when(
                          data: (count) {
                            if (count.total == 0) return const SizedBox.shrink();
                            
                            final checked = count.checked;
                            final total = count.total;
                            
                            Color checklistButtonColor;
                            if (checked == 0) {
                              checklistButtonColor = const Color(0xFFEF5350); // Red
                            } else if (checked < total) {
                              checklistButtonColor = const Color(0xFFFF9800); // Orange
                            } else {
                              checklistButtonColor = const Color(0xFF4CAF50); // Green
                            }

                            return Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: SizedBox(
                                height: 36,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: checklistButtonColor,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                                  ),
                                  onPressed: () async {
                                    final prepArticle = PreparationArticle(
                                      id: item.id,
                                      code: item.code,
                                      name: item.name,
                                      quantity: item.quantity,
                                      unitPrice: item.unitPrice,
                                      unite: item.unite,
                                      discountPercent: item.discountPercent,
                                      netHT: item.netHT,
                                      tvaPercent: item.tvaPercent,
                                      puTTC: item.puTTC,
                                      totalTTC: item.totalTTC,
                                      stock: item.stock,
                                      serialNumbers: item.serialNumbers,
                                      rawJson: item.rawJson,
                                      familyId: item.familyId,
                                      familyName: item.familyName,
                                      numSerie: item.numSerie,
                                    );
                                    await context.pushNamed(
                                      RouteNames.bonPreparationArticleChecklist,
                                      extra: {
                                        'preparationId': sortieId,
                                        'article': prepArticle,
                                        'docType': 'BS',
                                      },
                                    );
                                    ref.read(bonSortieDetailControllerProvider(sortieId).notifier).fetchDetails();
                                  },
                                  child: Text(
                                    'Tasks ($checked/$total)',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ),
                              ),
                            );
                          },
                          loading: () => const Padding(
                            padding: EdgeInsets.only(left: 8.0),
                            child: SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          error: (_, _) => const SizedBox.shrink(),
                        );
                      },
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
                  if (item.netHT != null && !hidePrices)
                    _buildFieldRow(
                        'Net HT',
                        NumberFormat.currency(
                                locale: 'fr_TN',
                                symbol: 'DT',
                                decimalDigits: 3)
                            .format(item.netHT)),
                  if (item.totalTTC != null && !hidePrices)
                    _buildFieldRow(
                        'Total TTC',
                        NumberFormat.currency(
                                locale: 'fr_TN',
                                symbol: 'DT',
                                decimalDigits: 3)
                            .format(item.totalTTC)),
                  if (item.tvaPercent != null && !hidePrices)
                    _buildFieldRow('TVA', '${item.tvaPercent}%'),
                  if (item.discountPercent != null &&
                      item.discountPercent! > 0 &&
                      !hidePrices)
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
}
