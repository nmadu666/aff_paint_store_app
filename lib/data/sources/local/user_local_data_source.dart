import 'package:shared_preferences/shared_preferences.dart';

class UserLocalDataSource {
  static const String _kiotVietUserIdKey = 'kiotVietUserId';
  static const String _branchIdKey = 'branchId';

  Future<void> saveUserData({
    required String? kiotVietUserId,
    required String? branchId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (kiotVietUserId != null) {
      await prefs.setString(_kiotVietUserIdKey, kiotVietUserId);
    }
    if (branchId != null) {
      await prefs.setString(_branchIdKey, branchId);
    }
  }

  Future<Map<String, String?>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'kiotVietUserId': prefs.getString(_kiotVietUserIdKey),
      'branchId': prefs.getString(_branchIdKey),
    };
  }

  Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kiotVietUserIdKey);
    await prefs.remove(_branchIdKey);
  }
}
