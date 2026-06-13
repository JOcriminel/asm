import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_sizes.dart';
import '../../../../core/widgets/dux_app_bar_title.dart';
import '../../../../core/widgets/dux_drawer.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../controllers/activity_feed_controller.dart';

class ActivityFeedScreen extends ConsumerStatefulWidget {
  const ActivityFeedScreen({super.key});

  @override
  ConsumerState<ActivityFeedScreen> createState() => _ActivityFeedScreenState();
}

class _ActivityFeedScreenState extends ConsumerState<ActivityFeedScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(activityFeedControllerProvider.notifier).fetchFeed();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(activityFeedControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      drawer: const DuxDrawer(),
      appBar: AppBar(
        title: const DuxAppBarTitle(title: 'Journal d\'Activité'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(activityFeedControllerProvider.notifier).fetchFeed(refresh: true),
          ),
        ],
      ),
      body: _buildBody(state, theme),
    );
  }

  Widget _buildBody(ActivityFeedState state, ThemeData theme) {
    if (state.isLoading && state.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.items.isEmpty) {
      return Center(
        child: ErrorStateWidget(
          description: state.error!,
          onRetry: () => ref.read(activityFeedControllerProvider.notifier).fetchFeed(refresh: true),
        ),
      );
    }

    if (state.items.isEmpty) {
      return const Center(child: Text("Aucune activité récente."));
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(activityFeedControllerProvider.notifier).fetchFeed(refresh: true),
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.all(AppSpacing.m),
        itemCount: state.items.length + (state.hasReachedMax ? 0 : 1),
        separatorBuilder: (context, index) => const Divider(),
        itemBuilder: (context, index) {
          if (index >= state.items.length) {
            return const Padding(
              padding: EdgeInsets.all(AppSpacing.l),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final item = state.items[index];
          final isScan = item.action == "SCAN";

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: isScan ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
              child: Icon(
                isScan ? Icons.qr_code_scanner : Icons.delete_outline,
                color: isScan ? Colors.green : Colors.orange,
              ),
            ),
            title: Text(
              isScan ? 'Article Scanné' : 'Article Supprimé',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppSpacing.gapXs,
                Text('N° Série: ${item.serialNumber}'),
                Text('Par: ${item.userId}', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary)),
              ],
            ),
            trailing: Text(
              item.relativeTime,
              style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.secondary),
            ),
          );
        },
      ),
    );
  }
}
