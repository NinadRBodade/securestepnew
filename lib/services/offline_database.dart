import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class OfflineDatabase {
  static final OfflineDatabase instance = OfflineDatabase._init();
  static Database? _database;

  OfflineDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('securestep_offline.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const intType = 'INTEGER NOT NULL';
    const textTypeNullable = 'TEXT';

    // Offline entry logs table
    await db.execute('''
    CREATE TABLE offline_entries (
      id $idType,
      agentId $textType,
      name $textType,
      email $textType,
      company $textTypeNullable,
      action $textType,
      timestamp $textType,
      verified INTEGER DEFAULT 0,
      score INTEGER DEFAULT 0,
      isOffline INTEGER DEFAULT 1,
      synced INTEGER DEFAULT 0,
      qrData $textType,
      expiresAt $textTypeNullable,
      signature $textTypeNullable
    )
    ''');

    print('✅ Offline database created');
  }

  // Insert offline entry
  Future<int> insertOfflineEntry(Map<String, dynamic> entry) async {
    final db = await database;
    final id = await db.insert('offline_entries', entry);
    print('💾 Offline entry saved: ID=$id');
    return id;
  }

  // Get all unsynced entries
  Future<List<Map<String, dynamic>>> getUnsyncedEntries() async {
    final db = await database;
    return await db.query(
      'offline_entries',
      where: 'synced = ?',
      whereArgs: [0],
      orderBy: 'timestamp DESC',
    );
  }

  // Mark entry as synced
  Future<int> markAsSynced(int id) async {
    final db = await database;
    return await db.update(
      'offline_entries',
      {'synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Get all entries (for display)
  Future<List<Map<String, dynamic>>> getAllEntries() async {
    final db = await database;
    return await db.query(
      'offline_entries',
      orderBy: 'timestamp DESC',
      limit: 100,
    );
  }

  // Get entry count
  Future<int> getUnsyncedCount() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM offline_entries WHERE synced = 0',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Delete old synced entries (cleanup)
  Future<int> deleteOldSyncedEntries({int daysOld = 7}) async {
    final db = await database;
    final cutoffDate = DateTime.now().subtract(Duration(days: daysOld)).toIso8601String();
    return await db.delete(
      'offline_entries',
      where: 'synced = 1 AND timestamp < ?',
      whereArgs: [cutoffDate],
    );
  }

  Future close() async {
    final db = await database;
    await db.close();
  }
}
