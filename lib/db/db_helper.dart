import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart'; 
import 'package:path/path.dart';

// Inisialisasi sqflite_common_ffi
void initSqfliteFfi() {
  sqfliteFfiInit();
}

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    initSqfliteFfi(); 
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'profile.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE profile(id INTEGER PRIMARY KEY, name TEXT, npwp TEXT, dob TEXT, gender TEXT, storeName TEXT, storeAddress TEXT)',
        );
      },
    );
  }

  Future<void> saveProfile(Map<String, dynamic> profile) async {
    final db = await database;
    print("Saving profile: $profile"); // Debugging

    try {
      await db.insert(
        'profile',
        profile,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      print("Profile data saved successfully.");
    } catch (e) {
      print("Error saving profile: $e");
    }
  }

  Future<Map<String, dynamic>?> getProfile() async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.query('profile');
    if (result.isNotEmpty) {
      print("Fetched profile: ${result.first}"); 
      return result.first;
    } else {
      print("No profile data found.");
      return null;
    }
  }
}
