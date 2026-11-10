// OpenStreetMap based map layer for the whole app.
//
// This file replaces `google_maps_flutter`: it keeps the small API surface the
// app already used (LatLng, Marker, Polyline, CameraPosition, CameraUpdate,
// an `AppMap` widget and an `AppMapController`) but renders OpenStreetMap
// tiles through `flutter_map`. No API key is needed.
//
// Tile usage: the public tile server (tile.openstreetmap.org) is meant for
// light traffic. For a busy production app point [AppMap.tileUrlTemplate] to
// your own / a commercial OSM tile provider (MapTiler, Stadia, Thunderforest...).
import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart' as ll;

export 'package:latlong2/latlong.dart' show LatLng;

typedef LatLng = ll.LatLng;

const String kOsmTileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
const String kOsmUserAgentPackage = 'com.femalecar.eon';

// ---------------------------------------------------------------------------
// Data classes (same names / shapes the app used before)
// ---------------------------------------------------------------------------

class LatLngBounds {
  final LatLng southwest;
  final LatLng northeast;
  const LatLngBounds({required this.southwest, required this.northeast});

  bool contains(LatLng p) =>
      p.latitude >= southwest.latitude &&
      p.latitude <= northeast.latitude &&
      p.longitude >= southwest.longitude &&
      p.longitude <= northeast.longitude;
}

class CameraPosition {
  final LatLng target;
  final double zoom;
  final double bearing;
  final double tilt;
  const CameraPosition(
      {required this.target, this.zoom = 14, this.bearing = 0, this.tilt = 0});
}

class CameraUpdate {
  final LatLng? target;
  final double? zoom;
  final LatLngBounds? bounds;
  final double padding;
  const CameraUpdate._({this.target, this.zoom, this.bounds, this.padding = 0});

  static CameraUpdate newCameraPosition(CameraPosition p) =>
      CameraUpdate._(target: p.target, zoom: p.zoom);
  static CameraUpdate newLatLng(LatLng l) => CameraUpdate._(target: l);
  static CameraUpdate newLatLngZoom(LatLng l, double zoom) =>
      CameraUpdate._(target: l, zoom: zoom);
  static CameraUpdate newLatLngBounds(LatLngBounds b, double padding) =>
      CameraUpdate._(bounds: b, padding: padding);
}

class MinMaxZoomPreference {
  final double? minZoom;
  final double? maxZoom;
  const MinMaxZoomPreference(this.minZoom, this.maxZoom);
}

class MarkerId {
  final String value;
  const MarkerId(this.value);
  @override
  bool operator ==(Object other) => other is MarkerId && other.value == value;
  @override
  int get hashCode => value.hashCode;
}

class PolylineId {
  final String value;
  const PolylineId(this.value);
  @override
  bool operator ==(Object other) => other is PolylineId && other.value == value;
  @override
  int get hashCode => value.hashCode;
}

class InfoWindow {
  final String? title;
  final String? snippet;
  const InfoWindow({this.title, this.snippet});
}

class BitmapDescriptor {
  final Uint8List? bytes;
  const BitmapDescriptor._(this.bytes);
  static const BitmapDescriptor defaultMarker = BitmapDescriptor._(null);
  // Same call shape as the old plugin: BitmapDescriptor.bytes(data)
  factory BitmapDescriptor.bytes(Uint8List bytes,
          {double? width, double? height}) =>
      BitmapDescriptor._(bytes);
}

class Marker {
  final MarkerId markerId;
  final LatLng position;
  final double rotation;
  final Offset anchor;
  final InfoWindow infoWindow;
  final BitmapDescriptor icon;
  final bool visible;
  final bool draggable;
  final bool flat;
  final int zIndexInt;
  const Marker({
    required this.markerId,
    this.position = const ll.LatLng(0, 0),
    this.rotation = 0,
    this.anchor = const Offset(0.5, 1.0),
    this.infoWindow = const InfoWindow(),
    this.icon = BitmapDescriptor.defaultMarker,
    this.visible = true,
    this.draggable = false,
    this.flat = false,
    this.zIndexInt = 0,
  });

  @override
  bool operator ==(Object other) =>
      other is Marker && other.markerId == markerId;
  @override
  int get hashCode => markerId.hashCode;
}

/// Dash / gap lengths for dashed lines (same call shape as the old plugin).
class PatternItem {
  final bool isDash;
  final double length;
  const PatternItem._(this.isDash, this.length);
  static PatternItem dash(double length) => PatternItem._(true, length);
  static PatternItem gap(double length) => PatternItem._(false, length);
}

class Polyline {
  final PolylineId polylineId;
  final List<LatLng> points;
  final int width;
  final Color color;
  final List<PatternItem> patterns;
  const Polyline({
    required this.polylineId,
    this.points = const [],
    this.width = 5,
    this.color = Colors.blue,
    this.patterns = const [],
  });
}

class PolygonId {
  final String value;
  const PolygonId(this.value);
  @override
  bool operator ==(Object other) => other is PolygonId && other.value == value;
  @override
  int get hashCode => value.hashCode;
}

class Polygon {
  final PolygonId polygonId;
  final List<LatLng> points;
  final Color fillColor;
  final Color strokeColor;
  final int strokeWidth;
  const Polygon({
    required this.polygonId,
    this.points = const [],
    this.fillColor = const Color(0x22000000),
    this.strokeColor = Colors.black,
    this.strokeWidth = 2,
  });
  @override
  bool operator ==(Object other) =>
      other is Polygon && other.polygonId == polygonId;
  @override
  int get hashCode => polygonId.hashCode;
}

// ---------------------------------------------------------------------------
// Controller
// ---------------------------------------------------------------------------

class AppMapController {
  fm.MapController? _inner;
  bool _ready = false;
  GlobalKey? _boundaryKey;

  void _attach(fm.MapController c, GlobalKey boundaryKey) {
    _inner = c;
    _boundaryKey = boundaryKey;
  }

  /// PNG screenshot of the map as currently drawn (used e.g. to attach a trip
  /// proof image). Returns null when the map is not on screen.
  Future<Uint8List?> takeSnapshot({double pixelRatio = 1.5}) async {
    try {
      final ctx = _boundaryKey?.currentContext;
      if (ctx == null) return null;
      final boundary = ctx.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
      final ByteData? data =
          await image.toByteData(format: ui.ImageByteFormat.png);
      return data?.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  void _setReady() => _ready = true;

  bool get isReady => _ready && _inner != null;

  Future<void> animateCamera(CameraUpdate update) async => moveCamera(update);

  Future<void> moveCamera(CameraUpdate update) async {
    if (!isReady) return;
    try {
      if (update.bounds != null) {
        final b = update.bounds!;
        _inner!.fitCamera(fm.CameraFit.bounds(
          bounds: fm.LatLngBounds(b.southwest, b.northeast),
          padding: EdgeInsets.all(update.padding),
          maxZoom: 18,
        ));
      } else if (update.target != null) {
        _inner!.move(update.target!, update.zoom ?? _inner!.camera.zoom);
      } else if (update.zoom != null) {
        _inner!.move(_inner!.camera.center, update.zoom!);
      }
    } catch (_) {
      // map not laid out yet / disposed: ignore
    }
  }

  Future<LatLngBounds> getVisibleRegion() async {
    final fm.LatLngBounds b = _inner!.camera.visibleBounds;
    return LatLngBounds(southwest: b.southWest, northeast: b.northEast);
  }

  Future<double> getZoomLevel() async => _inner!.camera.zoom;

  void dispose() {
    _ready = false;
  }
}

// ---------------------------------------------------------------------------
// Widget
// ---------------------------------------------------------------------------

class AppMap extends StatefulWidget {
  final CameraPosition initialCameraPosition;
  final Set<Marker> markers;
  final Set<Polyline> polylines;
  final Set<Polygon> polygons;
  final void Function(AppMapController controller)? onMapCreated;
  final void Function(CameraPosition position)? onCameraMove;
  final VoidCallback? onCameraMoveStarted;
  final VoidCallback? onCameraIdle;
  final void Function(LatLng position)? onTap;
  final MinMaxZoomPreference minMaxZoomPreference;
  final bool scrollGesturesEnabled;
  final bool zoomGesturesEnabled;
  final String tileUrlTemplate;

  // Accepted only so existing call sites (written for Google Maps) keep
  // compiling; they have no effect on the OpenStreetMap map.
  final dynamic style;
  final dynamic gestureRecognizers;
  final bool? myLocationEnabled,
      myLocationButtonEnabled,
      zoomControlsEnabled,
      compassEnabled,
      mapToolbarEnabled,
      indoorViewEnabled,
      tiltGesturesEnabled,
      rotateGesturesEnabled,
      buildingsEnabled,
      trafficEnabled;

  const AppMap({
    super.key,
    required this.initialCameraPosition,
    this.markers = const {},
    this.polylines = const {},
    this.polygons = const {},
    this.onMapCreated,
    this.onCameraMove,
    this.onCameraMoveStarted,
    this.onCameraIdle,
    this.onTap,
    this.minMaxZoomPreference = const MinMaxZoomPreference(0, 18),
    this.scrollGesturesEnabled = true,
    this.zoomGesturesEnabled = true,
    this.tileUrlTemplate = kOsmTileUrl,
    this.style,
    this.gestureRecognizers,
    this.myLocationEnabled,
    this.myLocationButtonEnabled,
    this.zoomControlsEnabled,
    this.compassEnabled,
    this.mapToolbarEnabled,
    this.indoorViewEnabled,
    this.tiltGesturesEnabled,
    this.rotateGesturesEnabled,
    this.buildingsEnabled,
    this.trafficEnabled,
  });

  @override
  State<AppMap> createState() => _AppMapState();
}

class _AppMapState extends State<AppMap> {
  final fm.MapController _fmController = fm.MapController();
  final AppMapController _controller = AppMapController();
  Timer? _idleTimer;
  final GlobalKey _boundaryKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _controller._attach(_fmController, _boundaryKey);
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    _controller.dispose();
    _fmController.dispose();
    super.dispose();
  }

  // PNG header holds width/height (big endian) at bytes 16..23.
  Size _iconSize(Uint8List bytes) {
    double w = 40, h = 40;
    if (bytes.length > 24) {
      final d = ByteData.sublistView(bytes);
      w = d.getUint32(16).toDouble();
      h = d.getUint32(20).toDouble();
    }
    // The app creates icons in physical pixels; show them at roughly half size.
    return Size(math.max(w / 2, 28), math.max(h / 2, 28));
  }

  List<fm.Marker> _buildMarkers() {
    final list = widget.markers.where((m) => m.visible).toList()
      ..sort((a, b) => a.zIndexInt.compareTo(b.zIndexInt));
    return list.map((m) {
      final bytes = m.icon.bytes;
      final Size size = bytes != null ? _iconSize(bytes) : const Size(36, 36);
      Widget child = bytes != null
          ? Image.memory(bytes,
              width: size.width, height: size.height, gaplessPlayback: true)
          : Icon(Icons.location_on,
              size: 36, color: Theme.of(context).primaryColor);
      if (m.rotation != 0) {
        child =
            Transform.rotate(angle: m.rotation * math.pi / 180, child: child);
      }
      return fm.Marker(
        point: m.position,
        width: size.width,
        height: size.height,
        rotate: false,
        alignment: Alignment((0.5 - m.anchor.dx) * 2, (0.5 - m.anchor.dy) * 2),
        child: child,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final bool interactive =
        widget.scrollGesturesEnabled || widget.zoomGesturesEnabled;
    int flags = fm.InteractiveFlag.none;
    if (widget.scrollGesturesEnabled)
      flags |= fm.InteractiveFlag.drag | fm.InteractiveFlag.flingAnimation;
    if (widget.zoomGesturesEnabled) {
      flags |= fm.InteractiveFlag.pinchZoom |
          fm.InteractiveFlag.doubleTapZoom |
          fm.InteractiveFlag.scrollWheelZoom;
    }

    return RepaintBoundary(
        key: _boundaryKey,
        child: fm.FlutterMap(
          mapController: _fmController,
          options: fm.MapOptions(
            initialCenter: widget.initialCameraPosition.target,
            initialZoom: widget.initialCameraPosition.zoom,
            minZoom: widget.minMaxZoomPreference.minZoom ?? 0,
            maxZoom: math.min(widget.minMaxZoomPreference.maxZoom ?? 18, 19),
            interactionOptions: fm.InteractionOptions(
                flags: interactive ? flags : fm.InteractiveFlag.none),
            onTap: widget.onTap == null
                ? null
                : (_, point) => widget.onTap!(point),
            onMapReady: () {
              _controller._setReady();
              widget.onMapCreated?.call(_controller);
            },
            onMapEvent: (event) {
              if (event is fm.MapEventMoveStart) {
                widget.onCameraMoveStarted?.call();
              }
              if (event is fm.MapEventMove) {
                widget.onCameraMove?.call(CameraPosition(
                    target: event.camera.center, zoom: event.camera.zoom));
              }
              if (event is fm.MapEventMove ||
                  event is fm.MapEventMoveEnd ||
                  event is fm.MapEventFlingAnimationEnd ||
                  event is fm.MapEventDoubleTapZoomEnd ||
                  event is fm.MapEventScrollWheelZoom) {
                _idleTimer?.cancel();
                _idleTimer = Timer(const Duration(milliseconds: 350), () {
                  if (!mounted) return;
                  widget.onCameraMove?.call(CameraPosition(
                      target: _fmController.camera.center,
                      zoom: _fmController.camera.zoom));
                  widget.onCameraIdle?.call();
                });
              }
            },
          ),
          children: [
            fm.TileLayer(
              urlTemplate: widget.tileUrlTemplate,
              userAgentPackageName: kOsmUserAgentPackage,
              tileBuilder: Get.isDarkMode ? fm.darkModeTileBuilder : null,
              maxNativeZoom: 19,
            ),
            if (widget.polygons.isNotEmpty)
              fm.PolygonLayer(
                polygons: widget.polygons
                    .map((p) => fm.Polygon(
                          points: p.points,
                          color: p.fillColor,
                          borderColor: p.strokeColor,
                          borderStrokeWidth: p.strokeWidth.toDouble(),
                        ))
                    .toList(),
              ),
            if (widget.polylines.isNotEmpty)
              fm.PolylineLayer(
                polylines: widget.polylines.map((p) {
                  final dashes = p.patterns
                      .where((e) => e.isDash)
                      .map((e) => e.length)
                      .toList();
                  final gaps = p.patterns
                      .where((e) => !e.isDash)
                      .map((e) => e.length)
                      .toList();
                  return fm.Polyline(
                    points: p.points,
                    strokeWidth: p.width.toDouble(),
                    color: p.color,
                    pattern: dashes.isEmpty
                        ? const fm.StrokePattern.solid()
                        : fm.StrokePattern.dashed(segments: [
                            dashes.first,
                            gaps.isEmpty ? dashes.first : gaps.first
                          ]),
                  );
                }).toList(),
              ),
            if (widget.markers.isNotEmpty)
              fm.MarkerLayer(markers: _buildMarkers()),
            const fm.RichAttributionWidget(
              alignment: fm.AttributionAlignment.bottomRight,
              attributions: [
                fm.TextSourceAttribution('© OpenStreetMap contributors')
              ],
            ),
          ],
        ));
  }
}
