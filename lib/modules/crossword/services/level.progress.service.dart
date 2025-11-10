import 'package:crosswords/services/local_storage/local_storage.services.dart';
import 'package:crosswords/modules/landing/repository/repositories.dart';

import '../data/crossword.level.data2.dart';

class LevelProgressService {
  static const _kCurrentIndex = 'cw_current_level_index';
  static final LevelProgressService instance = LevelProgressService._();

  LevelProgressService._();

  Future<int> getCurrentIndex() async {
    final raw = await storageInstance.getData(key: _kCurrentIndex);
    if (raw == null) return 0;
    final idx = int.tryParse(raw) ?? 0;
    return idx.clamp(0, allLevels.length - 1);
  }

  Future<void> setCurrentIndex(int index) async {
    await storageInstance.setData(key: _kCurrentIndex, value: index.toString());
  }

  Future<Set<String>> getCompleted() async {
    final rows = await Repos.level.getAllStatuses();
    final ids = <String>{};
    for (final r in rows) {
      if ((r['passed'] as int? ?? 0) == 1) {
        final id = r['id'] as String?;
        if (id != null) ids.add(id);
      }
    }
    return ids;
  }

  Future<Set<String>> getSkipped() async {
    final rows = await Repos.level.getAllStatuses();
    final ids = <String>{};
    for (final r in rows) {
      if ((r['skipped'] as int? ?? 0) == 1 && (r['passed'] as int? ?? 0) == 0) {
        final id = r['id'] as String?;
        if (id != null) ids.add(id);
      }
    }
    return ids;
  }

  Future<void> markCompleted(String levelId) async {
    await Repos.level.markPassed(levelId: levelId);
  }

  Future<void> markSkipped(String levelId) async {
    await Repos.level.markSkipped(levelId);
  }

  Future<void> resetAll() async {
    // Clear DB-backed level progress and local current index
    await Repos.level.resetAll();
    await storageInstance.removeData(key: _kCurrentIndex);
  }

  Future<int> nextPlayableIndex() async {
    // Next is current index if within bounds, else first incomplete
    final current = await getCurrentIndex();
    if (current < allLevels.length) return current;
    final completed = await getCompleted();
    for (var i = 0; i < allLevels.length; i++) {
      if (!completed.contains(allLevels[i].id)) return i;
    }
    return 0;
  }
}
