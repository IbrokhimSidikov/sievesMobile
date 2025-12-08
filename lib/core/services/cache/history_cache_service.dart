import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class HistoryCacheService {
  static const String _historyCacheKey = 'history_records_';
  static const String _historyTimestampKey = 'history_timestamp_';
  static const Duration _cacheExpiration = Duration(hours: 1);

  String _getHistoryCacheKey(int employeeId) {
    return '$_historyCacheKey$employeeId';
  }

  String _getHistoryTimestampKey(int employeeId) {
    return '$_historyTimestampKey$employeeId';
  }

  Future<bool> _isCacheValid(String timestampKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(timestampKey);

      if (timestamp == null) return false;

      final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final now = DateTime.now();
      final difference = now.difference(cacheTime);

      return difference < _cacheExpiration;
    } catch (e) {
      print('❌ Error checking cache validity: $e');
      return false;
    }
  }

  Future<void> cacheHistoryRecords(
    int employeeId,
    List<Map<String, dynamic>> records,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _getHistoryCacheKey(employeeId);
      final timestampKey = _getHistoryTimestampKey(employeeId);

      final jsonString = jsonEncode(records);

      await prefs.setString(cacheKey, jsonString);
      await prefs.setInt(timestampKey, DateTime.now().millisecondsSinceEpoch);

      print('✅ Cached ${records.length} history records for employee $employeeId');
    } catch (e) {
      print('❌ Error caching history records: $e');
    }
  }

  Future<List<Map<String, dynamic>>?> getCachedHistoryRecords(int employeeId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _getHistoryCacheKey(employeeId);
      final timestampKey = _getHistoryTimestampKey(employeeId);

      final isValid = await _isCacheValid(timestampKey);
      if (!isValid) {
        print('⚠️ History cache expired or invalid for employee $employeeId');
        return null;
      }

      final jsonString = prefs.getString(cacheKey);
      if (jsonString == null) {
        print('⚠️ No cached history records found for employee $employeeId');
        return null;
      }

      final List<dynamic> recordsJson = jsonDecode(jsonString);
      final records = recordsJson.cast<Map<String, dynamic>>();

      print('✅ Retrieved ${records.length} history records from cache');
      return records;
    } catch (e) {
      print('❌ Error retrieving cached history records: $e');
      return null;
    }
  }

  Future<void> clearHistoryCache(int employeeId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _getHistoryCacheKey(employeeId);
      final timestampKey = _getHistoryTimestampKey(employeeId);

      await prefs.remove(cacheKey);
      await prefs.remove(timestampKey);

      print('✅ Cleared history cache for employee $employeeId');
    } catch (e) {
      print('❌ Error clearing history cache: $e');
    }
  }

  Future<void> clearAllHistoryCaches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();

      for (final key in keys) {
        if (key.startsWith(_historyCacheKey) ||
            key.startsWith(_historyTimestampKey)) {
          await prefs.remove(key);
        }
      }

      print('✅ Cleared all history caches');
    } catch (e) {
      print('❌ Error clearing all history caches: $e');
    }
  }

  Future<Map<String, dynamic>> getCacheStats(int employeeId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestampKey = _getHistoryTimestampKey(employeeId);
      final cacheKey = _getHistoryCacheKey(employeeId);
      final timestamp = prefs.getInt(timestampKey);
      final hasCache = prefs.containsKey(cacheKey);

      return {
        'has_cache': hasCache,
        'cache_timestamp': timestamp != null 
            ? DateTime.fromMillisecondsSinceEpoch(timestamp).toIso8601String()
            : null,
        'cache_expiration_hours': _cacheExpiration.inHours,
      };
    } catch (e) {
      print('❌ Error getting cache stats: $e');
      return {};
    }
  }
}
