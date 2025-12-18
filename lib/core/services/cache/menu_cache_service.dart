import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../model/inventory_model.dart';

class MenuCacheService {
  static final MenuCacheService _instance = MenuCacheService._internal();
  factory MenuCacheService() => _instance;
  MenuCacheService._internal();

  List<InventoryItem>? _cachedMenuItems;
  List<PosActiveCategory>? _cachedCategories;
  DateTime? _lastFetchTime;
  bool _isInitialized = false;
  
  // Cache duration: 30 minutes (menu doesn't change frequently)
  static const Duration _cacheDuration = Duration(minutes: 30);
  
  // Storage keys
  static const String _menuItemsKey = 'cached_menu_items';
  static const String _categoriesKey = 'cached_categories';
  static const String _lastFetchTimeKey = 'cached_last_fetch_time';

  bool get isCacheValid {
    if (_lastFetchTime == null) return false;
    return DateTime.now().difference(_lastFetchTime!) < _cacheDuration;
  }

  bool get hasCache {
    return _cachedMenuItems != null && _cachedCategories != null;
  }

  // Initialize cache from persistent storage
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    final startTime = DateTime.now();
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load last fetch time
      final lastFetchTimeStr = prefs.getString(_lastFetchTimeKey);
      if (lastFetchTimeStr != null) {
        _lastFetchTime = DateTime.tryParse(lastFetchTimeStr);
      }
      
      // Check if cache is still valid before loading data
      if (_lastFetchTime != null && isCacheValid) {
        // Load menu items
        final menuItemsJson = prefs.getString(_menuItemsKey);
        if (menuItemsJson != null) {
          final menuItemsList = jsonDecode(menuItemsJson) as List;
          _cachedMenuItems = menuItemsList
              .map((json) => InventoryItem.fromJson(json))
              .toList();
        }
        
        // Load categories
        final categoriesJson = prefs.getString(_categoriesKey);
        if (categoriesJson != null) {
          final categoriesList = jsonDecode(categoriesJson) as List;
          _cachedCategories = categoriesList
              .map((json) => PosActiveCategory.fromJson(json))
              .toList();
        }
        
        final duration = DateTime.now().difference(startTime);
        print('✅ [CACHE] Loaded from persistent storage in ${duration.inMilliseconds}ms');
        print('   - ${_cachedMenuItems?.length ?? 0} menu items');
        print('   - ${_cachedCategories?.length ?? 0} categories');
      } else {
        print('📦 [CACHE] Persistent cache expired or empty');
      }
    } catch (e) {
      print('❌ [CACHE] Error loading from persistent storage: $e');
    }
    
    _isInitialized = true;
  }

  void cacheData(List<InventoryItem> menuItems, List<PosActiveCategory> categories) {
    _cachedMenuItems = menuItems;
    _cachedCategories = categories;
    _lastFetchTime = DateTime.now();
    print('✅ Cached ${menuItems.length} menu items and ${categories.length} categories');
    
    // Save to persistent storage asynchronously
    _saveToPersistentStorage();
  }
  
  Future<void> _saveToPersistentStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Save menu items
      if (_cachedMenuItems != null) {
        final menuItemsJson = jsonEncode(
          _cachedMenuItems!.map((item) => item.toJson()).toList(),
        );
        await prefs.setString(_menuItemsKey, menuItemsJson);
      }
      
      // Save categories
      if (_cachedCategories != null) {
        final categoriesJson = jsonEncode(
          _cachedCategories!.map((cat) => cat.toJson()).toList(),
        );
        await prefs.setString(_categoriesKey, categoriesJson);
      }
      
      // Save last fetch time
      if (_lastFetchTime != null) {
        await prefs.setString(_lastFetchTimeKey, _lastFetchTime!.toIso8601String());
      }
      
      print('💾 [CACHE] Saved to persistent storage');
    } catch (e) {
      print('❌ [CACHE] Error saving to persistent storage: $e');
    }
  }

  MenuCacheData? getCachedData() {
    if (!hasCache || !isCacheValid) {
      print('❌ Cache invalid or expired');
      return null;
    }
    
    print('✅ Returning cached data (${_cachedMenuItems!.length} items, ${_cachedCategories!.length} categories)');
    return MenuCacheData(
      menuItems: _cachedMenuItems!,
      categories: _cachedCategories!,
    );
  }

  MenuCacheData? getCachedDataEvenIfExpired() {
    if (!hasCache) {
      print('❌ No cache available');
      return null;
    }
    
    if (!isCacheValid) {
      print('⚠️ Returning expired cache data (${_cachedMenuItems!.length} items, ${_cachedCategories!.length} categories)');
    } else {
      print('✅ Returning valid cached data (${_cachedMenuItems!.length} items, ${_cachedCategories!.length} categories)');
    }
    
    return MenuCacheData(
      menuItems: _cachedMenuItems!,
      categories: _cachedCategories!,
    );
  }

  Future<void> clearCache() async {
    _cachedMenuItems = null;
    _cachedCategories = null;
    _lastFetchTime = null;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_menuItemsKey);
      await prefs.remove(_categoriesKey);
      await prefs.remove(_lastFetchTimeKey);
    } catch (e) {
      print('❌ [CACHE] Error clearing persistent storage: $e');
    }
    
    print('🗑️ Cache cleared');
  }
}

class MenuCacheData {
  final List<InventoryItem> menuItems;
  final List<PosActiveCategory> categories;

  MenuCacheData({
    required this.menuItems,
    required this.categories,
  });
}
