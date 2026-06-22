// lib/core/utils/doc_type.dart
// Enum representing document types for Bon Preparation flows.
// Supports the two current types: BP (Bon de Préparation) and BPR (Bon de Réservation).
// The extension provides convenient utilities for UI titles and query‑parameter keys.

enum DocType { bp, bpr }

extension DocTypeX on DocType {
  /// The query‑parameter key used in routing (e.g., "BP" or "BPR").
  String get key => this == DocType.bpr ? 'BPR' : 'BP';

  /// Human‑readable title used in UI headers.
  String get title => this == DocType.bpr ? 'Bon de Réservation' : 'Bon de Préparation';
}
