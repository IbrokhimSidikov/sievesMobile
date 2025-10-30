import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../model/work_entry_model.dart';

/// Service for caching work entries to reduce API calls
class WorkEntryCacheService {
  static const String _cachePrefix = 'work_entries_';
  static const String _cacheTimestampPrefix = 'work_entries_timestamp_';
  static const Duration _cacheExpiration = Duration(hours: 1); // Cache expires after 1 hour

  /// Generate cache key for a specific employee and date range
  String _getCacheKey(int employeeId, String startDate, String endDate) {
    return '$_cachePrefix${employeeId}_${startDate}_$endDate';
  }

  /// Generate timestamp key for a specific cache entry
  String _getTimestampKey(int employeeId, String startDate, String endDate) {
    return '$_cacheTimestampPrefix${employeeId}_${startDate}_$endDate';
  }

  /// Check if cached data exists and is still valid
  Future<bool> isCacheValid(int employeeId, String startDate, String endDate) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestampKey = _getTimestampKey(employeeId, startDate, endDate);
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

  /// Save work entries to cache
  Future<void> cacheWorkEntries(
    int employeeId,
    String startDate,
    String endDate,
    List<WorkEntry> entries,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _getCacheKey(employeeId, startDate, endDate);
      final timestampKey = _getTimestampKey(employeeId, startDate, endDate);

      // Convert entries to JSON
      final jsonList = entries.map((entry) => entry.toJson()).toList();
      final jsonString = jsonEncode(jsonList);

      // Save to cache
      await prefs.setString(cacheKey, jsonString);
      await prefs.setInt(timestampKey, DateTime.now().millisecondsSinceEpoch);

      print('✅ Cached ${entries.length} work entries for employee $employeeId');
    } catch (e) {
      print('❌ Error caching work entries: $e');
    }
  }

  /// Retrieve work entries from cache
  Future<List<WorkEntry>?> getCachedWorkEntries(
    int employeeId,
    String startDate,
    String endDate,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _getCacheKey(employeeId, startDate, endDate);

      // Check if cache is valid
      final isValid = await isCacheValid(employeeId, startDate, endDate);
      if (!isValid) {
        print('⚠️ Cache expired or invalid for employee $employeeId');
        return null;
      }

      // Retrieve from cache
      final jsonString = prefs.getString(cacheKey);
      if (jsonString == null) {
        print('⚠️ No cached data found for employee $employeeId');
        return null;
      }

      // Parse JSON
      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      final entries = jsonList.map((json) => WorkEntry.fromJson(json)).toList();

      print('✅ Retrieved ${entries.length} work entries from cache');
      return entries;
    } catch (e) {
      print('❌ Error retrieving cached work entries: $e');
      return null;
    }
  }

  /// Clear cache for a specific employee and date range
  Future<void> clearCache(int employeeId, String startDate, String endDate) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _getCacheKey(employeeId, startDate, endDate);
      final timestampKey = _getTimestampKey(employeeId, startDate, endDate);

      await prefs.remove(cacheKey);
      await prefs.remove(timestampKey);

      print('✅ Cleared cache for employee $employeeId');
    } catch (e) {
      print('❌ Error clearing cache: $e');
    }
  }

  /// Clear all work entry caches
  Future<void> clearAllCaches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();

      // Remove all keys that start with our cache prefix
      for (final key in keys) {
        if (key.startsWith(_cachePrefix) || key.startsWith(_cacheTimestampPrefix)) {
          await prefs.remove(key);
        }
      }

      print('✅ Cleared all work entry caches');
    } catch (e) {
      print('❌ Error clearing all caches: $e');
    }
  }

  /// Get cache statistics (for debugging)
  Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();

      int cacheCount = 0;
      int validCacheCount = 0;
      int expiredCacheCount = 0;

      for (final key in keys) {
        if (key.startsWith(_cachePrefix)) {
          cacheCount++;

          // Check if this cache is still valid
          final timestampKey = key.replaceFirst(_cachePrefix, _cacheTimestampPrefix);
          final timestamp = prefs.getInt(timestampKey);

          if (timestamp != null) {
            final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
            final now = DateTime.now();
            final difference = now.difference(cacheTime);

            if (difference < _cacheExpiration) {
              validCacheCount++;
            } else {
              expiredCacheCount++;
            }
          }
        }
      }

      return {
        'total_caches': cacheCount,
        'valid_caches': validCacheCount,
        'expired_caches': expiredCacheCount,
        'cache_expiration_hours': _cacheExpiration.inHours,
      };
    } catch (e) {
      print('❌ Error getting cache stats: $e');
      return {};
    }
  }
}
