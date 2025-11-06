import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  static final LocalStorageService _instance = LocalStorageService._internal();

  factory LocalStorageService() => _instance;

  LocalStorageService._internal();

  Future<SharedPreferences> get _prefs async =>
      await SharedPreferences.getInstance();

  Future<String?> getData({required String key}) async {
    try {
      final prefs = await _prefs;
      return prefs.getString(key);
    } catch (e) {
      return null;
    }
  }

  Future<bool> setData({required String key, required String value}) async {
    try {
      final prefs = await _prefs;
      return await prefs.setString(key, value);
    } catch (e) {
      return false;
    }
  }

  Future<bool> removeData({required String key}) async {
    try {
      final prefs = await _prefs;
      return await prefs.remove(key);
    } catch (e) {
      return false;
    }
  }

  Future<bool> clearAll() async {
    try {
      final prefs = await _prefs;
      return await prefs.clear();
    } catch (e) {
      return false;
    }
  }

  Future<bool> saveToken(String token) async {
    try {
      final prefs = await _prefs;
      return await prefs.setString(
        'accessToken',
        token,
      );
    } catch (e) {
      return false;
    }
  }

  Future<bool> saveUserProfile({
    String? id,
    String? email,
    String? name,
    String? username,
  }) async {
    try {
      final prefs = await _prefs;
      if (id != null) await prefs.setString('userId', id);
      if (email != null) await prefs.setString('userEmail', email);
      if (name != null) await prefs.setString('userName', name);
      if (username != null) await prefs.setString('userUsername', username);
      return true;
    } catch (e) {
      return false;
    }
  }

  //  Compatibility helpers
  Future<String?> getFromStore({required String key}) async {
    return await getData(key: key);
  }

  Future<bool> saveToStore({required String key, required String value}) async {
    return await setData(key: key, value: value);
  }



}
// Singleton Instance Getter
LocalStorageService get storageInstance => LocalStorageService();