import 'package:flutter/material.dart';
import '../theme/app_sizes.dart';

class AppSearchBar extends StatefulWidget {
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final List<String> recentSearches;
  final ValueChanged<String>? onRecentSearchTapped;
  final ValueChanged<String>? onSearchSubmitted;

  const AppSearchBar({
    super.key,
    this.hintText = 'Search...',
    this.onChanged,
    this.onClear,
    this.controller,
    this.focusNode,
    this.recentSearches = const [],
    this.onRecentSearchTapped,
    this.onSearchSubmitted,
  });

  @override
  State<AppSearchBar> createState() => _AppSearchBarState();
}

class _AppSearchBarState extends State<AppSearchBar> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  bool _showClear = false;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(_onTextChanged);
    _showClear = _controller.text.isNotEmpty;

    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChanged);
  }

  void _onFocusChanged() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  void _onTextChanged() {
    final show = _controller.text.isNotEmpty;
    if (show != _showClear) {
      setState(() {
        _showClear = show;
      });
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    } else {
      _controller.removeListener(_onTextChanged);
    }
    if (widget.focusNode == null) {
      _focusNode.dispose();
    } else {
      _focusNode.removeListener(_onFocusChanged);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppBorderRadius.roundedM,
        boxShadow: AppShadows.softShadow(context),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _controller,
            focusNode: _focusNode,
            onChanged: widget.onChanged,
            onSubmitted: widget.onSearchSubmitted,
            style: theme.textTheme.bodyLarge,
            decoration: InputDecoration(
              hintText: widget.hintText,
              prefixIcon: Icon(
                Icons.search,
                color: theme.colorScheme.secondary,
                size: 20,
              ),
              suffixIcon: _showClear
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _controller.clear();
                        widget.onChanged?.call('');
                        widget.onClear?.call();
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.transparent,
              contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.m),
              border: OutlineInputBorder(
                borderRadius: AppBorderRadius.roundedM,
                borderSide: BorderSide(color: theme.colorScheme.outline, width: 1),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppBorderRadius.roundedM,
                borderSide: BorderSide(color: theme.colorScheme.outline, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: AppBorderRadius.roundedM,
                borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
              ),
            ),
          ),
          if (_isFocused && widget.recentSearches.isNotEmpty) ...[
            const Divider(height: 1),
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(AppBorderRadius.m)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.s),
                    child: Text(
                      'Recherches récentes',
                      style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.secondary),
                    ),
                  ),
                  ...widget.recentSearches.map((query) => InkWell(
                        onTap: () {
                          _controller.text = query;
                          widget.onRecentSearchTapped?.call(query);
                          _focusNode.unfocus();
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.s),
                          child: Row(
                            children: [
                              Icon(Icons.history, size: 16, color: theme.colorScheme.secondary),
                              AppSpacing.gapS,
                              Expanded(
                                child: Text(query, style: theme.textTheme.bodyMedium),
                              ),
                              Icon(Icons.north_west, size: 16, color: theme.colorScheme.secondary),
                            ],
                          ),
                        ),
                      )),
                  AppSpacing.gapS,
                ],
              ),
            ),
          ]
        ],
      ),
    );
  }
}
