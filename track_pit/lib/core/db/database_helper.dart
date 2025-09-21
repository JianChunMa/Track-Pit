import 'package:sqflite/sqflite.dart';
// ignore: depend_on_referenced_packages
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('trackpit.db');

    await _seedData(_database!);
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    await deleteDatabase(path);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
    CREATE TABLE car_models (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      image_file TEXT
    )
  ''');

    await db.execute('''
    CREATE TABLE workshops(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      address TEXT NOT NULL,
      lat REAL NOT NULL,
      lng REAL NOT NULL
    )
    ''');

    await db.execute('''
    CREATE TABLE service_types(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL
    )
  ''');
  }

  Future _seedData(Database db) async {
    await db.delete('car_models');
    await db.delete('workshops');
    await db.delete('service_types');

    await db.execute("DELETE FROM sqlite_sequence WHERE name='car_models'");
    await db.execute("DELETE FROM sqlite_sequence WHERE name='workshops'");
    await db.execute("DELETE FROM sqlite_sequence WHERE name='service_types'");
    // --- Car Models ---

    // Honda
    await db.insert('car_models', {
      'name': 'Honda Accord',
      'image_file': 'honda/accord.png',
    });
    await db.insert('car_models', {
      'name': 'Honda City',
      'image_file': 'honda/city.png',
    });
    await db.insert('car_models', {
      'name': 'Honda City Hatchback',
      'image_file': 'honda/city_hatchback.png',
    });
    await db.insert('car_models', {
      'name': 'Honda Civic',
      'image_file': 'honda/civic.png',
    });
    await db.insert('car_models', {
      'name': 'Honda HR-V',
      'image_file': 'honda/hrv.png',
    });

    // Perodua
    await db.insert('car_models', {
      'name': 'Perodua Alza',
      'image_file': 'perodua/alza.png',
    });
    await db.insert('car_models', {
      'name': 'Perodua Ativa',
      'image_file': 'perodua/ativa.png',
    });
    await db.insert('car_models', {
      'name': 'Perodua Axia',
      'image_file': 'perodua/axia.png',
    });
    await db.insert('car_models', {
      'name': 'Perodua Bezza',
      'image_file': 'perodua/bezza.png',
    });
    await db.insert('car_models', {
      'name': 'Perodua Myvi',
      'image_file': 'perodua/myvi.png',
    });

    // Proton
    await db.insert('car_models', {
      'name': 'Proton Exora',
      'image_file': 'proton/exora.png',
    });
    await db.insert('car_models', {
      'name': 'Proton Iriz',
      'image_file': 'proton/iriz.png',
    });
    await db.insert('car_models', {
      'name': 'Proton Persona',
      'image_file': 'proton/persona.png',
    });
    await db.insert('car_models', {
      'name': 'Proton Saga',
      'image_file': 'proton/saga.png',
    });
    await db.insert('car_models', {
      'name': 'Proton X50',
      'image_file': 'proton/x50.png',
    });

    // Toyota
    await db.insert('car_models', {
      'name': 'Toyota Harrier',
      'image_file': 'toyota/harrier.png',
    });
    await db.insert('car_models', {
      'name': 'Toyota Hilux',
      'image_file': 'toyota/hilux.png',
    });
    await db.insert('car_models', {
      'name': 'Toyota Veloz',
      'image_file': 'toyota/veloz.png',
    });
    await db.insert('car_models', {
      'name': 'Toyota Vios',
      'image_file': 'toyota/vios.png',
    });
    await db.insert('car_models', {
      'name': 'Toyota Yaris',
      'image_file': 'toyota/yaris.jpg',
    });

    // --- Workshops ---
    await db.insert('workshops', {
      'name': 'TrackPit Jalan Munshi',
      'address': 'No. T-199, Jalan Munshi Abdullah, 75100 Melaka',
      'lat': 2.1979401,
      'lng': 102.2551923,
    });

    await db.insert('workshops', {
      'name': 'TrackPit Seremban Oakland',
      'address':
          'Geran 77949, Lot 21742 Pekan Bukit Kepayang, Seremban, Negeri Sembilan',
      'lat': 2.7048973,
      'lng': 101.917287,
    });

    await db.insert('workshops', {
      'name': 'TrackPit Ampang Service Center',
      'address':
          'Tambahan, Lot 1322, Kawasan Kilang, Jln 11, Kampung Baru Ampang, 68000 Ampang, Selangor',
      'lat': 3.133977,
      'lng': 101.7640914,
    });

    await db.insert('workshops', {
      'name': 'TrackPit PJ Service Center',
      'address':
          '2, Lorong 51 A/227C, Seksyen 51A, 46100 Petaling Jaya, Selangor',
      'lat': 3.1002416,
      'lng': 101.6320669,
    });

    final services = [
      "20-Point Inspection",
      "Brake System",
      "Aircond System",
      "Battery",
      "Suspension",
      "Tyre Services",
      "General Service",
      "Aircond Pollen Filter",
      "Engine Diagnostics",
      "Periodic Maintenance",
    ];

    for (var name in services) {
      await db.insert('service_types', {'name': name});
    }
  }
}
