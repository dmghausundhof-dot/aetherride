import 'package:maplibre_gl/maplibre_gl.dart';

import 'nav_puck_image.dart';

/// Eigenes Standort-/Navi-Symbol — ersetzt den MapLibre-Standardpuck
/// (Discover und Ride).
class NavPuckOverlay {
  Symbol? _symbol;
  bool _imageReady = false;
  int _gen = 0;
  NavPuckStyle _style = NavPuckStyle.rider;

  bool get imageReady => _imageReady;

  NavPuckStyle get style => _style;

  void reset() {
    _symbol = null;
    _imageReady = false;
  }

  /// Nach `clearSymbols()` — Image bleibt, Handle ist tot.
  void forgetSymbol() {
    _symbol = null;
  }

  Future<void> attach(
    MapLibreMapController c, {
    NavPuckStyle style = NavPuckStyle.rider,
  }) async {
    _style = style;
    await _registerImage(c, style);
    await hideNativePuck(c);
  }

  /// Style-Wechsel: PNG unter eigener Image-Id registrieren und Symbol updaten.
  Future<void> setStyle(MapLibreMapController c, NavPuckStyle style) async {
    _style = style;
    await _registerImage(c, style);
    if (_symbol == null) return;
    try {
      await c.updateSymbol(
        _symbol!,
        SymbolOptions(
          iconImage: style.imageId,
          iconSize: style.mapIconSize,
          iconRotate: style.usesRiderAsset ? 0 : null,
        ),
      );
    } catch (_) {}
  }

  Future<void> _registerImage(
    MapLibreMapController c,
    NavPuckStyle style,
  ) async {
    try {
      final bytes = await buildNavPuckPng(style: style);
      await c.addImage(style.imageId, bytes);
      _imageReady = true;
    } catch (_) {
      // Bereits registriert nach Style-Reload-Race — trotzdem nutzbar.
      _imageReady = true;
    }
  }

  Future<void> hideNativePuck(MapLibreMapController c) async {
    final ids = <String>{...kNativeLocationPuckLayerIds};
    try {
      for (final raw in await c.getLayerIds()) {
        ids.add(raw.toString());
      }
    } catch (_) {}
    for (final id in ids) {
      if (!_isNativePuckLayer(id)) continue;
      try {
        await c.setLayerVisibility(id, false);
      } catch (_) {}
    }
  }

  static bool _isNativePuckLayer(String id) {
    if (id.contains('accuracy')) return false;
    if (kNativeLocationPuckLayerIds.contains(id)) return true;
    return id.startsWith('mapbox-location') ||
        id.contains('location-indicator');
  }

  Future<void> sync(
    MapLibreMapController c, {
    required LatLng at,
    required double iconRotateDeg,
    NavPuckStyle? style,
  }) async {
    if (style != null && style != _style) {
      await setStyle(c, style);
    }
    if (!_imageReady) await attach(c, style: _style);
    if (!_imageReady) return;
    final gen = ++_gen;
    final rider = _style.usesRiderAsset;
    final opts = SymbolOptions(
      geometry: at,
      iconImage: _style.imageId,
      iconSize: _style.mapIconSize,
      iconRotate: rider ? 0 : iconRotateDeg,
      iconAnchor: 'center',
      zIndex: 24,
    );
    try {
      if (_symbol == null) {
        final added = await c.addSymbol(opts);
        if (gen != _gen) return;
        _symbol ??= added;
      } else {
        await c.updateSymbol(_symbol!, opts);
      }
    } catch (_) {
      if (gen != _gen) return;
      try {
        _symbol = await c.addSymbol(opts);
      } catch (_) {}
    }
  }
}
