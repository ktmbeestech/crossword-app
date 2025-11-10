import 'package:crosswords/modules/landing/repository/reward.repos.dart';
import 'package:crosswords/modules/landing/repository/repositories.dart';
import 'package:crosswords/modules/landing/services/hint.service.dart';
import 'package:crosswords/services/databse/database.service.dart';
import 'package:sqflite/sqflite.dart';

class DailyRewardService {
  final RewardRepository _rewards = Repos.reward;

  Future<bool> canClaimToday() => _rewards.canClaimToday();
  Future<bool> isClaimedToday() => _rewards.isClaimedToday();
  Future<int> currentStreak() => _rewards.getStreak();
  Future<int> currentDayIndex() => _rewards.getCurrentDayIndex();

  // Map day index (0..6) to hint amount: x1..x7
  int amountForDayIndex(int dayIdx) => (dayIdx + 1).clamp(1, 7);

  Future<List<Map<String, Object?>>> history({int limit = 30}) =>
      _rewards.getHistory(limit: limit);

  // Claims the daily reward if eligible and grants hints, returning new hint total.
  Future<int?> claimDailyAndGrantHints() async {
    final can = await canClaimToday();
    if (!can) return null;
    final dayIdx = await currentDayIndex();
    final amount = amountForDayIndex(dayIdx);
    await _rewards.claimToday(amount: amount);
    await _rewards.logEvent(type: 'daily_hints', amount: amount);
    final n = await HintService.instance.add(amount);
    return n;
  }

  // Grants a one-time level completion bonus (default 5 hints) per level.
  // Returns new hint total if granted, or null if already granted before.
  Future<int?> grantLevelCompletionBonus(String levelId, {int amount = 5}) async {
    final Database db = await DatabaseService.instance.db;
    final type = 'level_bonus:$levelId';
    final existing = await db.query('reward_events', where: 'type = ?', whereArgs: [type], limit: 1);
    if (existing.isNotEmpty) return null; // already granted
    await db.insert('reward_events', {
      'claimed_utc': DateTime.now().toUtc().millisecondsSinceEpoch,
      'type': type,
      'amount': amount,
    });
    final n = await HintService.instance.add(amount);
    return n;
  }
}
