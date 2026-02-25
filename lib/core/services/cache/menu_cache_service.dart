import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../model/inventory_model.dart';

// Top-level functions for compute isolate
List<InventoryItem> _parseMenuItems(String jsonString) {
  final menuItemsList = jsonDecode(jsonString) as List;
  return menuItemsList.map((json) => InventoryItem.fromJson(json)).toList();
}

List<PosActiveCategory> _parseCategories(String jsonString) {
  final categoriesList = jsonDecode(jsonString) as List;
  return categoriesList
      .map((json) => PosActiveCategory.fromJson(json))
      .toList();
}

class MenuCacheService {
  static final MenuCacheService _instance = MenuCacheService._internal();
  factory MenuCacheService() => _instance;
  MenuCacheService._internal();

  List<InventoryItem>? _cachedMenuItems;
  List<PosActiveCategory>? _cachedCategories;
  DateTime? _lastFetchTime;
  bool _isInitialized = false;

  // Cache duration: 3 days (menu doesn't change frequently)
  static const Duration _cacheDuration = Duration(days: 3);

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

      // Load data even if expired (will be refreshed in background)
      // This provides instant UI display
      final menuItemsJson = prefs.getString(_menuItemsKey);
      final categoriesJson = prefs.getString(_categoriesKey);

      if (menuItemsJson != null && categoriesJson != null) {
        // Parse JSON in parallel using compute for better performance
        final results = await Future.wait([
          compute(_parseMenuItems, menuItemsJson),
          compute(_parseCategories, categoriesJson),
        ]);

        _cachedMenuItems = results[0] as List<InventoryItem>;
        _cachedCategories = results[1] as List<PosActiveCategory>;

        final duration = DateTime.now().difference(startTime);
        print(
          '✅ [CACHE] Loaded from persistent storage in ${duration.inMilliseconds}ms',
        );
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

  void cacheData(
    List<InventoryItem> menuItems,
    List<PosActiveCategory> categories,
  ) {
    _cachedMenuItems = menuItems;
    _cachedCategories = categories;
    _lastFetchTime = DateTime.now();
    print(
      '✅ Cached ${menuItems.length} menu items and ${categories.length} categories',
    );

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
        await prefs.setString(
          _lastFetchTimeKey,
          _lastFetchTime!.toIso8601String(),
        );
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

    print(
      '✅ Returning cached data (${_cachedMenuItems!.length} items, ${_cachedCategories!.length} categories)',
    );
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
      print(
        '⚠️ Returning expired cache data (${_cachedMenuItems!.length} items, ${_cachedCategories!.length} categories)',
      );
    } else {
      print(
        '✅ Returning valid cached data (${_cachedMenuItems!.length} items, ${_cachedCategories!.length} categories)',
      );
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

  /// Preload menu data in background (call after app launch/login)
  /// This fetches fresh data and caches it for 3 days
  Future<void> preloadMenuData(Function getInventoryMenu, Function getPosCategories) async {
    print('🔧 [CACHE PRELOAD] preloadMenuData() method called');
    try {
      print('🔧 [CACHE PRELOAD] Initializing cache...');
      // Initialize cache first to load any existing data
      await initialize();
      print('🔧 [CACHE PRELOAD] Cache initialized. isCacheValid: $isCacheValid');
      
      // If cache is still valid, no need to fetch
      if (isCacheValid) {
        print('✅ [CACHE PRELOAD] Cache is still valid, skipping preload');
        return;
      }
      
      print('🔄 [CACHE PRELOAD] Cache expired or invalid - starting background fetch...');
      final startTime = DateTime.now();
      
      print('📡 [CACHE PRELOAD] Calling API methods...');
      // Fetch fresh data in parallel
      final results = await Future.wait([
        getInventoryMenu(),
        getPosCategories(),
      ] as Iterable<Future<dynamic>>);
      
      final items = results[0] as List<InventoryItem>;
      final categories = results[1] as List<PosActiveCategory>;
      
      // Cache the fresh data
      cacheData(items, categories);
      
      final duration = DateTime.now().difference(startTime);
      print('✅ [CACHE PRELOAD] Completed in ${duration.inMilliseconds}ms');
      print('   - Cached ${items.length} items and ${categories.length} categories');
      print('   - Cache valid for 3 days');
    } catch (e) {
      print('❌ [CACHE PRELOAD] Error: $e');
      // Don\'t throw - preload failure shouldn\'t break the app
    }
  }
}

class MenuCacheData {
  final List<InventoryItem> menuItems;
  final List<PosActiveCategory> categories;

  MenuCacheData({required this.menuItems, required this.categories});
}
