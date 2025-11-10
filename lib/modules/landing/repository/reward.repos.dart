import 'package:crosswords/services/databse/database.service.dart';
import 'package:sqflite/sqflite.dart';

class RewardRepository {
  Future<Database> get _db async => await DatabaseService.instance.db;

  // Treat “day” as UTC day
  int _utcDayStartMillis(DateTime dtUtc) {
    final d = DateTime.utc(dtUtc.year, dtUtc.month, dtUtc.day);
    return d.millisecondsSinceEpoch;
  }

  Future<bool> canClaimToday({DateTime? nowUtc}) async {
    final db = await _db;
    final now = (nowUtc ?? DateTime.now().toUtc());
    final todayStart = _utcDayStartMillis(now);

    final row = (await db.query('reward_state', limit: 1)).first;
    final lastClaimed = row['last_claimed_utc'] as int?;
    if (lastClaimed == null) return true;

    final lastDayStart = _utcDayStartMillis(
      DateTime.fromMillisecondsSinceEpoch(lastClaimed, isUtc: true),
    );
    return lastDayStart < todayStart;
  }

  Future<Map<String, dynamic>> getState() async {
    final db = await _db;
    return (await db.query('reward_state', limit: 1)).first;
  }

  Future<int> getStreak() async {
    final s = await getState();
    return (s['streak'] as int?) ?? 0;
  }

  // Returns updated streak
  Future<int> claimToday({int amount = 1, DateTime? nowUtc}) async {
    final db = await _db;
    final now = (nowUtc ?? DateTime.now().toUtc());
    final todayStart = _utcDayStartMillis(now);

    return await db.transaction<int>((txn) async {
      final row = (await txn.query('reward_state', limit: 1)).first;
      final lastClaimed = row['last_claimed_utc'] as int?;
      int streak = (row['streak'] as int?) ?? 0;

      if (lastClaimed != null) {
        final lastDayStart = _utcDayStartMillis(
          DateTime.fromMillisecondsSinceEpoch(lastClaimed, isUtc: true),
        );
        final daysDiff =
            (todayStart - lastDayStart) ~/ Duration.millisecondsPerDay;

        if (daysDiff == 0) {
          // already claimed today
          return streak;
        } else if (daysDiff == 1) {
          streak += 1;
        } else if (daysDiff > 1) {
          streak = 1; // reset
        }
      } else {
        streak = 1;
      }

      await txn.update(
        'reward_state',
        {
          'last_claimed_utc': now.millisecondsSinceEpoch,
          'streak': streak,
        },
        where: 'id = 1',
      );

      await txn.insert('reward_events', {
        'claimed_utc': now.millisecondsSinceEpoch,
        'type': 'daily',
        'amount': amount,
      });

      return streak;
    });
  }

  Future<List<Map<String, Object?>>> getHistory({int limit = 30}) async {
    final db = await _db;
    return await db.query(
      'reward_events',
      orderBy: 'claimed_utc DESC',
      limit: limit,
    );
  }

  Future<void> logEvent({required String type, required int amount, DateTime? whenUtc}) async {
    final db = await _db;
    final now = (whenUtc ?? DateTime.now().toUtc()).millisecondsSinceEpoch;
    await db.insert('reward_events', {
      'claimed_utc': now,
      'type': type,
      'amount': amount,
    });
  }

  Future<int> getCurrentDayIndex() async {
    // Day index cycles 0..6 based on current streak
    final s = await getState();
    final streak = (s['streak'] as int?) ?? 0;
    if (streak <= 0) return 0;
    return (streak % 7);
  }

  Future<bool> isClaimedToday() async {
    final can = await canClaimToday();
    return !can;
  }
}