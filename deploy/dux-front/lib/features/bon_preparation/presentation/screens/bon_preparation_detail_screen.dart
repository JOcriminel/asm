import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dux_front/core/models/screen_config.dart';
import 'package:intl/intl.dart';
import '../../../checklist/presentation/controllers/checklist_response_controller.dart';
import 'package:dux_front/core/widgets/signature_pad_dialog.dart';
import 'package:dux_front/core/widgets/photo_proof_overlay.dart';

import 'package:dux_front/core/theme/app_sizes.dart';
import 'package:dux_front/core/widgets/info_card.dart';
import 'package:dux_front/core/widgets/section_header.dart';
import 'package:dux_front/core/widgets/dux_app_bar_title.dart';
import 'package:dux_front/core/widgets/status_badge.dart';
import 'package:dux_front/core/widgets/dux_loading_screen.dart';
import 'package:dux_front/core/widgets/error_state_widget.dart';
import 'package:dux_front/features/bon_preparation/presentation/screens/serial_number_entry_screen.dart';
import 'package:dux_front/core/routing/route_constants.dart';
import 'package:dux_front/core/widgets/document_validation_proof_widget.dart';
import '../controllers/bon_preparation_detail_controller.dart';
import '../../domain/models/bon_preparation.dart';
import 'package:dux_front/core/services/screen_config_controller.dart';
import 'package:dux_front/core/theme/theme_helper.dart';
import 'package:dux_front/features/bon_preparation/data/repositories/bon_preparation_repository_impl.dart';
import 'package:dux_front/features/auth/presentation/controllers/auth_controller.dart';

class BonPreparationDetailScreen extends ConsumerWidget {
  final String preparationId;
  final String docType;
  final bool isFromCalendar;

  const BonPreparationDetailScreen({
    super.key,
    required this.preparationId,
    this.docType = 'BP',
    this.isFromCalendar = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    debugPrint('DetailScreen: build called for preparationId: $preparationId, docType: $docType');
    final theme = Theme.of(context);
    final state = ref.watch(bonPreparationDetailControllerProvider(preparationId));
    debugPrint('DetailScreen: state (isLoading: ${state.isLoading}, error: ${state.error}, hasPrep: ${state.preparation != null})');

    final configState = ref.watch(screenConfigControllerProvider);
    final normalizedDocType = docType == 'DPR' ? 'BP' : (docType == 'BCC' ? 'BC' : docType);
    final bpConfig = configState.configs[normalizedDocType] ?? configState.configs['BP'];
    final pageTitle = bpConfig?.detailPageTitle ?? (docType == 'BPR' ? 'BPR-D' : 'BP-D');
    final isTrackingSN = bpConfig?.enableSerialNumberTracking ?? false;
    final isChecklistEnabled = bpConfig?.enableChecklistTracking ?? false;

    final authState = ref.watch(authControllerProvider);
    final userRole = authState.user?.role.toLowerCase() ?? '';
    final isOperator = userRole == 'operateur' || userRole == 'opérateur';
    final hidePrices = (bpConfig?.hidePrices ?? false) ||
                       ((bpConfig?.hidePricesForOperateurs ?? false) && isOperator) ||
                       (bpConfig?.hidePricesForRoles.any((r) => r.trim().toLowerCase() == userRole) ?? false);

    final requireSignature = bpConfig?.requireSignature ?? false;
    final requirePhoto = bpConfig?.requirePhoto ?? false;

    final isAllowed = bpConfig == null || 
                      userRole == 'admin' || 
                      userRole == 'administrateur' ||
                      bpConfig.allowedRolesToFinalize.any((r) => r.trim().toLowerCase() == userRole.trim());

    final dynamicTheme = getDynamicTheme(context, bpConfig?.primaryColor);

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
              if (docType == 'BPR') {
                context.go('/pages/bon-reservation/list');
              } else {
                context.goNamed(RouteNames.bonPreparationList);
              }
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.wifi, color: Colors.green),
            onPressed: () {},
          ),
            if (!isFromCalendar)
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
                            Expanded(child: _buildDocDetailsCard(theme, preparation, bpConfig)),
                            AppSpacing.gapL,
                            Expanded(child: _buildClientDetailsCard(theme, preparation)),
                          ],
                        )
                      : Column(
                          children: [
                            _buildDocDetailsCard(theme, preparation, bpConfig),
                            AppSpacing.gapL,
                            _buildClientDetailsCard(theme, preparation),
                          ],
                        ),
                  AppSpacing.gapL,

                  // Articles / Product Lines Section
                  SectionHeader(title: docType == 'BPR' ? 'Articles & Lignes de Réservation' : 'Articles & Lignes de Préparation'),
                  _buildArticlesList(context, ref, theme, preparation.articles, isTrackingSN, isChecklistEnabled, preparation.idClassedocument),
                  AppSpacing.gapL,
                  
                  // Summary Section at the bottom
                  if (!hidePrices) ...[
                    _buildSummarySection(theme, preparation),
                    AppSpacing.gapXxl,
                  ],

                  DocumentValidationProofWidget(documentId: preparation.id),
                  AppSpacing.gapL,
                  
                  // Finaliser button
                  if (isAllowed) ...[
                    if (!isTrackingSN || preparation.totalScannedSerialNumbers == preparation.totalRequiredSerialNumbers)
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
                          onPressed: () {
                            if (isChecklistEnabled) {
                              context.pushNamed(
                                docType == 'BPR' ? RouteNames.bonReservationChecklist : RouteNames.bonPreparationChecklist,
                                extra: {
                                  'preparationId': preparation.id,
                                  'docType': normalizedDocType,
                                },
                              );
                            } else {
                              _finalizeDirectly(context, ref, preparation.id, requireSignature, requirePhoto, bpConfig?.customFinalizeMessage);
                            }
                          },
                          child: Text(
                            docType == 'BPR' ? 'Finaliser la réservation' : 'Finaliser la préparation',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    if (isTrackingSN && preparation.totalScannedSerialNumbers < preparation.totalRequiredSerialNumbers)
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
                    if (isTrackingSN && preparation.totalScannedSerialNumbers > preparation.totalRequiredSerialNumbers)
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
                  ],
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

  Widget _buildDocDetailsCard(ThemeData theme, BonPreparation preparation, ScreenConfig? config) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final formattedDocDate = dateFormat.format(preparation.date);
    final formattedDelivDate = preparation.timeline.delivered != null
        ? dateFormat.format(preparation.timeline.delivered!)
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
    addRow(Icons.receipt_long_outlined, 'piece', preparation.codePiece ?? preparation.documentCode);
    addRow(Icons.info_outline, 'status', preparation.status);
    addRow(Icons.person_outline, 'preparedBy', preparation.preparedBy ?? 'N/A');
    addRow(Icons.badge_outlined, 'representative', preparation.representative);
    addRow(Icons.local_shipping_outlined, 'deliveryDate', formattedDelivDate);
    addRow(Icons.storefront_outlined, 'station', preparation.stationName.isNotEmpty ? preparation.stationName : 'N/A');

    // Note: We also map remaining fields from the 13 fields if they are set on the document, to keep all 13 supported
    addRow(Icons.assignment_turned_in_outlined, 'concretizedBy', 'N/A');
    addRow(Icons.handshake, 'apporteur', 'N/A');
    addRow(Icons.monetization_on_outlined, 'currency', 'N/A');
    addRow(Icons.currency_exchange_outlined, 'exchangeRate', '1.000');
    addRow(Icons.swap_horiz_outlined, 'affecterSur', 'N/A');
    addRow(Icons.person_pin_outlined, 'customer', preparation.customerName);

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
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l, vertical: AppSpacing.s),
              child: Column(
                children: childrenWithDividers,
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
    bool isTrackingSN,
    bool isChecklistEnabled,
    String? idClassedocument,
  ) {
    final normalizedDocType = docType == 'DPR' ? 'BP' : (docType == 'BCC' ? 'BC' : docType);
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
                    if (isTrackingSN && item.hasSerialNumbers) ...[
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
                              docType: normalizedDocType,
                              idClassedocument: idClassedocument,
                              rawArticleJson: item.rawJson,
                            );
                             final updated = await context.pushNamed<bool>(
                              docType == 'BPR' ? RouteNames.bonReservationSerialNumber : RouteNames.bonPreparationSerialNumber,
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
                    Consumer(
                      builder: (context, ref, child) {
                        if (!isChecklistEnabled) return const SizedBox.shrink();
                        final familyId = item.familyId ?? '';
                        final countAsync = ref.watch(articleChecklistCountProvider('${item.id}:$familyId:$normalizedDocType'));
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
                                    await context.pushNamed(
                                      docType == 'BPR' 
                                          ? RouteNames.bonReservationArticleChecklist 
                                          : RouteNames.bonPreparationArticleChecklist,
                                      extra: {
                                        'preparationId': preparationId,
                                        'article': item,
                                        'docType': normalizedDocType,
                                      },
                                    );
                                    // Refresh details after returning from checklist page
                                    ref.read(bonPreparationDetailControllerProvider(preparationId).notifier).fetchDetails();
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
                  ],
                ),
                subtitle: (isTrackingSN && item.hasSerialNumbers && item.serialNumbers.isNotEmpty)
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

  Future<void> _finalizeDirectly(
    BuildContext context, 
    WidgetRef ref, 
    String preparationId,
    bool requireSignature,
    bool requirePhoto,
    String? customFinalizeMessage,
  ) async {
    String? signatureBase64;
    if (requireSignature) {
      signatureBase64 = await SignaturePadDialog.show(context);
      if (signatureBase64 == null) return;
    }

    String? photoBase64;
    if (requirePhoto) {
      photoBase64 = await PhotoProofOverlay.show(context);
      if (photoBase64 == null) return;
    }

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
      await repository.updateDocumentStatus(preparationId, '12', {
        'signatureBase64': signatureBase64,
        'photoBase64': photoBase64,
        'docType': docType,
      });
      
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
      ref.read(bonPreparationDetailControllerProvider(preparationId).notifier).fetchDetails();
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

}
