/// Maps HTTP/API chat failures to something a rider can read.
/// Engine dumps and status codes must never land in the bubble.
enum ChatSurfaceFault { unavailable, limit }

bool looksLikeEngineDump(String raw) {
  final t = raw.trim();
  if (t.isEmpty) return false;
  final lower = t.toLowerCase();
  if (lower.contains('is not iterable')) return true;
  if (lower.contains('typeerror')) return true;
  if (lower.contains('cannot read')) return true;
  if (lower.contains('undefined is not')) return true;
  if (lower.contains('stack trace')) return true;
  if (lower.contains('exception:')) return true;
  if (RegExp(r'\.dart:\d+').hasMatch(t)) return true;
  if (RegExp(
    r'^(fehler|error|erreur|errore)\s+\d{3}$',
    caseSensitive: false,
  ).hasMatch(t)) {
    return true;
  }
  return false;
}

ChatSurfaceFault? chatSurfaceFault({
  required int statusCode,
  String? jsonText,
  String? jsonError,
}) {
  if (statusCode == 429) return ChatSurfaceFault.limit;
  if (statusCode == 401 ||
      statusCode == 402 ||
      statusCode == 403 ||
      statusCode >= 500) {
    return ChatSurfaceFault.unavailable;
  }
  final blob = '${jsonText ?? ''} ${jsonError ?? ''}';
  if (looksLikeEngineDump(blob)) return ChatSurfaceFault.unavailable;
  if (statusCode >= 400) return ChatSurfaceFault.unavailable;
  return null;
}

String sanitizeStoredAssistantText(String text, {required String fallback}) {
  return looksLikeEngineDump(text) ? fallback : text;
}
