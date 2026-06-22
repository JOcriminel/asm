// lib/core/utils/task_type.dart

/// Enum representing the different task/document types that can be
/// associated with a page via the `$codeDoc` query parameter.
///
/// Currently we expose two example types, but this can be extended
/// without touching the UI code – just add a new value and update the
/// extensions below.
library;


enum TaskType {
  /// Represents a Bon de Préparation (BP).
  bp,

  /// Represents a Bon de Réservation (BPR).
  bpr,

  // Add other task types here, e.g. invoice, quote, order, etc.
}

extension TaskTypeExtension on TaskType {
  /// The raw string key used in the URL query parameter.
  /// Upper‑case to match legacy values ("BP", "BPR", ...).
  String get key => toString().split('.').last.toUpperCase();

  /// Human‑readable title for UI displays.
  String get title {
    switch (this) {
      case TaskType.bp:
        return 'Bon de Préparation';
      case TaskType.bpr:
        return 'Bon de Réservation';
    }
  }

  /// Convert a raw string (e.g. from a URL) into a [TaskType].
  /// Returns `null` if the value does not match any known type.
  static TaskType? fromKey(String? raw) {
    if (raw == null) return null;
    final normalized = raw.toUpperCase();
    for (final t in TaskType.values) {
      if (t.key == normalized) return t;
    }
    return null;
  }
}
