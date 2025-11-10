import 'package:crosswords/services/databse/database.service.dart';
import 'package:sqflite/sqflite.dart';

class LevelStatus {
  final bool passed;
  final bool skipped;
  LevelStatus({required this.passed, required this.skipped});
}

class LevelRepository {
  Future<Database> get _db async => await DatabaseService.instance.db;

  Future<void> _ensureLevelExists(DatabaseExecutor txn, String levelId, int nowUtc) async {
    final rows = await txn.query('levels', where: 'id = ?', whereArgs: [levelId], limit: 1);
    if (rows.isEmpty) {
      await txn.insert('levels', {
        'id': levelId,
        'passed': 0,
        'skipped': 0,
        'last_updated_utc': nowUtc,
      });
    }
  }

  Future<void> markPassed({
    required String levelId,
    int timeSpentMs = 0,
    DateTime? completedAtUtc,
  }) async {
    final db = await _db;
    final now = (completedAtUtc ?? DateTime.now().toUtc()).millisecondsSinceEpoch;

    await db.transaction((txn) async {
      await _ensureLevelExists(txn, levelId, now);

      await txn.update(
        'levels',
        {
          'passed': 1,
          'skipped': 0, // once passed, clear skipped
          'last_updated_utc': now,
        },
        where: 'id = ?',
        whereArgs: [levelId],
      );

      await txn.insert('level_runs', {
        'level_id': levelId,
        'passed': 1,
        'time_spent_ms': timeSpentMs,
        'completed_at_utc': now,
      });
    });
  }

  Future<void> markSkipped(String levelId) async {
    final db = await _db;
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;

    await db.transaction((txn) async {
      await _ensureLevelExists(txn, levelId, now);
      await txn.update(
        'levels',
        {
          'skipped': 1,
          // do not set passed here
          'last_updated_utc': now,
        },
        where: 'id = ?',
        whereArgs: [levelId],
      );
    });
  }

  Future<void> clearSkip(String levelId) async {
    final db = await _db;
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    await db.update(
      'levels',
      {'skipped': 0, 'last_updated_utc': now},
      where: 'id = ?',
      whereArgs: [levelId],
    );
  }

  Future<LevelStatus> getStatus(String levelId) async {
    final db = await _db;
    final rows = await db.query('levels', where: 'id = ?', whereArgs: [levelId], limit: 1);
    if (rows.isEmpty) return LevelStatus(passed: false, skipped: false);
    final r = rows.first;
    return LevelStatus(
      passed: (r['passed'] as int? ?? 0) == 1,
      skipped: (r['skipped'] as int? ?? 0) == 1,
    );
  }

  Future<List<Map<String, Object?>>> getAllStatuses() async {
    final db = await _db;
    return await db.query('levels', orderBy: 'id ASC');
  }

  // Helper for UI: returns a 3-state int for a level (0=locked/none, 1=skipped, 2=passed)
  Future<int> statusCode(String levelId) async {
    final s = await getStatus(levelId);
    if (s.passed) return 2;
    if (s.skipped) return 1;
    return 0;
  }

  Future<void> resetAll() async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.delete('level_runs');
      await txn.delete('levels');
    });
  }
}