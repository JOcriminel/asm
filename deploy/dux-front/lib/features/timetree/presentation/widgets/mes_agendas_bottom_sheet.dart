import 'dart:convert';
import 'dart:io' as io;
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:dux_front/features/auth/presentation/controllers/auth_controller.dart';
import 'package:dux_front/features/timetree/domain/models/timetree_calendar.dart';
import 'package:dux_front/core/services/screen_config_controller.dart';
import 'package:dux_front/features/timetree/domain/models/timetree_member.dart';
import 'package:dux_front/features/timetree/presentation/provider/timetree_calendars_provider.dart';
import 'package:dux_front/features/timetree/presentation/provider/timetree_events_provider.dart';
import 'package:dux_front/features/timetree/presentation/provider/timetree_members_provider.dart';
import 'package:dux_front/features/timetree/data/repositories/timetree_calendars_repository.dart';
import 'package:dux_front/features/timetree/data/repositories/timetree_members_repository.dart';

String _getCalendarCover(TimetreeCalendar cal) {
  if (cal.description.contains('|[cover:')) {
    final parts = cal.description.split('|[cover:');
    if (parts.length > 1) {
      return parts[1].replaceAll(']', '').trim();
    }
  }
  return '';
}

String _getCleanDescription(TimetreeCalendar cal) {
  if (cal.description.contains('|[cover:')) {
    return cal.description.split('|[cover:')[0].trim();
  }
  return cal.description;
}

String _formatDescriptionWithCover(String desc, String cover) {
  return '${desc.trim()}|[cover:$cover]';
}

class MesAgendasBottomSheet extends ConsumerWidget {
  const MesAgendasBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;
    final role = user?.role.toUpperCase() ?? 'MEMBER';
    final isAdmin = role == 'ADMIN' || role == 'ADMINISTRATEUR';

    final calendarsAsync = ref.watch(timetreeCalendarsProvider);
    final selectedCalendarIds = ref.watch(selectedCalendarIdsProvider);

    return Container(
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 24),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
                margin: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            // Header Row
            SizedBox(
              width: double.infinity,
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text(
                    'Mes Agendas',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  if (isAdmin)
                    TextButton(
                      onPressed: () => _showCreateCalendarDialog(context, ref),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add, size: 16, color: Color(0xFF1E88E5)),
                          SizedBox(width: 4),
                          Text(
                            'Créer un agenda',
                            style: TextStyle(
                              color: Color(0xFF1E88E5),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Calendars List
            Flexible(
              child: calendarsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(child: Text('Erreur: $err')),
                data: (calendars) {
                  if (calendars.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Text('Aucun agenda trouvé.'),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: calendars.length,
                    itemBuilder: (cellContext, index) {
                      final cal = calendars[index];
                      final isSelected = selectedCalendarIds.contains(cal.id);
                      final coverBase64 = _getCalendarCover(cal);
                      final cleanDesc = _getCleanDescription(cal);

                      final chefs = cal.members
                          .where((m) => m.role.toUpperCase() == 'CHEF')
                          .map((m) => m.fullName)
                          .toList();
                      final ownerText = chefs.isNotEmpty ? chefs.join(', ') : 'admin';

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Top Uppercase label
                            Text(
                              cal.name.toUpperCase(),
                              style: const TextStyle(
                                color: Color(0xFF1E88E5),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 6),
                            // Agenda Card Container
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected ? const Color(0xFF64B5F6) : Colors.grey.shade200,
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.02),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  )
                                ],
                              ),
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  // Cover image / placeholder
                                  Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      color: Colors.blueGrey.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                      image: coverBase64.isNotEmpty
                                          ? DecorationImage(
                                              image: MemoryImage(base64Decode(coverBase64)),
                                              fit: BoxFit.cover,
                                            )
                                          : null,
                                    ),
                                    child: coverBase64.isEmpty
                                        ? Icon(
                                            Icons.calendar_today_rounded,
                                            color: Colors.blueGrey.shade400,
                                            size: 24,
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  // Details text
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          cal.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        if (cleanDesc.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            cleanDesc,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                        const SizedBox(height: 2),
                                        Text(
                                          'Propriétaire : $ownerText',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontStyle: FontStyle.italic,
                                            color: Colors.grey.shade500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Action Buttons
                                  if (isAdmin || cal.members.any((m) => m.username == user?.username && m.role.toUpperCase() == 'CHEF'))
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Color(0xFF1E88E5)),
                                      onPressed: () => _showModifyCalendarDialog(context, ref, cal),
                                    ),
                                  Checkbox(
                                    value: isSelected,
                                    activeColor: const Color(0xFF1E88E5),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                    onChanged: (val) {
                                      ref.read(selectedCalendarIdsProvider.notifier).toggleCalendar(cal.id, val ?? false);
                                    },
                                  )
                                ],
                              ),
                            )
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateCalendarDialog(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      useRootNavigator: true,
      builder: (dialogCtx) => const _CalendarFormDialog(calendar: null),
    );
  }

  void _showModifyCalendarDialog(BuildContext context, WidgetRef ref, TimetreeCalendar calendar) {
    showDialog<void>(
      context: context,
      useRootNavigator: true,
      builder: (dialogCtx) => _CalendarFormDialog(calendar: calendar),
    );
  }
}

class _CalendarFormDialog extends ConsumerStatefulWidget {
  final TimetreeCalendar? calendar;
  const _CalendarFormDialog({required this.calendar});

  @override
  ConsumerState<_CalendarFormDialog> createState() => _CalendarFormDialogState();
}

class _CalendarFormDialogState extends ConsumerState<_CalendarFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late String _selectedCover;
  bool _submitting = false;
  List<String> _selectedDocs = [];
  List<String> _selectedTiers = [];
  Set<String> _tierCodes = {};

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.calendar?.name ?? '');
    _descCtrl = TextEditingController(text: widget.calendar != null ? _getCleanDescription(widget.calendar!) : '');
    _selectedCover = widget.calendar != null ? _getCalendarCover(widget.calendar!) : 'default';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCalendarAttachedEntities();
    });
  }

  Future<void> _loadCalendarAttachedEntities() async {
    try {
      final tierTypes = await ref.read(screenConfigControllerProvider.notifier).fetchAllTierTypes();
      _tierCodes = tierTypes
          .map((t) => (t['typeCode'] ?? t['code'])?.toString().trim().toUpperCase())
          .where((c) => c != null)
          .cast<String>()
          .toSet();

      final attached = widget.calendar?.attachedDocuments?.split(',') ?? [];
      final docs = <String>[];
      final tiers = <String>[];
      for (final code in attached) {
        final trimmed = code.trim();
        if (trimmed.isEmpty) continue;
        if (_tierCodes.contains(trimmed.toUpperCase())) {
          tiers.add(trimmed);
        } else {
          docs.add(trimmed);
        }
      }
      if (mounted) {
        setState(() {
          _selectedDocs = docs;
          _selectedTiers = tiers;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _showDocumentSelectorDialog(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(child: CircularProgressIndicator());
      },
    );

    List<Map<String, dynamic>> allClasses = [];
    try {
      allClasses = await ref.read(screenConfigControllerProvider.notifier).fetchAllDocumentClasses();
    } catch (e) {
      debugPrint('Error fetching all document classes: $e');
    }

    if (context.mounted) {
      Navigator.pop(context); // close loading
    }

    if (allClasses.isEmpty) {
      allClasses = [
        {'code': 'BC', 'libelle': 'Bon de Commande (BC)'},
        {'code': 'BP', 'libelle': 'Bon de Préparation (BP)'},
        {'code': 'BS', 'libelle': 'Bon de Sortie (BS)'},
      ];
    }

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _DocumentSelectorSearchDialog(
          allClasses: allClasses,
          initialSelected: List<String>.from(_selectedDocs),
          onChanged: (selected) {
            setState(() {
              _selectedDocs = selected;
            });
          },
        );
      },
    );
  }

  void _showTierSelectorDialog(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(child: CircularProgressIndicator());
      },
    );

    List<Map<String, dynamic>> allClasses = [];
    try {
      allClasses = await ref.read(screenConfigControllerProvider.notifier).fetchAllTierTypes();
    } catch (e) {
      debugPrint('Error fetching all tier types: $e');
    }

    if (context.mounted) {
      Navigator.pop(context); // close loading
    }

    if (allClasses.isEmpty) {
      allClasses = [
        {'code': '1', 'libelle': 'Client'},
      ];
    }

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _DocumentSelectorSearchDialog(
          allClasses: allClasses,
          initialSelected: List<String>.from(_selectedTiers),
          onChanged: (selected) {
            setState(() {
              _selectedTiers = selected;
            });
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.calendar != null;

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(isEdit ? 'Modifier l\'agenda' : 'Créer un agenda'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Nom de l\'agenda'),
                validator: (val) => val == null || val.isEmpty ? 'Requis' : null,
              ),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: 16),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Couverture de l\'agenda', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 8),
              // Gallery Picker Container
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      try {
                        final result = await FilePicker.platform.pickFiles(
                          type: FileType.image,
                          withData: true,
                        );
                        if (result != null) {
                          final file = result.files.single;
                          Uint8List? bytes = file.bytes;
                          if (bytes == null && file.path != null) {
                            bytes = await io.File(file.path!).readAsBytes();
                          }
                          if (bytes != null) {
                            final decodedImage = img.decodeImage(bytes);
                            if (decodedImage != null) {
                              final resizedImage = img.copyResize(decodedImage, width: 150);
                              final compressedBytes = img.encodeJpg(resizedImage, quality: 70);
                              final base64String = base64Encode(compressedBytes);
                              setState(() {
                                _selectedCover = base64String;
                              });
                            } else {
                              messenger.showSnackBar(
                                const SnackBar(content: Text('Impossible de décoder l\'image')),
                              );
                            }
                          }
                        }
                      } catch (e) {
                        messenger.showSnackBar(
                          SnackBar(content: Text('Erreur sélection d\'image: $e')),
                        );
                      }
                    },
                    child: Container(
                      height: 120,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                        image: _selectedCover.isNotEmpty && _selectedCover != 'default'
                            ? DecorationImage(
                                image: MemoryImage(base64Decode(_selectedCover)),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: _selectedCover.isEmpty || _selectedCover == 'default'
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.image_search_rounded, size: 36, color: Colors.grey.shade500),
                                const SizedBox(height: 8),
                                Text(
                                  'Sélectionner une image de la galerie',
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                ),
                              ],
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
                  if (_selectedCover.isNotEmpty && _selectedCover != 'default') ...[
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _selectedCover = '';
                          });
                        },
                        icon: const Icon(Icons.delete_outline, color: Colors.red, size: 16),
                        label: const Text('Supprimer l\'image', style: TextStyle(color: Colors.red, fontSize: 12)),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 24),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Documents associés', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () => _showDocumentSelectorDialog(context),
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Sélectionner des documents',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    suffixIcon: const Icon(Icons.arrow_drop_down),
                  ),
                  child: _selectedDocs.isEmpty
                      ? const Text('Aucun document associé')
                      : Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: _selectedDocs.map((docType) {
                            return Chip(
                              label: Text(docType),
                              deleteIcon: const Icon(Icons.close, size: 16),
                              onDeleted: () {
                                setState(() {
                                  _selectedDocs.remove(docType);
                                });
                              },
                            );
                          }).toList(),
                        ),
                ),
              ),
              const SizedBox(height: 24),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Tiers associés', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () => _showTierSelectorDialog(context),
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Sélectionner des tiers',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    suffixIcon: const Icon(Icons.arrow_drop_down),
                  ),
                  child: _selectedTiers.isEmpty
                      ? const Text('Aucun tiers associé')
                      : Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: _selectedTiers.map((tierType) {
                            return Chip(
                              label: Text(tierType),
                              deleteIcon: const Icon(Icons.close, size: 16),
                              onDeleted: () {
                                setState(() {
                                  _selectedTiers.remove(tierType);
                                });
                              },
                            );
                          }).toList(),
                        ),
                ),
              ),
              if (isEdit) ...[
                const SizedBox(height: 24),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Membres de l\'agenda', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.spaceBetween,
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade50,
                        foregroundColor: const Color(0xFF1E88E5),
                        elevation: 0,
                      ),
                      onPressed: () => _showAddMemberSelection(context, ref, widget.calendar!),
                      icon: const Icon(Icons.person_add_alt_1, size: 18),
                      label: const Text('Add'),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade50,
                        foregroundColor: Colors.orange.shade700,
                        elevation: 0,
                      ),
                      onPressed: () => _showManageMembersSelection(context, ref, widget.calendar!),
                      icon: const Icon(Icons.people_outline, size: 18),
                      label: Text('Manage members (${widget.calendar!.members.length})'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: _submitting
              ? null
              : () async {
                  if (!_formKey.currentState!.validate()) return;
                  setState(() => _submitting = true);
                  try {
                    final descWithCover = _formatDescriptionWithCover(_descCtrl.text, _selectedCover);
                    final joinedAttached = [..._selectedDocs, ..._selectedTiers].join(',');
                    if (isEdit) {
                      await ref.read(timetreeCalendarsProvider.notifier).updateCalendar(
                            id: widget.calendar!.id,
                            name: _nameCtrl.text,
                            description: descWithCover,
                            color: widget.calendar!.color,
                            attachedDocuments: joinedAttached,
                          );
                    } else {
                      await ref.read(timetreeCalendarsProvider.notifier).createCalendar(
                            name: _nameCtrl.text,
                            description: descWithCover,
                            color: '#2196F3',
                            attachedDocuments: joinedAttached,
                          );
                    }
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              isEdit ? 'Agenda mis à jour' : 'Agenda créé avec succès'),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Erreur: $e')),
                      );
                    }
                  } finally {
                    if (mounted) setState(() => _submitting = false);
                  }
                },
          child: _submitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Enregistrer'),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dropdown styled search dialog
// ─────────────────────────────────────────────────────────────────────────────
class _DropdownSearchDialog extends StatefulWidget {
  final String title;
  final String hintText;
  final List<dynamic> items;
  final Widget Function(BuildContext, dynamic, String query) itemBuilder;

  const _DropdownSearchDialog({
    required this.title,
    required this.hintText,
    required this.items,
    required this.itemBuilder,
  });

  @override
  State<_DropdownSearchDialog> createState() => _DropdownSearchDialogState();
}

class _DropdownSearchDialogState extends State<_DropdownSearchDialog> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.toLowerCase().trim();
    final filteredItems = widget.items.where((item) {
      if (item is TimetreeMember) {
        return item.fullName.toLowerCase().contains(query) ||
            item.username.toLowerCase().contains(query);
      }
      return true;
    }).toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 8,
      backgroundColor: Colors.white,
      child: Container(
        width: 320,
        constraints: const BoxConstraints(maxHeight: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title / Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => Navigator.pop(context),
                  )
                ],
              ),
            ),
            const Divider(height: 1),
            // Search Input
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() {}),
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  prefixIcon: const Icon(Icons.search, size: 18),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),
            ),
            // Items list
            Expanded(
              child: filteredItems.isEmpty
                  ? const Center(child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Aucun résultat trouvé', style: TextStyle(color: Colors.grey)),
                    ))
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: filteredItems.length,
                      itemBuilder: (context, index) {
                        return widget.itemBuilder(context, filteredItems[index], _searchController.text);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

void _showAddMemberSelection(BuildContext context, WidgetRef ref, TimetreeCalendar calendar) async {
  final membersRepo = ref.read(timetreeMembersRepositoryProvider);
  try {
    final allMembers = await membersRepo.getMembers();

    if (!context.mounted) return;

    showDialog<void>(
      context: context,
      useRootNavigator: true,
      builder: (dialogCtx) => _DropdownSearchDialog(
        title: 'Ajouter un membre',
        hintText: 'Rechercher un utilisateur...',
        items: allMembers,
        itemBuilder: (itemCtx, item, query) {
          final m = item as TimetreeMember;
          final isAlreadyMember = calendar.members.any((existing) => existing.id == m.id);
          return ListTile(
            title: Text(isAlreadyMember ? '${m.fullName} (Déjà membre)' : m.fullName),
            subtitle: Text(m.username),
            trailing: isAlreadyMember
                ? const Icon(Icons.check_circle, color: Colors.grey)
                : const Icon(Icons.add_circle_outline, color: Color(0xFF1E88E5)),
            onTap: isAlreadyMember
                ? null
                : () async {
                    Navigator.pop(dialogCtx);
                    try {
                      // Add user to calendar
                      await ref.read(timetreeMembersRepositoryProvider).addMemberToCalendar(calendar.id, m.id);
                      // Reload calendars
                      await ref.read(timetreeCalendarsProvider.notifier).loadCalendars();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${m.fullName} ajouté avec succès')),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Erreur: $e')),
                        );
                      }
                    }
                  },
          );
        },
      ),
    );
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du chargement des membres: $e')),
      );
    }
  }
}

void _showManageMembersSelection(BuildContext context, WidgetRef ref, TimetreeCalendar calendar) {
  showDialog<void>(
    context: context,
    useRootNavigator: true,
    builder: (dialogCtx) {
      return StatefulBuilder(
        builder: (context, setState) {
          // Re-get the calendar from the provider to get latest members
          final calendars = ref.watch(timetreeCalendarsProvider).value ?? [];
          final currentCal = calendars.firstWhere((c) => c.id == calendar.id, orElse: () => calendar);
          final currentMembers = currentCal.members;
          final totalMembers = currentMembers.length;

          return _DropdownSearchDialog(
            title: 'Gérer les membres ($totalMembers)',
            hintText: 'Rechercher un membre...',
            items: currentMembers,
            itemBuilder: (itemCtx, item, query) {
              final m = item as TimetreeMember;
              final isChef = m.role.toUpperCase() == 'CHEF';

              return ListTile(
                title: Text(m.fullName, overflow: TextOverflow.ellipsis, maxLines: 1),
                subtitle: Text(m.role, overflow: TextOverflow.ellipsis, maxLines: 1),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Role Dropdown Button (Chef vs Member)
                    DropdownButton<String>(
                      value: isChef ? 'CHEF' : 'MEMBER',
                      underline: const SizedBox.shrink(),
                      icon: const Icon(Icons.arrow_drop_down, size: 18),
                      elevation: 4,
                      style: TextStyle(
                        fontSize: 12,
                        color: isChef ? Colors.orange.shade700 : Colors.blue.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                      dropdownColor: Colors.white,
                      items: const [
                        DropdownMenuItem(
                          value: 'CHEF',
                          child: Text('Chef', style: TextStyle(color: Colors.orange)),
                        ),
                        DropdownMenuItem(
                          value: 'MEMBER',
                          child: Text('Membre', style: TextStyle(color: Colors.blue)),
                        ),
                      ],
                      onChanged: (newRole) async {
                        if (newRole != null && newRole != (isChef ? 'CHEF' : 'MEMBER')) {
                          try {
                            final allCals = ref.read(timetreeCalendarsProvider).value ?? [];
                            final chefCalendarIds = allCals
                                .where((c) => c.members.any((mem) => mem.id == m.id && mem.role.toUpperCase() == 'CHEF'))
                                .map((c) => c.id)
                                .toList();

                            final List<String> calendarIds;
                            final String apiRole;
                            if (newRole == 'CHEF') {
                              calendarIds = List<String>.from(chefCalendarIds);
                              if (!calendarIds.contains(currentCal.id)) {
                                calendarIds.add(currentCal.id);
                              }
                              apiRole = 'CHEF';
                            } else {
                              calendarIds = List<String>.from(chefCalendarIds)..remove(currentCal.id);
                              apiRole = calendarIds.isNotEmpty ? 'CHEF' : 'MEMBER';
                            }

                            await ref.read(timetreeMembersProvider.notifier).updateMember(
                              id: m.id,
                              username: m.username,
                              fullName: m.fullName,
                              email: m.email,
                              role: apiRole,
                              calendarIds: calendarIds,
                            );
                            // Reload calendars
                            await ref.read(timetreeCalendarsProvider.notifier).loadCalendars();
                            setState(() {});
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Erreur: $e')),
                              );
                            }
                          }
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    // Delete Button
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () async {
                        try {
                          await ref.read(timetreeCalendarsRepositoryProvider).removeMemberFromCalendar(currentCal.id, m.id);
                          await ref.read(timetreeCalendarsProvider.notifier).loadCalendars();
                          setState(() {});
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('${m.fullName} retiré de l\'agenda')),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Erreur: $e')),
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
    },
  );
}

class _DocumentSelectorSearchDialog extends StatefulWidget {
  final List<Map<String, dynamic>> allClasses;
  final List<String> initialSelected;
  final ValueChanged<List<String>> onChanged;

  const _DocumentSelectorSearchDialog({
    required this.allClasses,
    required this.initialSelected,
    required this.onChanged,
  });

  @override
  State<_DocumentSelectorSearchDialog> createState() => _DocumentSelectorSearchDialogState();
}

class _DocumentSelectorSearchDialogState extends State<_DocumentSelectorSearchDialog> {
  late List<String> _tempSelected;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tempSelected = List<String>.from(widget.initialSelected);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final filtered = widget.allClasses.where((doc) {
      final code = (doc['code'] ?? '').toString().toLowerCase();
      final libelle = (doc['libelle'] ?? '').toString().toLowerCase();
      return code.contains(_searchQuery.toLowerCase()) || libelle.contains(_searchQuery.toLowerCase());
    }).toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16),
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Documents associés',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: InputDecoration(
                hintText: 'Rechercher un document...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
            ),
            const SizedBox(height: 12),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        'Aucun document trouvé',
                        style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    )
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        final code = (item['code'] ?? '').toString();
                        final libelle = (item['libelle'] ?? '').toString();
                        final isChecked = _tempSelected.contains(code);

                        return CheckboxListTile(
                          title: Text(
                            libelle,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          subtitle: Text(
                            code,
                            style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                          ),
                          value: isChecked,
                          activeColor: theme.colorScheme.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                if (!_tempSelected.contains(code)) {
                                  _tempSelected.add(code);
                                }
                              } else {
                                _tempSelected.remove(code);
                              }
                            });
                          },
                        );
                      },
                    ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Annuler'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    widget.onChanged(_tempSelected);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Valider'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
