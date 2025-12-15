import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/model/inventory_model.dart';
import '../../../core/services/auth/auth_manager.dart';

class ChangeItemDialog extends StatefulWidget {
  final InventoryItem item;
  final Function(ChangeableItem?) onItemSelected;
  final List<InventoryItem> allMenuItems;

  const ChangeItemDialog({
    super.key,
    required this.item,
    required this.onItemSelected,
    required this.allMenuItems,
  });

  @override
  State<ChangeItemDialog> createState() => _ChangeItemDialogState();
}

class _ChangeItemDialogState extends State<ChangeItemDialog>
    with SingleTickerProviderStateMixin {
  ChangeableItem? _selectedItem;
  late TabController _tabController;
  final AuthManager _authManager = AuthManager();

  // Cache for category products
  final Map<int, List<ChangeableItem>> _categoryProducts = {};
  final Map<int, bool> _loadingCategories = {};

  List<_TabData> _tabs = [];

  @override
  void initState() {
    super.initState();
    _initializeTabs();
  }

  void _initializeTabs() {
    final defaultItems = widget.item.changeableContains?.defaultItems ?? [];

    print('🔄 [CHANGE DIALOG] Initializing tabs for item: ${widget.item.name}');
    print('🔄 [CHANGE DIALOG] Default items count: ${defaultItems.length}');

    _tabs = [];

    // Create a tab for each default item (e.g., "Bread", "Cheese", "Meat")
    // Each tab will show products from that default item's changeableCategories
    for (int i = 0; i < defaultItems.length; i++) {
      final defaultItem = defaultItems[i];
      print('🔄 [CHANGE DIALOG] Default item [$i]: ${defaultItem.name}');

      _tabs.add(
        _TabData(
          id: i,
          name: defaultItem.name,
          isDefault: false,
          defaultItem: defaultItem,
        ),
      );
    }

    // If no tabs, add empty default tab
    if (_tabs.isEmpty) {
      _tabs.add(_TabData(id: -1, name: 'No Options', isDefault: true));
    }

    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_onTabChanged);

    // Pre-populate category products from allMenuItems
    _populateCategoryProducts();
  }

  void _populateCategoryProducts() {
    for (final tab in _tabs) {
      if (!tab.isDefault && tab.defaultItem != null) {
        // Get the changeable categories from THIS default item
        // Each default item has its own changeableCategories array
        final changeableCategories = tab.defaultItem!.changeableCategories;

        print(
          '🔍 [CHANGE DIALOG] Tab "${tab.name}" - changeableCategories count: ${changeableCategories.length}',
        );

        // Get all pos_category_ids from the changeable categories
        final posCategoryIds = changeableCategories
            .map((cat) => cat.posCategoryId)
            .toSet();

        print(
          '🔍 [CHANGE DIALOG] Looking for items in categories: $posCategoryIds',
        );

        // Filter products from allMenuItems by pos_category_id
        final products = widget.allMenuItems
            .where((item) => posCategoryIds.contains(item.posCategoryId))
            .map(
              (item) => ChangeableItem(
                id: item.id,
                name: item.name,
                photoId: item.photoId,
                posCategoryId: item.posCategoryId,
                photo: item.photo,
                inventoryPriceList: item.inventoryPriceList,
              ),
            )
            .toList();

        print(
          '🔍 [CHANGE DIALOG] Found ${products.length} products for tab "${tab.name}"',
        );
        _categoryProducts[tab.id] = products;
      }
    }
  }

  void _onTabChanged() {
    // Reset selection when changing tabs
    if (_tabController.indexIsChanging) {
      setState(() {
        _selectedItem = null;
      });
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 40.h),
      child: Container(
        constraints: BoxConstraints(maxHeight: 600.h),
        decoration: BoxDecoration(
          color: isDark ? theme.colorScheme.surface : AppColors.cxWhite,
          borderRadius: BorderRadius.circular(24.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.4 : 0.15),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(theme, isDark),
            if (_tabs.length > 1) _buildTabBar(theme, isDark),
            Flexible(child: _buildTabContent(theme, isDark)),
            _buildFooter(theme, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar(ThemeData theme, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surfaceVariant.withOpacity(0.3)
            : AppColors.cxF5F7F9,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: _tabs.length > 3,
        labelColor: isDark ? const Color(0xFF6366F1) : const Color(0xFF0071E3),
        unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
        labelStyle: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(
          fontSize: 13.sp,
          fontWeight: FontWeight.w500,
        ),
        indicatorColor: isDark
            ? const Color(0xFF6366F1)
            : const Color(0xFF0071E3),
        indicatorWeight: 3,
        labelPadding: EdgeInsets.symmetric(horizontal: 16.w),
        tabs: _tabs.map((tab) => Tab(text: tab.name)).toList(),
      ),
    );
  }

  Widget _buildTabContent(ThemeData theme, bool isDark) {
    return TabBarView(
      controller: _tabController,
      children: _tabs.map((tab) {
        final categoryItems = _categoryProducts[tab.id] ?? [];
        return _buildItemsList(categoryItems, theme, isDark, tab.defaultItem);
      }).toList(),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDark) {
    final headerColors = isDark
        ? [const Color(0xFF6366F1), const Color(0xFF8B5CF6)]
        : [const Color(0xFF0071E3), const Color(0xFF5E5CE6)];

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: headerColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24.r),
          topRight: Radius.circular(24.r),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: AppColors.cxWhite.withOpacity(0.25),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              Icons.swap_horiz_rounded,
              color: AppColors.cxWhite,
              size: 24.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Change Item',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.cxWhite,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  widget.item.name,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.cxWhite.withOpacity(0.85),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: AppColors.cxWhite.withOpacity(0.25),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(
                Icons.close_rounded,
                color: AppColors.cxWhite,
                size: 20.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList(
    List<ChangeableItem> items,
    ThemeData theme,
    bool isDark,
    ChangeableItem? defaultItem,
  ) {
    if (items.isEmpty) {
      return Padding(
        padding: EdgeInsets.all(40.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 48.sp,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            SizedBox(height: 12.h),
            Text(
              'No alternative items available',
              style: TextStyle(
                fontSize: 14.sp,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (defaultItem != null) ...[
              SizedBox(height: 8.h),
              Text(
                'Default: ${defaultItem.name}',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      padding: EdgeInsets.all(16.w),
      itemCount: items.length,
      separatorBuilder: (context, index) => SizedBox(height: 12.h),
      itemBuilder: (context, index) {
        final changeableItem = items[index];
        final isSelected = _selectedItem?.id == changeableItem.id;
        final price = changeableItem.inventoryPriceList?.price ?? 0;

        return GestureDetector(
          onTap: () {
            setState(() {
              if (_selectedItem?.id == changeableItem.id) {
                _selectedItem = null;
              } else {
                _selectedItem = changeableItem;
              }
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: isSelected
                  ? (isDark
                        ? const Color(0xFF6366F1).withOpacity(0.15)
                        : const Color(0xFF0071E3).withOpacity(0.08))
                  : (isDark
                        ? theme.colorScheme.surfaceVariant.withOpacity(0.3)
                        : AppColors.cxF5F7F9),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: isSelected
                    ? (isDark
                          ? const Color(0xFF6366F1)
                          : const Color(0xFF0071E3))
                    : Colors.transparent,
                width: 2,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color:
                            (isDark
                                    ? const Color(0xFF6366F1)
                                    : const Color(0xFF0071E3))
                                .withOpacity(0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 60.w,
                  height: 60.w,
                  decoration: BoxDecoration(
                    color: AppColors.cxWarning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: changeableItem.imageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12.r),
                          child: Image.network(
                            changeableItem.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Icon(
                                  Icons.fastfood_rounded,
                                  size: 28.sp,
                                  color: AppColors.cxWarning,
                                ),
                              );
                            },
                          ),
                        )
                      : Center(
                          child: Icon(
                            Icons.fastfood_rounded,
                            size: 28.sp,
                            color: AppColors.cxWarning,
                          ),
                        ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        changeableItem.name,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (price > 0) ...[
                        SizedBox(height: 4.h),
                        Text(
                          '$price UZS',
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.cxWarning,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 28.w,
                  height: 28.w,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isDark
                              ? const Color(0xFF6366F1)
                              : const Color(0xFF0071E3))
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: isSelected
                          ? (isDark
                                ? const Color(0xFF6366F1)
                                : const Color(0xFF0071E3))
                          : theme.colorScheme.outline.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? Icon(
                          Icons.check_rounded,
                          size: 18.sp,
                          color: AppColors.cxWhite,
                        )
                      : null,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFooter(ThemeData theme, bool isDark) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : AppColors.cxWhite,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24.r),
          bottomRight: Radius.circular(24.r),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                widget.onItemSelected(null);
                Navigator.of(context).pop();
              },
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 14.h),
                decoration: BoxDecoration(
                  color: isDark
                      ? theme.colorScheme.surfaceVariant
                      : AppColors.cxF5F7F9,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: theme.colorScheme.outline.withOpacity(0.2),
                  ),
                ),
                child: Center(
                  child: Text(
                    'Keep Original',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: GestureDetector(
              onTap: _selectedItem != null
                  ? () {
                      widget.onItemSelected(_selectedItem);
                      Navigator.of(context).pop();
                    }
                  : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(vertical: 14.h),
                decoration: BoxDecoration(
                  gradient: _selectedItem != null
                      ? LinearGradient(
                          colors: isDark
                              ? [
                                  const Color(0xFF6366F1),
                                  const Color(0xFF8B5CF6),
                                ]
                              : [
                                  const Color(0xFF0071E3),
                                  const Color(0xFF5E5CE6),
                                ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: _selectedItem == null
                      ? theme.colorScheme.outline.withOpacity(0.2)
                      : null,
                  borderRadius: BorderRadius.circular(12.r),
                  boxShadow: _selectedItem != null
                      ? [
                          BoxShadow(
                            color:
                                (isDark
                                        ? const Color(0xFF6366F1)
                                        : const Color(0xFF0071E3))
                                    .withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    'Confirm Change',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: _selectedItem != null
                          ? AppColors.cxWhite
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabData {
  final int id;
  final String name;
  final bool isDefault;
  final ChangeableItem? defaultItem;

  _TabData({
    required this.id,
    required this.name,
    required this.isDefault,
    this.defaultItem,
  });
}
