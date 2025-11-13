import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:math';

import 'package:clarity_flutter/clarity_flutter.dart';
import 'package:device_info_plus/device_info_plus.dart';

import '../local_storage/local_storage.services.dart';

class AnalyticsService {
  AnalyticsService._internal();
  static final AnalyticsService instance = AnalyticsService._internal();

  static const _kUserIdKey = 'analytics_user_id';
  static const _kInstallTrackedKey = 'analytics_install_tracked';
  static const _kCompletedLevelsKey = 'completed_levels';
  static const _kSkippedLevelsKey = 'skipped_levels';

  bool _initialized = false;
  String? _userId;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    _userId = await _getOrCreateUserId();
    try {
      Clarity.setCustomUserId(_userId!);
    } catch (_) {}

    // Fire one-time install event
    final tracked = await storageInstance.getData(key: _kInstallTrackedKey);
    if (tracked != 'true') {
      final device = await _collectDeviceInfo();
      _track('install', device);
      await storageInstance.setData(key: _kInstallTrackedKey, value: 'true');
    }

    //  app-open event 
    final device = await _collectDeviceInfo();
    _track('app_open', device);
  }

  Future<void> trackReachedLevel(String levelId) async {
    _track('reached_level', {
      'userId': _userId,
      'level': levelId,
    });
  }

  Future<void> trackLevelCompleted(String levelId, {int? timeSeconds, int? mistakes}) async {
    await _appendToList(_kCompletedLevelsKey, levelId);
    _track('level_completed', {
      'userId': _userId,
      'level': levelId,
      if (timeSeconds != null) 'time_s': timeSeconds,
      if (mistakes != null) 'mistakes': mistakes,
    });
  }

  Future<void> trackLevelSkipped(String levelId) async {
    await _appendToList(_kSkippedLevelsKey, levelId);
    _track('level_skipped', {
      'userId': _userId,
      'level': levelId,
    });
  }

  Future<void> trackDailyRewardClaimed(int dayIndex) async {
    _track('daily_reward_claimed', {
      'userId': _userId,
      'day_index': dayIndex,
    });
  }

  Future<List<String>> getCompletedLevels() async => _getList(_kCompletedLevelsKey);
  Future<List<String>> getSkippedLevels() async => _getList(_kSkippedLevelsKey);
  String? getUserId() => _userId;

  // --- internals ---
  Future<String> _getOrCreateUserId() async {
    final existing = await storageInstance.getData(key: _kUserIdKey);
    if (existing != null && existing.isNotEmpty) return existing;

    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final a = await deviceInfo.androidInfo;
        final id = a.id;
        if (id.isNotEmpty) {
          await storageInstance.setData(key: _kUserIdKey, value: id);
          return id;
        }
      } else if (Platform.isIOS) {
        final i = await deviceInfo.iosInfo;
        final id = i.identifierForVendor;
        if (id != null && id.isNotEmpty) {
          await storageInstance.setData(key: _kUserIdKey, value: id);
          return id;
        }
      }
    } catch (_) {}

    // Fallback UUID-like string
    final rand = Random();
    final fallback = '${DateTime.now().millisecondsSinceEpoch.toRadixString(16)}-${rand.nextInt(1 << 32).toRadixString(16)}';
    await storageInstance.setData(key: _kUserIdKey, value: fallback);
    return fallback;
  }

  Future<Map<String, dynamic>> _collectDeviceInfo() async {
    final out = <String, dynamic>{
      'userId': _userId,
      'platform': Platform.operatingSystem,
    };
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final a = await deviceInfo.androidInfo;
        out.addAll({
          'model': a.model,
          'manufacturer': a.manufacturer,
          'osVersion': 'Android ${a.version.release} (${a.version.sdkInt})',
        });
      } else if (Platform.isIOS) {
        final i = await deviceInfo.iosInfo;
        out.addAll({
          'model': i.utsname.machine,
          'osVersion': 'iOS ${i.systemVersion}',
        });
      }
    } catch (_) {}
    return out;
  }

  void _track(String name, Map<String, dynamic> props) {
    try {
      for (final entry in props.entries) {
        final key = '${name}_${entry.key}';
        final value = entry.value?.toString() ?? '';
        Clarity.setCustomTag(key, value);
      }
      Clarity.sendCustomEvent(name);
    } catch (_) {}
  }

  Future<void> _appendToList(String key, String value) async {
    final list = await _getList(key);
    if (!list.contains(value)) list.add(value);
    await storageInstance.setData(key: key, value: jsonEncode(list));
  }

  Future<List<String>> _getList(String key) async {
    final raw = await storageInstance.getData(key: key);
    if (raw == null || raw.isEmpty) return <String>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.map((e) => e.toString()).toList();
      }
    } catch (_) {}
    return <String>[];
  }
}
