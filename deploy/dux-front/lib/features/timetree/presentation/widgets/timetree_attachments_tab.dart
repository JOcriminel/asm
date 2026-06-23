import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:dux_front/features/timetree/presentation/provider/timetree_attachments_provider.dart';
import 'package:dux_front/features/timetree/domain/models/timetree_attachment.dart';

class TimetreeAttachmentsTab extends ConsumerStatefulWidget {
  final String eventId;

  const TimetreeAttachmentsTab({super.key, required this.eventId});

  @override
  ConsumerState<TimetreeAttachmentsTab> createState() => _TimetreeAttachmentsTabState();
}

class _TimetreeAttachmentsTabState extends ConsumerState<TimetreeAttachmentsTab> {
  bool _downloadingId = false;
  String _activeDownloadId = '';

  Future<void> _pickAndUpload() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'docx', 'xlsx'],
      );

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        final fileName = result.files.single.name;
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Téléversement en cours...')),
        );

        await ref.read(timetreeAttachmentsProvider(widget.eventId).notifier).uploadFile(filePath, fileName);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fichier téléversé avec succès !')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du téléversement: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _downloadFile(TimetreeAttachment attachment) async {
    setState(() {
      _downloadingId = true;
      _activeDownloadId = attachment.id;
    });

    try {
      final bytes = await ref.read(timetreeAttachmentsProvider(widget.eventId).notifier).downloadAttachment(attachment.id);
      
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/${attachment.fileName}');
      await file.writeAsBytes(bytes);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Téléchargé avec succès !\nSauvegardé dans: ${file.path}'),
          action: SnackBarAction(
            label: 'Ouvrir',
            onPressed: () {
              // Open file using printing or launcher if needed
            },
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de téléchargement: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _downloadingId = false;
          _activeDownloadId = '';
        });
      }
    }
  }

  Future<void> _previewFile(TimetreeAttachment attachment) async {
    setState(() {
      _downloadingId = true;
      _activeDownloadId = attachment.id;
    });

    try {
      final bytes = await ref.read(timetreeAttachmentsProvider(widget.eventId).notifier).downloadAttachment(attachment.id);
      final isPdf = attachment.fileType.toLowerCase().contains('pdf') || attachment.fileName.toLowerCase().endsWith('.pdf');
      final isImage = attachment.fileType.toLowerCase().contains('image') ||
          ['png', 'jpg', 'jpeg'].any((ext) => attachment.fileName.toLowerCase().endsWith('.$ext'));

      if (!mounted) return;

      if (isPdf) {
        // Show PDF Preview in App using printing package
        await showDialog<void>(
          context: context,
          builder: (context) => Dialog.fullscreen(
            child: Scaffold(
              appBar: AppBar(
                title: Text(attachment.fileName),
                leading: IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              body: PdfPreview(
                build: (format) => Uint8List.fromList(bytes),
                allowPrinting: true,
                allowSharing: true,
                canChangePageFormat: false,
              ),
            ),
          ),
        );
      } else if (isImage) {
        // Show Image Preview
        await showDialog<void>(
          context: context,
          builder: (context) => Dialog(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppBar(
                  title: Text(attachment.fileName),
                  leading: IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Image.memory(
                      Uint8List.fromList(bytes),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Prévisualisation non supportée pour ce type de fichier. Veuillez le télécharger.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de prévisualisation: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _downloadingId = false;
          _activeDownloadId = '';
        });
      }
    }
  }

  void _deleteFile(TimetreeAttachment attachment) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer le fichier ?'),
        content: Text('Voulez-vous supprimer définitivement "${attachment.fileName}" ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(timetreeAttachmentsProvider(widget.eventId).notifier).deleteAttachment(attachment.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Fichier supprimé !')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  IconData _getFileIcon(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.pdf')) return Icons.picture_as_pdf_rounded;
    if (lower.endsWith('.docx') || lower.endsWith('.doc')) return Icons.description_rounded;
    if (lower.endsWith('.xlsx') || lower.endsWith('.xls')) return Icons.table_chart_rounded;
    if (['png', 'jpg', 'jpeg', 'gif'].any((ext) => lower.endsWith('.$ext'))) return Icons.image_rounded;
    return Icons.insert_drive_file_rounded;
  }

  Color _getFileColor(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.pdf')) return Colors.red.shade600;
    if (lower.endsWith('.docx') || lower.endsWith('.doc')) return Colors.blue.shade600;
    if (lower.endsWith('.xlsx') || lower.endsWith('.xls')) return Colors.green.shade600;
    if (['png', 'jpg', 'jpeg', 'gif'].any((ext) => lower.endsWith('.$ext'))) return Colors.purple.shade600;
    return Colors.blueGrey;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(timetreeAttachmentsProvider(widget.eventId));

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Fichiers Partagés (${state.attachments.length})',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              FilledButton.icon(
                onPressed: state.isUploading ? null : _pickAndUpload,
                icon: state.isUploading
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.upload_file_rounded),
                label: const Text('Ajouter un fichier'),
              ),
            ],
          ),
        ),
        if (state.error != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(state.error!, style: const TextStyle(color: Colors.red)),
          ),
        Expanded(
          child: state.attachments.isEmpty
              ? _buildEmptyState()
              : GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 220,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.3,
                  ),
                  itemCount: state.attachments.length,
                  itemBuilder: (context, index) {
                    final attachment = state.attachments[index];
                    final isBusy = _downloadingId && _activeDownloadId == attachment.id;
                    final isPreviewable = attachment.fileName.toLowerCase().endsWith('.pdf') ||
                        ['png', 'jpg', 'jpeg'].any((ext) => attachment.fileName.toLowerCase().endsWith('.$ext'));

                    return Card(
                      clipBehavior: Clip.antiAlias,
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _getFileIcon(attachment.fileName),
                                  color: _getFileColor(attachment.fileName),
                                  size: 28,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        attachment.fileName,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        attachment.sizeFormatted,
                                        style: const TextStyle(color: Colors.grey, fontSize: 9),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Text(
                              'Par: ${attachment.uploadedBy}',
                              style: const TextStyle(fontSize: 9, color: Colors.black54),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (isPreviewable)
                                  IconButton(
                                    icon: const Icon(Icons.visibility_outlined, size: 18),
                                    tooltip: 'Aperçu',
                                    onPressed: isBusy ? null : () => _previewFile(attachment),
                                  ),
                                IconButton(
                                  icon: isBusy
                                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 1.5))
                                      : const Icon(Icons.download_rounded, size: 18),
                                  tooltip: 'Télécharger',
                                  onPressed: isBusy ? null : () => _downloadFile(attachment),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                                  tooltip: 'Supprimer',
                                  onPressed: isBusy ? null : () => _deleteFile(attachment),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.folder_open_rounded, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            'Aucun fichier partagé',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 4),
          Text(
            'Partagez des documents, images ou tableurs.',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
