import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dux_front/features/bon_preparation/domain/repositories/bon_preparation_repository.dart';
import 'package:dux_front/features/bon_preparation/data/repositories/bon_preparation_repository_impl.dart';

class DocumentValidationProofWidget extends ConsumerStatefulWidget {
  final String documentId;

  const DocumentValidationProofWidget({
    super.key,
    required this.documentId,
  });

  @override
  ConsumerState<DocumentValidationProofWidget> createState() => _DocumentValidationProofWidgetState();
}

class _DocumentValidationProofWidgetState extends ConsumerState<DocumentValidationProofWidget> {
  Map<String, dynamic>? _proof;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProof();
  }

  @override
  void didUpdateWidget(covariant DocumentValidationProofWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.documentId != widget.documentId) {
      _loadProof();
    }
  }

  Future<void> _loadProof() async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(bonPreparationRepositoryProvider);
      final data = await repo.getValidationProof(widget.documentId);
      if (mounted) {
        setState(() {
          _proof = data;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (_proof == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final validatedBy = _proof!['validatedBy'] ?? 'Inconnu';
    final validatedAt = _proof!['validatedAt'] ?? '';
    final signatureUrl = _proof!['signatureUrl'] as String?;
    final photoUrl = _proof!['photoUrl'] as String?;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      color: theme.colorScheme.surfaceContainerLowest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.verified_user_rounded, color: theme.colorScheme.primary, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Preuves de Validation',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Validé par :',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                Text(
                  validatedBy,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Date de validation :',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                Text(
                  validatedAt,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ],
            ),
            if (signatureUrl != null || photoUrl != null) ...[
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (signatureUrl != null)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Signature Client',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                signatureUrl,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (signatureUrl != null && photoUrl != null) const SizedBox(width: 16),
                  if (photoUrl != null)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Photo Preuve',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                          ),
                          const SizedBox(height: 6),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (context) => Scaffold(
                                    backgroundColor: Colors.black,
                                    appBar: AppBar(
                                      backgroundColor: Colors.black,
                                      iconTheme: const IconThemeData(color: Colors.white),
                                      title: const Text('Preuve de Validation', style: TextStyle(color: Colors.white)),
                                    ),
                                    body: Center(
                                      child: InteractiveViewer(
                                        child: Image.network(photoUrl),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              height: 100,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        photoUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) =>
                                            const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 4,
                                    right: 4,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.6),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.zoom_in, color: Colors.white, size: 14),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
