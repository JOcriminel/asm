import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/widgets/app_search_bar.dart';
import '../../../../core/widgets/dux_app_bar_title.dart';
import '../../../../core/widgets/dux_drawer.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../controllers/clients_controller.dart';
import '../widgets/client_filter_bottom_sheet.dart';

class ClientsListScreen extends ConsumerStatefulWidget {
  const ClientsListScreen({super.key});

  @override
  ConsumerState<ClientsListScreen> createState() => _ClientsListScreenState();
}

class _ClientsListScreenState extends ConsumerState<ClientsListScreen> {
  final ScrollController _scrollController = ScrollController();
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(clientsControllerProvider.notifier).fetchClients();
    }
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: const ClientFilterBottomSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(clientsControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      drawer: const DuxDrawer(),
      appBar: AppBar(
        title: const DuxAppBarTitle(title: 'Clients'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterSheet,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(clientsControllerProvider.notifier).refresh(),
          ),
        ],
      ),
      body: Column(
        children: [
          AppSearchBar(
            controller: _searchController,
            hintText: 'Rechercher un client...',
            onChanged: (val) {
              final currentFilter = ref.read(clientsControllerProvider).filter;
              ref.read(clientsControllerProvider.notifier).updateFilter(currentFilter.copyWith(searchTerm: val));
            },
          ),
          Expanded(
            child: _buildContent(state, theme),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ClientsState state, ThemeData theme) {
    if (state.isLoading && state.clients.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.clients.isEmpty) {
      return ErrorStateWidget(
        title: 'Erreur',
        description: state.error!,
        onRetry: () => ref.read(clientsControllerProvider.notifier).refresh(),
      );
    }

    if (state.clients.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.group_off_outlined,
        title: 'Aucun client',
        description: 'Il n\'y a pas de clients correspondant à vos critères.',
        actionLabel: 'Actualiser',
        onActionPressed: () => ref.read(clientsControllerProvider.notifier).refresh(),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.read(clientsControllerProvider.notifier).refresh();
      },
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(AppSpacing.m),
        itemCount: state.clients.length + (state.isFetchingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == state.clients.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.m),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final client = state.clients[index];
          return Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.m),
            child: InkWell(
              onTap: () => context.push('/clients/details/${client.id}'),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.l),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.1)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                      child: Icon(Icons.person, color: theme.colorScheme.primary),
                    ),
                    AppSpacing.gapM,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            client.nomPrenom.isNotEmpty ? client.nomPrenom : 'Client Inconnu',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Code: ${client.code}',
                            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                          if (client.ville != null && client.ville!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Row(
                                children: [
                                  Icon(Icons.location_on_outlined, size: 14, color: theme.colorScheme.onSurfaceVariant),
                                  const SizedBox(width: 4),
                                  Text(client.ville!, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
