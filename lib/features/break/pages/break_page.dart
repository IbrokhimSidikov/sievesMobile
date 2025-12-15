import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/model/inventory_model.dart';
import '../../../core/services/auth/auth_manager.dart';
import '../../../core/services/cache/menu_cache_service.dart';

class BreakPage extends StatefulWidget {
  const BreakPage({super.key});

  @override
  State<BreakPage> createState() => _BreakPageState();
}

class _BreakPageState extends State<BreakPage> with SingleTickerProviderStateMixin {
  final AuthManager _authManager = AuthManager();
  final MenuCacheService _cacheService = MenuCacheService();
  bool _isLoading = true;
  String? _errorMessage;
  List<InventoryItem> _menuItems = [];
  List<PosActiveCategory> _categories = [];
  int? _selectedCategoryId;
  Map<int, int> _cart = {};
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _shimmerAnimation = Tween<double>(
      begin: 0.3,
      end: 0.7,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOut,
    ));
    
    _fetchMenuItems();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  Future<void> _fetchMenuItems() async {
    final startTime = DateTime.now();
    print('⏱️ [BREAK PAGE] Starting to fetch menu items at ${startTime.toIso8601String()}');
    
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Check cache first
      final cacheCheckStart = DateTime.now();
      final cachedData = _cacheService.getCachedData();
      final cacheCheckDuration = DateTime.now().difference(cacheCheckStart);
      print('⏱️ [BREAK PAGE] Cache check took: ${cacheCheckDuration.inMilliseconds}ms');
      
      if (cachedData != null) {
        print('📦 [BREAK PAGE] Using cached menu data (${cachedData.menuItems.length} items, ${cachedData.categories.length} categories)');
        if (!mounted) return;
        
        final sortStart = DateTime.now();
        // Sort categories alphabetically
        final sortedCategories = List<PosActiveCategory>.from(cachedData.categories)
          ..sort((a, b) => (a.posCategory?.name ?? '').compareTo(b.posCategory?.name ?? ''));
        final sortDuration = DateTime.now().difference(sortStart);
        print('⏱️ [BREAK PAGE] Sorting categories took: ${sortDuration.inMilliseconds}ms');
        
        final setStateStart = DateTime.now();
        setState(() {
          _menuItems = cachedData.menuItems;
          _categories = sortedCategories;
          // Select first category by default
          if (sortedCategories.isNotEmpty) {
            _selectedCategoryId = sortedCategories.first.posCategoryId;
          }
          _isLoading = false;
        });
        final setStateDuration = DateTime.now().difference(setStateStart);
        print('⏱️ [BREAK PAGE] setState took: ${setStateDuration.inMilliseconds}ms');
        
        final totalDuration = DateTime.now().difference(startTime);
        print('✅ [BREAK PAGE] Total load time (from cache): ${totalDuration.inMilliseconds}ms');
        return;
      }
      
      print('🌐 [BREAK PAGE] No cache found, fetching from API...');
      
      // Fetch both menu items and categories in parallel
      final apiStartTime = DateTime.now();
      print('📡 [BREAK PAGE] Starting parallel API calls...');
      final results = await Future.wait([
        _authManager.apiService.getInventoryMenu(),
        _authManager.apiService.getPosCategories(),
      ]);
      final apiDuration = DateTime.now().difference(apiStartTime);
      print('⏱️ [BREAK PAGE] Both API calls completed in: ${apiDuration.inMilliseconds}ms');
      
      if (!mounted) return;
      
      final processingStart = DateTime.now();
      final items = results[0] as List<InventoryItem>;
      final categories = results[1] as List<PosActiveCategory>;
      print('⏱️ [BREAK PAGE] Received ${items.length} items and ${categories.length} categories');
      
      // Sort categories alphabetically
      final sortStart = DateTime.now();
      final sortedCategories = List<PosActiveCategory>.from(categories)
        ..sort((a, b) => (a.posCategory?.name ?? '').compareTo(b.posCategory?.name ?? ''));
      final sortDuration = DateTime.now().difference(sortStart);
      print('⏱️ [BREAK PAGE] Sorting categories took: ${sortDuration.inMilliseconds}ms');
      
      // Cache the data
      final cacheStart = DateTime.now();
      _cacheService.cacheData(items, sortedCategories);
      final cacheDuration = DateTime.now().difference(cacheStart);
      print('⏱️ [BREAK PAGE] Caching data took: ${cacheDuration.inMilliseconds}ms');
      
      final setStateStart = DateTime.now();
      setState(() {
        _menuItems = items;
        _categories = sortedCategories;
        // Select first category by default
        if (sortedCategories.isNotEmpty) {
          _selectedCategoryId = sortedCategories.first.posCategoryId;
        }
        _isLoading = false;
      });
      final setStateDuration = DateTime.now().difference(setStateStart);
      print('⏱️ [BREAK PAGE] setState took: ${setStateDuration.inMilliseconds}ms');
      
      final processingDuration = DateTime.now().difference(processingStart);
      print('⏱️ [BREAK PAGE] Data processing took: ${processingDuration.inMilliseconds}ms');

      final totalDuration = DateTime.now().difference(startTime);
      print('✅ [BREAK PAGE] Total load time (from API): ${totalDuration.inMilliseconds}ms');
      print('   - API calls: ${apiDuration.inMilliseconds}ms (${(apiDuration.inMilliseconds / totalDuration.inMilliseconds * 100).toStringAsFixed(1)}%)');
      print('   - Processing: ${processingDuration.inMilliseconds}ms (${(processingDuration.inMilliseconds / totalDuration.inMilliseconds * 100).toStringAsFixed(1)}%)');
    } catch (e) {
      final totalDuration = DateTime.now().difference(startTime);
      print('❌ [BREAK PAGE] Error after ${totalDuration.inMilliseconds}ms: $e');
      
      if (!mounted) return;
      
      setState(() {
        _errorMessage = 'Failed to load menu. Please try again.';
        _isLoading = false;
      });
    }
  }

  void _addToCart(InventoryItem item) {
    setState(() {
      _cart[item.id] = (_cart[item.id] ?? 0) + 1;
    });
  }

  void _removeFromCart(InventoryItem item) {
    setState(() {
      if (_cart[item.id] != null && _cart[item.id]! > 0) {
        _cart[item.id] = _cart[item.id]! - 1;
        if (_cart[item.id] == 0) {
          _cart.remove(item.id);
        }
      }
    });
  }

  int _getCartTotal() {
    int total = 0;
    for (var item in _menuItems) {
      final quantity = _cart[item.id] ?? 0;
      if (quantity > 0 && item.inventoryPriceList != null) {
        total += item.inventoryPriceList!.price * quantity;
      }
    }
    return total;
  }

  int _getCartItemCount() {
    return _cart.values.fold(0, (sum, quantity) => sum + quantity);
  }

  @override
  Widget build(BuildContext context) {
    final buildStart = DateTime.now();
    print('🎨 [BREAK PAGE] Build started - isLoading: $_isLoading, items: ${_menuItems.length}, categories: ${_categories.length}');
    
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final widget = Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(theme, isDark),
            Expanded(
              child: _isLoading
                  ? _buildSkeletonLoader(theme, isDark)
                  : _errorMessage != null
                      ? _buildErrorState(theme)
                      : _buildMenuGrid(theme, isDark),
            ),
            if (!_isLoading && _categories.isNotEmpty) _buildCategoryFooter(theme, isDark),
            if (_cart.isNotEmpty) _buildCartFooter(theme, isDark),
          ],
        ),
      ),
    );
    
    final buildDuration = DateTime.now().difference(buildStart);
    print('🎨 [BREAK PAGE] Build completed in ${buildDuration.inMilliseconds}ms');
    
    return widget;
  }

  Widget _buildHeader(ThemeData theme, bool isDark) {
    final headerColors = isDark
        ? [const Color(0xFF6366F1), const Color(0xFF8B5CF6)] // Indigo to Purple
        : [const Color(0xFF0071E3), const Color(0xFF5E5CE6)]; // Blue to Indigo
    
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: headerColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: headerColors[0].withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: AppColors.cxWhite.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: AppColors.cxWhite.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: IconButton(
                  onPressed: () => context.go('/home'),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  color: AppColors.cxWhite,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context).breakOrder,
                      style: TextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.cxWhite,
                        shadows: [
                          Shadow(
                            color: AppColors.cxBlack.withOpacity(0.15),
                            offset: const Offset(0, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      AppLocalizations.of(context).breakOrderSubtitle,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: AppColors.cxWhite.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: AppColors.cxWhite.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: AppColors.cxWhite.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  Icons.restaurant_menu_rounded,
                  color: AppColors.cxWhite,
                  size: 28.sp,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuGrid(ThemeData theme, bool isDark) {
    final filterStart = DateTime.now();
    final categoryItems = _selectedCategoryId != null
        ? _menuItems.where((item) => item.posCategoryId == _selectedCategoryId).toList()
        : [];
    final filterDuration = DateTime.now().difference(filterStart);
    print('🔍 [BREAK PAGE] Filtering items for category $_selectedCategoryId took: ${filterDuration.inMilliseconds}ms (found ${categoryItems.length} items)');

    if (categoryItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant_outlined,
              size: 64.sp,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            SizedBox(height: 16.h),
            Text(
              'No items in this category',
              style: TextStyle(
                fontSize: 16.sp,
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    print('📋 [BREAK PAGE] Building GridView with ${categoryItems.length} items');
    return GridView.builder(
      padding: EdgeInsets.all(20.w),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16.w,
        mainAxisSpacing: 16.h,
      ),
      itemCount: categoryItems.length,
      itemBuilder: (context, index) {
        return _buildMenuItem(categoryItems[index], theme, isDark);
      },
    );
  }

  Widget _buildMenuItem(InventoryItem item, ThemeData theme, bool isDark) {
    final quantity = _cart[item.id] ?? 0;
    final price = item.inventoryPriceList?.price ?? 0;
    final imageUrl = item.photo?.url;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : AppColors.cxWhite,
        borderRadius: BorderRadius.circular(20.r),
        border: isDark
            ? Border.all(
                color: theme.colorScheme.outline.withOpacity(0.2),
                width: 1,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                height: 120.h,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20.r),
                    topRight: Radius.circular(20.r),
                  ),
                  gradient: LinearGradient(
                    colors: [
                      AppColors.cxWarning.withOpacity(0.1),
                      AppColors.cxFEDA84.withOpacity(0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: imageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20.r),
                          topRight: Radius.circular(20.r),
                        ),
                        child: Image.network(
                          imageUrl,
                          width: double.infinity,
                          height: 120.h,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Icon(
                                Icons.fastfood_rounded,
                                size: 48.sp,
                                color: AppColors.cxWarning,
                              ),
                            );
                          },
                        ),
                      )
                    : Center(
                        child: Icon(
                          Icons.fastfood_rounded,
                          size: 48.sp,
                          color: AppColors.cxWarning,
                        ),
                      ),
              ),
              // if (item.inventoryGroup != null)
              //   Positioned(
              //     top: 8.h,
              //     right: 8.w,
              //     child: Container(
              //       padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              //       decoration: BoxDecoration(
              //         color: AppColors.cxWarning,
              //         borderRadius: BorderRadius.circular(8.r),
              //         boxShadow: [
              //           BoxShadow(
              //             color: AppColors.cxBlack.withOpacity(0.2),
              //             blurRadius: 4,
              //             offset: const Offset(0, 2),
              //           ),
              //         ],
              //       ),
              //       child: Text(
              //         item.inventoryGroup!.name,
              //         style: TextStyle(
              //           fontSize: 10.sp,
              //           fontWeight: FontWeight.w700,
              //           color: AppColors.cxWhite,
              //         ),
              //       ),
              //     ),
              //   ),
            ],
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(12.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '$price UZS',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.cxWarning,
                          ),
                        ),
                      ),
                      if (quantity == 0)
                        GestureDetector(
                          onTap: () => _addToCart(item),
                          child: Container(
                            padding: EdgeInsets.all(8.w),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [AppColors.cxWarning, AppColors.cxFEDA84],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(10.r),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.cxWarning.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.add_rounded,
                              color: AppColors.cxWhite,
                              size: 20.sp,
                            ),
                          ),
                        )
                      else
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => _removeFromCart(item),
                              child: Container(
                                padding: EdgeInsets.all(6.w),
                                decoration: BoxDecoration(
                                  color: AppColors.cxWarning.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8.r),
                                  border: Border.all(
                                    color: AppColors.cxWarning,
                                    width: 1.5,
                                  ),
                                ),
                                child: Icon(
                                  Icons.remove_rounded,
                                  color: AppColors.cxWarning,
                                  size: 16.sp,
                                ),
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              '$quantity',
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            SizedBox(width: 8.w),
                            GestureDetector(
                              onTap: () => _addToCart(item),
                              child: Container(
                                padding: EdgeInsets.all(6.w),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [AppColors.cxWarning, AppColors.cxFEDA84],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                child: Icon(
                                  Icons.add_rounded,
                                  color: AppColors.cxWhite,
                                  size: 16.sp,
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFooter(ThemeData theme, bool isDark) {
    return Container(
      height: 70.h,
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : AppColors.cxWhite,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24.r),
          topRight: Radius.circular(24.r),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.4 : 0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategoryId == category.posCategoryId;
          final itemCount = _menuItems
              .where((item) => item.posCategoryId == category.posCategoryId)
              .length;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategoryId = category.posCategoryId;
              });
            },
            child: Container(
              margin: EdgeInsets.only(right: 12.w),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: isSelected 
                    ? (isDark ? const Color(0xFF6366F1) : const Color(0xFF0071E3))
                    : theme.colorScheme.surfaceVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: isSelected
                      ? (isDark ? const Color(0xFF6366F1) : const Color(0xFF0071E3))
                      : theme.colorScheme.outline.withOpacity(0.2),
                  width: isSelected ? 1.5 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: (isDark ? const Color(0xFF6366F1) : const Color(0xFF0071E3)).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    category.posCategory?.name ?? 'Category',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? AppColors.cxWhite
                          : theme.colorScheme.onSurface,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2.h),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.h),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.cxWhite.withOpacity(0.3)
                          : (isDark ? const Color(0xFF6366F1) : const Color(0xFF0071E3)).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Text(
                      '$itemCount',
                      style: TextStyle(
                        fontSize: 9.sp,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? AppColors.cxWhite
                            : (isDark ? const Color(0xFF6366F1) : const Color(0xFF0071E3)),
                        height: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCartFooter(ThemeData theme, bool isDark) {
    final total = _getCartTotal();
    final itemCount = _getCartItemCount();

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : AppColors.cxWhite,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24.r),
          topRight: Radius.circular(24.r),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.4 : 0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$itemCount ${itemCount == 1 ? 'item' : 'items'}',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  '$total UZS',
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w800,
                    color: isDark ? const Color(0xFF6366F1) : const Color(0xFF0071E3),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: GestureDetector(
              onTap: () {
                // TODO: Implement order submission
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Order submission coming soon!'),
                    backgroundColor: AppColors.cxSuccess,
                  ),
                );
              },
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 16.h),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF6366F1), const Color(0xFF8B5CF6)]
                        : [const Color(0xFF0071E3), const Color(0xFF5E5CE6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color: (isDark ? const Color(0xFF6366F1) : const Color(0xFF0071E3)).withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.shopping_cart_checkout_rounded,
                      color: AppColors.cxWhite,
                      size: 24.sp,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      AppLocalizations.of(context).placeOrder,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.cxWhite,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonLoader(ThemeData theme, bool isDark) {
    return GridView.builder(
      padding: EdgeInsets.all(20.w),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16.w,
        mainAxisSpacing: 16.h,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return _buildSkeletonCard(theme, isDark);
      },
    );
  }

  Widget _buildSkeletonCard(ThemeData theme, bool isDark) {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? theme.colorScheme.surface : AppColors.cxWhite,
            borderRadius: BorderRadius.circular(20.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 120.h,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20.r),
                    topRight: Radius.circular(20.r),
                  ),
                  gradient: LinearGradient(
                    colors: [
                      AppColors.cxPlatinumGray.withOpacity(_shimmerAnimation.value),
                      AppColors.cxSilverTint.withOpacity(_shimmerAnimation.value * 0.5),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(12.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 100.w,
                      height: 14.h,
                      decoration: BoxDecoration(
                        color: AppColors.cxPlatinumGray.withOpacity(_shimmerAnimation.value),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Container(
                      width: 60.w,
                      height: 12.h,
                      decoration: BoxDecoration(
                        color: AppColors.cxPlatinumGray.withOpacity(_shimmerAnimation.value),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64.sp,
            color: AppColors.cxWarning,
          ),
          SizedBox(height: 16.h),
          Text(
            _errorMessage ?? 'An error occurred',
            style: TextStyle(
              fontSize: 16.sp,
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24.h),
          ElevatedButton(
            onPressed: _fetchMenuItems,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.cxWarning,
              padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 12.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            child: Text(
              'Retry',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.cxWhite,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
