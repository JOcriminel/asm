import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dux_front/core/theme/app_sizes.dart';
import 'package:dux_front/core/widgets/info_card.dart';
import 'package:dux_front/core/widgets/section_header.dart';
import 'package:dux_front/core/widgets/dux_app_bar_title.dart';
import 'package:dux_front/core/widgets/loading_skeleton.dart';
import 'package:dux_front/core/widgets/error_state_widget.dart';
import 'package:dux_front/core/widgets/status_badge.dart';
import 'package:dux_front/core/widgets/dux_drawer.dart';
import '../controllers/station_controller.dart';

class StationDetailsScreen extends ConsumerWidget {
  const StationDetailsScreen({super.key});

  void _copyToClipboard(BuildContext context, String text, String fieldName) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$fieldName copié dans le presse-papiers'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(stationControllerProvider);

    return Scaffold(
      drawer: const DuxDrawer(),
      appBar: AppBar(
        title: const DuxAppBarTitle(title: 'Détails de la Station'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(stationControllerProvider.notifier).fetchStationDetails(),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 768;

          if (state.isLoading && state.station == null) {
            return _buildLoadingState();
          }

          if (state.error != null && state.station == null) {
            return ErrorStateWidget(
              description: state.error!,
              onRetry: () => ref.read(stationControllerProvider.notifier).fetchStationDetails(),
            );
          }

          final station = state.station!;
          final isActive = station.active == '1';

          Widget content = RefreshIndicator(
            onRefresh: () => ref.read(stationControllerProvider.notifier).fetchStationDetails(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.l),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Station Main Header Dashboard (Gradient Banner)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.secondary,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: AppBorderRadius.roundedL,
                      boxShadow: AppShadows.softShadow(context),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.warehouse_rounded,
                            color: Colors.white,
                            size: 48,
                          ),
                        ),
                        AppSpacing.gapL,
                        Text(
                          station.name,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        AppSpacing.gapXs,
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            station.typeStation.isNotEmpty ? station.typeStation : 'Station',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        AppSpacing.gapM,
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Chip(
                              label: Text(
                                'Code: ${station.code}',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                              ),
                              backgroundColor: Colors.white.withOpacity(0.2),
                              side: BorderSide.none,
                              shape: const StadiumBorder(),
                            ),
                            AppSpacing.gapM,
                            StatusBadge(status: isActive ? 'active' : 'inactive'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.gapL,

                  // Dynamic layout for details
                  isWide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildContactSection(context, theme, station)),
                            AppSpacing.gapL,
                            Expanded(child: _buildAdminSection(context, theme, station)),
                          ],
                        )
                      : Column(
                          children: [
                            _buildContactSection(context, theme, station),
                            AppSpacing.gapL,
                            _buildAdminSection(context, theme, station),
                          ],
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

  Widget _buildContactSection(BuildContext context, ThemeData theme, dynamic station) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'Coordonnées & Contact'),
        InfoCard(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l, vertical: AppSpacing.s),
          child: Column(
            children: [
              _buildInfoRow(
                context,
                theme,
                Icons.location_on_rounded,
                'Adresse',
                station.address,
                onCopy: () => _copyToClipboard(context, station.address, 'Adresse'),
              ),
              const Divider(),
              _buildInfoRow(
                context,
                theme,
                Icons.phone_rounded,
                'Téléphone',
                station.phone,
                onCopy: () => _copyToClipboard(context, station.phone, 'Téléphone'),
              ),
              const Divider(),
              _buildInfoRow(
                context,
                theme,
                Icons.fax_rounded,
                'Fax',
                station.fax,
                onCopy: () => _copyToClipboard(context, station.fax, 'Fax'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAdminSection(BuildContext context, ThemeData theme, dynamic station) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'Informations Administratives'),
        InfoCard(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l, vertical: AppSpacing.s),
          child: Column(
            children: [
              _buildInfoRow(
                context,
                theme,
                Icons.description_rounded,
                'Matricule Fiscal',
                station.matriculeFiscal,
                onCopy: () => _copyToClipboard(context, station.matriculeFiscal, 'Matricule Fiscal'),
              ),
              const Divider(),
              _buildInfoRow(
                context,
                theme,
                Icons.check_circle_rounded,
                'Statut Station',
                station.active == '1' ? 'Active / Ouverte' : 'Inactive / Fermée',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    ThemeData theme,
    IconData icon,
    String label,
    String value, {
    VoidCallback? onCopy,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: theme.colorScheme.primary, size: 20),
          ),
          AppSpacing.gapM,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.secondary,
                  ),
                ),
                AppSpacing.gapXs,
                Text(
                  value.isNotEmpty ? value : 'Non spécifié',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onBackground,
                  ),
                ),
              ],
            ),
          ),
          if (onCopy != null && value.isNotEmpty && value != 'N/A') ...[
            IconButton(
              icon: const Icon(Icons.copy_rounded, size: 18),
              onPressed: onCopy,
              tooltip: 'Copier',
              visualDensity: VisualDensity.compact,
            ),
          ],
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
          const LoadingSkeleton(height: 180, width: double.infinity),
          AppSpacing.gapL,
          const LoadingSkeleton(height: 24, width: 180),
          AppSpacing.gapM,
          const LoadingSkeleton(height: 200, width: double.infinity),
        ],
      ),
    );
  }
}
