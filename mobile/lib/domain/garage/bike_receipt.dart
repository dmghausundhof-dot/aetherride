/// Beleg am Rad — Werkstatt, Ersatzteil, Garantie oder frei.
///
/// Foto lokal. OCR füllt Felder nur als Vorschlag.
enum BikeReceiptKind { workshop, parts, warranty, other }

class BikeReceipt {
  const BikeReceipt({
    required this.id,
    required this.bikeId,
    required this.kind,
    required this.createdAt,
    this.merchant,
    this.date,
    this.amountEur,
    this.title,
    this.notes,
    this.photoPath,
    this.componentId,
    this.ocrFilled = false,
  });

  final String id;
  final String bikeId;
  final BikeReceiptKind kind;
  final DateTime createdAt;
  final String? merchant;
  final String? date;
  final double? amountEur;
  final String? title;
  final String? notes;
  final String? photoPath;
  final String? componentId;
  final bool ocrFilled;

  bool get hasPhoto => (photoPath ?? '').trim().isNotEmpty;

  bool get hasFacts =>
      (merchant ?? '').trim().isNotEmpty ||
      (date ?? '').trim().isNotEmpty ||
      amountEur != null ||
      (title ?? '').trim().isNotEmpty ||
      (notes ?? '').trim().isNotEmpty;

  String get summary {
    final bits = <String>[
      if ((merchant ?? '').trim().isNotEmpty) merchant!.trim(),
      if ((title ?? '').trim().isNotEmpty) title!.trim(),
      if (amountEur != null) '${amountEur!.toStringAsFixed(0)} €',
      if ((date ?? '').trim().isNotEmpty) date!,
    ];
    return bits.isEmpty ? kindLabel : bits.join(' · ');
  }

  String get kindLabel => switch (kind) {
        BikeReceiptKind.workshop => 'Werkstatt',
        BikeReceiptKind.parts => 'Ersatzteil',
        BikeReceiptKind.warranty => 'Garantie',
        BikeReceiptKind.other => 'Beleg',
      };

  BikeReceipt copyWith({
    BikeReceiptKind? kind,
    String? merchant,
    String? date,
    double? amountEur,
    String? title,
    String? notes,
    String? photoPath,
    String? componentId,
    bool? ocrFilled,
    bool clearPhoto = false,
    bool clearComponent = false,
  }) {
    return BikeReceipt(
      id: id,
      bikeId: bikeId,
      kind: kind ?? this.kind,
      createdAt: createdAt,
      merchant: merchant ?? this.merchant,
      date: date ?? this.date,
      amountEur: amountEur ?? this.amountEur,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      photoPath: clearPhoto ? null : (photoPath ?? this.photoPath),
      componentId: clearComponent ? null : (componentId ?? this.componentId),
      ocrFilled: ocrFilled ?? this.ocrFilled,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'bikeId': bikeId,
        'kind': kind.name,
        'createdAt': createdAt.toIso8601String(),
        if (merchant != null) 'merchant': merchant,
        if (date != null) 'date': date,
        if (amountEur != null) 'amountEur': amountEur,
        if (title != null) 'title': title,
        if (notes != null) 'notes': notes,
        if (photoPath != null) 'photoPath': photoPath,
        if (componentId != null) 'componentId': componentId,
        if (ocrFilled) 'ocrFilled': true,
      };

  factory BikeReceipt.fromJson(Map<String, dynamic> m) {
    return BikeReceipt(
      id: (m['id'] as String?) ?? '',
      bikeId: (m['bikeId'] as String?) ?? '',
      kind: BikeReceiptKind.values.firstWhere(
        (k) => k.name == m['kind'],
        orElse: () => BikeReceiptKind.other,
      ),
      createdAt: DateTime.tryParse((m['createdAt'] as String?) ?? '') ??
          DateTime.now().toUtc(),
      merchant: _text(m['merchant']),
      date: _text(m['date']),
      amountEur: m['amountEur'] is num
          ? (m['amountEur'] as num).toDouble()
          : double.tryParse('${m['amountEur'] ?? ''}'.replaceAll(',', '.')),
      title: _text(m['title']),
      notes: _text(m['notes']),
      photoPath: _text(m['photoPath']),
      componentId: _text(m['componentId']),
      ocrFilled: m['ocrFilled'] == true,
    );
  }
}

enum ReceiptScanReason { ok, noKey, quota, failed, unreadable, none }

ReceiptScanReason receiptScanReasonFrom(String? raw) {
  return switch (raw) {
    'ok' => ReceiptScanReason.ok,
    'no_key' => ReceiptScanReason.noKey,
    'quota' => ReceiptScanReason.quota,
    'failed' => ReceiptScanReason.failed,
    'unreadable' => ReceiptScanReason.unreadable,
    _ => ReceiptScanReason.none,
  };
}

String receiptScanMessage(ReceiptScanReason reason) {
  return switch (reason) {
    ReceiptScanReason.ok =>
      'Scan hat Felder vorausgefüllt — bitte prüfen.',
    ReceiptScanReason.noKey =>
      'Kein Vision-Schlüssel auf dem Server. Foto merken, Text nachtragen.',
    ReceiptScanReason.quota =>
      'Scan-Kontingent leer. Foto merken, Text nachtragen.',
    ReceiptScanReason.failed =>
      'Scan nicht erreichbar. Foto merken, Text nachtragen.',
    ReceiptScanReason.unreadable =>
      'Beleg nicht erkannt. Felder selbst eintragen.',
    ReceiptScanReason.none =>
      'Foto merken. Text später nachtragen.',
  };
}

class ReceiptScanHint {
  const ReceiptScanHint({
    this.merchant,
    this.date,
    this.amountEur,
    this.title,
    this.kind = BikeReceiptKind.other,
    this.items = const [],
    this.scanned = false,
    this.reason = ReceiptScanReason.none,
  });

  final String? merchant;
  final String? date;
  final double? amountEur;
  final String? title;
  final BikeReceiptKind kind;
  final List<String> items;
  final bool scanned;
  final ReceiptScanReason reason;

  factory ReceiptScanHint.fromJson(Map<String, dynamic> m) {
    final kindRaw = (m['kind'] as String?) ?? 'other';
    final scanned = m['scanned'] == true;
    var reason = receiptScanReasonFrom(m['reason'] as String?);
    if (scanned && reason == ReceiptScanReason.none) {
      reason = ReceiptScanReason.ok;
    }
    if (!scanned && reason == ReceiptScanReason.none && m.containsKey('scanned')) {
      reason = ReceiptScanReason.unreadable;
    }
    return ReceiptScanHint(
      merchant: _text(m['merchant']),
      date: _text(m['date']),
      amountEur: m['amountEur'] is num
          ? (m['amountEur'] as num).toDouble()
          : double.tryParse('${m['amountEur'] ?? ''}'.replaceAll(',', '.')),
      title: _text(m['title'] ?? m['what']),
      kind: BikeReceiptKind.values.firstWhere(
        (k) => k.name == kindRaw,
        orElse: () => BikeReceiptKind.other,
      ),
      items: [
        for (final e in (m['items'] as List? ?? const []))
          if (e is String && e.trim().isNotEmpty) e.trim(),
      ],
      scanned: scanned,
      reason: reason,
    );
  }
}

String? _text(Object? v) {
  if (v == null) return null;
  final t = v.toString().trim();
  return t.isEmpty ? null : t;
}
