/// Private owner facts for one bike: frame number, purchase, insurance, care.
///
/// Local + own-device sync only. Never public profile, never chat context.
/// Invoice photos stay on-device (`invoicePhotoPath` is not synced).
class BikeOwner {
  const BikeOwner({
    this.serialNumber,
    this.color,
    this.weightKg,
    this.notes,
    this.purchasedAt,
    this.purchasedFrom,
    this.purchasePriceEur,
    this.insuranceName,
    this.insurancePolicy,
    this.keyNumber,
    this.workshopName,
    this.workshopAddress,
    this.workshopPhone,
    this.nextServiceAt,
    this.nextServiceNote,
    this.lastServiceAt,
    this.lastServiceWork,
    this.lastServiceAmountEur,
    this.lastServiceNote,
    this.invoicePhotoPath,
  });

  /// Rahmennummer as stamped on the frame.
  final String? serialNumber;
  final String? color;
  final double? weightKg;
  final String? notes;

  /// ISO date `yyyy-mm-dd`.
  final String? purchasedAt;
  final String? purchasedFrom;
  final double? purchasePriceEur;
  final String? insuranceName;
  final String? insurancePolicy;

  /// Lock or battery key code.
  final String? keyNumber;

  /// Optional local workshop — never required.
  final String? workshopName;
  final String? workshopAddress;
  final String? workshopPhone;

  /// Next booked service, ISO `yyyy-mm-dd`.
  final String? nextServiceAt;
  final String? nextServiceNote;

  /// Last visit / invoice date and what was done.
  final String? lastServiceAt;
  final String? lastServiceWork;
  final double? lastServiceAmountEur;
  final String? lastServiceNote;

  /// Local file path of the invoice photo. Device-only.
  final String? invoicePhotoPath;

  static const empty = BikeOwner();

  bool get hasSerial => (serialNumber ?? '').trim().isNotEmpty;

  bool get hasWorkshop =>
      (workshopName ?? '').trim().isNotEmpty ||
      (workshopAddress ?? '').trim().isNotEmpty ||
      (workshopPhone ?? '').trim().isNotEmpty;

  /// Name, sonst Adresse, sonst Telefon — für Chip und Karte.
  String? get workshopLabel {
    final name = (workshopName ?? '').trim();
    if (name.isNotEmpty) return name;
    final address = (workshopAddress ?? '').trim();
    if (address.isNotEmpty) return address;
    final phone = (workshopPhone ?? '').trim();
    return phone.isEmpty ? null : phone;
  }

  bool get hasServiceAppointment => (nextServiceAt ?? '').trim().isNotEmpty;

  bool get hasLastService =>
      (lastServiceAt ?? '').trim().isNotEmpty ||
      (lastServiceWork ?? '').trim().isNotEmpty ||
      lastServiceAmountEur != null ||
      (lastServiceNote ?? '').trim().isNotEmpty;

  bool get hasInvoicePhoto => (invoicePhotoPath ?? '').trim().isNotEmpty;

  bool get hasCareFacts =>
      hasWorkshop ||
      hasServiceAppointment ||
      hasLastService ||
      hasInvoicePhoto ||
      (workshopAddress ?? '').trim().isNotEmpty ||
      (workshopPhone ?? '').trim().isNotEmpty ||
      (nextServiceNote ?? '').trim().isNotEmpty;

  bool get isEmpty =>
      !hasSerial &&
      (color == null || color!.isEmpty) &&
      weightKg == null &&
      (notes == null || notes!.isEmpty) &&
      (purchasedAt == null || purchasedAt!.isEmpty) &&
      (purchasedFrom == null || purchasedFrom!.isEmpty) &&
      purchasePriceEur == null &&
      (insuranceName == null || insuranceName!.isEmpty) &&
      (insurancePolicy == null || insurancePolicy!.isEmpty) &&
      (keyNumber == null || keyNumber!.isEmpty) &&
      !hasCareFacts;

  /// Days from local midnight to [nextServiceAt]. Negative = overdue.
  int? daysUntilService([DateTime? now]) {
    return daysUntilIsoDate(nextServiceAt, now);
  }

  BikeOwner clearServiceAppointment() {
    return copyWithKeeping(
      nextServiceAt: null,
      nextServiceNote: null,
      clearNextService: true,
    );
  }

  BikeOwner copyWith({
    String? serialNumber,
    String? color,
    double? weightKg,
    String? notes,
    String? purchasedAt,
    String? purchasedFrom,
    double? purchasePriceEur,
    String? insuranceName,
    String? insurancePolicy,
    String? keyNumber,
    String? workshopName,
    String? workshopAddress,
    String? workshopPhone,
    String? nextServiceAt,
    String? nextServiceNote,
    String? lastServiceAt,
    String? lastServiceWork,
    double? lastServiceAmountEur,
    String? lastServiceNote,
    String? invoicePhotoPath,
  }) {
    return BikeOwner(
      serialNumber: serialNumber ?? this.serialNumber,
      color: color ?? this.color,
      weightKg: weightKg ?? this.weightKg,
      notes: notes ?? this.notes,
      purchasedAt: purchasedAt ?? this.purchasedAt,
      purchasedFrom: purchasedFrom ?? this.purchasedFrom,
      purchasePriceEur: purchasePriceEur ?? this.purchasePriceEur,
      insuranceName: insuranceName ?? this.insuranceName,
      insurancePolicy: insurancePolicy ?? this.insurancePolicy,
      keyNumber: keyNumber ?? this.keyNumber,
      workshopName: workshopName ?? this.workshopName,
      workshopAddress: workshopAddress ?? this.workshopAddress,
      workshopPhone: workshopPhone ?? this.workshopPhone,
      nextServiceAt: nextServiceAt ?? this.nextServiceAt,
      nextServiceNote: nextServiceNote ?? this.nextServiceNote,
      lastServiceAt: lastServiceAt ?? this.lastServiceAt,
      lastServiceWork: lastServiceWork ?? this.lastServiceWork,
      lastServiceAmountEur: lastServiceAmountEur ?? this.lastServiceAmountEur,
      lastServiceNote: lastServiceNote ?? this.lastServiceNote,
      invoicePhotoPath: invoicePhotoPath ?? this.invoicePhotoPath,
    );
  }

  BikeOwner copyWithKeeping({
    String? serialNumber,
    String? color,
    double? weightKg,
    String? notes,
    String? purchasedAt,
    String? purchasedFrom,
    double? purchasePriceEur,
    String? insuranceName,
    String? insurancePolicy,
    String? keyNumber,
    String? workshopName,
    String? workshopAddress,
    String? workshopPhone,
    String? nextServiceAt,
    String? nextServiceNote,
    String? lastServiceAt,
    String? lastServiceWork,
    double? lastServiceAmountEur,
    String? lastServiceNote,
    String? invoicePhotoPath,
    bool clearNextService = false,
    bool clearInvoice = false,
  }) {
    return BikeOwner(
      serialNumber: serialNumber ?? this.serialNumber,
      color: color ?? this.color,
      weightKg: weightKg ?? this.weightKg,
      notes: notes ?? this.notes,
      purchasedAt: purchasedAt ?? this.purchasedAt,
      purchasedFrom: purchasedFrom ?? this.purchasedFrom,
      purchasePriceEur: purchasePriceEur ?? this.purchasePriceEur,
      insuranceName: insuranceName ?? this.insuranceName,
      insurancePolicy: insurancePolicy ?? this.insurancePolicy,
      keyNumber: keyNumber ?? this.keyNumber,
      workshopName: workshopName ?? this.workshopName,
      workshopAddress: workshopAddress ?? this.workshopAddress,
      workshopPhone: workshopPhone ?? this.workshopPhone,
      nextServiceAt: clearNextService ? null : (nextServiceAt ?? this.nextServiceAt),
      nextServiceNote:
          clearNextService ? null : (nextServiceNote ?? this.nextServiceNote),
      lastServiceAt: lastServiceAt ?? this.lastServiceAt,
      lastServiceWork: lastServiceWork ?? this.lastServiceWork,
      lastServiceAmountEur: lastServiceAmountEur ?? this.lastServiceAmountEur,
      lastServiceNote: lastServiceNote ?? this.lastServiceNote,
      invoicePhotoPath:
          clearInvoice ? null : (invoicePhotoPath ?? this.invoicePhotoPath),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (serialNumber != null) 'serialNumber': serialNumber,
      if (color != null) 'color': color,
      if (weightKg != null) 'weightKg': weightKg,
      if (notes != null) 'notes': notes,
      if (purchasedAt != null) 'purchasedAt': purchasedAt,
      if (purchasedFrom != null) 'purchasedFrom': purchasedFrom,
      if (purchasePriceEur != null) 'purchasePriceEur': purchasePriceEur,
      if (insuranceName != null) 'insuranceName': insuranceName,
      if (insurancePolicy != null) 'insurancePolicy': insurancePolicy,
      if (keyNumber != null) 'keyNumber': keyNumber,
      if (workshopName != null) 'workshopName': workshopName,
      if (workshopAddress != null) 'workshopAddress': workshopAddress,
      if (workshopPhone != null) 'workshopPhone': workshopPhone,
      if (nextServiceAt != null) 'nextServiceAt': nextServiceAt,
      if (nextServiceNote != null) 'nextServiceNote': nextServiceNote,
      if (lastServiceAt != null) 'lastServiceAt': lastServiceAt,
      if (lastServiceWork != null) 'lastServiceWork': lastServiceWork,
      if (lastServiceAmountEur != null)
        'lastServiceAmountEur': lastServiceAmountEur,
      if (lastServiceNote != null) 'lastServiceNote': lastServiceNote,
      if (invoicePhotoPath != null) 'invoicePhotoPath': invoicePhotoPath,
    };
  }

  /// Flat keys for sync / web Bike fields. Invoice path stays on the device.
  Map<String, dynamic> toSyncFields() {
    final m = toJson();
    m.remove('invoicePhotoPath');
    return m;
  }

  factory BikeOwner.fromJson(Object? raw) {
    if (raw is! Map) return empty;
    final m = Map<String, dynamic>.from(raw);
    return BikeOwner.normalize(
      serialNumber: _firstString(m, const [
        'serialNumber',
        'frameNumber',
        'rahmennummer',
        'serial',
      ]),
      color: _asString(m['color']),
      weightKg: _asDouble(m['weightKg'] ?? m['weight']),
      notes: _asString(m['notes']),
      purchasedAt: _asString(m['purchasedAt'] ?? m['purchased_at']),
      purchasedFrom: _asString(
        m['purchasedFrom'] ?? m['purchased_from'] ?? m['shop'] ?? m['dealer'],
      ),
      purchasePriceEur: _asDouble(
        m['purchasePriceEur'] ?? m['purchase_price_eur'] ?? m['priceEur'],
      ),
      insuranceName: _asString(m['insuranceName'] ?? m['insurance']),
      insurancePolicy: _asString(
        m['insurancePolicy'] ?? m['insurance_policy'] ?? m['policy'],
      ),
      keyNumber: _asString(m['keyNumber'] ?? m['key_number'] ?? m['keyCode']),
      workshopName: _asString(m['workshopName'] ?? m['workshop']),
      workshopAddress: _asString(m['workshopAddress']),
      workshopPhone: _asString(m['workshopPhone']),
      nextServiceAt: _asString(m['nextServiceAt'] ?? m['next_service_at']),
      nextServiceNote: _asString(m['nextServiceNote']),
      lastServiceAt: _asString(m['lastServiceAt'] ?? m['last_service_at']),
      lastServiceWork: _asString(m['lastServiceWork'] ?? m['last_service_work']),
      lastServiceAmountEur: _asDouble(
        m['lastServiceAmountEur'] ?? m['last_service_amount_eur'],
      ),
      lastServiceNote: _asString(m['lastServiceNote']),
      invoicePhotoPath: _asString(m['invoicePhotoPath']),
    );
  }

  factory BikeOwner.fromSync(Map<String, dynamic> bike) {
    final nested = bike['owner'];
    if (nested is Map) return BikeOwner.fromJson(nested);
    return BikeOwner.fromJson(bike);
  }

  static BikeOwner normalize({
    String? serialNumber,
    String? color,
    Object? weightKg,
    String? notes,
    String? purchasedAt,
    String? purchasedFrom,
    Object? purchasePriceEur,
    String? insuranceName,
    String? insurancePolicy,
    String? keyNumber,
    String? workshopName,
    String? workshopAddress,
    String? workshopPhone,
    String? nextServiceAt,
    String? nextServiceNote,
    String? lastServiceAt,
    String? lastServiceWork,
    Object? lastServiceAmountEur,
    String? lastServiceNote,
    String? invoicePhotoPath,
  }) {
    return BikeOwner(
      serialNumber: _cleanSerial(serialNumber),
      color: _cleanText(color),
      weightKg: _clamp(_asDouble(weightKg), 4, 80),
      notes: _cleanText(notes, max: 800),
      purchasedAt: normalizeDate(purchasedAt),
      purchasedFrom: _cleanText(purchasedFrom, max: 80),
      purchasePriceEur: _clamp(_asDouble(purchasePriceEur), 0, 100000),
      insuranceName: _cleanText(insuranceName, max: 80),
      insurancePolicy: _cleanText(insurancePolicy, max: 80),
      keyNumber: _cleanText(keyNumber, max: 40),
      workshopName: _cleanText(workshopName, max: 80),
      workshopAddress: _cleanText(workshopAddress, max: 160),
      workshopPhone: _cleanText(workshopPhone, max: 40),
      nextServiceAt: normalizeDate(nextServiceAt, maxYearOffset: 3),
      nextServiceNote: _cleanText(nextServiceNote, max: 200),
      lastServiceAt: normalizeDate(lastServiceAt, maxYearOffset: 1),
      lastServiceWork: _cleanText(lastServiceWork, max: 200),
      lastServiceAmountEur: _clamp(_asDouble(lastServiceAmountEur), 0, 100000),
      lastServiceNote: _cleanText(lastServiceNote, max: 400),
      invoicePhotoPath: _cleanText(invoicePhotoPath, max: 400),
    );
  }

  static String? normalizeDate(String? raw, {int maxYearOffset = 1}) {
    final t = (raw ?? '').trim();
    if (t.isEmpty) return null;
    final iso = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(t);
    if (iso != null) {
      return _validYmd(
        iso.group(1)!,
        iso.group(2)!,
        iso.group(3)!,
        maxYearOffset: maxYearOffset,
      );
    }
    final de = RegExp(r'^(\d{1,2})\.(\d{1,2})\.(\d{4})$').firstMatch(t);
    if (de != null) {
      return _validYmd(
        de.group(3)!,
        de.group(2)!.padLeft(2, '0'),
        de.group(1)!.padLeft(2, '0'),
        maxYearOffset: maxYearOffset,
      );
    }
    final parsed = DateTime.tryParse(t);
    if (parsed == null) return null;
    return _validYmd(
      '${parsed.year}',
      parsed.month.toString().padLeft(2, '0'),
      parsed.day.toString().padLeft(2, '0'),
      maxYearOffset: maxYearOffset,
    );
  }

  static String formatDate(String iso) {
    final p = iso.split('-');
    if (p.length != 3) return iso;
    return '${p[2]}.${p[1]}.${p[0]}';
  }

  static String? _validYmd(
    String y,
    String mo,
    String d, {
    int maxYearOffset = 1,
  }) {
    final year = int.tryParse(y);
    final month = int.tryParse(mo);
    final day = int.tryParse(d);
    if (year == null || month == null || day == null) return null;
    if (year < 1980 || year > DateTime.now().year + maxYearOffset) return null;
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;
    final dt = DateTime(year, month, day);
    if (dt.year != year || dt.month != month || dt.day != day) return null;
    return '${year.toString().padLeft(4, '0')}-'
        '${month.toString().padLeft(2, '0')}-'
        '${day.toString().padLeft(2, '0')}';
  }
}

int? daysUntilIsoDate(String? iso, [DateTime? now]) {
  if (iso == null || iso.isEmpty) return null;
  final p = iso.split('-');
  if (p.length != 3) return null;
  final y = int.tryParse(p[0]);
  final m = int.tryParse(p[1]);
  final d = int.tryParse(p[2]);
  if (y == null || m == null || d == null) return null;
  final clock = now ?? DateTime.now();
  final target = DateTime(y, m, d);
  final today = DateTime(clock.year, clock.month, clock.day);
  return target.difference(today).inDays;
}

String? _cleanSerial(String? raw) {
  final t = (raw ?? '').trim().replaceAll(RegExp(r'\s+'), ' ');
  if (t.isEmpty) return null;
  if (t.length > 48) return t.substring(0, 48);
  return t;
}

String? _cleanText(String? raw, {int max = 48}) {
  final t = (raw ?? '').trim().replaceAll(RegExp(r'\s+'), ' ');
  if (t.isEmpty) return null;
  if (t.length > max) return t.substring(0, max);
  return t;
}

String? _asString(Object? v) {
  if (v == null) return null;
  final t = v.toString().trim();
  return t.isEmpty ? null : t;
}

String? _firstString(Map<String, dynamic> m, List<String> keys) {
  for (final k in keys) {
    final s = _asString(m[k]);
    if (s != null) return s;
  }
  return null;
}

double? _asDouble(Object? v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  final t = v.toString().trim().replaceAll(',', '.');
  if (t.isEmpty) return null;
  return double.tryParse(t);
}

double? _clamp(double? v, double min, double max) {
  if (v == null || v.isNaN) return null;
  if (v < min || v > max) return null;
  return v;
}
