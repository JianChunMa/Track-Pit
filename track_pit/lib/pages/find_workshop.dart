import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:track_pit/core/utils/app_logger.dart';
import 'package:track_pit/core/utils/snackbar.dart';
import 'package:track_pit/models/workshop.dart';
import 'package:track_pit/services/workshop_service.dart';
import 'package:track_pit/core/constants/colors.dart';
import 'package:track_pit/core/constants/scale.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class FindWorkshopPage extends StatefulWidget {
  const FindWorkshopPage({super.key});

  @override
  State<FindWorkshopPage> createState() => _FindWorkshopPageState();
}

class _FindWorkshopPageState extends State<FindWorkshopPage>
    with SingleTickerProviderStateMixin {
  static const double minZoom = 6.0;
  static const double maxZoom = 18.0;

  final MapController _mapController = MapController();
  List<Workshop> _workshops = [];
  LatLng _currentCenter = LatLng(3.1573, 101.7122);
  double _zoom = 11.0;
  static const _offset = 6.0;

  late AnimationController _animController;
  Animation<double>? _animation;
  Tween<double>? _latTween, _lngTween, _zoomTween;

  Workshop? _selectedWorkshop;
  bool _isClosingDrawer = false;
  Workshop? _pendingWorkshop;
  Duration _drawerDuration = const Duration(milliseconds: 500);

  LatLng? _userLocation;
  List<LatLng> _routePoints = [];
  double? _routeDistanceKm;
  bool _isFetchingRoute = false;

  Future<void> _tryGetUserLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return; // GPS off → ignore

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return; // ignore if still denied
      }

      // Now safe to get location
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );

      if (mounted) {
        setState(() {
          _userLocation = LatLng(pos.latitude, pos.longitude);
        });
        _animatedMove(_userLocation!, 15);
      }
    } catch (e) {
      // silently ignore errors (no snackbar)
    }
  }

  @override
  void initState() {
    super.initState();
    _loadWorkshops();
    _tryGetUserLocation();

    _animController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );

    _animController.addListener(() {
      if (_latTween != null && _lngTween != null && _zoomTween != null) {
        final lat = _latTween!.evaluate(_animation!);
        final lng = _lngTween!.evaluate(_animation!);
        final newZoom = _zoomTween!.evaluate(_animation!);
        _mapController.move(LatLng(lat, lng), newZoom);
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadWorkshops() async {
    final list = await WorkshopService.getWorkshops();
    setState(() {
      _workshops = list;
      if (_workshops.isNotEmpty) {
        _currentCenter = LatLng(_workshops.first.lat, _workshops.first.lng);
      }
    });
  }

  void _animatedMove(LatLng dest, double zoom) {
    final targetZoom = zoom.clamp(minZoom, maxZoom);

    _latTween = Tween<double>(
      begin: _currentCenter.latitude,
      end: dest.latitude,
    );
    _lngTween = Tween<double>(
      begin: _currentCenter.longitude,
      end: dest.longitude,
    );
    _zoomTween = Tween<double>(begin: _zoom, end: targetZoom);

    _animController.forward(from: 0);
  }

  void _zoomIn() {
    setState(() => _zoom = (_zoom + 1).clamp(minZoom, maxZoom));
    _animatedMove(_currentCenter, _zoom);
  }

  void _zoomOut() {
    setState(() => _zoom = (_zoom - 1).clamp(minZoom, maxZoom));
    _animatedMove(_currentCenter, _zoom);
  }

  void _openSearch() async {
    final result = await showSearch<Workshop?>(
      context: context,
      delegate: WorkshopSearchDelegate(
        _workshops,
        onFind: (shop) {
          _animatedMove(LatLng(shop.lat, shop.lng), 15);
        },

        onDirections: (shop) {
          _handleWorkshopSelection(shop);
          _startDirections(shop);
        },
      ),
    );

    if (result != null) {
      _handleWorkshopSelection(result);
    }
  }

  void _handleWorkshopSelection(Workshop shop) {
    if (_selectedWorkshop == null) {
      setState(() {
        _drawerDuration = const Duration(milliseconds: 500);
        _selectedWorkshop = shop;
        _isClosingDrawer = false;
      });
    } else if (_selectedWorkshop?.id != shop.id) {
      setState(() {
        _drawerDuration = const Duration(milliseconds: 250);
        _pendingWorkshop = shop;
        _isClosingDrawer = true;
      });
    }
    _animatedMove(LatLng(shop.lat, shop.lng), 15);
  }

  void _closeDrawer() {
    setState(() {
      _drawerDuration = const Duration(milliseconds: 500);
      _isClosingDrawer = true;
    });
  }

  Future<bool> _ensureLocationPermission() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      if (mounted) {
        showClosableSnackBar(
          context,
          'Location services are disabled. Please enable GPS/location services in your phone settings.',
        );
      }
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      if (mounted) {
        showClosableSnackBar(context, 'Location permission denied.');
      }
      return false;
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        showClosableSnackBar(
          context,
          'Location permission permanently denied. Enable it in settings.',
          extraAction: SnackBarAction(
            label: 'Settings',
            onPressed: () {
              Geolocator.openAppSettings();
            },
          ),
        );
      }
      return false;
    }

    return true;
  }

  Future<void> _startDirections(Workshop shop) async {
    if (_isFetchingRoute) return;

    final ok = await _ensureLocationPermission();
    if (!ok) return;

    setState(() {
      _isFetchingRoute = true;
    });

    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 0,
          timeLimit: const Duration(seconds: 15),
        ),
      );
      final start = LatLng(pos.latitude, pos.longitude);
      final dest = LatLng(shop.lat, shop.lng);

      _userLocation = start;

      final url =
          'https://router.project-osrm.org/route/v1/driving/${start.longitude},${start.latitude};${dest.longitude},${dest.latitude}?overview=full&geometries=geojson';
      final resp = await http.get(Uri.parse(url));

      if (resp.statusCode == 200) {
        final data = json.decode(resp.body) as Map<String, dynamic>;
        final routes = data['routes'] as List<dynamic>?;
        if (routes != null && routes.isNotEmpty) {
          final route = routes.first as Map<String, dynamic>;
          final distanceMeters = (route['distance'] ?? 0).toDouble();
          final geometry = route['geometry'] as Map<String, dynamic>?;
          final coords =
              (geometry?['coordinates'] as List<dynamic>?)
                  ?.cast<List<dynamic>>() ??
              [];

          final points = <LatLng>[];
          for (final c in coords) {
            if (c.length >= 2) {
              final lon = (c[0] as num).toDouble();
              final lat = (c[1] as num).toDouble();
              points.add(LatLng(lat, lon));
            }
          }

          setState(() {
            _routePoints = points.isNotEmpty ? points : [start, dest];
            _routeDistanceKm =
                (distanceMeters > 0
                    ? distanceMeters
                    : Geolocator.distanceBetween(
                      start.latitude,
                      start.longitude,
                      dest.latitude,
                      dest.longitude,
                    )) /
                1000.0;
          });

          if (_routePoints.isNotEmpty) {
            final bounds = LatLngBounds.fromPoints(_routePoints);
            _mapController.fitCamera(
              CameraFit.bounds(
                bounds: bounds,
                padding: const EdgeInsets.all(60),
              ),
            );
          }
        } else {
          setState(() {
            _routePoints = [start, dest];
            _routeDistanceKm =
                Geolocator.distanceBetween(
                  start.latitude,
                  start.longitude,
                  dest.latitude,
                  dest.longitude,
                ) /
                1000.0;
          });
        }
      } else {
        setState(() {
          _routePoints = [start, dest];
          _routeDistanceKm =
              Geolocator.distanceBetween(
                start.latitude,
                start.longitude,
                dest.latitude,
                dest.longitude,
              ) /
              1000.0;
        });
      }
    } catch (e) {
      if (mounted) {
        showClosableSnackBar(context, 'Directions error: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isFetchingRoute = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    AppLogger.info((_zoom / 12).clamp(0.6, 1.3));
    final drawerVisible = _selectedWorkshop != null && !_isClosingDrawer;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Find Workshop"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: _openSearch),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentCenter,
              initialZoom: _zoom,
              minZoom: minZoom,
              maxZoom: maxZoom,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
              onPositionChanged: (pos, _) {
                setState(() {
                  _zoom = pos.zoom.clamp(minZoom, maxZoom);
                  _currentCenter = pos.center;
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                    "https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png",
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.example.track_pit',
              ),

              if (_routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      strokeWidth: pow((_zoom / 14).clamp(0.6, 1.3), 2) * 6,
                      color: AppColors.secondaryGreen,
                    ),
                  ],
                ),

              MarkerLayer(
                markers: [
                  if (_userLocation != null)
                    Marker(
                      point: _userLocation!,
                      width: 60,
                      height: 60,
                      child: Builder(
                        builder: (context) {
                          final scale = (_zoom / 12).clamp(0.6, 1.3);

                          return GestureDetector(
                            onTap: () {
                              _animatedMove(_userLocation!, 15);
                            },
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // 🔵 Current location pin with background
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.blueAccent.withValues(
                                      alpha: 0.25,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  padding: EdgeInsets.all(6 * scale),
                                  child: Icon(
                                    Icons.my_location,
                                    color: Colors.blueAccent,
                                    size: 28 * scale,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ..._workshops.map((shop) {
                    double scale = (_zoom / 12).clamp(0.6, 1.3);

                    return Marker(
                      point: LatLng(shop.lat, shop.lng),
                      width: 200 * scale,
                      height: 100 * scale,
                      child: GestureDetector(
                        onTap: () => _handleWorkshopSelection(shop),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.primaryGreen.withValues(
                                  alpha: 0.25,
                                ), // light background
                                shape: BoxShape.circle,
                              ),
                              padding: EdgeInsets.all(6 * scale),
                              child: Icon(
                                Icons.location_on,
                                color: AppColors.primaryGreen,
                                size: 28 * scale,
                              ),
                            ),
                            const SizedBox(height: 2),
                            // 🏷️ Shop name in card
                            Material(
                              elevation: 4,
                              borderRadius: BorderRadius.circular(10 * scale),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8 * scale,
                                  vertical: 6 * scale,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(
                                    12 * scale,
                                  ),
                                  border: Border.all(
                                    color: AppColors.primaryAccent,
                                    width: 1.2,
                                  ),
                                ),
                                constraints: BoxConstraints(
                                  maxWidth: 130.0 * pow(scale, 1.5),
                                ),
                                child: Text(
                                  shop.name,
                                  style: TextStyle(
                                    fontSize: 12 * scale,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black87,
                                    height: 1.15,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),

          Positioned(
            top: 16,
            left: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.primaryAccent, width: 1.4),
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromRGBO(0, 0, 0, 0.1),
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  IconButton(
                    icon: const Icon(Icons.add, size: 22),
                    color: AppColors.primaryGreen,
                    onPressed: _zoomIn,
                  ),
                  const Divider(height: 1, color: Colors.black26),
                  IconButton(
                    icon: const Icon(Icons.remove, size: 22),
                    color: AppColors.primaryGreen,
                    onPressed: _zoomOut,
                  ),
                ],
              ),
            ),
          ),
          if (_userLocation != null)
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(
                    color: AppColors.primaryAccent,
                    width: 1.4,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(
                      color: Color.fromRGBO(0, 0, 0, 0.1),
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.my_location, size: 22),
                  color: AppColors.primaryGreen,
                  onPressed: () {
                    _animatedMove(_userLocation!, 15);
                  },
                ),
              ),
            ),

          AnimatedPositioned(
            duration: _drawerDuration,
            curve: const Cubic(0.16, 1, 0.3, 1),
            left: 0,
            right: 0,
            bottom: drawerVisible ? 0 : -250,
            onEnd: () {
              if (_isClosingDrawer) {
                if (_pendingWorkshop != null) {
                  setState(() {
                    _selectedWorkshop = _pendingWorkshop;
                    _pendingWorkshop = null;
                    _isClosingDrawer = false;
                    _drawerDuration = const Duration(milliseconds: 250);
                  });
                } else {
                  setState(() {
                    _selectedWorkshop = null;
                    _isClosingDrawer = false;
                  });
                }
              } else {
                _drawerDuration = const Duration(milliseconds: 500);
              }
            },
            child: Material(
              elevation: 12,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              child: Container(
                padding: const EdgeInsets.fromLTRB(
                  Scale.cardMargin + _offset,
                  Scale.cardMargin,
                  Scale.cardMargin,
                  Scale.cardMargin,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Color.fromRGBO(0, 0, 0, 0.12),
                      blurRadius: 8,
                      offset: Offset(0, -2),
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child:
                    _selectedWorkshop == null
                        ? const SizedBox.shrink()
                        : Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _selectedWorkshop!.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: _closeDrawer,
                                ),
                              ],
                            ),
                            Padding(
                              padding: EdgeInsets.only(right: _offset),
                              child: Text(
                                _selectedWorkshop!.address,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.blueGrey.shade600,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.access_time,
                                  size: 18,
                                  color: Colors.black87,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  "Working Hours",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Color(0xFFEFF7F1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: AppColors.primaryGreen,
                                      width: 1,
                                    ),
                                  ),
                                  child: const Text(
                                    "8:00 AM – 7:00 PM",
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primaryGreen,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            if (_routeDistanceKm != null) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F0FE),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Colors.blueAccent,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.route, size: 18),
                                    const SizedBox(width: 8),
                                    Text(
                                      "${_routeDistanceKm!.toStringAsFixed(2)} km",
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 24),
                            Padding(
                              padding: EdgeInsets.only(right: _offset),
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryGreen,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size.fromHeight(48),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed:
                                    _isFetchingRoute
                                        ? null
                                        : () {
                                          if (_selectedWorkshop != null) {
                                            _startDirections(
                                              _selectedWorkshop!,
                                            );
                                          }
                                        },
                                icon:
                                    _isFetchingRoute
                                        ? const SizedBox(
                                          height: 18,
                                          width: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                        : const Icon(Icons.directions),
                                label: Text(
                                  _isFetchingRoute
                                      ? "Fetching route..."
                                      : "Directions",
                                ),
                              ),
                            ),
                          ],
                        ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class WorkshopSearchDelegate extends SearchDelegate<Workshop?> {
  final List<Workshop> workshops;
  final Function(Workshop) onFind;
  final Function(Workshop)? onDirections;

  WorkshopSearchDelegate(
    this.workshops, {
    required this.onFind,
    this.onDirections,
  });

  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = Theme.of(context);
    return theme.copyWith(
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
        titleTextStyle: theme.textTheme.titleLarge?.copyWith(
          color: Colors.black,
          fontWeight: FontWeight.w600,
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        hintStyle: TextStyle(color: Colors.black54),
        border: InputBorder.none,
      ),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ""),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results =
        workshops
            .where(
              (w) =>
                  w.name.toLowerCase().contains(query.toLowerCase()) ||
                  w.address.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();

    return Container(
      color: Colors.white,
      child: ListView.builder(
        itemCount: results.length,
        itemBuilder: (context, index) {
          final shop = results[index];
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.primaryAccent, width: 1.5),
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, 0.12),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shop.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        shop.address,
                        style: TextStyle(
                          color: Colors.blueGrey.shade600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        textStyle: const TextStyle(fontSize: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        onFind(shop);
                        close(context, shop);
                      },
                      child: const Text("Find in Map"),
                    ),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryGreen,
                        side: const BorderSide(color: AppColors.primaryGreen),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        textStyle: const TextStyle(fontSize: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        if (onDirections != null) {
                          onDirections!(shop);
                        } else {
                          onFind(shop);
                        }
                        close(context, shop);
                      },
                      child: const Text("Directions"),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return buildResults(context);
  }
}
