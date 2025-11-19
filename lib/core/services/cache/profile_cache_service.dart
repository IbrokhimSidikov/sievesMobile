import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for caching profile data to reduce API calls
class ProfileCacheService {
  static const String _profileCacheKey = 'profile_data_';
  static const String _profileTimestampKey = 'profile_timestamp_';
  static const String _prePaidCacheKey = 'prepaid_data_';
  static const String _prePaidTimestampKey = 'prepaid_timestamp_';
  static const String _vacationCacheKey = 'vacation_data_';
  static const String _vacationTimestampKey = 'vacation_timestamp_';
  static const String _bonusCacheKey = 'bonus_data_';
  static const String _bonusTimestampKey = 'bonus_timestamp_';
  static const Duration _cacheExpiration = Duration(hours: 1); // Cache expires after 1 hour

  /// Generate cache key for profile data
  String _getProfileCacheKey(int employeeId) {
    return '$_profileCacheKey$employeeId';
  }

  /// Generate timestamp key for profile cache
  String _getProfileTimestampKey(int employeeId) {
    return '$_profileTimestampKey$employeeId';
  }

  /// Generate cache key for pre-paid data
  String _getPrePaidCacheKey(int individualId) {
    return '$_prePaidCacheKey$individualId';
  }

  /// Generate timestamp key for pre-paid cache
  String _getPrePaidTimestampKey(int individualId) {
    return '$_prePaidTimestampKey$individualId';
  }

  /// Generate cache key for vacation data
  String _getVacationCacheKey(int employeeId) {
    return '$_vacationCacheKey$employeeId';
  }

  /// Generate timestamp key for vacation cache
  String _getVacationTimestampKey(int employeeId) {
    return '$_vacationTimestampKey$employeeId';
  }

  /// Generate cache key for bonus data
  String _getBonusCacheKey(int employeeId) {
    return '$_bonusCacheKey$employeeId';
  }

  /// Generate timestamp key for bonus cache
  String _getBonusTimestampKey(int employeeId) {
    return '$_bonusTimestampKey$employeeId';
  }

  /// Check if cached data exists and is still valid
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

  // ============ Profile Data Caching ============

  /// Save profile data to cache
  Future<void> cacheProfileData(
    int employeeId,
    Map<String, dynamic> profileData,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _getProfileCacheKey(employeeId);
      final timestampKey = _getProfileTimestampKey(employeeId);

      final jsonString = jsonEncode(profileData);

      await prefs.setString(cacheKey, jsonString);
      await prefs.setInt(timestampKey, DateTime.now().millisecondsSinceEpoch);

      print('✅ Cached profile data for employee $employeeId');
    } catch (e) {
      print('❌ Error caching profile data: $e');
    }
  }

  /// Retrieve profile data from cache
  Future<Map<String, dynamic>?> getCachedProfileData(int employeeId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _getProfileCacheKey(employeeId);
      final timestampKey = _getProfileTimestampKey(employeeId);

      // Check if cache is valid
      final isValid = await _isCacheValid(timestampKey);
      if (!isValid) {
        print('⚠️ Profile cache expired or invalid for employee $employeeId');
        return null;
      }

      // Retrieve from cache
      final jsonString = prefs.getString(cacheKey);
      if (jsonString == null) {
        print('⚠️ No cached profile data found for employee $employeeId');
        return null;
      }

      // Parse JSON
      final profileData = jsonDecode(jsonString) as Map<String, dynamic>;

      print('✅ Retrieved profile data from cache');
      return profileData;
    } catch (e) {
      print('❌ Error retrieving cached profile data: $e');
      return null;
    }
  }

  /// Clear profile cache for a specific employee
  Future<void> clearProfileCache(int employeeId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _getProfileCacheKey(employeeId);
      final timestampKey = _getProfileTimestampKey(employeeId);

      await prefs.remove(cacheKey);
      await prefs.remove(timestampKey);

      print('✅ Cleared profile cache for employee $employeeId');
    } catch (e) {
      print('❌ Error clearing profile cache: $e');
    }
  }

  // ============ Pre-Paid Data Caching ============

  /// Save pre-paid data to cache
  Future<void> cachePrePaidData(
    int individualId,
    double amount,
    List<Map<String, dynamic>> transactions,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _getPrePaidCacheKey(individualId);
      final timestampKey = _getPrePaidTimestampKey(individualId);

      final data = {
        'amount': amount,
        'transactions': transactions,
      };

      final jsonString = jsonEncode(data);

      await prefs.setString(cacheKey, jsonString);
      await prefs.setInt(timestampKey, DateTime.now().millisecondsSinceEpoch);

      print('✅ Cached pre-paid data for individual $individualId');
    } catch (e) {
      print('❌ Error caching pre-paid data: $e');
    }
  }

  /// Retrieve pre-paid data from cache
  Future<Map<String, dynamic>?> getCachedPrePaidData(int individualId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _getPrePaidCacheKey(individualId);
      final timestampKey = _getPrePaidTimestampKey(individualId);

      // Check if cache is valid
      final isValid = await _isCacheValid(timestampKey);
      if (!isValid) {
        print('⚠️ Pre-paid cache expired or invalid for individual $individualId');
        return null;
      }

      // Retrieve from cache
      final jsonString = prefs.getString(cacheKey);
      if (jsonString == null) {
        print('⚠️ No cached pre-paid data found for individual $individualId');
        return null;
      }

      // Parse JSON
      final data = jsonDecode(jsonString) as Map<String, dynamic>;

      print('✅ Retrieved pre-paid data from cache');
      return data;
    } catch (e) {
      print('❌ Error retrieving cached pre-paid data: $e');
      return null;
    }
  }

  /// Clear pre-paid cache for a specific individual
  Future<void> clearPrePaidCache(int individualId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _getPrePaidCacheKey(individualId);
      final timestampKey = _getPrePaidTimestampKey(individualId);

      await prefs.remove(cacheKey);
      await prefs.remove(timestampKey);

      print('✅ Cleared pre-paid cache for individual $individualId');
    } catch (e) {
      print('❌ Error clearing pre-paid cache: $e');
    }
  }

  // ============ Vacation Data Caching ============

  /// Save vacation data to cache
  Future<void> cacheVacationData(
    int employeeId,
    int availableDays,
    int totalDays,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _getVacationCacheKey(employeeId);
      final timestampKey = _getVacationTimestampKey(employeeId);

      final data = {
        'availableDays': availableDays,
        'totalDays': totalDays,
      };

      final jsonString = jsonEncode(data);

      await prefs.setString(cacheKey, jsonString);
      await prefs.setInt(timestampKey, DateTime.now().millisecondsSinceEpoch);

      print('✅ Cached vacation data for employee $employeeId');
    } catch (e) {
      print('❌ Error caching vacation data: $e');
    }
  }

  /// Retrieve vacation data from cache
  Future<Map<String, dynamic>?> getCachedVacationData(int employeeId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _getVacationCacheKey(employeeId);
      final timestampKey = _getVacationTimestampKey(employeeId);

      // Check if cache is valid
      final isValid = await _isCacheValid(timestampKey);
      if (!isValid) {
        print('⚠️ Vacation cache expired or invalid for employee $employeeId');
        return null;
      }

      // Retrieve from cache
      final jsonString = prefs.getString(cacheKey);
      if (jsonString == null) {
        print('⚠️ No cached vacation data found for employee $employeeId');
        return null;
      }

      // Parse JSON
      final data = jsonDecode(jsonString) as Map<String, dynamic>;

      print('✅ Retrieved vacation data from cache');
      return data;
    } catch (e) {
      print('❌ Error retrieving cached vacation data: $e');
      return null;
    }
  }

  /// Clear vacation cache for a specific employee
  Future<void> clearVacationCache(int employeeId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _getVacationCacheKey(employeeId);
      final timestampKey = _getVacationTimestampKey(employeeId);

      await prefs.remove(cacheKey);
      await prefs.remove(timestampKey);

      print('✅ Cleared vacation cache for employee $employeeId');
    } catch (e) {
      print('❌ Error clearing vacation cache: $e');
    }
  }

  // ============ Bonus Data Caching ============

  /// Save bonus data to cache
  Future<void> cacheBonusData(
    int employeeId,
    double amount,
    String month,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _getBonusCacheKey(employeeId);
      final timestampKey = _getBonusTimestampKey(employeeId);

      final data = {
        'amount': amount,
        'month': month,
      };

      final jsonString = jsonEncode(data);

      await prefs.setString(cacheKey, jsonString);
      await prefs.setInt(timestampKey, DateTime.now().millisecondsSinceEpoch);

      print('✅ Cached bonus data for employee $employeeId');
    } catch (e) {
      print('❌ Error caching bonus data: $e');
    }
  }

  /// Retrieve bonus data from cache
  Future<Map<String, dynamic>?> getCachedBonusData(int employeeId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _getBonusCacheKey(employeeId);
      final timestampKey = _getBonusTimestampKey(employeeId);

      // Check if cache is valid
      final isValid = await _isCacheValid(timestampKey);
      if (!isValid) {
        print('⚠️ Bonus cache expired or invalid for employee $employeeId');
        return null;
      }

      // Retrieve from cache
      final jsonString = prefs.getString(cacheKey);
      if (jsonString == null) {
        print('⚠️ No cached bonus data found for employee $employeeId');
        return null;
      }

      // Parse JSON
      final data = jsonDecode(jsonString) as Map<String, dynamic>;

      print('✅ Retrieved bonus data from cache');
      return data;
    } catch (e) {
      print('❌ Error retrieving cached bonus data: $e');
      return null;
    }
  }

  /// Clear bonus cache for a specific employee
  Future<void> clearBonusCache(int employeeId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _getBonusCacheKey(employeeId);
      final timestampKey = _getBonusTimestampKey(employeeId);

      await prefs.remove(cacheKey);
      await prefs.remove(timestampKey);

      print('✅ Cleared bonus cache for employee $employeeId');
    } catch (e) {
      print('❌ Error clearing bonus cache: $e');
    }
  }

  // ============ Clear All Caches ============

  /// Clear all profile-related caches for a specific user
  Future<void> clearAllCachesForUser(int employeeId, int? individualId) async {
    await clearProfileCache(employeeId);
    await clearVacationCache(employeeId);
    await clearBonusCache(employeeId);
    if (individualId != null) {
      await clearPrePaidCache(individualId);
    }
    print('✅ Cleared all profile caches for employee $employeeId');
  }

  /// Clear all profile caches
  Future<void> clearAllCaches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();

      // Remove all keys that start with our cache prefixes
      for (final key in keys) {
        if (key.startsWith(_profileCacheKey) ||
            key.startsWith(_profileTimestampKey) ||
            key.startsWith(_prePaidCacheKey) ||
            key.startsWith(_prePaidTimestampKey) ||
            key.startsWith(_vacationCacheKey) ||
            key.startsWith(_vacationTimestampKey) ||
            key.startsWith(_bonusCacheKey) ||
            key.startsWith(_bonusTimestampKey)) {
          await prefs.remove(key);
        }
      }

      print('✅ Cleared all profile caches');
    } catch (e) {
      print('❌ Error clearing all caches: $e');
    }
  }

  /// Get cache statistics (for debugging)
  Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();

      int profileCacheCount = 0;
      int prePaidCacheCount = 0;
      int vacationCacheCount = 0;
      int bonusCacheCount = 0;

      for (final key in keys) {
        if (key.startsWith(_profileCacheKey)) profileCacheCount++;
        if (key.startsWith(_prePaidCacheKey)) prePaidCacheCount++;
        if (key.startsWith(_vacationCacheKey)) vacationCacheCount++;
        if (key.startsWith(_bonusCacheKey)) bonusCacheCount++;
      }

      return {
        'profile_caches': profileCacheCount,
        'prepaid_caches': prePaidCacheCount,
        'vacation_caches': vacationCacheCount,
        'bonus_caches': bonusCacheCount,
        'cache_expiration_hours': _cacheExpiration.inHours,
      };
    } catch (e) {
      print('❌ Error getting cache stats: $e');
      return {};
    }
  }
}
