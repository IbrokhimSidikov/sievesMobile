import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../model/break_order_model.dart';

/// Service for caching break records data to reduce API calls
class BreakRecordsCacheService {
  static const String _breakOrdersCacheKey = 'break_orders_';
  static const String _breakOrdersTimestampKey = 'break_orders_timestamp_';
  static const String _breakBalanceCacheKey = 'break_balance_';
  static const String _breakBalanceTimestampKey = 'break_balance_timestamp_';
  static const Duration _cacheExpiration = Duration(hours: 1); // Cache expires after 1 hour

  /// Generate cache key for break orders
  String _getBreakOrdersCacheKey(int employeeId) {
    return '$_breakOrdersCacheKey$employeeId';
  }

  /// Generate timestamp key for break orders cache
  String _getBreakOrdersTimestampKey(int employeeId) {
    return '$_breakOrdersTimestampKey$employeeId';
  }

  /// Generate cache key for break balance
  String _getBreakBalanceCacheKey(int employeeId) {
    return '$_breakBalanceCacheKey$employeeId';
  }

  /// Generate timestamp key for break balance cache
  String _getBreakBalanceTimestampKey(int employeeId) {
    return '$_breakBalanceTimestampKey$employeeId';
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

  // ============ Break Orders Caching ============

  /// Save break orders to cache
  Future<void> cacheBreakOrders(
    int employeeId,
    List<BreakOrder> orders,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _getBreakOrdersCacheKey(employeeId);
      final timestampKey = _getBreakOrdersTimestampKey(employeeId);

      // Convert orders to JSON
      final jsonList = orders.map((order) => order.toJson()).toList();
      final jsonString = jsonEncode(jsonList);

      await prefs.setString(cacheKey, jsonString);
      await prefs.setInt(timestampKey, DateTime.now().millisecondsSinceEpoch);

      print('✅ Cached ${orders.length} break orders for employee $employeeId');
    } catch (e) {
      print('❌ Error caching break orders: $e');
    }
  }

  /// Retrieve break orders from cache
  Future<List<BreakOrder>?> getCachedBreakOrders(int employeeId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _getBreakOrdersCacheKey(employeeId);
      final timestampKey = _getBreakOrdersTimestampKey(employeeId);

      // Check if cache is valid
      final isValid = await _isCacheValid(timestampKey);
      if (!isValid) {
        print('⚠️ Break orders cache expired or invalid for employee $employeeId');
        return null;
      }

      // Retrieve from cache
      final jsonString = prefs.getString(cacheKey);
      if (jsonString == null) {
        print('⚠️ No cached break orders found for employee $employeeId');
        return null;
      }

      // Parse JSON
      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      final orders = jsonList.map((json) => BreakOrder.fromJson(json)).toList();

      print('✅ Retrieved ${orders.length} break orders from cache');
      return orders;
    } catch (e) {
      print('❌ Error retrieving cached break orders: $e');
      return null;
    }
  }

  /// Clear break orders cache for a specific employee
  Future<void> clearBreakOrdersCache(int employeeId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _getBreakOrdersCacheKey(employeeId);
      final timestampKey = _getBreakOrdersTimestampKey(employeeId);

      await prefs.remove(cacheKey);
      await prefs.remove(timestampKey);

      print('✅ Cleared break orders cache for employee $employeeId');
    } catch (e) {
      print('❌ Error clearing break orders cache: $e');
    }
  }

  // ============ Break Balance Caching ============

  /// Save break balance to cache
  Future<void> cacheBreakBalance(
    int employeeId,
    double balance,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _getBreakBalanceCacheKey(employeeId);
      final timestampKey = _getBreakBalanceTimestampKey(employeeId);

      await prefs.setDouble(cacheKey, balance);
      await prefs.setInt(timestampKey, DateTime.now().millisecondsSinceEpoch);

      print('✅ Cached break balance for employee $employeeId: $balance');
    } catch (e) {
      print('❌ Error caching break balance: $e');
    }
  }

  /// Retrieve break balance from cache
  Future<double?> getCachedBreakBalance(int employeeId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _getBreakBalanceCacheKey(employeeId);
      final timestampKey = _getBreakBalanceTimestampKey(employeeId);

      // Check if cache is valid
      final isValid = await _isCacheValid(timestampKey);
      if (!isValid) {
        print('⚠️ Break balance cache expired or invalid for employee $employeeId');
        return null;
      }

      // Retrieve from cache
      final balance = prefs.getDouble(cacheKey);
      if (balance == null) {
        print('⚠️ No cached break balance found for employee $employeeId');
        return null;
      }

      print('✅ Retrieved break balance from cache: $balance');
      return balance;
    } catch (e) {
      print('❌ Error retrieving cached break balance: $e');
      return null;
    }
  }

  /// Clear break balance cache for a specific employee
  Future<void> clearBreakBalanceCache(int employeeId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _getBreakBalanceCacheKey(employeeId);
      final timestampKey = _getBreakBalanceTimestampKey(employeeId);

      await prefs.remove(cacheKey);
      await prefs.remove(timestampKey);

      print('✅ Cleared break balance cache for employee $employeeId');
    } catch (e) {
      print('❌ Error clearing break balance cache: $e');
    }
  }

  // ============ Clear All Caches ============

  /// Clear all break-related caches for a specific employee
  Future<void> clearAllCachesForEmployee(int employeeId) async {
    await clearBreakOrdersCache(employeeId);
    await clearBreakBalanceCache(employeeId);
    print('✅ Cleared all break records caches for employee $employeeId');
  }

  /// Clear all break records caches
  Future<void> clearAllCaches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();

      // Remove all keys that start with our cache prefixes
      for (final key in keys) {
        if (key.startsWith(_breakOrdersCacheKey) ||
            key.startsWith(_breakOrdersTimestampKey) ||
            key.startsWith(_breakBalanceCacheKey) ||
            key.startsWith(_breakBalanceTimestampKey)) {
          await prefs.remove(key);
        }
      }

      print('✅ Cleared all break records caches');
    } catch (e) {
      print('❌ Error clearing all caches: $e');
    }
  }

  /// Get cache statistics (for debugging)
  Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();

      int ordersCacheCount = 0;
      int balanceCacheCount = 0;

      for (final key in keys) {
        if (key.startsWith(_breakOrdersCacheKey)) ordersCacheCount++;
        if (key.startsWith(_breakBalanceCacheKey)) balanceCacheCount++;
      }

      return {
        'orders_caches': ordersCacheCount,
        'balance_caches': balanceCacheCount,
        'cache_expiration_hours': _cacheExpiration.inHours,
      };
    } catch (e) {
      print('❌ Error getting cache stats: $e');
      return {};
    }
  }
}
