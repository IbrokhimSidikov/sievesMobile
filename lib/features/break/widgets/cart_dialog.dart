import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/model/inventory_model.dart';

class CartDialog extends StatelessWidget {
  final Map<int, int> cart;
  final Map<int, ChangeableItem?> itemChanges;
  final List<InventoryItem> menuItems;
  final Function(InventoryItem) onRemoveItem;
  final Function(InventoryItem) onAddItem;
  final VoidCallback onClearCart;

  const CartDialog({
    super.key,
    required this.cart,
    required this.itemChanges,
    required this.menuItems,
    required this.onRemoveItem,
    required this.onAddItem,
    required this.onClearCart,
  });

  int _calculateItemPrice(InventoryItem item) {
    int itemPrice = item.inventoryPriceList?.price ?? 0;

    final changedItem = itemChanges[item.id];
    if (changedItem != null && item.hasChangeableItems) {
      final defaultItems = item.changeableContains?.defaultItems ?? [];

      for (int i = 0; i < defaultItems.length; i++) {
        final defaultItem = defaultItems[i];
        if (changedItem.id != defaultItem.id) {
          final defaultPrice = defaultItem.inventoryPriceList?.price ?? 0;
          final changedPrice = changedItem.inventoryPriceList?.price ?? 0;

          if (changedPrice > defaultPrice) {
            itemPrice += (changedPrice - defaultPrice);
          }
          break;
        }
      }
    }

    return itemPrice;
  }

  int _getCartTotal() {
    int total = 0;
    for (var item in menuItems) {
      final quantity = cart[item.id] ?? 0;
      if (quantity > 0) {
        total += _calculateItemPrice(item) * quantity;
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cartItems = menuItems
        .where((item) => (cart[item.id] ?? 0) > 0)
        .toList();

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
            _buildHeader(theme, isDark, context),
            if (cartItems.isEmpty)
              _buildEmptyCart(theme)
            else
              Flexible(child: _buildCartItems(cartItems, theme, isDark)),
            if (cartItems.isNotEmpty) _buildFooter(theme, isDark, context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDark, BuildContext context) {
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
              Icons.shopping_cart_rounded,
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
                  'Your Cart',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.cxWhite,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  '${cart.values.fold(0, (sum, qty) => sum + qty)} items',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.cxWhite.withOpacity(0.85),
                  ),
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

  Widget _buildEmptyCart(ThemeData theme) {
    return Padding(
      padding: EdgeInsets.all(60.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 64.sp,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          SizedBox(height: 16.h),
          Text(
            'Your cart is empty',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Add items to get started',
            style: TextStyle(
              fontSize: 13.sp,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItems(
    List<InventoryItem> cartItems,
    ThemeData theme,
    bool isDark,
  ) {
    return ListView.separated(
      shrinkWrap: true,
      padding: EdgeInsets.all(16.w),
      itemCount: cartItems.length,
      separatorBuilder: (context, index) => SizedBox(height: 12.h),
      itemBuilder: (context, index) {
        final item = cartItems[index];
        final quantity = cart[item.id] ?? 0;
        final itemPrice = _calculateItemPrice(item);
        final changedItem = itemChanges[item.id];
        final imageUrl = item.photo?.url;

        return Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: isDark
                ? theme.colorScheme.surfaceVariant.withOpacity(0.3)
                : AppColors.cxF5F7F9,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.1),
            ),
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
                child: imageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12.r),
                        child: Image.network(
                          imageUrl,
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
                      item.name,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (changedItem != null) ...[
                      SizedBox(height: 4.h),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6.w,
                          vertical: 2.h,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6.r),
                          border: Border.all(
                            color: const Color(0xFF6366F1).withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.swap_horiz_rounded,
                              size: 10.sp,
                              color: const Color(0xFF6366F1),
                            ),
                            SizedBox(width: 3.w),
                            Flexible(
                              child: Text(
                                'Changed: ${changedItem.name}',
                                style: TextStyle(
                                  fontSize: 9.sp,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF6366F1),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    SizedBox(height: 4.h),
                    Text(
                      '$itemPrice UZS × $quantity',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.cxWarning,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => onRemoveItem(item),
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
                    onTap: () => onAddItem(item),
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
        );
      },
    );
  }

  Widget _buildFooter(ThemeData theme, bool isDark, BuildContext context) {
    final total = _getCartTotal();

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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                '$total UZS',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w800,
                  color: isDark
                      ? const Color(0xFF6366F1)
                      : const Color(0xFF0071E3),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          GestureDetector(
            onTap: () {
              onClearCart();
              Navigator.of(context).pop();
            },
            child: Container(
              width: double.infinity,
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
                  'Clear Cart',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.error,
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
