import 'dart:convert';

import 'package:ma_exam_t/models/Albatross.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._constructor();
  static Database? _database;

  final String _tableName = "albatross";
  final String _offlineChangesTable = "offline_changes";

  DatabaseService._constructor();

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await getDatabase();
    return _database!;
  }

  Future<Database> getDatabase() async {
    final databaseDirPath = await getDatabasesPath();
    final databasePath = join(databaseDirPath, "albatross_db.db");

    // databaseFactory.deleteDatabase(databasePath);
    final database = await openDatabase(
      databasePath,
      version: 5,
      onCreate: (db, version) {
        db.execute('''
          CREATE TABLE IF NOT EXISTS $_tableName (
            id INTEGER PRIMARY KEY,
            date TEXT NOT NULL,
            name TEXT NOT NULL
          )
        ''');
        db.execute('''
          CREATE TABLE IF NOT EXISTS $_offlineChangesTable (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            change_type TEXT NOT NULL,
            internal_id INTEGER,
            data TEXT,
            synced INTEGER DEFAULT 0
          )
        ''');
      },
    );

    return database;
  }

  Future<int> addEntity(Albatross entity) async {
    final db = await database;

    int resultId = await db.insert(_tableName, entity.toJson());
    return resultId;
  }

  Future<int> addEntityOffline(Albatross entity) async {
    final db = await database;

    int temporaryId = await db.insert(_tableName, entity.toJsonWithoutId());

    await db.insert(_offlineChangesTable, {
      "change_type": "add",
      "internal_id": temporaryId,
      "data": json.encode(entity.toJson()),
      "synced": 0,
    });

    return temporaryId;
  }

  Future<int> updateEntity(Albatross entity) async {
    final db = await database;

    int result = await db.update(
      _tableName,
      entity.toJsonWithoutId(),
      where: "id = ?",
      whereArgs: [entity.id],
    );

    return result;
  }

  Future<int> deleteEntity(int id) async {
    final db = await database;
    int result = await db.delete(_tableName, where: "id = ?", whereArgs: [id]);
    return result;
  }

  Future<Albatross?> getEntityById(int id) async {
    final db = await database;

    final data = await db.query(
      _tableName,
      where: "id = ?",
      whereArgs: [id],
    );

    if (data.isNotEmpty) {
      return Albatross.fromJson(data.first);

    } else {
      return null;
    }
  }

  Future<List<Albatross>> getAllEntities() async {
    final db = await database;
    final data = await db.query(_tableName);

    return data.map((e) => Albatross.fromJson(e)).toList();
  }

  Future<void> clearAllEntities() async {
    final db = await database;
    await db.delete(_tableName);
  }

  Future<List<Map<String, dynamic>>> getOfflineChanges() async {
    final db = await database;
    return await db.query(_offlineChangesTable, where: "synced = 0");
  }

  Future<void> markChangeAsSynced(int id) async {
    final db = await database;
    await db.update(
      _offlineChangesTable,
      {"synced": 1},
      where: "id = ?",
      whereArgs: [id],
    );
  }

  Future<void> clearOfflineChanges() async {
    final db = await database;
    await db.delete(_offlineChangesTable);
  }
}