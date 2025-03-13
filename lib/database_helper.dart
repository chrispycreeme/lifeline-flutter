import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:latlong2/latlong.dart';

class DatabaseHelper {
  static Database? _database;
  static const String tableName = 'markers';

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    try {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final path = join(documentsDirectory.path, 'markers.db');

      return openDatabase(
        path,
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
          CREATE TABLE $tableName (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            latitude REAL,
            longitude REAL,
            address TEXT,
            type TEXT,
            barangay TEXT,
            captain TEXT,
            contact TEXT,
            name TEXT
          )
          ''');

          List<Map<String, dynamic>> markers = [
            {'latitude': 14.84631, 'longitude': 120.41158, 'address': 'Colo, Dinalupihan 2110 Bataan, Philippines', 'type': 'Purpose-Built Evacuation', 'barangay': 'Colo', 'captain': 'Aurelio M. Cruz', 'contact': '972405343', 'name': 'Dinalupihan Evacuation Center'},
            {'latitude': 14.84788, 'longitude': 120.41242, 'address': 'Colo, Dinalupihan 2110 Bataan, Philippines', 'type': 'School', 'barangay': 'Colo', 'captain': 'Aurelio M. Cruz', 'contact': '972405343', 'name': 'Colo Elementary School'},
            {'latitude': 14.84676, 'longitude': 120.36064, 'address': 'Roosevelt, Dinalupihan 2110, Bataan', 'type': 'School', 'barangay': 'Roosevelt', 'captain': 'Gonzalo B. Antonio Jr.', 'contact': '9641883387', 'name': 'Roosevelt Elementary School'},
            {'latitude': 14.86183, 'longitude': 120.44044, 'address': 'Saguing, Dinalupihan 2110, Bataan', 'type': 'School', 'barangay': 'Saguing', 'captain': 'Luzviminda F. Esquivel', 'contact': 'No data available', 'name': 'Saguing Elementary School'},
            {'latitude': 14.86244, 'longitude': 120.42657, 'address': 'Maligaya, Dinalupihan 2110, Bataan', 'type': 'School', 'barangay': 'Maligaya', 'captain': 'Marivic F. Castro', 'contact': 'No data available', 'name': 'Maligaya Elementary School'},
            {'latitude': 14.89329, 'longitude': 120.46785, 'address': 'Pagalanggang, Dinalupihan 2110 Bataan', 'type': 'School', 'barangay': 'Pagalanggang', 'captain': 'Francisco D. Aguilar', 'contact': '9082563724', 'name': 'Pagalanggang Elementary School'},
            {'latitude': 14.88954, 'longitude': 120.46269, 'address': 'Old San Jose, Dinalupihan 2110 Bataan', 'type': 'School', 'barangay': 'Old San Jose', 'captain': 'Albert E. Bacordo', 'contact': '9472377400', 'name': 'Old San Jose Elementary School'},
            {'latitude': 14.8651, 'longitude': 120.44869, 'address': 'Luacan, Dinalupihan 2110, Bataan', 'type': 'School', 'barangay': 'Luacan', 'captain': 'Arnold V. Tajonera', 'contact': '9192759211', 'name': 'Luacan Elementary School'},
            {'latitude': 14.84659, 'longitude': 120.42011, 'address': 'Magsaysay, Dinalupihan 2110, Bataan', 'type': 'School', 'barangay': 'Magsaysay', 'captain': 'Daniel S. Quinto', 'contact': '09432921043', 'name': 'Magsaysay Elementary School'},
            {'latitude': 14.89391, 'longitude': 120.4394, 'address': 'Pita, Dinalupihan 2110, Bataan', 'type': 'School', 'barangay': 'Pita', 'captain': 'Josephine N. Jones', 'contact': '9082533842', 'name': 'Pita Elementary School'},
            {'latitude': 14.84804, 'longitude': 120.42463, 'address': 'San Benito, Dinalupihan 2110, Bataan', 'type': 'School', 'barangay': 'San Benito', 'captain': 'Armando S. Felicitas', 'contact': 'No data available', 'name': 'San Benito Elementary School'}
          ];

          for (var marker in markers) {
            await db.insert(tableName, marker);
          }
        },
      );
    } catch (e) {
      print("Database init error: $e");
      rethrow;
    }
  }

  static Future<void> insertMarker(
    LatLng position,
    String address,
    String type,
    String barangay,
    String captain,
    String contact,
    String name,
  ) async {
    final db = await database;
    await db.insert(tableName, {
      'latitude': position.latitude,
      'longitude': position.longitude,
      'address': address,
      'type': type,
      'barangay': barangay,
      'captain': captain,
      'contact': contact,
      'name': name,
    });
  }

  static Future<List<Map<String, dynamic>>> getMarkers() async {
    final db = await database;
    return await db.query(tableName);
  }
}
