/// Epoch values that may be ms, µs, or ns (SQLite / cloud mix-ups).
const int kDartEpochMsMin = -8640000000000000;
const int kDartEpochMsMax = 8640000000000000;

/// Parse [raw] to milliseconds, or 0 if missing / unusable.
int epochMsFromUpdatedAt(String? raw) {
  if (raw == null) return 0;
  final s = raw.trim();
  if (s.isEmpty) return 0;
  final parsed = DateTime.tryParse(s);
  if (parsed != null) {
    try {
      return parsed.millisecondsSinceEpoch;
    } catch (_) {
      return 0;
    }
  }
  final n = int.tryParse(s);
  if (n == null) return 0;
  return clampEpochMs(n);
}

/// Bring a raw epoch into Unix milliseconds (not µs / ns).
int clampEpochMs(int n) {
  var v = n;
  // 1e14 ms ≈ year 5138 — anything larger is µs or ns from SQLite/cloud.
  while (v.abs() >= 100000000000000) {
    v = v ~/ 1000;
  }
  if (v < kDartEpochMsMin || v > kDartEpochMsMax) return 0;
  return v;
}

DateTime? dateTimeFromLooseEpoch(int n) {
  try {
    return DateTime.fromMillisecondsSinceEpoch(clampEpochMs(n), isUtc: true);
  } catch (_) {
    return null;
  }
}
