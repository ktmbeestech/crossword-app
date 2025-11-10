import 'package:crosswords/services/databse/database.service.dart';

class HintService {
  HintService._();
  static final HintService instance = HintService._();

  Future<int> getCount() async {
    final db = await DatabaseService.instance.db;
    final rows = await db.query('wallet', where: 'id = 1', limit: 1);
    if (rows.isEmpty) return 0;
    final n = (rows.first['hints'] as int?) ?? 0;
    return n < 0 ? 0 : n;
  }

  Future<void> setCount(int value) async {
    final db = await DatabaseService.instance.db;
    final v = value < 0 ? 0 : value;
    await db.update('wallet', {'hints': v}, where: 'id = 1');
  }

  Future<int> add(int delta) async {
    final db = await DatabaseService.instance.db;
    return await db.transaction<int>((txn) async {
      final rows = await txn.query('wallet', where: 'id = 1', limit: 1);
      final current = rows.isEmpty ? 0 : (rows.first['hints'] as int? ?? 0);
      final next = current + delta;
      await txn.update('wallet', {'hints': next < 0 ? 0 : next}, where: 'id = 1');
      return next < 0 ? 0 : next;
    });
  }

  Future<int> consume(int amount) async {
    final db = await DatabaseService.instance.db;
    return await db.transaction<int>((txn) async {
      final rows = await txn.query('wallet', where: 'id = 1', limit: 1);
      final current = rows.isEmpty ? 0 : (rows.first['hints'] as int? ?? 0);
      final next = current - amount;
      await txn.update('wallet', {'hints': next < 0 ? 0 : next}, where: 'id = 1');
      return next < 0 ? 0 : next;
    });
  }
}
