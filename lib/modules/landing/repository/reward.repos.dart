import 'package:flutter/foundation.dart';
import 'package:crosswords/services/databse/database.service.dart';
import 'package:sqflite/sqflite.dart';

class RewardRepository {
  Future<Database> get _db async => await DatabaseService.instance.db;

  // Treat “day” as local day
  int _localDayStartMillis(DateTime dt) {
    final d = DateTime(dt.year, dt.month, dt.day);
    return d.millisecondsSinceEpoch;
  }

  Future<bool> canClaimToday({DateTime? now}) async {
    final db = await _db;
    final nowTime = (now ?? DateTime.now());
    final todayStart = _localDayStartMillis(nowTime);

    final row = (await db.query('reward_state', limit: 1)).first;
    final lastClaimed = row['last_claimed_utc'] as int?;
    if (lastClaimed == null) return true;

    final lastDayStart = _localDayStartMillis(
      DateTime.fromMillisecondsSinceEpoch(lastClaimed),
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
  Future<int> claimToday({int amount = 1, DateTime? now}) async {
    final db = await _db;
    final nowTime = (now ?? DateTime.now());
    final todayStart = _localDayStartMillis(nowTime);

    return await db.transaction<int>((txn) async {
      final row = (await txn.query('reward_state', limit: 1)).first;
      final lastClaimed = row['last_claimed_utc'] as int?;
      int streak = (row['streak'] as int?) ?? 0;

      if (lastClaimed != null) {
        final lastDayStart = _localDayStartMillis(
          DateTime.fromMillisecondsSinceEpoch(lastClaimed),
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

      await txn.update('reward_state', {
        'last_claimed_utc': nowTime.millisecondsSinceEpoch,
        'streak': streak,
      }, where: 'id = 1');

      await txn.insert('reward_events', {
        'claimed_utc': nowTime.millisecondsSinceEpoch,
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

  Future<void> logEvent({
    required String type,
    required int amount,
    DateTime? when,
  }) async {
    final db = await _db;
    final now = (when ?? DateTime.now()).millisecondsSinceEpoch;
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

  // DEBUG ONLY: Shift to specific day for testing (bypasses daily refresh)
  Future<void> debugShiftToDay({
    required int targetDay, // 1-7 (actual day number)
    DateTime? customTime,
  }) async {
    if (!kDebugMode) return;

    final db = await _db;
    final now = customTime ?? DateTime.now();

    // Calculate what the streak should be for this target day
    final targetStreak = targetDay;

    // Set the reward state to make it think we're ready to claim this day
    await db.update('reward_state', {
      'streak': targetStreak,
      'last_claimed_utc':
          now
              .subtract(Duration(days: targetDay - 1))
              .millisecondsSinceEpoch, // Last claim was previous day
    }, where: 'id = 1');

    // Create real claim events for previous days only
    await db.delete('reward_events', where: 'type = ?', whereArgs: ['daily']);

    // Add claims for days 1 to (targetDay-1)
    for (int i = 1; i < targetDay; i++) {
      final eventTime = now.subtract(Duration(days: targetDay - i));
      await db.insert('reward_events', {
        'claimed_utc': eventTime.millisecondsSinceEpoch,
        'type': 'daily',
        'amount': i, // Day 1 = 1 hint, Day 2 = 2 hints, etc.
      });
    }
  }
}
