import '../../model/inventory_model.dart';

class MenuCacheService {
  static final MenuCacheService _instance = MenuCacheService._internal();
  factory MenuCacheService() => _instance;
  MenuCacheService._internal();

  List<InventoryItem>? _cachedMenuItems;
  List<PosActiveCategory>? _cachedCategories;
  DateTime? _lastFetchTime;
  
  // Cache duration: 5 minutes
  static const Duration _cacheDuration = Duration(minutes: 5);

  bool get isCacheValid {
    if (_lastFetchTime == null) return false;
    return DateTime.now().difference(_lastFetchTime!) < _cacheDuration;
  }

  bool get hasCache {
    return _cachedMenuItems != null && _cachedCategories != null;
  }

  void cacheData(List<InventoryItem> menuItems, List<PosActiveCategory> categories) {
    _cachedMenuItems = menuItems;
    _cachedCategories = categories;
    _lastFetchTime = DateTime.now();
    print('✅ Cached ${menuItems.length} menu items and ${categories.length} categories');
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

  void clearCache() {
    _cachedMenuItems = null;
    _cachedCategories = null;
    _lastFetchTime = null;
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
