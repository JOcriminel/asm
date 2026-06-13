import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dux_front/core/theme/app_sizes.dart';
import 'package:dux_front/core/widgets/primary_button.dart';
import 'package:dux_front/core/widgets/dux_app_bar_title.dart';
import 'package:dux_front/features/bon_preparation/data/repositories/bon_preparation_repository_impl.dart';
import '../controllers/bon_preparation_detail_controller.dart';
import '../widgets/scanner_overlay.dart';


class SerialNumberArgs {
  final String documentId;
  final String lineId;
  final String productCode;
  final String productName;
  final int quantity;
  final List<String> initialSerialNumbers;

  const SerialNumberArgs({
    required this.documentId,
    required this.lineId,
    required this.productCode,
    required this.productName,
    required this.quantity,
    required this.initialSerialNumbers,
  });
}

class SerialNumberEntryScreen extends ConsumerStatefulWidget {
  final SerialNumberArgs args;

  const SerialNumberEntryScreen({
    super.key,
    required this.args,
  });

  @override
  ConsumerState<SerialNumberEntryScreen> createState() => _SerialNumberEntryScreenState();
}

class _SerialNumberEntryScreenState extends ConsumerState<SerialNumberEntryScreen> {
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;
  String? _validationError;
  Map<String, String> _serialNumberIds = {};
  bool _isLoadingIds = false;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.args.quantity,
      (index) => TextEditingController(
        text: index < widget.args.initialSerialNumbers.length
            ? widget.args.initialSerialNumbers[index]
            : '',
      ),
    );
    _focusNodes = List.generate(
      widget.args.quantity,
      (_) => FocusNode(),
    );
    _fetchSerialNumberIds();
  }

  Future<void> _fetchSerialNumberIds() async {
    setState(() {
      _isLoadingIds = true;
    });
    try {
      final repo = ref.read(bonPreparationRepositoryProvider);
      final ids = await repo.getSerialNumberIds(widget.args.lineId);
      if (mounted) {
        setState(() {
          _serialNumberIds = ids;
          _isLoadingIds = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingIds = false;
        });
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }


  Future<void> _openScanner(int index) async {
    final scannedCode = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (context) => ScannerOverlay(
          title: '${widget.args.productName} (Serial ${index + 1}/${widget.args.quantity})',
        ),
      ),
    );

    if (scannedCode != null && scannedCode.isNotEmpty) {
      setState(() {
        _controllers[index].text = scannedCode;
        _validationError = null; // Reset validation on edit
      });

      // Move to next empty input field
      _focusNextEmpty(index);
    }
  }

  void _focusNextEmpty(int currentIndex) {
    int? nextEmptyIndex;
    
    // Check fields after current
    for (int i = currentIndex + 1; i < _controllers.length; i++) {
      if (_controllers[i].text.trim().isEmpty) {
        nextEmptyIndex = i;
        break;
      }
    }
    
    // Fallback: check fields before current
    if (nextEmptyIndex == null) {
      for (int i = 0; i < currentIndex; i++) {
        if (_controllers[i].text.trim().isEmpty) {
          nextEmptyIndex = i;
          break;
        }
      }
    }

    if (nextEmptyIndex != null) {
      _focusNodes[nextEmptyIndex].requestFocus();
    } else {
      // All filled, remove focus
      FocusScope.of(context).unfocus();
    }
  }

  bool _validateInputs() {
    final values = _controllers.map((c) => c.text.trim()).toList();
    final nonExactEmptyValues = values.where((val) => val.isNotEmpty).toList();

    // Check for duplicate fields among non-empty values
    final uniqueValues = nonExactEmptyValues.toSet();
    if (uniqueValues.length < nonExactEmptyValues.length) {
      setState(() {
        _validationError = 'Les numéros de série en doublon ne sont pas autorisés.';
      });
      return false;
    }

    setState(() {
      _validationError = null;
    });
    return true;
  }

  Future<void> _handleDelete(int index) async {
    final snValue = _controllers[index].text.trim();
    final id = _serialNumberIds[snValue];

    if (id != null && id.isNotEmpty) {
      // It exists in the database, confirm and delete via API
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Supprimer le numéro de série'),
          content: Text('Voulez-vous vraiment supprimer définitivement le numéro de série "$snValue" de DUX ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Supprimer'),
            ),
          ],
        ),
      );

      if (confirm == true) {
        setState(() {
          _isLoadingIds = true;
        });
        
        final controller = ref.read(bonPreparationDetailControllerProvider(widget.args.documentId).notifier);
        final success = await controller.deleteSerialNumber(id);
        
        if (mounted) {
          setState(() {
            _isLoadingIds = false;
          });
          if (success) {
            setState(() {
              _controllers[index].clear();
              _serialNumberIds.remove(snValue);
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Numéro de série supprimé avec succès.')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Échec de la suppression du numéro de série.')),
            );
          }
        }
      }
    } else {
      // Just local clean
      setState(() {
        _controllers[index].clear();
      });
    }
  }

  Future<void> _save() async {
    if (!_validateInputs()) return;

    final serials = _controllers
        .map((c) => c.text.trim())
        .where((val) => val.isNotEmpty)
        .toList();
    final controller = ref.read(bonPreparationDetailControllerProvider(widget.args.documentId).notifier);

    final success = await controller.saveSerialNumbers(
      lineId: widget.args.lineId,
      serialNumbers: serials,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Numéros de série enregistrés avec succès !')),
      );
      Navigator.of(context).pop(true); // Return success to details page
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(bonPreparationDetailControllerProvider(widget.args.documentId));

    return Scaffold(
      appBar: AppBar(
        title: const DuxAppBarTitle(title: 'Saisie N° Série'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Info Card
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
                  Text(
                    widget.args.productName,
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  AppSpacing.gapS,
                  Text(
                    'Code Article: ${widget.args.productCode}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontFamily: 'monospace',
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                  AppSpacing.gapXs,
                  Text(
                    'Quantité Totale: ${widget.args.quantity}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            AppSpacing.gapL,

            // Validation Error alert banner
            if (_validationError != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.m),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: AppBorderRadius.roundedM,
                  border: Border.all(color: theme.colorScheme.error),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline_rounded, color: theme.colorScheme.onErrorContainer),
                    AppSpacing.gapM,
                    Expanded(
                      child: Text(
                        _validationError!,
                        style: TextStyle(color: theme.colorScheme.onErrorContainer, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              AppSpacing.gapL,
            ],

            if (_isLoadingIds) ...[
              const LinearProgressIndicator(),
              AppSpacing.gapM,
            ],

            // Dynamic Inputs List
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.args.quantity,
              itemBuilder: (context, index) {
                final isFilled = _controllers[index].text.trim().isNotEmpty;
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.m),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _controllers[index],
                          focusNode: _focusNodes[index],
                          decoration: InputDecoration(
                            labelText: 'Numéro de Série ${index + 1}',
                            hintText: 'Saisir ou scanner le SN...',
                            prefixIcon: const Icon(Icons.qr_code_2_rounded, size: 20),
                          ),
                          onChanged: (_) {
                            setState(() {}); // Rebuild to toggle scanner/delete button
                            if (_validationError != null) {
                              setState(() {
                                _validationError = null;
                              });
                            }
                          },
                        ),
                      ),
                      AppSpacing.gapM,
                      
                      // Scanner or Delete button
                      isFilled
                          ? IconButton(
                              icon: Icon(Icons.close_rounded, color: theme.colorScheme.error),
                              tooltip: 'Supprimer le numéro de série',
                              onPressed: () => _handleDelete(index),
                            )
                          : IconButton.filledTonal(
                              icon: const Icon(Icons.photo_camera_rounded),
                              tooltip: 'Scanner le code',
                              onPressed: () => _openScanner(index),
                            ),
                    ],
                  ),
                );
              },
            ),
            AppSpacing.gapL,

            // Save / Submit Button
            state.isSaving
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : PrimaryButton(
                    text: 'Enregistrer les SN',
                    onPressed: _save,
                  ),
          ],
        ),
      ),
    );
  }
}
