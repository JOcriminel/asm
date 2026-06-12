import 'package:flutter/material.dart';
import '../theme/app_sizes.dart';

class AppSearchBar extends StatefulWidget {
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final TextEditingController? controller;

  const AppSearchBar({
    super.key,
    this.hintText = 'Search...',
    this.onChanged,
    this.onClear,
    this.controller,
  });

  @override
  State<AppSearchBar> createState() => _AppSearchBarState();
}

class _AppSearchBarState extends State<AppSearchBar> {
  late final TextEditingController _controller;
  bool _showClear = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(_onTextChanged);
    _showClear = _controller.text.isNotEmpty;
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
      child: TextField(
        controller: _controller,
        onChanged: widget.onChanged,
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
    );
  }
}
