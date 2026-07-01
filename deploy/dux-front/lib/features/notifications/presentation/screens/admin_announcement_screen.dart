import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dux_front/features/timetree/presentation/provider/timetree_calendars_provider.dart';
import 'package:dux_front/features/timetree/data/repositories/timetree_notifications_repository.dart';

class AdminAnnouncementScreen extends ConsumerStatefulWidget {
  const AdminAnnouncementScreen({super.key});

  @override
  ConsumerState<AdminAnnouncementScreen> createState() =>
      _AdminAnnouncementScreenState();
}

class _AdminAnnouncementScreenState
    extends ConsumerState<AdminAnnouncementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  bool _isGlobalBroadcast = true;
  final List<String> _selectedCalendarIds = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submitAnnouncement() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final repo = ref.read(timetreeNotificationsRepositoryProvider);
      final calendarIdsToSend = _isGlobalBroadcast ? <String>[] : _selectedCalendarIds;

      await repo.sendAnnouncement(
        _titleController.text.trim(),
        _contentController.text.trim(),
        calendarIdsToSend,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Annonce envoyée avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
        // Clear form
        _titleController.clear();
        _contentController.clear();
        setState(() {
          _selectedCalendarIds.clear();
          _isGlobalBroadcast = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'envoi : $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final calendarsAsync = ref.watch(timetreeCalendarsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Publier une Annonce'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Contenu de l\'annonce',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _titleController,
                            decoration: const InputDecoration(
                              labelText: 'Titre de l\'annonce',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.title),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Veuillez saisir un titre';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _contentController,
                            maxLines: 5,
                            decoration: const InputDecoration(
                              labelText: 'Message / Contenu',
                              border: OutlineInputBorder(),
                              alignLabelWithHint: true,
                              prefixIcon: Padding(
                                padding: EdgeInsets.only(bottom: 80.0),
                                child: Icon(Icons.message_outlined),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Veuillez saisir le contenu du message';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ciblage de l\'annonce',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          RadioListTile<bool>(
                            title: const Text('Tous les utilisateurs (Broadcast Global)'),
                            value: true,
                            groupValue: _isGlobalBroadcast,
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _isGlobalBroadcast = val;
                                });
                              }
                            },
                          ),
                          RadioListTile<bool>(
                            title: const Text('Sélectionner des calendriers spécifiques'),
                            value: false,
                            groupValue: _isGlobalBroadcast,
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _isGlobalBroadcast = val;
                                });
                              }
                            },
                          ),
                          if (!_isGlobalBroadcast) ...[
                            const Divider(),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                              child: Text(
                                'Sélectionnez les calendriers cibles :',
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                              ),
                            ),
                            calendarsAsync.when(
                              loading: () => const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                              error: (err, stack) => Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text('Impossible de charger les calendriers : $err'),
                              ),
                              data: (calendars) {
                                if (calendars.isEmpty) {
                                  return const Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: Text('Aucun calendrier disponible.'),
                                  );
                                }
                                return ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: calendars.length,
                                  itemBuilder: (context, index) {
                                    final cal = calendars[index];
                                    final isSelected = _selectedCalendarIds.contains(cal.id);
                                    return CheckboxListTile(
                                      title: Text(cal.name),
                                      subtitle: Text(
                                        cal.description.isEmpty 
                                            ? 'Pas de description' 
                                            : cal.description,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      value: isSelected,
                                      onChanged: (val) {
                                        setState(() {
                                          if (val == true) {
                                            _selectedCalendarIds.add(cal.id);
                                          } else {
                                            _selectedCalendarIds.remove(cal.id);
                                          }
                                        });
                                      },
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                      ),
                      onPressed: _submitAnnouncement,
                      icon: const Icon(Icons.send),
                      label: const Text(
                        'Publier l\'annonce',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
