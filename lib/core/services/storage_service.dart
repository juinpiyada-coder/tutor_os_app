import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _kSessionKey = 'tutor_os_session';
  static const String _kUserKey = 'tutor_os_user';
  static const String _kInstituteKey = 'tutor_os_institute';
  
  // In-memory Session Storage cache (mimics sessionStorage in web)
  static final Map<String, dynamic> _sessionMemoryStore = {};

  /// Save session into both Persistent Storage (localStorage) and In-Memory Cache (sessionStorage)
  static Future<void> saveSession({
    required int tenantId,
    required int userId,
    int? instituteId,
    String? token,
    String? role,
    String? firstName,
    String? lastName,
    String? instituteName,
    String? instituteCode,
  }) async {
    final Map<String, dynamic> sessionData = {
      'tenant_id': tenantId,
      'user_id': userId,
      'institute_id': instituteId,
      'token': token,
      'role': role ?? 'ADMIN',
      'first_name': firstName ?? '',
      'last_name': lastName ?? '',
      'institute_name': instituteName,
      'institute_code': instituteCode,
      'timestamp': DateTime.now().toIso8601String(),
    };

    // 1. Write to Session Storage (In-memory)
    _sessionMemoryStore.addAll(sessionData);

    // 2. Write to Local Storage (SharedPreferences persistent)
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSessionKey, jsonEncode(sessionData));
    if (instituteName != null) {
      await prefs.setString(_kInstituteKey, instituteName);
    }
  }

  /// Load session from Session Storage or Local Storage
  static Future<Map<String, dynamic>?> loadSession() async {
    // Check in-memory session cache first
    if (_sessionMemoryStore.containsKey('tenant_id') && _sessionMemoryStore['tenant_id'] != null) {
      return Map<String, dynamic>.from(_sessionMemoryStore);
    }

    // Fallback to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kSessionKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(raw);
        _sessionMemoryStore.addAll(decoded);
        return decoded;
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  /// Get specific value with session & local storage fallback
  static String getSessionString(String key, {String defaultValue = ''}) {
    if (_sessionMemoryStore.containsKey(key) && _sessionMemoryStore[key] != null) {
      return _sessionMemoryStore[key].toString();
    }
    return defaultValue;
  }

  /// Clear both session storage and local storage
  static Future<void> clearAll() async {
    _sessionMemoryStore.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kSessionKey);
    await prefs.remove(_kUserKey);
    await prefs.remove(_kInstituteKey);
  }
}
