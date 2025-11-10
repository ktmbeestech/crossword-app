import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class DatabaseService {
  DatabaseService._internal();

  static final DatabaseService instance = DatabaseService._internal();

  Database? _db;

  static const _dbName = 'crossword.db';

  static const _dbVersion = 2;

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, _dbName);
    return await openDatabase(
      path,
       version: _dbVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        );
  }

   Future<void> _onCreate(Database db, int version) async {
    // rewards
    await db.execute('''
      CREATE TABLE reward_state (
        id INTEGER PRIMARY KEY CHECK(id = 1),
        last_claimed_utc INTEGER,
        streak INTEGER NOT NULL DEFAULT 0
      );
    ''');
    await db.execute('INSERT INTO reward_state (id, streak) VALUES (1, 0);');

    await db.execute('''
      CREATE TABLE reward_events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        claimed_utc INTEGER NOT NULL,
        type TEXT NOT NULL DEFAULT 'daily',
        amount INTEGER NOT NULL DEFAULT 0
      );
    ''');

    // levels
    await db.execute('''
      CREATE TABLE levels (
        id TEXT PRIMARY KEY,
        passed INTEGER NOT NULL DEFAULT 0,
        skipped INTEGER NOT NULL DEFAULT 0,
        last_updated_utc INTEGER
      );
    ''');

    await db.execute('''
      CREATE TABLE level_runs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        level_id TEXT NOT NULL,
        passed INTEGER NOT NULL,
        time_spent_ms INTEGER NOT NULL DEFAULT 0,
        completed_at_utc INTEGER,
        FOREIGN KEY(level_id) REFERENCES levels(id) ON DELETE CASCADE
      );
    ''');

    // speed up frequent lookups
    await db.execute('CREATE INDEX idx_level_runs_level_id ON level_runs(level_id);');
    await db.execute('CREATE INDEX idx_reward_events_claimed ON reward_events(claimed_utc);');

    // wallet: store hint balance
    await db.execute('''
      CREATE TABLE wallet (
        id INTEGER PRIMARY KEY CHECK(id = 1),
        hints INTEGER NOT NULL DEFAULT 0
      );
    ''');
    await db.insert('wallet', {'id': 1, 'hints': 3});
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS wallet (
          id INTEGER PRIMARY KEY CHECK(id = 1),
          hints INTEGER NOT NULL DEFAULT 0
        );
      ''');
      // Seed if missing
      final rows = await db.query('wallet', where: 'id = 1', limit: 1);
      if (rows.isEmpty) {
        await db.insert('wallet', {'id': 1, 'hints': 3});
      }
    }
  }

}
