/// F-ACC-005/006 — Consent keys mirroring web `src/lib/privacy/consents.ts`.

enum ConsentPurpose {
  rawDataUpload,
  heatmapContribution,
  productRecommendations,
  analytics,
  healthData,
}

extension ConsentPurposeApi on ConsentPurpose {
  /// Wire/JSON key matching web ConsentPurpose.
  String get apiId => switch (this) {
        ConsentPurpose.rawDataUpload => 'raw_data_upload',
        ConsentPurpose.heatmapContribution => 'heatmap_contribution',
        ConsentPurpose.productRecommendations => 'product_recommendations',
        ConsentPurpose.analytics => 'analytics',
        ConsentPurpose.healthData => 'health_data',
      };

  static ConsentPurpose? fromApiId(String id) {
    for (final p in ConsentPurpose.values) {
      if (p.apiId == id) return p;
    }
    return null;
  }
}

class ConsentLabel {
  const ConsentLabel({required this.title, required this.description});
  final String title;
  final String description;
}

const consentLabels = <ConsentPurpose, ConsentLabel>{
  ConsentPurpose.rawDataUpload: ConsentLabel(
    title: 'Rohdaten-Upload',
    description:
        'Sensor-Rohdaten nur bei WLAN und wenn du zustimmst. '
        'Jederzeit widerrufbar.',
  ),
  ConsentPurpose.heatmapContribution: ConsentLabel(
    title: 'Wo viele fahren (anonym, erst ab 5)',
    description:
        'Lokal: deine Fahrten. Mit Konto: anonymisierte Zellen ohne Zeitstempel. '
        'Die Karte erscheint erst, wenn 5 Fahrer in einer Zelle unterwegs waren.',
  ),
  ConsentPurpose.productRecommendations: ConsentLabel(
    title: 'Produktempfehlungen',
    description:
        'Nur anlassbezogen, mit nachvollziehbarem Datenpunkt. '
        'Kein Tracking-Marketing.',
  ),
  ConsentPurpose.analytics: ConsentLabel(
    title: 'Analytics',
    description: 'Produktmetriken ohne Gesundheits- oder Rohsensordaten.',
  ),
  ConsentPurpose.healthData: ConsentLabel(
    title: 'Gesundheitsdaten',
    description:
        'Vorbereitung — noch keine Anbindung an Health Connect. '
        'Die Einwilligung speichert nur deine Präferenz für später.',
  ),
};

/// Default: all consents off (opt-in).
Map<String, bool> defaultConsentGrants() => {
      for (final p in ConsentPurpose.values) p.apiId: false,
    };

class PrivacyZone {
  const PrivacyZone({
    required this.id,
    required this.label,
    required this.lat,
    required this.lng,
    required this.radiusM,
  });

  final String id;
  final String label;
  final double lat;
  final double lng;
  final double radiusM;

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'lat': lat,
        'lng': lng,
        'radiusM': radiusM,
      };

  factory PrivacyZone.fromJson(Map<String, dynamic> json) {
    return PrivacyZone(
      id: json['id'] as String? ?? '',
      label: json['label'] as String? ?? 'Zone',
      lat: (json['lat'] as num?)?.toDouble() ?? 0,
      lng: (json['lng'] as num?)?.toDouble() ?? 0,
      radiusM: (json['radiusM'] as num?)?.toDouble() ?? 200,
    );
  }
}
