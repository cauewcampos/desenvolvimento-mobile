import 'dart:io';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseHelper {
  static Database? _database;
  static bool _ffiInitialized = false;
  static const String _databaseName = 'pets.db';
  static const String _tableName = 'pets';

  static Future<void> initialize() async {
    if (_ffiInitialized) {
      return;
    }

    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    _ffiInitialized = true;
  }

  static Future<Database> get database async {
    await initialize();

    if (_database != null) {
      return _database!;
    }

    _database = await _initDatabase();
    return _database!;
  }

  static Future<String> _databasePath() async {
    await initialize();

    if (Platform.isWindows || Platform.isLinux) {
      final dbPath = await databaseFactoryFfi.getDatabasesPath();
      return join(dbPath, _databaseName);
    }

    return join(await getDatabasesPath(), _databaseName);
  }

  static Future<Database> _initDatabase() async {
    final path = await _databasePath();

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_tableName (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            age INTEGER NOT NULL
          )
        ''');
      },
    );
  }

  static Future<void> resetDatabase() async {
    final db = await database;
    await db.close();
    _database = null;
    final path = await _databasePath();
    await deleteDatabase(path);
  }

  static Future<int> inserirPet(Map<String, dynamic> pet) async {
    final db = await database;
    return db.insert(_tableName, pet);
  }

  static Future<List<Map<String, dynamic>>> listarPets() async {
    final db = await database;
    return db.query(_tableName, orderBy: 'id ASC');
  }

  static Future<int> atualizarPet(int id, Map<String, dynamic> pet) async {
    final db = await database;
    return db.update(
      _tableName,
      pet,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<int> apagarPet(int id) async {
    final db = await database;
    return db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<int> insertPet(Map<String, dynamic> pet) async {
    return inserirPet(pet);
  }

  static Future<List<Map<String, dynamic>>> getPets() async {
    return listarPets();
  }

  static Future<int> updatePet(int id, Map<String, dynamic> pet) async {
    return atualizarPet(id, pet);
  }

  static Future<int> deletePet(int id) async {
    return apagarPet(id);
  }
}
