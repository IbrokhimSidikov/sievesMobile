import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LmsCacheService {
  static const String _coursesCacheKey = 'lms_courses_data';
  static const String _coursesTimestampKey = 'lms_courses_timestamp';
  static const Duration _cacheExpiration = Duration(hours: 2);

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

  Future<void> cacheCourses(List<Map<String, dynamic>> courses) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(courses);

      await prefs.setString(_coursesCacheKey, jsonString);
      await prefs.setInt(_coursesTimestampKey, DateTime.now().millisecondsSinceEpoch);

      print('✅ Cached ${courses.length} courses');
    } catch (e) {
      print('❌ Error caching courses: $e');
    }
  }

  Future<List<Map<String, dynamic>>?> getCachedCourses() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final isValid = await _isCacheValid(_coursesTimestampKey);
      if (!isValid) {
        print('⚠️ Courses cache expired or invalid');
        return null;
      }

      final jsonString = prefs.getString(_coursesCacheKey);
      if (jsonString == null) {
        print('⚠️ No cached courses data found');
        return null;
      }

      final List<dynamic> coursesJson = jsonDecode(jsonString);
      final courses = coursesJson.cast<Map<String, dynamic>>();

      print('✅ Retrieved ${courses.length} courses from cache');
      return courses;
    } catch (e) {
      print('❌ Error retrieving cached courses: $e');
      return null;
    }
  }

  Future<void> clearCoursesCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_coursesCacheKey);
      await prefs.remove(_coursesTimestampKey);

      print('✅ Cleared courses cache');
    } catch (e) {
      print('❌ Error clearing courses cache: $e');
    }
  }

  Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_coursesTimestampKey);
      final hasCache = prefs.containsKey(_coursesCacheKey);

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
