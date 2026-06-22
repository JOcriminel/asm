import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dux_front/core/theme/app_sizes.dart';
import 'package:dux_front/core/widgets/primary_button.dart';
import 'package:dux_front/core/widgets/dux_app_bar_title.dart';
import 'package:dux_front/features/bon_preparation/data/repositories/bon_preparation_repository_impl.dart';
import '../controllers/bon_preparation_detail_controller.dart';
import 'package:dux_front/features/bon_sortie/presentation/controllers/bon_sortie_detail_controller.dart';
import 'package:dux_front/features/command_details/presentation/controllers/command_details_controller.dart';
import '../widgets/scanner_overlay.dart';
import 'package:dux_front/core/services/serial_number_cache_service.dart';
import 'package:dux_front/core/services/screen_config_controller.dart';

class SerialNumberArgs {
  final String documentId;
  final String lineId;
  final String productCode;
  final String productName;
  final int quantity;
  final List<String> initialSerialNumbers;
  final String docType;
  final String? idClassedocument;
  final Map<String, dynamic>? rawArticleJson;

  const SerialNumberArgs({
    required this.documentId,
    required this.lineId,
    required this.productCode,
    required this.productName,
    required this.quantity,
    required this.initialSerialNumbers,
    required this.docType,
    this.idClassedocument,
    this.rawArticleJson,
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
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final inputCount = max(widget.args.quantity, widget.args.initialSerialNumbers.length);
    _controllers = List.generate(
      inputCount,
      (index) => TextEditingController(
        text: index < widget.args.initialSerialNumbers.length
            ? widget.args.initialSerialNumbers[index]
            : '',
      ),
    );
    _focusNodes = List.generate(
      inputCount,
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

  Future<void> _openScanner(int startIndex) async {
    final initialScanned = _controllers.where((c) => c.text.trim().isNotEmpty).length;
    final config = ref.read(screenConfigControllerProvider).configs[widget.args.docType];

    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => ScannerOverlay(
          title: widget.args.productName,
          continuousMode: true,
          expectedCount: widget.args.quantity,
          initialScannedCount: initialScanned,
          enableSoundAlerts: config?.enableSoundAlerts ?? true,
          enableVibrationAlerts: config?.enableVibrationAlerts ?? true,
          onBarcodeScanned: (scannedCode) {
            int? nextEmptyIndex;
            for (int i = 0; i < _controllers.length; i++) {
              final checkIndex = (startIndex + i) % _controllers.length;
              if (_controllers[checkIndex].text.trim().isEmpty) {
                nextEmptyIndex = checkIndex;
                break;
              }
            }

            if (nextEmptyIndex != null) {
              final index = nextEmptyIndex;
              setState(() {
                _controllers[index].text = scannedCode;
                _validationError = null;
              });
              _focusNextEmpty(index);
            }
          },
        ),
      ),
    );
  }

  void _focusNextEmpty(int currentIndex) {
    int? nextEmptyIndex;
    
    for (int i = currentIndex + 1; i < _controllers.length; i++) {
      if (_controllers[i].text.trim().isEmpty) {
        nextEmptyIndex = i;
        break;
      }
    }
    
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
      FocusScope.of(context).unfocus();
    }
  }

  bool _validateInputs() {
    final values = _controllers.map((c) => c.text.trim()).toList();
    final nonExactEmptyValues = values.where((val) => val.isNotEmpty).toList();

    if (nonExactEmptyValues.length > widget.args.quantity) {
      setState(() {
        _validationError = 'Vous avez scanné plus de numéros de série que la quantité demandée (${widget.args.quantity}). Veuillez en supprimer.';
      });
      return false;
    }

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
        
        try {
          await ref.read(bonPreparationRepositoryProvider).deleteSerialNumber(id);
          
          if (mounted) {
            setState(() {
              _isLoadingIds = false;
            });
            ref.read(serialNumberCacheServiceProvider).untrackSerialNumber(snValue);
            
            setState(() {
              _controllers[index].clear();
              _serialNumberIds.remove(snValue);
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Numéro de série supprimé avec succès.')),
            );
          }
        } catch (e) {
          if (mounted) {
            setState(() {
              _isLoadingIds = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Échec de la suppression : ${e.toString()}')),
            );
          }
        }
      }
    } else {
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

    List<String> otherLinesSerialNumbers = [];
    if (widget.args.docType == 'BP') {
      final state = ref.read(bonPreparationDetailControllerProvider(widget.args.documentId));
      if (state.preparation != null) {
        for (var article in state.preparation!.articles) {
          if (article.id != widget.args.lineId) {
            otherLinesSerialNumbers.addAll(article.serialNumbers.map((s) => s.trim().toLowerCase()));
          }
        }
      }
    } else if (widget.args.docType == 'BS') {
      final state = ref.read(bonSortieDetailControllerProvider(widget.args.documentId));
      if (state.sortie != null) {
        for (var article in state.sortie!.articles) {
          if (article.id != widget.args.lineId) {
            otherLinesSerialNumbers.addAll(article.serialNumbers.map((s) => s.trim().toLowerCase()));
          }
        }
      }
    } else if (widget.args.docType == 'BC') {
      final state = ref.read(commandDetailsControllerProvider(widget.args.documentId));
      if (state.command != null) {
        for (var article in state.command!.articles) {
          if (article.id != widget.args.lineId) {
            otherLinesSerialNumbers.addAll(article.serialNumbers.map((s) => s.trim().toLowerCase()));
          }
        }
      }
    }

    for (var sn in serials) {
      if (otherLinesSerialNumbers.contains(sn.toLowerCase())) {
        setState(() {
          _validationError = 'Le numéro de série $sn est déjà utilisé dans une autre ligne de ce document.';
        });
        return;
      }
    }

    setState(() {
      _isSaving = true;
      _validationError = null;
    });

    try {
      await ref.read(bonPreparationRepositoryProvider).saveSerialNumbers(
        documentId: widget.args.documentId,
        lineId: widget.args.lineId,
        serialNumbers: serials,
        idClassedocument: widget.args.idClassedocument,
        rawArticleJson: widget.args.rawArticleJson,
      );

      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Numéros de série enregistrés avec succès !')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _validationError = 'Erreur lors de l\'enregistrement : ${e.toString()}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const DuxAppBarTitle(title: 'Saisie N° Série')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _controllers.length,
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
                          textInputAction: TextInputAction.next,
                          onFieldSubmitted: (value) {
                            if (value.trim().isNotEmpty) {
                              _focusNextEmpty(index);
                            }
                          },
                          decoration: InputDecoration(
                            labelText: 'Numéro de Série ${index + 1}',
                            hintText: 'Saisir ou scanner le SN...',
                            prefixIcon: const Icon(Icons.qr_code_2_rounded, size: 20),
                          ),
                          onChanged: (_) {
                            setState(() {});
                            if (_validationError != null) {
                              setState(() {
                                _validationError = null;
                              });
                            }
                          },
                        ),
                      ),
                      AppSpacing.gapM,
                      
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

            _isSaving
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
