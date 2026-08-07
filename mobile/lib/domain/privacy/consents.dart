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
        'Sensor-Rohdaten nur bei WLAN und Opt-in (Spec F-SEN-006). Widerruf jederzeit.',
  ),
  ConsentPurpose.heatmapContribution: ConsentLabel(
    title: 'Heatmap-Beitrag',
    description:
        'Anonymisierte Segmente nach Privacy-Trim und k≥5 (F-NAV-005). Kein Zeitstempel.',
  ),
  ConsentPurpose.productRecommendations: ConsentLabel(
    title: 'Produktempfehlungen',
    description:
        'Nur anlassbezogen mit Datenpunkt (F-SHP-002). Kein Tracking-Marketing.',
  ),
  ConsentPurpose.analytics: ConsentLabel(
    title: 'Analytics',
    description: 'Produktmetriken ohne Gesundheits-/Rohsensordaten.',
  ),
  ConsentPurpose.healthData: ConsentLabel(
    title: 'Gesundheitsdaten (Art. 9)',
    description:
        'Herzfrequenz / Health Connect — nur mit ausdrücklicher Einwilligung.',
  ),
};

/// Default: product recommendations on (demo shop), rest off.
Map<String, bool> defaultConsentGrants() => {
      for (final p in ConsentPurpose.values)
        p.apiId: p == ConsentPurpose.productRecommendations,
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
