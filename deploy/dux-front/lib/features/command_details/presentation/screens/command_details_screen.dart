import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dux_front/core/models/screen_config.dart';
import 'package:intl/intl.dart';
import 'package:dux_front/core/theme/app_sizes.dart';
import 'package:dux_front/core/widgets/info_card.dart';
import 'package:dux_front/core/widgets/section_header.dart';
import 'package:dux_front/core/widgets/dux_app_bar_title.dart';
import 'package:dux_front/core/widgets/status_badge.dart';
import 'package:dux_front/core/widgets/dux_loading_screen.dart';
import 'package:dux_front/core/widgets/error_state_widget.dart';
import '../controllers/command_details_controller.dart';
import 'package:dux_front/features/commands/domain/models/command.dart';
import '../widgets/timeline_widget.dart';
import 'package:dux_front/core/services/screen_config_controller.dart';
import 'package:dux_front/core/theme/theme_helper.dart';
import 'package:dux_front/features/auth/presentation/controllers/auth_controller.dart';
import 'package:dux_front/features/bon_preparation/data/repositories/bon_preparation_repository_impl.dart';
import 'package:dux_front/features/bon_preparation/presentation/screens/serial_number_entry_screen.dart';
import 'package:dux_front/features/bon_preparation/domain/models/bon_preparation.dart';
import 'package:dux_front/features/command_details/presentation/utils/pdf_generation_helper.dart';
import 'package:dux_front/core/widgets/signature_pad_dialog.dart';
import 'package:dux_front/core/widgets/photo_proof_overlay.dart';
import 'package:dux_front/core/routing/route_constants.dart';
import 'package:dux_front/features/checklist/presentation/controllers/checklist_response_controller.dart';

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
    final configState = ref.watch(screenConfigControllerProvider);
    
    final docTypeCode = state.command?.documentTypeCode ?? 'BC';
    final normalizedDocType = docTypeCode == 'BCC' ? 'BC' : (docTypeCode == 'DPR' ? 'BP' : docTypeCode);
    final bcConfig = configState.configs[normalizedDocType];
    final pageTitle = bcConfig?.detailPageTitle ?? ('$docTypeCode-D');

    final authState = ref.watch(authControllerProvider);
    final userRole = authState.user?.role.toLowerCase() ?? '';
    final isOperator = userRole == 'operateur' || userRole == 'opérateur';
    final hidePrices = (bcConfig?.hidePrices ?? false) ||
                       ((bcConfig?.hidePricesForOperateurs ?? false) && isOperator) ||
                       (bcConfig?.hidePricesForRoles.any((r) => r.trim().toLowerCase() == userRole) ?? false);

    final isTrackingSN = bcConfig?.enableSerialNumberTracking ?? false;
    final isChecklistEnabled = bcConfig?.enableChecklistTracking ?? false;
    final enablePdfPrinting = bcConfig?.enablePdfPrinting ?? false;
    final requireSignature = bcConfig?.requireSignature ?? false;
    final requirePhoto = bcConfig?.requirePhoto ?? false;

    final dynamicTheme = getDynamicTheme(context, bcConfig?.primaryColor);

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
                context.go('/commands');
              }
            },
          ),
          actions: [
            if (enablePdfPrinting && state.command != null)
              IconButton(
                icon: const Icon(Icons.print_rounded),
                tooltip: 'Imprimer',
                onPressed: () async {
                  await PdfGenerationHelper.printCommand(state.command!);
                },
              ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Actualiser',
              onPressed: () =>
                  ref.read(commandDetailsControllerProvider(commandId).notifier).fetchDetails(),
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

            if (state.error != null && state.command == null) {
              return ErrorStateWidget(
                description: state.error!,
                onRetry: () => ref.read(commandDetailsControllerProvider(commandId).notifier).fetchDetails(),
              );
            }

          final command = state.command!;
          final formattedDate = DateFormat('MMMM dd, yyyy').format(command.date);

          final totalRequiredSerialNumbers = command.articles.where((a) => a.hasSerialNumbers).fold(0, (sum, a) => sum + a.quantity);
          final totalScannedSerialNumbers = command.articles.where((a) => a.hasSerialNumbers).fold(0, (sum, a) => sum + a.serialNumbers.length);
          final allowedRoles = bcConfig?.allowedRolesToFinalize ?? const ['admin', 'commercial', 'operateur', 'Administrateur', 'Commercial', 'Opérateur'];
          final isAllowed = allowedRoles.isEmpty || allowedRoles.contains(userRole);

          Widget content = RefreshIndicator(
            onRefresh: () => ref.read(commandDetailsControllerProvider(commandId).notifier).fetchDetails(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.l),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Block
                  Hero(
                    tag: 'command_${command.id}',
                    child: Material(
                      type: MaterialType.transparency,
                      child: Container(
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
                                    fontSize: 32, // Make it bigger
                                  ),
                                ),
                                StatusBadge(status: command.status),
                              ],
                            ),
                            AppSpacing.gapS,
                            Text(
                              command.customerName,
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
                            Expanded(child: _buildInfoSection(theme, command, bcConfig)),
                          ],
                        )
                      : Column(
                          children: [
                            _buildInfoSection(theme, command, bcConfig),
                          ],
                        ),
                  AppSpacing.gapL,

                  // Articles List Section
                  SectionHeader(title: 'Articles & Items'),
                  _buildArticlesList(context, ref, theme, command.articles, hidePrices, isTrackingSN, isChecklistEnabled, command.id, normalizedDocType, command),
                  AppSpacing.gapL,

                  // Summary Section moved to bottom
                  if (!hidePrices) ...[
                    _buildSummarySection(theme, command),
                    AppSpacing.gapXxl,
                  ],

                  // Finalizer Button
                  if (command.status != '12' && isAllowed) ...[
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
                            command.id,
                            normalizedDocType,
                            requireSignature,
                            requirePhoto,
                            isChecklistEnabled,
                            bcConfig?.customFinalizeMessage,
                          ),
                          child: const Text(
                            'Finaliser la commande',
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
                width: 900,
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

  Widget _buildInfoSection(ThemeData theme, Command command, ScreenConfig? config) {
    return Column(
      children: [
        _buildCommandInfoCard(theme, command, config),
        AppSpacing.gapL,
        _buildClientInfoCard(theme, command),
      ],
    );
  }

  Widget _buildCommandInfoCard(ThemeData theme, Command command, ScreenConfig? config) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final formattedDocDate = dateFormat.format(command.date);
    final formattedDelivDate = command.timeline.delivered != null
        ? dateFormat.format(command.timeline.delivered!)
        : 'N/A';
    final exchangeRateStr = command.exchangeRate != null
        ? command.exchangeRate!.toStringAsFixed(3)
        : '1.000';

    final fields = _getDetailsFields(config?.detailsFieldsConfig);
    final List<Widget> rows = [];

    void addRow(IconData icon, String key, String value) {
      final row = _buildDynamicInfoRow(theme, icon, key, value, fields);
      if (row != null) {
        rows.add(row);
      }
    }

    addRow(Icons.calendar_today_outlined, 'date', formattedDocDate);
    addRow(Icons.receipt_long_outlined, 'piece', command.codePiece ?? command.documentCode);
    addRow(Icons.info_outline, 'status', command.status);
    addRow(Icons.person_outline, 'preparedBy', command.preparedBy ?? 'N/A');
    addRow(Icons.assignment_turned_in_outlined, 'concretizedBy', command.concretizedBy ?? 'N/A');
    addRow(Icons.badge_outlined, 'representative', command.representative);
    addRow(Icons.handshake, 'apporteur', command.apporteur ?? 'N/A');
    addRow(Icons.monetization_on_outlined, 'currency', command.currency);
    addRow(Icons.currency_exchange_outlined, 'exchangeRate', exchangeRateStr);
    addRow(Icons.local_shipping_outlined, 'deliveryDate', formattedDelivDate);
    addRow(Icons.storefront_outlined, 'station', command.stationName.isNotEmpty ? command.stationName : 'N/A');
    addRow(Icons.swap_horiz_outlined, 'affecterSur', command.affecterSur ?? 'N/A');
    addRow(Icons.person_pin_outlined, 'customer', command.customerName);

    final List<Widget> childrenWithDividers = [];
    for (int i = 0; i < rows.length; i++) {
      childrenWithDividers.add(rows[i]);
      if (i < rows.length - 1) {
        childrenWithDividers.add(const Divider());
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Theme(
          data: theme.copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            title: const Text('Détails du Document', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            childrenPadding: EdgeInsets.zero,
            tilePadding: EdgeInsets.zero,
            initiallyExpanded: false,
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
        ),
      ],
    );
  }

  Widget _buildClientInfoCard(ThemeData theme, Command command) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Theme(
          data: theme.copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            title: const Text('Détails du Client', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            childrenPadding: EdgeInsets.zero,
            tilePadding: EdgeInsets.zero,
            initiallyExpanded: false,
            children: [
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

  Widget _buildArticlesList(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    List<ArticleItem> articles,
    bool hidePrices,
    bool isTrackingSN,
    bool isChecklistEnabled,
    String commandId,
    String docTypeCode,
    Command command,
  ) {
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
                columns: [
                  const DataColumn(label: Text('Code')),
                  const DataColumn(label: Text('Désignation')),
                  const DataColumn(label: Text('Stock')),
                  const DataColumn(label: Text('Quantité')),
                  const DataColumn(label: Text('Unité')),
                  if (!hidePrices) const DataColumn(label: Text('PUHT/U')),
                  if (!hidePrices) const DataColumn(label: Text('R. %')),
                  if (!hidePrices) const DataColumn(label: Text('Mnt Net HT')),
                  if (!hidePrices) const DataColumn(label: Text('TVA %')),
                  if (!hidePrices) const DataColumn(label: Text('PUTTC')),
                  if (!hidePrices) const DataColumn(label: Text('TTC')),
                  const DataColumn(label: Text('Action')),
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
                      if (!hidePrices) DataCell(Text(currencyFormat.format(item.unitPrice))),
                      if (!hidePrices) DataCell(Text('${item.discountPercent ?? 0.0} %')),
                      if (!hidePrices) DataCell(Text(currencyFormat.format(item.netHT ?? item.total))),
                      if (!hidePrices) DataCell(Text('${item.tvaPercent ?? 19.0} %')),
                      if (!hidePrices) DataCell(Text(currencyFormat.format(item.puTTC ?? (item.unitPrice * 1.19)))),
                      if (!hidePrices) DataCell(Text(currencyFormat.format(item.totalTTC ?? (item.total * 1.19)))),
                      DataCell(Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isTrackingSN && item.hasSerialNumbers) ...[
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: item.serialNumbers.isEmpty
                                    ? const Color(0xFFEF5350)
                                    : (item.serialNumbers.length < item.quantity ? const Color(0xFFFF9800) : const Color(0xFF4CAF50)),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                              ),
                              onPressed: () async {
                                final args = SerialNumberArgs(
                                  documentId: commandId,
                                  lineId: item.id,
                                  productCode: item.code,
                                  productName: item.name,
                                  quantity: item.quantity,
                                  initialSerialNumbers: item.serialNumbers,
                                  docType: docTypeCode,
                                  idClassedocument: command.classeDocument?.id,
                                  rawArticleJson: item.rawJson,
                                );
                                final updated = await context.pushNamed<bool>(
                                  RouteNames.bonPreparationSerialNumber,
                                  extra: args,
                                );
                                if (updated == true) {
                                  ref.read(commandDetailsControllerProvider(commandId).notifier).fetchDetails();
                                }
                              },
                              child: Text('SN (${item.serialNumbers.length}/${item.quantity})', style: const TextStyle(fontSize: 11)),
                            ),
                            const SizedBox(width: 4),
                          ],
                          Consumer(
                            builder: (context, ref, child) {
                              if (!isChecklistEnabled) return const SizedBox.shrink();
                              final familyId = item.familyId ?? '';
                              final countAsync = ref.watch(articleChecklistCountProvider('${item.id}:$familyId:$docTypeCode'));
                              return countAsync.when(
                                data: (count) {
                                  if (count.total == 0) return const SizedBox.shrink();
                                  final checked = count.checked;
                                  final total = count.total;
                                  Color btnColor = checked == 0
                                      ? const Color(0xFFEF5350)
                                      : (checked < total ? const Color(0xFFFF9800) : const Color(0xFF4CAF50));
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 4.0),
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: btnColor,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
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
                                            'preparationId': commandId,
                                            'article': prepArticle,
                                            'docType': docTypeCode,
                                          },
                                        );
                                        ref.read(commandDetailsControllerProvider(commandId).notifier).fetchDetails();
                                      },
                                      child: Text('Tasks ($checked/$total)', style: const TextStyle(fontSize: 11)),
                                    ),
                                  );
                                },
                                loading: () => const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                                error: (_, _) => const SizedBox.shrink(),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.info_outline, size: 18),
                            onPressed: () {
                              _showItemDetailDialog(context, item, hidePrices);
                            },
                          ),
                        ],
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
                                  documentId: commandId,
                                  lineId: item.id,
                                  productCode: item.code,
                                  productName: item.name,
                                  quantity: item.quantity,
                                  initialSerialNumbers: item.serialNumbers,
                                  docType: docTypeCode,
                                  idClassedocument: command.classeDocument?.id,
                                  rawArticleJson: item.rawJson,
                                );
                                final updated = await context.pushNamed<bool>(
                                  RouteNames.bonPreparationSerialNumber,
                                  extra: args,
                                );
                                if (updated == true) {
                                  ref.read(commandDetailsControllerProvider(commandId).notifier).fetchDetails();
                                }
                              },
                              child: Text(
                                'SN (${item.serialNumbers.length}/${item.quantity})',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                          ),
                        ],
                        Consumer(
                          builder: (context, ref, child) {
                            if (!isChecklistEnabled) return const SizedBox.shrink();
                            final familyId = item.familyId ?? '';
                            final countAsync = ref.watch(articleChecklistCountProvider('${item.id}:$familyId:$docTypeCode'));
                            return countAsync.when(
                              data: (count) {
                                if (count.total == 0) return const SizedBox.shrink();
                                final checked = count.checked;
                                final total = count.total;
                                Color btnColor = checked == 0
                                    ? const Color(0xFFEF5350)
                                    : (checked < total ? const Color(0xFFFF9800) : const Color(0xFF4CAF50));
                                return Padding(
                                  padding: const EdgeInsets.only(left: 8.0),
                                  child: SizedBox(
                                    height: 36,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: btnColor,
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
                                            'preparationId': commandId,
                                            'article': prepArticle,
                                            'docType': docTypeCode,
                                          },
                                        );
                                        ref.read(commandDetailsControllerProvider(commandId).notifier).fetchDetails();
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
                                child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                              ),
                              error: (_, _) => const SizedBox.shrink(),
                            );
                          },
                        ),
                      ],
                    ),
                    childrenPadding: const EdgeInsets.all(AppSpacing.l).copyWith(top: 0),
                    children: [
                      const Divider(height: 20),
                      _buildMobileDetailRow('Code', item.code),
                      _buildMobileDetailRow('Stockable', isStockable ? 'Oui' : 'Non'),
                      _buildMobileDetailRow('Quantité', '${item.quantity} ${item.unite ?? 'Pièce'}'),
                      if (!hidePrices) ...[
                        _buildMobileDetailRow('PUHT/U', currencyFormat.format(item.unitPrice)),
                        _buildMobileDetailRow('Remise', '${item.discountPercent ?? 0.0} %'),
                        _buildMobileDetailRow('Mnt Net HT', currencyFormat.format(item.netHT ?? item.total)),
                        _buildMobileDetailRow('TVA', '${item.tvaPercent ?? 19.0} %'),
                        _buildMobileDetailRow('PUTTC', currencyFormat.format(item.puTTC ?? (item.unitPrice * 1.19))),
                        _buildMobileDetailRow('Total TTC', currencyFormat.format(item.totalTTC ?? (item.total * 1.19)), isHighlight: true),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
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
        ref.read(commandDetailsControllerProvider(docId).notifier).fetchDetails();
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
        ref.read(commandDetailsControllerProvider(docId).notifier).fetchDetails();
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

  void _showItemDetailDialog(BuildContext context, ArticleItem item, bool hidePrices) {
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
              if (!hidePrices) ...[
                Text('PUHT/U: ${currencyFormat.format(item.unitPrice)}'),
                Text('Remise: ${item.discountPercent ?? 0.0} %'),
                Text('Net HT: ${currencyFormat.format(item.netHT ?? item.total)}'),
                Text('TVA: ${item.tvaPercent ?? 19.0} %'),
                Text('PUTTC: ${currencyFormat.format(item.puTTC ?? (item.unitPrice * 1.19))}'),
                Text('Total TTC: ${currencyFormat.format(item.totalTTC ?? (item.total * 1.19))}'),
              ],
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
