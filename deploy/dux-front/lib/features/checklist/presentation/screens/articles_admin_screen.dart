import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dux_front/core/theme/app_sizes.dart';
import '../../data/repositories/checklist_repository.dart';

class ArticlesAdminScreen extends ConsumerStatefulWidget {
  const ArticlesAdminScreen({super.key});

  @override
  ConsumerState<ArticlesAdminScreen> createState() => _ArticlesAdminScreenState();
}

class _ArticlesAdminScreenState extends ConsumerState<ArticlesAdminScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  final List<Map<String, dynamic>> _articles = [];
  int _currentPage = 0;
  bool _isLoading = false;
  bool _hasMore = true;
  String _currentQuery = '';
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadArticles();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadArticles() async {
    if (_isLoading) return;

    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final repo = ref.read(checklistRepositoryProvider);
      final newArticles = await repo.getArticles(
        search: _currentQuery,
        page: _currentPage,
        size: 15,
      );

      if (mounted) {
        setState(() {
          _articles.clear();
          _articles.addAll(newArticles);
          _isLoading = false;
          _hasMore = newArticles.length == 15;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _currentQuery = value;
      _currentPage = 0;
      _loadArticles();
    });
    setState(() {}); // Updates the clear suffix icon immediately
  }

  Future<void> _goToPage(int page) async {
    if (_isLoading) return;
    setState(() {
      _currentPage = page;
    });
    await _loadArticles();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Articles & Familles'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.l),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher un article par code ou nom...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _debounce?.cancel();
                          _currentQuery = '';
                          _currentPage = 0;
                          _loadArticles();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          Expanded(
            child: _buildContent(theme),
          ),
          _buildPaginationFooter(theme),
        ],
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    if (_errorMessage != null && _articles.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Erreur: $_errorMessage',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _loadArticles(),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_articles.isEmpty) {
      return const Center(child: Text('Aucun article trouvé.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
      itemCount: _articles.length,
      itemBuilder: (context, index) {
        final article = _articles[index];
        final String name = article['libelle']?.toString() ?? 'Nom inconnu';
        final String code = article['code']?.toString() ?? '-';
        final String familyName = article['libelleFamille']?.toString() ?? 'Inconnue';
        final String familyCode = article['codeFamille']?.toString() ?? 'vide';

        return Card(
          margin: const EdgeInsets.only(bottom: AppSpacing.m),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: AppBorderRadius.roundedL,
            side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Code: $code',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.secondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Famille: $familyCode',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24, thickness: 0.5),
                Row(
                  children: [
                    Icon(Icons.folder_outlined, size: 16, color: theme.colorScheme.secondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Nom de Famille: $familyName',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPaginationFooter(ThemeData theme) {
    if (_articles.isEmpty && !_isLoading) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5), width: 0.5),
        ),
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton.filledTonal(
              onPressed: _currentPage > 0 && !_isLoading ? () => _goToPage(_currentPage - 1) : null,
              icon: const Icon(Icons.arrow_back_ios_new, size: 16),
              style: IconButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                'Page ${_currentPage + 1}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            IconButton.filledTonal(
              onPressed: _hasMore && !_isLoading ? () => _goToPage(_currentPage + 1) : null,
              icon: const Icon(Icons.arrow_forward_ios, size: 16),
              style: IconButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
