import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:permission_handler/permission_handler.dart';
import 'database_helper.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

const Color locationRed = Color(0xFFA31621);
const Color locationBlue = Color(0xFF0E6BA8);

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _MapScreenState createState() => _MapScreenState();
}

class CachedTileProvider extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    final urlTemplate = options.urlTemplate;
    if (urlTemplate == null) {
      throw Exception('URL template is null');
    }
    final url = urlTemplate
        .replaceAll('{z}', '${coordinates.z}')
        .replaceAll('{x}', '${coordinates.x}')
        .replaceAll('{y}', '${coordinates.y}');
    return CachedNetworkImageProvider(url, cacheManager: DefaultCacheManager());
  }
}

class _MapScreenState extends State<MapScreen> {
  LatLng? _selectedMarker;
  String? _selectedMarkerName;
  LatLng? _currentPosition;
  LatLng? _nearestMarker;
  String? _nearestMarkerName;
  bool _isLoading = true;
  bool _isMapLoaded = false;
  String _errorMessage = '';
  List<LatLng> _routePoints = [];
  List<Map<String, dynamic>> _markers = [];
  Timer? _timer;

  bool _isConnected = true;
  StreamSubscription<List<ConnectivityResult>>?
  _connectivitySubscription; // Updated type

  bool _isManualRouteSelection = false;

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
    _loadCachedRoute().then((points) {
      setState(() {
        _routePoints = points;
      });
    });
    _checkConnectivity();
    _loadOfflineRoute().then((points) {
      if (points.isNotEmpty) {
        setState(() {
          _routePoints = points;
        });
      }
    });
    // Simulate map loading
    Future.delayed(Duration(seconds: 2), () {
      setState(() {
        _isMapLoaded = true;
      });
    });
  }

  Future<void> _requestLocationPermission() async {
    final status = await Permission.location.request();
    if (status.isGranted) {
      _listenToLocationUpdates();
      await _loadMarkers();
      _startNearestMarkerTimer();
      _findNearestMarker(); // Add this line
    } else {
      setState(() {
        _errorMessage = 'Location permission denied';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  void _checkConnectivity() {
    Connectivity().checkConnectivity().then((List<ConnectivityResult> results) {
      setState(() {
        _isConnected =
            results.isNotEmpty && !results.contains(ConnectivityResult.none);
        if (_isConnected) {
          _getRoute();
        }
      });
    });

    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      setState(() {
        _isConnected =
            results.isNotEmpty && !results.contains(ConnectivityResult.none);
        if (_isConnected) {
          _getRoute();
        }
      });
    });
  }

  void _startNearestMarkerTimer() {
    _timer = Timer.periodic(Duration(seconds: 10), (timer) {
      _findNearestMarker();
    });
  }

  void _findNearestMarker() {
    if (_currentPosition == null || _markers.isEmpty) return;

    double minDistance = double.infinity;
    Map<String, dynamic>? nearestMarker;

    for (var marker in _markers) {
      double distance = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        marker['latitude'],
        marker['longitude'],
      );

      if (distance < minDistance) {
        minDistance = distance;
        nearestMarker = marker;
      }
    }

    if (nearestMarker != null) {

      setState(() {
        _nearestMarker = LatLng(
          nearestMarker!['latitude'],
          nearestMarker['longitude'],
        );
        _nearestMarkerName = nearestMarker['name'];

        // Only update the route if no manual selection is active
        if (!_isManualRouteSelection) {
          _getRoute();
        }
      });
    }
  }

  Future<void> _loadMarkers() async {
    final markers = await DatabaseHelper.getMarkers();
    setState(() {
      _markers = markers;
      _findNearestMarker(); // Add this line
    });
  }

  void _listenToLocationUpdates() {
    setState(() => _isLoading = true);

    Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen(
      (Position position) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
          _isLoading = false;
          _getRoute();
        });
      },
      onError: (e) {
        setState(() {
          _errorMessage = "Error retrieving location: $e";
          _isLoading = false;
        });
      },
    );
  }

  Future<void> _getRoute() async {
    if (_currentPosition == null ||
        (!_isManualRouteSelection && _nearestMarker == null) ||
        (_isManualRouteSelection && _selectedMarker == null) ||
        !_isConnected) {
      return;
    }

    LatLng destination =
        _isManualRouteSelection ? _selectedMarker! : _nearestMarker!;

    final String url =
        "http://router.project-osrm.org/route/v1/walking/${_currentPosition!.longitude},${_currentPosition!.latitude};${destination.longitude},${destination.latitude}?overview=full&geometries=geojson";

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<LatLng> points =
            (data['routes'][0]['geometry']['coordinates'] as List)
                .map((coord) => LatLng(coord[1], coord[0]))
                .toList();
        setState(() {
          _routePoints = points;
        });
        await _cacheRoute(points);
        await _saveRouteForOfflineUse(points); // Save the route for offline use
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Error fetching route: $e";
      });
    }
  }

  Future<void> _cacheRoute(List<LatLng> points) async {
    final db = await openDatabase(
      join(await getDatabasesPath(), 'routes.db'),
      onCreate: (db, version) {
        return db.execute(
          "CREATE TABLE routes(id INTEGER PRIMARY KEY, latitude REAL, longitude REAL)",
        );
      },
      version: 1,
    );

    await db.delete('routes');

    for (var point in points) {
      await db.insert('routes', {
        'latitude': point.latitude,
        'longitude': point.longitude,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<void> _saveRouteForOfflineUse(List<LatLng> points) async {
    final db = await openDatabase(
      join(await getDatabasesPath(), 'offline_routes.db'),
      onCreate: (db, version) {
        return db.execute(
          "CREATE TABLE offline_routes(id INTEGER PRIMARY KEY, latitude REAL, longitude REAL)",
        );
      },
      version: 1,
    );

    await db.delete('offline_routes');

    for (var point in points) {
      await db.insert('offline_routes', {
        'latitude': point.latitude,
        'longitude': point.longitude,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<List<LatLng>> _loadCachedRoute() async {
    final db = await openDatabase(
      join(await getDatabasesPath(), 'routes.db'),
      onCreate: (db, version) {
        return db.execute(
          "CREATE TABLE routes(id INTEGER PRIMARY KEY, latitude REAL, longitude REAL)",
        );
      },
      version: 1,
    );

    try {
      final List<Map<String, dynamic>> maps = await db.query('routes');

      return List.generate(maps.length, (i) {
        return LatLng(maps[i]['latitude'], maps[i]['longitude']);
      });
    } catch (e) {
      // If the table does not exist, return an empty list
      return [];
    }
  }

  Future<List<LatLng>> _loadOfflineRoute() async {
    final db = await openDatabase(
      join(await getDatabasesPath(), 'offline_routes.db'),
      onCreate: (db, version) {
        return db.execute(
          "CREATE TABLE offline_routes(id INTEGER PRIMARY KEY, latitude REAL, longitude REAL)",
        );
      },
      version: 1,
    );

    try {
      final List<Map<String, dynamic>> maps = await db.query('offline_routes');

      return List.generate(maps.length, (i) {
        return LatLng(maps[i]['latitude'], maps[i]['longitude']);
      });
    } catch (e) {
      return [];
    }
  }

  void _showMarkerInfo(BuildContext context, Map<String, dynamic> marker) {
    if (!context.mounted) return;

    final distanceInMeters =
        _currentPosition != null
            ? Geolocator.distanceBetween(
              _currentPosition!.latitude,
              _currentPosition!.longitude,
              marker['latitude'],
              marker['longitude'],
            )
            : null;

    final distance =
        distanceInMeters != null
            ? (distanceInMeters / 1000).toStringAsFixed(1)
            : 'Unknown';

    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (BuildContext bottomSheetContext) {
        return Container(
          padding: EdgeInsets.all(25.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Evacuation Information',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey[900],
                      fontFamily: 'Inter',
                    ),
                  ),
                  Icon(Icons.info_outline, color: Colors.blueGrey[600]),
                ],
              ),
              SizedBox(height: 12),

              // Distance
              Row(
                children: [
                  Text(
                    distance,
                    style: TextStyle(
                      fontSize: 35,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey[900],
                      fontFamily: 'Inter',
                    ),
                  ),
                  SizedBox(width: 5),
                  Text(
                    'km',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey[600],
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),

              // Address
              Row(
                children: [
                  Icon(Icons.place, color: Colors.blueGrey[600], size: 20),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      marker['address'],
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blueGrey[800],
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),

              // Type
              Row(
                children: [
                  Icon(
                    Icons.sports_soccer,
                    color: Colors.blueGrey[600],
                    size: 20,
                  ),
                  SizedBox(width: 6),
                  Text(
                    marker['type'],
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blueGrey[800],
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),

              Divider(),

              // Contact & Captain
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Contact Number
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.orange[100],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.phone,
                          color: Colors.orange,
                          size: 18,
                        ),
                      ),
                      SizedBox(width: 6),
                      Text(
                        marker['contact'],
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blueGrey[800],
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),

                  // Barangay Captain
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.blueGrey[100],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.person,
                          color: Colors.blueGrey[700],
                          size: 18,
                        ),
                      ),
                      SizedBox(width: 6),
                      Text(
                        marker['captain'],
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blueGrey[800],
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  void _showUsageInstructions(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Usage Instructions'),
          content: Text(
            '1. Tap on a marker to view its information.\n'
            '2. Use the "Change Route" button to select a different marker to route to.\n'
            '3. The map will update to show the route to the selected marker.',
          ),
          actions: [
            TextButton(
              child: Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _changeRoute(BuildContext context) {
    if (_markers.isEmpty) return;

    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select an Evacuation Center',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[900],
                  fontFamily: 'Inter',
                ),
              ),
              SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: _markers.length,
                  itemBuilder: (BuildContext context, int index) {
                    final marker = _markers[index];
                    final isSelected =
                        marker['name'] == _nearestMarkerName &&
                        _isManualRouteSelection;
                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 2,
                      margin: EdgeInsets.symmetric(vertical: 5),
                      child: ListTile(
                        contentPadding: EdgeInsets.all(10),
                        title: Text(
                          marker['name'],
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueGrey[800],
                            fontFamily: 'Inter',
                          ),
                        ),
                        subtitle: Text(
                          marker['address'] + (isSelected ? ' (Selected)' : ''),
                          style: TextStyle(
                            fontSize: 14,
                            color:
                                isSelected
                                    ? Colors.lightGreen
                                    : Colors.blueGrey[600],
                            fontWeight:
                                isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                            fontFamily: 'Inter',
                          ),
                        ),
                        trailing: Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.blueGrey[600],
                        ),
                        onTap: () {
                          setState(() {
                            _selectedMarker = LatLng(
                              marker['latitude'],
                              marker['longitude'],
                            );
                            _selectedMarkerName = marker['name'];
                            _isManualRouteSelection = true;
                            _getRoute();
                          });
                          Navigator.of(context).pop();
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          if (!_isMapLoaded)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('( ＾◡＾)っ', style: TextStyle(fontSize: 50)),
                  SizedBox(height: 20),
                  CircularProgressIndicator(),
                ],
              ),
            )
          else if (_isLoading)
            Center(child: CircularProgressIndicator())
          else if (_errorMessage.isNotEmpty)
            Center(
              child: Text(_errorMessage, style: TextStyle(color: Colors.red)),
            )
          else
            FlutterMap(
              options: MapOptions(
                initialCenter: LatLng(
                  14.824384,
                  120.372642,
                ), // Center the map on Bataan
                initialZoom: 10.0, // Modify the zoom level here
                cameraConstraint: CameraConstraint.contain(
                  bounds: LatLngBounds(
                    LatLng(
                      14.360095282689867,
                      120.18260424908377,
                    ), // Southwest corner of Bataan
                    LatLng(
                      15.005139508118162,
                      120.57009879938303,
                    ), // Northeast corner of Bataan
                  ),
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                  tileProvider: CachedTileProvider(),
                ),
                MarkerLayer(
                  markers: [
                    if (_currentPosition != null)
                      Marker(
                        width: 80.0,
                        height: 80.0,
                        point: _currentPosition!,
                        child: Icon(
                          Icons.my_location,
                          color: Colors.blue,
                          size: 40,
                        ),
                      ),
                    ..._markers.map(
                      (marker) => Marker(
                        width: 80.0,
                        height: 80.0,
                        point: LatLng(marker['latitude'], marker['longitude']),
                        child: GestureDetector(
                          onTap: () => _showMarkerInfo(context, marker),
                          child: Column(
                            children: [
                              Icon(
                                Icons.place,
                                color:
                                    marker['name'] == _nearestMarkerName
                                        ? Colors.red
                                        : Colors.green,
                                size: 40,
                              ),
                              if (marker['name'] == _nearestMarkerName)
                                Text(
                                  'Nearest',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_routePoints.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _routePoints,
                        color: Colors.red,
                        strokeWidth: 4.0,
                      ),
                    ],
                  ),
              ],
            ),
          Positioned(
            top: 40,
            left: 40,
            right: 40,
            child: Container(
              padding: EdgeInsets.only(
                top: 15,
                bottom: 15,
                left: 20,
                right: 20,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 3,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: locationRed, width: 4),
                        ),
                      ),
                      SizedBox(width: 15),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "From",
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w300,
                              color: Colors.black26,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            _currentPosition != null
                                ? "${_currentPosition!.latitude}, ${_currentPosition!.longitude}"
                                : "Unknown Location",
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w400,
                              color: Colors.black,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Divider(indent: 35, endIndent: 60),
                  Row(
                    children: [
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: locationBlue, width: 4),
                        ),
                      ),
                      SizedBox(width: 15),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "To",
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w300,
                              color: Colors.black26,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            _isManualRouteSelection &&
                                    _selectedMarkerName != null
                                ? _selectedMarkerName!
                                : _nearestMarkerName ?? "Finding nearest...",
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w400,
                              color: Colors.black,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () => _changeRoute(context),
            tooltip: 'Change Route',
            child: Icon(Icons.directions),
          ),
          SizedBox(height: 10),
          FloatingActionButton(
            onPressed: () => _showUsageInstructions(context),
            tooltip: 'Usage Instructions',
            child: Icon(Icons.help_outline),
          ),
          SizedBox(height: 10),
          FloatingActionButton(
            onPressed: () {
              if (_isManualRouteSelection && _selectedMarker != null) {
                final selectedMarker = _markers.firstWhere(
                  (marker) =>
                      marker['latitude'] == _selectedMarker!.latitude &&
                      marker['longitude'] == _selectedMarker!.longitude,
                  orElse: () => {},
                );

                _showMarkerInfo(context, selectedMarker);
              } else if (_nearestMarker != null) {
                final nearestMarker = _markers.firstWhere(
                  (marker) =>
                      marker['latitude'] == _nearestMarker!.latitude &&
                      marker['longitude'] == _nearestMarker!.longitude,
                  orElse: () => {},
                );

                _showMarkerInfo(context, nearestMarker);
              }
            },
            tooltip: 'Show Selected Marker Info',
            child: Icon(Icons.location_on),
          ),
        ],
      ),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final documentsDirectory = await getApplicationDocumentsDirectory();
  final path = join(documentsDirectory.path, 'markers.db');

  await deleteDatabase(path);

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(),
      home: MapScreen(),
    ),
  );
}
