import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:dux_front/core/widgets/dux_drawer.dart';
import 'package:dux_front/features/timetree/presentation/provider/timetree_search_provider.dart';

class TimetreeSearchScreen extends ConsumerStatefulWidget {
  const TimetreeSearchScreen({super.key});

  @override
  ConsumerState<TimetreeSearchScreen> createState() => _TimetreeSearchScreenState();
}

class _TimetreeSearchScreenState extends ConsumerState<TimetreeSearchScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _queryController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _queryController.dispose();
    super.dispose();
  }

  void _onSearchSubmitted(String val) {
    setState(() {
      _searchQuery = val.trim();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final searchAsync = ref.watch(timetreeSearchProvider(_searchQuery));

    return Scaffold(
      drawer: const DuxDrawer(),
      appBar: AppBar(
        title: const Text('Dux Calender – Recherche Globale'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.event_note_rounded), text: 'Événements'),
            Tab(icon: Icon(Icons.calendar_month_rounded), text: 'Calendriers'),
            Tab(icon: Icon(Icons.attachment_rounded), text: 'Fichiers'),
            Tab(icon: Icon(Icons.chat_rounded), text: 'Discussions'),
            Tab(icon: Icon(Icons.people_rounded), text: 'Membres'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search Box
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _queryController,
              decoration: InputDecoration(
                hintText: 'Saisissez au moins 2 caractères pour rechercher…',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _queryController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _queryController.clear();
                          _onSearchSubmitted('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) {
                if (val.trim().length >= 2 || val.trim().isEmpty) {
                  _onSearchSubmitted(val);
                }
              },
              onSubmitted: _onSearchSubmitted,
            ),
          ),

          // Search Results
          Expanded(
            child: _searchQuery.length < 2
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_rounded, size: 64, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5)),
                        const SizedBox(height: 12),
                        const Text('Recherchez des événements, fichiers, membres, etc.'),
                      ],
                    ),
                  )
                : searchAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, _) => Center(
                      child: Text('Erreur: $err', style: const TextStyle(color: Colors.red)),
                    ),
                    data: (results) {
                      final events = results['events'] as List? ?? [];
                      final calendars = results['calendars'] as List? ?? [];
                      final attachments = results['attachments'] as List? ?? [];
                      final messages = results['messages'] as List? ?? [];
                      final members = results['members'] as List? ?? [];

                      return TabBarView(
                        controller: _tabController,
                        children: [
                          _EventsResultList(list: events),
                          _CalendarsResultList(list: calendars),
                          _AttachmentsResultList(list: attachments),
                          _MessagesResultList(list: messages),
                          _MembersResultList(list: members),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _EventsResultList extends StatelessWidget {
  const _EventsResultList({required this.list});
  final List list;

  @override
  Widget build(BuildContext context) {
    if (list.isEmpty) return const Center(child: Text('Aucun événement trouvé'));

    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index] as Map<String, dynamic>;
        final title = item['title'] as String? ?? 'Sans titre';
        final desc = item['description'] as String? ?? '';
        final start = DateTime.parse(item['startDate'] as String).toLocal();
        final priority = item['priority'] as String? ?? 'NORMAL';
        final status = item['status'] as String? ?? 'PLANNED';

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: ListTile(
            leading: Icon(Icons.event_rounded, color: Colors.blue.shade700),
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${DateFormat('dd/MM/yyyy HH:mm').format(start)}\n$desc'),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    priority,
                    style: TextStyle(color: Colors.orange.shade800, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 4),
                Text(status, style: const TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }
}

class _CalendarsResultList extends StatelessWidget {
  const _CalendarsResultList({required this.list});
  final List list;

  @override
  Widget build(BuildContext context) {
    if (list.isEmpty) return const Center(child: Text('Aucun calendrier trouvé'));

    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index] as Map<String, dynamic>;
        final name = item['name'] as String? ?? 'Sans nom';
        final desc = item['description'] as String? ?? '';
        final hexColor = item['color'] as String? ?? '#000000';
        final color = Color(int.parse(hexColor.replaceFirst('#', 'FF'), radix: 16));

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: ListTile(
            leading: Icon(Icons.circle_rounded, color: color),
            title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(desc),
          ),
        );
      },
    );
  }
}

class _AttachmentsResultList extends StatelessWidget {
  const _AttachmentsResultList({required this.list});
  final List list;

  @override
  Widget build(BuildContext context) {
    if (list.isEmpty) return const Center(child: Text('Aucun fichier trouvé'));

    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index] as Map<String, dynamic>;
        final name = item['fileName'] as String? ?? 'Fichier';
        final eventTitle = item['eventTitle'] as String? ?? '';
        final uploadedBy = item['uploadedBy'] as String? ?? '';
        final size = (item['fileSize'] as num?)?.toInt() ?? 0;
        final sizeText = size > 1024 * 1024
            ? '${(size / (1024 * 1024)).toStringAsFixed(1)} MB'
            : '${(size / 1024).toStringAsFixed(1)} KB';

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: ListTile(
            leading: Icon(Icons.insert_drive_file_rounded, color: Colors.red.shade700),
            title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Dans: $eventTitle\nPartagé par: $uploadedBy'),
            trailing: Text(sizeText, style: const TextStyle(color: Colors.grey)),
            isThreeLine: true,
          ),
        );
      },
    );
  }
}

class _MessagesResultList extends StatelessWidget {
  const _MessagesResultList({required this.list});
  final List list;

  @override
  Widget build(BuildContext context) {
    if (list.isEmpty) return const Center(child: Text('Aucune discussion trouvée'));

    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index] as Map<String, dynamic>;
        final text = item['message'] as String? ?? '';
        final eventTitle = item['eventTitle'] as String? ?? '';
        final sender = item['memberName'] as String? ?? 'Système';
        final sentAt = DateTime.parse(item['sentAt'] as String).toLocal();

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: ListTile(
            leading: Icon(Icons.chat_bubble_rounded, color: Colors.green.shade700),
            title: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Par: $sender | Événement: $eventTitle'),
            trailing: Text(DateFormat('dd/MM HH:mm').format(sentAt), style: const TextStyle(color: Colors.grey, fontSize: 10)),
          ),
        );
      },
    );
  }
}

class _MembersResultList extends StatelessWidget {
  const _MembersResultList({required this.list});
  final List list;

  @override
  Widget build(BuildContext context) {
    if (list.isEmpty) return const Center(child: Text('Aucun membre trouvé'));

    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index] as Map<String, dynamic>;
        final name = item['fullName'] as String? ?? '';
        final email = item['email'] as String? ?? '';
        final role = item['role'] as String? ?? 'MEMBER';

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: ListTile(
            leading: CircleAvatar(child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'M')),
            title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(email),
            trailing: Chip(label: Text(role, style: const TextStyle(fontSize: 10)), visualDensity: VisualDensity.compact),
          ),
        );
      },
    );
  }
}
