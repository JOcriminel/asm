import 'package:dux_front/core/widgets/dux_app_bar_title.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/widgets/info_card.dart';
import '../../../../core/widgets/dux_loading_screen.dart';
import '../../../../core/widgets/section_header.dart';
import '../controllers/client_details_controller.dart';
import 'package:intl/intl.dart';

class ClientDetailsScreen extends ConsumerWidget {
  final String clientId;

  const ClientDetailsScreen({super.key, required this.clientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(clientDetailsControllerProvider(clientId));
    final theme = Theme.of(context);

    if (state.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const DuxAppBarTitle(title: 'Détails Client')),
        body: const DuxLoadingScreen(isFullScreen: false),
      );
    }

    if (state.error != null || state.client == null) {
      return Scaffold(
        appBar: AppBar(title: const DuxAppBarTitle(title: 'Détails Client')),
        body: Center(child: Text(state.error ?? 'Client introuvable')),
      );
    }

    final client = state.client!;

    return Scaffold(
      appBar: AppBar(
        title: Text(client.nomPrenom.isNotEmpty ? client.nomPrenom : 'Détails Client'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(title: 'Informations Générales'),
            InfoCard(
              child: Column(
                children: [
                  _InfoRow(icon: Icons.person, label: 'Nom', value: client.nomPrenom),
                  const Divider(),
                  _InfoRow(icon: Icons.tag, label: 'Code', value: client.code),
                  const Divider(),
                  _InfoRow(icon: Icons.phone, label: 'Téléphone', value: client.tel ?? '-'),
                  const Divider(),
                  _InfoRow(icon: Icons.email, label: 'Email', value: client.mail ?? '-'),
                  const Divider(),
                  _InfoRow(icon: Icons.location_on, label: 'Ville', value: client.ville ?? '-'),
                  const Divider(),
                  _InfoRow(icon: Icons.home, label: 'Adresse', value: client.adresse ?? '-'),
                  if (client.dateCreation != null) ...[
                    const Divider(),
                    _InfoRow(icon: Icons.calendar_today, label: 'Création', value: DateFormat('dd/MM/yyyy').format(client.dateCreation!)),
                  ],
                ],
              ),
            ),
            
            AppSpacing.gapXxl,
            const SectionHeader(title: 'Statistiques des Documents'),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Bons de\nCommande',
                    count: state.commandsCount,
                    icon: Icons.receipt_long,
                    color: theme.colorScheme.primary,
                  ),
                ),
                AppSpacing.gapM,
                Expanded(
                  child: _StatCard(
                    title: 'Bons de\nPréparation',
                    count: state.preparationsCount,
                    icon: Icons.precision_manufacturing,
                    color: const Color(0xFFF6D32D),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          AppSpacing.gapM,
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final int count;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.l),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.1),
            child: Icon(icon, color: color),
          ),
          AppSpacing.gapM,
          Text(
            count.toString(),
            style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: color),
          ),
          AppSpacing.gapS,
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

