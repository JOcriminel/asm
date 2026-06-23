import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dux_front/features/timetree/domain/models/timetree_custom_field.dart';

/// A dynamic form renderer that renders input widgets based on Custom Field definitions.
///
/// Supports validation, display rules (hidden, read-only, conditional visibility),
/// and formatting for 14 different field types.
class DynamicEventFormRenderer extends StatefulWidget {
  final List<TimetreeCustomField> fields;
  final Map<String, String> values;
  final Function(Map<String, String> values) onValuesChanged;
  final GlobalKey<FormState> formKey;

  const DynamicEventFormRenderer({
    super.key,
    required this.fields,
    required this.values,
    required this.onValuesChanged,
    required this.formKey,
  });

  @override
  State<DynamicEventFormRenderer> createState() => _DynamicEventFormRendererState();
}

class _DynamicEventFormRendererState extends State<DynamicEventFormRenderer> {
  late Map<String, String> _currentValues;

  @override
  void initState() {
    super.initState();
    _currentValues = Map<String, String>.from(widget.values);
    // Initialize default values for missing keys
    for (final field in widget.fields) {
      if (!_currentValues.containsKey(field.id) && field.defaultValue != null) {
        _currentValues[field.id] = field.defaultValue!;
      }
    }
  }

  @override
  void didUpdateWidget(covariant DynamicEventFormRenderer oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Synchronize external values change, preserving local edits for keys that exist
    for (final field in widget.fields) {
      if (widget.values.containsKey(field.id) && widget.values[field.id] != oldWidget.values[field.id]) {
        _currentValues[field.id] = widget.values[field.id]!;
      }
    }
  }

  void _updateValue(String fieldId, String value) {
    setState(() {
      _currentValues[fieldId] = value;
    });
    widget.onValuesChanged(_currentValues);
  }

  /// Evaluates conditional visibility for a field based on current form values.
  ///
  /// Rule format: "fieldName==value" or "fieldLabel==value"
  bool _evalVisibility(TimetreeCustomField field) {
    if (field.hidden) return false;
    final rule = field.visibilityRule;
    if (rule == null || rule.isEmpty) return true;

    try {
      final parts = rule.split('==');
      if (parts.length == 2) {
        final targetFieldName = parts[0].trim();
        final targetValue = parts[1].trim();

        // Find the target field by name or label
        final targetField = widget.fields.firstWhere(
          (f) => f.name == targetFieldName || f.label == targetFieldName,
          orElse: () => throw Exception('Target field not found'),
        );

        final actualValue = _currentValues[targetField.id] ?? '';
        return actualValue == targetValue;
      }
    } catch (e) {
      // Fallback to visible if parsing fails
      return true;
    }
    return true;
  }

  List<String> _parseOptions(String? optionsStr) {
    if (optionsStr == null || optionsStr.isEmpty) return [];
    return optionsStr.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visibleFields = widget.fields.where(_evalVisibility).toList();

    if (visibleFields.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            'Aucun champ personnalisé disponible.',
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
        ),
      );
    }

    return Form(
      key: widget.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: visibleFields.map((field) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildFieldWidget(context, field, theme),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFieldWidget(BuildContext context, TimetreeCustomField field, ThemeData theme) {
    final isReadOnly = field.readOnly;
    final currentValue = _currentValues[field.id] ?? '';

    // Check if select-based types have options
    final options = _parseOptions(field.options);

    switch (field.fieldType.toUpperCase()) {
      case 'BOOLEAN':
        final boolVal = currentValue.toLowerCase() == 'true';
        return SwitchListTile(
          title: Text(field.label),
          subtitle: field.required ? const Text('Requis', style: TextStyle(color: Colors.red, fontSize: 12)) : null,
          value: boolVal,
          onChanged: isReadOnly
              ? null
              : (val) {
                  _updateValue(field.id, val.toString());
                },
        );

      case 'RADIO':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(field.label, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
            if (field.required) const Text('Requis', style: TextStyle(color: Colors.red, fontSize: 12)),
            const SizedBox(height: 8),
            if (options.isEmpty)
              const Text('Aucune option configurée.', style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12))
            else
              ...options.map((opt) {
                return RadioListTile<String>(
                  title: Text(opt),
                  value: opt,
                  groupValue: currentValue,
                  onChanged: isReadOnly
                      ? null
                      : (val) {
                          if (val != null) _updateValue(field.id, val);
                        },
                );
              }),
            FormField<String>(
              initialValue: currentValue,
              validator: (val) {
                if (field.required && (val == null || val.isEmpty)) {
                  return 'Veuillez sélectionner une option';
                }
                return null;
              },
              builder: (state) {
                if (state.hasError) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 16, top: 4),
                    child: Text(
                      state.errorText ?? '',
                      style: TextStyle(color: theme.colorScheme.error, fontSize: 12),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        );

      case 'CHECKBOX':
        final selectedList = currentValue.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(field.label, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
            if (field.required) const Text('Requis', style: TextStyle(color: Colors.red, fontSize: 12)),
            const SizedBox(height: 8),
            if (options.isEmpty)
              CheckboxListTile(
                title: Text(field.label),
                value: currentValue.toLowerCase() == 'true',
                onChanged: isReadOnly
                    ? null
                    : (val) {
                        _updateValue(field.id, (val ?? false).toString());
                      },
              )
            else
              ...options.map((opt) {
                final isChecked = selectedList.contains(opt);
                return Material(
                  color: Colors.transparent,
                  child: CheckboxListTile(
                    title: Text(opt),
                    value: isChecked,
                    onChanged: isReadOnly
                        ? null
                        : (val) {
                            final newList = List<String>.from(selectedList);
                            if (val == true) {
                              newList.add(opt);
                            } else {
                              newList.remove(opt);
                            }
                            _updateValue(field.id, newList.join(', '));
                          },
                  ),
                );
              }),
            FormField<String>(
              initialValue: currentValue,
              validator: (val) {
                if (field.required && (val == null || val.trim().isEmpty || val == 'false')) {
                  return 'Ce champ est requis';
                }
                return null;
              },
              builder: (state) {
                if (state.hasError) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 16, top: 4),
                    child: Text(
                      state.errorText ?? '',
                      style: TextStyle(color: theme.colorScheme.error, fontSize: 12),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        );

      case 'DROPDOWN':
        return DropdownButtonFormField<String>(
          decoration: InputDecoration(
            labelText: field.label,
            border: const OutlineInputBorder(),
          ),
          value: options.contains(currentValue) ? currentValue : null,
          items: options.map((opt) {
            return DropdownMenuItem<String>(
              value: opt,
              child: Text(opt),
            );
          }).toList(),
          onChanged: isReadOnly
              ? null
              : (val) {
                  if (val != null) _updateValue(field.id, val);
                },
          validator: (val) {
            if (field.required && (val == null || val.isEmpty)) {
              return 'Veuillez choisir une valeur';
            }
            return null;
          },
        );

      case 'MULTI_SELECT':
        final selectedList = currentValue.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: isReadOnly
                  ? null
                  : () => _showMultiSelectDialog(context, field, options, selectedList),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: field.label,
                  border: const OutlineInputBorder(),
                  suffixIcon: const Icon(Icons.arrow_drop_down),
                ),
                child: Text(
                  selectedList.isEmpty ? 'Aucune option sélectionnée' : selectedList.join(', '),
                  style: selectedList.isEmpty ? const TextStyle(color: Colors.grey) : null,
                ),
              ),
            ),
            FormField<String>(
              initialValue: currentValue,
              validator: (val) {
                if (field.required && (val == null || val.isEmpty)) {
                  return 'Veuillez sélectionner au moins une option';
                }
                return null;
              },
              builder: (state) {
                if (state.hasError) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 12, top: 4),
                    child: Text(
                      state.errorText ?? '',
                      style: TextStyle(color: theme.colorScheme.error, fontSize: 12),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        );

      case 'DATE':
      case 'DATETIME':
        final isDateTime = field.fieldType.toUpperCase() == 'DATETIME';
        return InkWell(
          onTap: isReadOnly
              ? null
              : () => _showDateTimePicker(context, field.id, isDateTime),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: field.label,
              border: const OutlineInputBorder(),
              suffixIcon: Icon(isDateTime ? Icons.calendar_today : Icons.date_range),
            ),
            child: Text(
              currentValue.isEmpty ? 'Sélectionner une date' : currentValue,
              style: currentValue.isEmpty ? const TextStyle(color: Colors.grey) : null,
            ),
          ),
        );

      case 'TEXT_AREA':
        return TextFormField(
          maxLines: 4,
          initialValue: currentValue,
          readOnly: isReadOnly,
          decoration: InputDecoration(
            labelText: field.label,
            border: const OutlineInputBorder(),
          ),
          onChanged: (val) => _updateValue(field.id, val),
          validator: (val) => _validateInput(field, val),
        );

      case 'INTEGER':
        return TextFormField(
          initialValue: currentValue,
          readOnly: isReadOnly,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: field.label,
            border: const OutlineInputBorder(),
          ),
          onChanged: (val) => _updateValue(field.id, val),
          validator: (val) => _validateInput(field, val),
        );

      case 'FLOAT':
        return TextFormField(
          initialValue: currentValue,
          readOnly: isReadOnly,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: field.label,
            border: const OutlineInputBorder(),
          ),
          onChanged: (val) => _updateValue(field.id, val),
          validator: (val) => _validateInput(field, val),
        );

      case 'EMAIL':
        return TextFormField(
          initialValue: currentValue,
          readOnly: isReadOnly,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: field.label,
            border: const OutlineInputBorder(),
          ),
          onChanged: (val) => _updateValue(field.id, val),
          validator: (val) => _validateInput(field, val),
        );

      case 'PHONE':
        return TextFormField(
          initialValue: currentValue,
          readOnly: isReadOnly,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: field.label,
            border: const OutlineInputBorder(),
          ),
          onChanged: (val) => _updateValue(field.id, val),
          validator: (val) => _validateInput(field, val),
        );

      case 'URL':
        return TextFormField(
          initialValue: currentValue,
          readOnly: isReadOnly,
          keyboardType: TextInputType.url,
          decoration: InputDecoration(
            labelText: field.label,
            border: const OutlineInputBorder(),
          ),
          onChanged: (val) => _updateValue(field.id, val),
          validator: (val) => _validateInput(field, val),
        );

      case 'STRING':
      default:
        return TextFormField(
          initialValue: currentValue,
          readOnly: isReadOnly,
          decoration: InputDecoration(
            labelText: field.label,
            border: const OutlineInputBorder(),
          ),
          onChanged: (val) => _updateValue(field.id, val),
          validator: (val) => _validateInput(field, val),
        );
    }
  }

  String? _validateInput(TimetreeCustomField field, String? val) {
    val ??= '';
    
    // Required check
    if (field.required && val.trim().isEmpty) {
      return 'Ce champ est requis';
    }

    if (val.trim().isEmpty) return null;

    // Type specific checks
    final type = field.fieldType.toUpperCase();
    if (type == 'INTEGER') {
      final intVal = int.tryParse(val);
      if (intVal == null) {
        return 'Veuillez saisir un nombre entier valide';
      }
      if (field.minValue != null && intVal < field.minValue!) {
        return 'Valeur minimale: ${field.minValue?.toInt()}';
      }
      if (field.maxValue != null && intVal > field.maxValue!) {
        return 'Valeur maximale: ${field.maxValue?.toInt()}';
      }
    }

    if (type == 'FLOAT') {
      final floatVal = double.tryParse(val);
      if (floatVal == null) {
        return 'Veuillez saisir un nombre décimal valide';
      }
      if (field.minValue != null && floatVal < field.minValue!) {
        return 'Valeur minimale: ${field.minValue}';
      }
      if (field.maxValue != null && floatVal > field.maxValue!) {
        return 'Valeur maximale: ${field.maxValue}';
      }
    }

    // Min / Max Length check
    if (field.minLength != null && val.length < field.minLength!) {
      return 'Longueur minimale: ${field.minLength} caractères';
    }
    if (field.maxLength != null && val.length > field.maxLength!) {
      return 'Longueur maximale: ${field.maxLength} caractères';
    }

    // Format validators
    if (type == 'EMAIL') {
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegex.hasMatch(val)) {
        return 'Adresse email invalide';
      }
    }

    if (type == 'PHONE') {
      final phoneRegex = RegExp(r'^\+?[0-9\s\-]{8,15}$');
      if (!phoneRegex.hasMatch(val)) {
        return 'Numéro de téléphone invalide';
      }
    }

    if (type == 'URL') {
      final urlRegex = RegExp(r'^(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?$');
      if (!urlRegex.hasMatch(val)) {
        return 'Lien URL invalide';
      }
    }

    // Custom regex check
    if (field.regexPattern != null && field.regexPattern!.isNotEmpty) {
      try {
        final customRegex = RegExp(field.regexPattern!);
        if (!customRegex.hasMatch(val)) {
          return 'Format invalide';
        }
      } catch (e) {
        // Ignore invalid regex settings on field definition
      }
    }

    return null;
  }

  Future<void> _showDateTimePicker(BuildContext context, String fieldId, bool includeTime) async {
    final initialDate = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      if (includeTime) {
        if (!context.mounted) return;
        final pickedTime = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.now(),
        );

        if (pickedTime != null) {
          final fullDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
          final formatted = DateFormat('yyyy-MM-dd HH:mm').format(fullDateTime);
          _updateValue(fieldId, formatted);
        }
      } else {
        final formatted = DateFormat('yyyy-MM-dd').format(pickedDate);
        _updateValue(fieldId, formatted);
      }
    }
  }

  void _showMultiSelectDialog(
      BuildContext context, TimetreeCustomField field, List<String> options, List<String> currentSelected) {
    final tempSelected = List<String>.from(currentSelected);

    showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(field.label),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: options.map((opt) {
                    final isChecked = tempSelected.contains(opt);
                    return CheckboxListTile(
                      title: Text(opt),
                      value: isChecked,
                      onChanged: (val) {
                        setDialogState(() {
                          if (val == true) {
                            tempSelected.add(opt);
                          } else {
                            tempSelected.remove(opt);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Annuler'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _updateValue(field.id, tempSelected.join(', '));
                  },
                  child: const Text('Confirmer'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
