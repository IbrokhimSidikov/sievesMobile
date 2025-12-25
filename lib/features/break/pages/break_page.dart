import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/model/inventory_model.dart';
import '../../../core/services/auth/auth_manager.dart';
import '../../../core/services/cache/menu_cache_service.dart';
import '../../../core/services/face_verification/face_verification_service.dart';
import '../widgets/face_capture_dialog.dart';
import '../widgets/change_item_dialog.dart';
import '../widgets/cart_dialog.dart';
import '../widgets/success_dialog.dart';
import '../widgets/pizza_selection_dialog.dart';
import '../widgets/combo_selection_dialog.dart';
import '../widgets/notice_dialog.dart';

// Helper class to track changed item with its tab index
class ItemChange {
  final ChangeableItem changedItem;
  final int tabIndex; // Which tab (0, 1, 2) the item was selected from

  ItemChange(this.changedItem, this.tabIndex);
}

class BreakPage extends StatefulWidget {
  const BreakPage({super.key});

  @override
  State<BreakPage> createState() => _BreakPageState();
}

class _BreakPageState extends State<BreakPage>
    with SingleTickerProviderStateMixin {
  final AuthManager _authManager = AuthManager();
  final MenuCacheService _cacheService = MenuCacheService();
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _errorMessage;
  String _loadingMessage = 'Loading menu...';
  List<InventoryItem> _menuItems = [];
  List<PosActiveCategory> _categories = [];
  int? _selectedCategoryId;
  Map<int, int> _cart = {};
  Map<int, List<ItemChange>> _itemChanges =
      {}; // Changed to store List of ItemChange objects
  Map<int, int> _itemPrices =
      {}; // Stores calculated price for items with changes
  Map<int, String> _itemComments = {}; // Stores comments/notes for cart items
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;
  bool _isSubmittingOrder = false;
  bool _hasOrderedToday = false;
  bool _isCheckingDailyOrder = true;

  // Pizza product IDs (matching website logic)
  final List<int> _pizzaIds = [227, 228, 229, 230, 231, 234, 235, 724];

  // Mapping for Americano product IDs
  final Map<int, int> _pizzaAmericanoMap = {
    227: 1011,
    228: 1012,
    229: 1013,
    230: 1014,
    231: 1015,
    234: 1016,
    235: 1017,
    724: 1018,
  };

  // Combo product IDs (matching website logic)
  final List<int> _comboProductIds = [985, 986, 990, 992, 993, 994, 995];

  // Track selected combo for multi-step selection
  InventoryItem? _selectedComboProduct;
  bool _pizzaOptionOpened = false;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _shimmerAnimation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    _fetchMenuItems();
    _checkDailyOrderStatus();

    // Show notice dialog after frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showNoticeDialog();
    });
  }

  // Check if current time is within allowed order windows

  bool _isWithinOrderTime() {
    // Bypass time restriction for department IDs 16 and 28
    final departmentId = _authManager.currentIdentity?.employee?.departmentId;
    if (departmentId == 16 || departmentId == 28 || departmentId == 20) {
      return true;
    }
    if (_authManager.currentIdentity?.employee?.branchId == 6) {
      return true;
    }

    final now = DateTime.now();
    final day = now.weekday; // Monday = 1, Friday = 5
    final hour = now.hour;
    final minute = now.minute;

    if (day == 5) {
      // Friday: 12:45 - 14:30
      return (hour == 12 && minute >= 45) ||
          hour == 13 ||
          (hour == 14 && minute <= 30);
    } else {
      // Other days
      // Window 1: 12:00 - 12:30
      if (hour == 12 && minute >= 0 && minute <= 30) {
        return true;
      }

      // Window 2: 13:30 - 14:00
      if ((hour == 13 && minute >= 30) || (hour == 14 && minute == 0)) {
        return true;
      }
    }

    return false;
  }

  // Get next available order window message
  String _getNextOrderWindowMessage() {
    final now = DateTime.now();
    final day = now.weekday; // Monday = 1, Friday = 5
    final hour = now.hour;
    final minute = now.minute;

    if (day == 5) {
      // Friday
      if (hour < 12 || (hour == 12 && minute < 45)) {
        return 'Orders available at 12:45 - 14:30 (Friday)';
      } else {
        return 'Orders available tomorrow at 12:00 - 12:30';
      }
    } else {
      // Other days
      if (hour < 12) {
        return 'Orders available at 12:00 - 12:30';
      } else if (hour == 12 && minute > 30) {
        return 'Orders available at 13:30 - 14:00';
      } else if (hour >= 13 && hour < 13 || (hour == 13 && minute < 30)) {
        return 'Orders available at 13:30 - 14:00';
      } else {
        return 'Orders available tomorrow at 12:00 - 12:30';
      }
    }
  }

  Future<void> _checkDailyOrderStatus() async {
    final employeeId = _authManager.currentEmployeeId;
    if (employeeId == null) {
      setState(() {
        _isCheckingDailyOrder = false;
      });
      return;
    }

    try {
      final hasOrdered = await _authManager.apiService.hasOrderedToday(
        employeeId,
      );
      if (mounted) {
        setState(() {
          _hasOrderedToday = hasOrdered;
          _isCheckingDailyOrder = false;
        });
      }
    } catch (e) {
      print('❌ Error checking daily order status: $e');
      if (mounted) {
        setState(() {
          _isCheckingDailyOrder = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  void _showNoticeDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const NoticeDialog(
        title: 'Diqqat',
        message:
            '''Ushbu urilgan BREAK buyurtmalar faqatgina CITY BOULEVARD filialiga chiqadi. Boshqa filialda bolsangiz Planshetdan foydalaning''',
      ),
    );
  }

  Future<void> _fetchMenuItems({bool forceRefresh = false}) async {
    final startTime = DateTime.now();
    print(
      '⏱️ [BREAK PAGE] Starting to fetch menu items at ${startTime.toIso8601String()} (forceRefresh: $forceRefresh)',
    );

    if (!mounted) return;

    try {
      // If force refresh, clear the cache first
      if (forceRefresh) {
        print('🔄 [BREAK PAGE] Force refresh - clearing cache');
        await _cacheService.clearCache();
      }

      // Initialize cache from persistent storage first
      setState(() {
        _loadingMessage = 'Loading cached menu...';
      });
      await _cacheService.initialize();

      // Check if we have ANY cached data (even if expired)
      final cachedData = _cacheService.getCachedDataEvenIfExpired();
      final hasValidCache = _cacheService.isCacheValid;

      if (cachedData != null) {
        // Show cached data immediately
        print(
          '📦 [BREAK PAGE] Displaying cached data immediately (${cachedData.menuItems.length} items, valid: $hasValidCache)',
        );

        final sortedCategories =
            List<PosActiveCategory>.from(cachedData.categories)..sort(
              (a, b) => (a.posCategory?.name ?? '').compareTo(
                b.posCategory?.name ?? '',
              ),
            );

        if (!mounted) return;
        setState(() {
          _menuItems = cachedData.menuItems;
          _categories = sortedCategories;
          if (sortedCategories.isNotEmpty) {
            _selectedCategoryId = sortedCategories.first.posCategoryId;
          }
          _isLoading = false;
        });

        // If cache is valid, we're done
        if (hasValidCache) {
          final totalDuration = DateTime.now().difference(startTime);
          print(
            '✅ [BREAK PAGE] Loaded from valid cache in ${totalDuration.inMilliseconds}ms',
          );
          return;
        }

        // Cache is expired, refresh in background
        print('🔄 [BREAK PAGE] Cache expired, refreshing in background...');
        if (!mounted) return;
        setState(() {
          _isRefreshing = true;
        });
      } else {
        // No cache at all, show loading state
        print('🌐 [BREAK PAGE] No cache found, fetching from API...');
        if (!mounted) return;
        setState(() {
          _isLoading = true;
          _loadingMessage = 'Fetching menu from server...';
          _errorMessage = null;
        });
      }

      // Fetch fresh data from API
      final apiStartTime = DateTime.now();
      print('📡 [BREAK PAGE] Starting parallel API calls...');

      if (!mounted) return;
      setState(() {
        _loadingMessage = 'Downloading menu items...';
      });

      final results = await Future.wait([
        _authManager.apiService.getInventoryMenu(),
        _authManager.apiService.getPosCategories(),
      ]);
      final apiDuration = DateTime.now().difference(apiStartTime);
      print(
        '⏱️ [BREAK PAGE] Both API calls completed in: ${apiDuration.inMilliseconds}ms',
      );

      if (!mounted) return;

      final items = results[0] as List<InventoryItem>;
      final categories = results[1] as List<PosActiveCategory>;
      print(
        '⏱️ [BREAK PAGE] Received ${items.length} items and ${categories.length} categories',
      );

      // Sort categories alphabetically
      final sortedCategories = List<PosActiveCategory>.from(categories)
        ..sort(
          (a, b) =>
              (a.posCategory?.name ?? '').compareTo(b.posCategory?.name ?? ''),
        );

      // Cache the fresh data
      _cacheService.cacheData(items, sortedCategories);

      if (!mounted) return;
      setState(() {
        _menuItems = items;
        _categories = sortedCategories;
        if (sortedCategories.isNotEmpty) {
          _selectedCategoryId = sortedCategories.first.posCategoryId;
        }
        _isLoading = false;
        _isRefreshing = false;
      });

      final totalDuration = DateTime.now().difference(startTime);
      print(
        '✅ [BREAK PAGE] Total load time: ${totalDuration.inMilliseconds}ms (API: ${apiDuration.inMilliseconds}ms)',
      );
    } catch (e) {
      final totalDuration = DateTime.now().difference(startTime);
      print('❌ [BREAK PAGE] Error after ${totalDuration.inMilliseconds}ms: $e');

      if (!mounted) return;

      setState(() {
        _errorMessage = 'Failed to load menu. Please try again.';
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }

  void _addToCart(
    InventoryItem item, {
    Map<int, ChangeableItem?>? changedItems,
  }) {
    setState(() {
      _cart[item.id] = (_cart[item.id] ?? 0) + 1;
      if (changedItems != null && changedItems.isNotEmpty) {
        // Store all changed items as List of ItemChange
        List<ItemChange> changes = [];
        int totalPriceDifference = 0;

        changedItems.forEach((tabIndex, changedItem) {
          if (changedItem != null) {
            changes.add(ItemChange(changedItem, tabIndex));
            // Calculate price difference for this change
            final defaultItem = item.changeableContains?.defaultItems[tabIndex];
            if (defaultItem != null) {
              final defaultPrice = defaultItem.inventoryPriceList?.price ?? 0;
              final changedPrice = changedItem.inventoryPriceList?.price ?? 0;
              if (changedPrice > defaultPrice) {
                totalPriceDifference += (changedPrice - defaultPrice);
              }
            }
          }
        });

        _itemChanges[item.id] = changes;
        // Store total price including all differences
        final basePrice = item.inventoryPriceList?.price ?? 0;
        _itemPrices[item.id] = basePrice + totalPriceDifference;
      }
    });
  }

  void _updateItemModifiers(
    InventoryItem item,
    Map<int, ChangeableItem?>? changedItems,
  ) {
    setState(() {
      if (changedItems != null && changedItems.isNotEmpty) {
        // Store all changed items as List of ItemChange
        List<ItemChange> changes = [];
        int totalPriceDifference = 0;

        changedItems.forEach((tabIndex, changedItem) {
          if (changedItem != null) {
            changes.add(ItemChange(changedItem, tabIndex));
            // Calculate price difference for this change
            final defaultItem = item.changeableContains?.defaultItems[tabIndex];
            if (defaultItem != null) {
              final defaultPrice = defaultItem.inventoryPriceList?.price ?? 0;
              final changedPrice = changedItem.inventoryPriceList?.price ?? 0;
              if (changedPrice > defaultPrice) {
                totalPriceDifference += (changedPrice - defaultPrice);
              }
            }
          }
        });

        _itemChanges[item.id] = changes;
        // Store total price including all differences
        final basePrice = item.inventoryPriceList?.price ?? 0;
        _itemPrices[item.id] = basePrice + totalPriceDifference;
      } else {
        // If no changes, remove the modifications and reset to base price
        _itemChanges.remove(item.id);
        _itemPrices.remove(item.id);
      }
    });
  }

  void _showChangeItemDialog(InventoryItem item) {
    showDialog(
      context: context,
      builder: (context) => ChangeItemDialog(
        item: item,
        onItemSelected: (selectedItems) {
          _addToCart(item, changedItems: selectedItems);
        },
        allMenuItems: _menuItems,
      ),
    );
  }

  void _showPizzaSelectionDialog(InventoryItem pizzaItem) {
    showDialog(
      context: context,
      builder: (context) => PizzaSelectionDialog(
        selectedPizza: pizzaItem,
        onPizzaTypeSelected: (pizzaType) {
          _handlePizzaSelection(pizzaItem, pizzaType);
        },
      ),
    );
  }

  void _handlePizzaSelection(InventoryItem pizzaItem, String pizzaType) {
    InventoryItem productToAdd = pizzaItem;

    // If Americano is selected and there's a mapping, use the Americano version
    if (pizzaType == 'americano' &&
        _pizzaAmericanoMap.containsKey(pizzaItem.id)) {
      final americanoId = _pizzaAmericanoMap[pizzaItem.id];
      final americanoProduct = _menuItems.firstWhere(
        (item) => item.id == americanoId,
        orElse: () => pizzaItem,
      );
      productToAdd = americanoProduct;
    }
    // If Italiano is selected, use the original pizza product

    // If this pizza is part of a combo selection, add combo first
    if (_pizzaOptionOpened && _selectedComboProduct != null) {
      _addToCart(_selectedComboProduct!);
      setState(() {
        _selectedComboProduct = null;
        _pizzaOptionOpened = false;
      });
    }

    // Add the selected pizza to cart
    _addToCart(productToAdd);
  }

  List<InventoryItem> _filterComboProducts(int posCategoryId) {
    List<int> categories = [];
    bool isBurger = true;

    // Match website logic for category filtering
    if (posCategoryId == 9) {
      categories = [9];
      isBurger = false;
    } else {
      categories = [2, 10];
      isBurger = true;
    }

    if (isBurger) {
      return _menuItems
          .where((item) => categories.contains(item.posCategoryId))
          .toList();
    } else {
      // For non-burger combos, exclude inventoryGroup.id == 1
      return _menuItems
          .where(
            (item) =>
                categories.contains(item.posCategoryId) &&
                item.inventoryGroup?.id != 1,
          )
          .toList();
    }
  }

  void _showComboSelectionDialog(InventoryItem comboItem) {
    final filteredProducts = _filterComboProducts(comboItem.posCategoryId ?? 0);

    showDialog(
      context: context,
      builder: (context) => ComboSelectionDialog(
        selectedCombo: comboItem,
        filteredProducts: filteredProducts,
        onProductSelected: (selectedProduct) {
          _handleComboProductSelection(comboItem, selectedProduct);
        },
      ),
    );
  }

  void _handleComboProductSelection(
    InventoryItem comboItem,
    InventoryItem selectedProduct,
  ) {
    // If the selected product is a pizza (part of a combo)
    if (_pizzaIds.contains(selectedProduct.id)) {
      // Store the combo as the selected combo product
      setState(() {
        _selectedComboProduct = comboItem;
        _pizzaOptionOpened = true;
      });
      // Show pizza selection dialog
      _showPizzaSelectionDialog(selectedProduct);
    } else {
      // Add combo first, then the selected product
      _addToCart(comboItem);
      _addToCart(selectedProduct);
    }
  }

  void _handleProductClick(InventoryItem item) {
    // Check if it's a combo product
    if (_comboProductIds.contains(item.id)) {
      _showComboSelectionDialog(item);
    } else if (_pizzaIds.contains(item.id)) {
      // Check if it's a pizza product
      _showPizzaSelectionDialog(item);
    } else if (item.hasChangeableItems) {
      _showChangeItemDialog(item);
    } else {
      _addToCart(item);
    }
  }

  void _showCartDialog() {
    showDialog(
      context: context,
      builder: (context) => CartDialog(
        cart: _cart,
        itemChanges: _itemChanges,
        itemPrices: _itemPrices,
        itemComments: _itemComments,
        menuItems: _menuItems,
        onRemoveItem: _removeFromCart,
        onAddItem: (item) => _addToCart(item),
        onAddComment: (item, comment) {
          setState(() {
            if (comment.isEmpty) {
              _itemComments.remove(item.id);
            } else {
              _itemComments[item.id] = comment;
            }
          });
        },
        onChangeItem: (item) {
          // Show change item dialog to update modifiers (not add to cart)
          showDialog(
            context: context,
            builder: (context) => ChangeItemDialog(
              item: item,
              onItemSelected: (selectedItems) {
                _updateItemModifiers(item, selectedItems);
              },
              allMenuItems: _menuItems,
            ),
          );
        },
        onClearCart: () {
          setState(() {
            _cart.clear();
            _itemChanges.clear();
            _itemPrices.clear();
            _itemComments.clear();
          });
        },
      ),
    );
  }

  void _removeFromCart(InventoryItem item) {
    setState(() {
      if (_cart[item.id] != null && _cart[item.id]! > 0) {
        _cart[item.id] = _cart[item.id]! - 1;
        if (_cart[item.id] == 0) {
          _cart.remove(item.id);
          _itemChanges.remove(item.id);
          _itemPrices.remove(item.id);
          _itemComments.remove(item.id);
        }
      }
    });
  }

  int _getCartTotal() {
    int total = 0;
    for (var item in _menuItems) {
      final quantity = _cart[item.id] ?? 0;
      if (quantity > 0 && item.inventoryPriceList != null) {
        // Use stored calculated price if item was changed, otherwise use base price
        int itemPrice = _itemPrices[item.id] ?? item.inventoryPriceList!.price;
        total += itemPrice * quantity;
      }
    }
    return total;
  }

  int _getCartItemCount() {
    return _cart.values.fold(0, (sum, quantity) => sum + quantity);
  }

  Future<void> _handleOrderSubmission() async {
    // Check time restriction first
    if (!_isWithinOrderTime()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_getNextOrderWindowMessage()),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    // Check if already ordered today
    if (_hasOrderedToday) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'You have already placed an order today. One order per day allowed.',
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    final startTime = DateTime.now();
    print('');
    print('╔══════════════════════════════════════════════════════════════╗');
    print('║           🛒 BREAK ORDER SUBMISSION STARTED                  ║');
    print('╚══════════════════════════════════════════════════════════════╝');
    print('⏰ Start time: ${startTime.toIso8601String()}');
    print('📦 Cart items: ${_cart.length}');
    print('💰 Cart total: ${_getCartTotal()} UZS');
    print('');

    try {
      setState(() {
        _isSubmittingOrder = true;
      });

      // ═══════════════════════════════════════════════════════════════
      // STEP 1: GET PROFILE PHOTO URL
      // ═══════════════════════════════════════════════════════════════
      print('┌─────────────────────────────────────────────────────────────┐');
      print('│ STEP 1: Getting profile photo URL                          │');
      print('└─────────────────────────────────────────────────────────────┘');

      final step1Start = DateTime.now();
      final profilePhotoUrl = await _authManager.getProfilePhotoUrl();
      final step1Duration = DateTime.now().difference(step1Start);

      if (profilePhotoUrl == null) {
        print('❌ Profile photo URL is null');
        throw Exception(
          'Profile photo not found. Please update your profile picture in the app settings.',
        );
      }
      print(
        '✅ Profile photo URL obtained in ${step1Duration.inMilliseconds}ms',
      );
      print('   URL: $profilePhotoUrl');
      print('');

      // ═══════════════════════════════════════════════════════════════
      // STEP 2: DOWNLOAD PROFILE PHOTO
      // ═══════════════════════════════════════════════════════════════
      print('┌─────────────────────────────────────────────────────────────┐');
      print('│ STEP 2: Downloading profile photo                          │');
      print('└─────────────────────────────────────────────────────────────┘');

      final step2Start = DateTime.now();
      final profileImageResponse = await http.get(Uri.parse(profilePhotoUrl));
      final step2Duration = DateTime.now().difference(step2Start);

      print('   HTTP Status: ${profileImageResponse.statusCode}');
      print('   Response size: ${profileImageResponse.bodyBytes.length} bytes');

      if (profileImageResponse.statusCode != 200) {
        print('❌ Failed to download profile photo');
        throw Exception('Failed to download profile photo');
      }

      final tempDir = Directory.systemTemp;
      final profileImageFile = File(
        '${tempDir.path}/profile_image_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await profileImageFile.writeAsBytes(profileImageResponse.bodyBytes);
      print('✅ Profile photo downloaded in ${step2Duration.inMilliseconds}ms');
      print('   Saved to: ${profileImageFile.path}');
      print('');

      // ═══════════════════════════════════════════════════════════════
      // STEP 3: CAPTURE FACE FROM CAMERA
      // ═══════════════════════════════════════════════════════════════
      print('┌─────────────────────────────────────────────────────────────┐');
      print('│ STEP 3: Opening face capture dialog                         │');
      print('└─────────────────────────────────────────────────────────────┘');

      final step3Start = DateTime.now();
      final capturedImage = await showDialog<File>(
        context: context,
        barrierDismissible: false,
        builder: (context) => const FaceCaptureDialog(),
      );
      final step3Duration = DateTime.now().difference(step3Start);

      if (capturedImage == null) {
        print(
          '❌ User cancelled face capture after ${step3Duration.inMilliseconds}ms',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Face verification cancelled'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }
      print('✅ Face captured in ${step3Duration.inMilliseconds}ms');
      print('   Path: ${capturedImage.path}');
      print('   Size: ${await capturedImage.length()} bytes');
      print('');

      // ═══════════════════════════════════════════════════════════════
      // STEP 4: VERIFY FACE
      // ═══════════════════════════════════════════════════════════════
      print('┌─────────────────────────────────────────────────────────────┐');
      print('│ STEP 4: Verifying face                                     │');
      print('└─────────────────────────────────────────────────────────────┘');

      final step4Start = DateTime.now();
      final verificationService = FaceVerificationService();
      final result = await verificationService.verifyFace(
        profileImage: profileImageFile,
        capturedImage: capturedImage,
      );
      final step4Duration = DateTime.now().difference(step4Start);

      try {
        await profileImageFile.delete();
        print('   🗑️ Profile image file cleaned up');
      } catch (e) {
        print('   ⚠️ Failed to clean up profile image file: $e');
      }

      print('   Verification result: ${result.success ? "SUCCESS" : "FAILED"}');
      print('   Message: ${result.message}');
      print('   Duration: ${step4Duration.inMilliseconds}ms');

      if (!result.success) {
        print('❌ Face verification failed');
        try {
          await capturedImage.delete();
        } catch (e) {
          print('   ⚠️ Failed to clean up captured image: $e');
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      print('✅ Face verification passed in ${step4Duration.inMilliseconds}ms');
      print('');
      // ═══════════════════════════════════════════════════════════════
      // STEP 5: UPLOAD BREAK PHOTO
      // ═══════════════════════════════════════════════════════════════
      print('┌─────────────────────────────────────────────────────────────┐');
      print('│ STEP 5: Uploading break photo                              │');
      print('└─────────────────────────────────────────────────────────────┘');
      print('   Endpoint: POST /v1/photo?belongs_to=employee_break');

      final step5Start = DateTime.now();
      final photoId = await _authManager.apiService.uploadBreakPhoto(
        capturedImage,
      );
      final step5Duration = DateTime.now().difference(step5Start);

      // Clean up captured image after upload
      try {
        await capturedImage.delete();
        print('   🗑️ Captured image file cleaned up');
      } catch (e) {
        print('   ⚠️ Failed to clean up captured image: $e');
      }

      if (photoId == null) {
        print('❌ Photo upload failed');
        throw Exception('Failed to upload break photo');
      }
      print('✅ Photo uploaded in ${step5Duration.inMilliseconds}ms');
      print('   Photo ID: $photoId');
      print('');

      // ═══════════════════════════════════════════════════════════════
      // STEP 6: PREPARE ORDER DATA
      // ═══════════════════════════════════════════════════════════════
      print('┌─────────────────────────────────────────────────────────────┐');
      print('│ STEP 6: Preparing order data                               │');
      print('└─────────────────────────────────────────────────────────────┘');

      final orderItems = <Map<String, dynamic>>[];
      print('   Order items:');
      for (var entry in _cart.entries) {
        final itemId = entry.key;
        final quantity = entry.value;
        final item = _menuItems.firstWhere((i) => i.id == itemId);
        final itemChangesList = _itemChanges[itemId];

        // Use calculated price if item was changed (base price + difference)
        // Otherwise use base price
        final actualPrice =
            _itemPrices[itemId] ?? (item.inventoryPriceList?.price ?? 0);

        if (itemChangesList != null && itemChangesList.isNotEmpty) {
          final changedNames = itemChangesList
              .map((c) => c.changedItem.name)
              .join(', ');
          print(
            '   - ${item.name} (changed to: $changedNames): qty=$quantity, actual_price=$actualPrice UZS (base: ${item.inventoryPriceList?.price ?? 0} + difference)',
          );
        } else {
          print(
            '   - ${item.name}: qty=$quantity, actual_price=$actualPrice UZS',
          );
        }

        // Build product object with changeableContains.actual if item was changed
        Map<String, dynamic> productData = item.toJson();

        if (itemChangesList != null &&
            itemChangesList.isNotEmpty &&
            item.hasChangeableItems) {
          // Update product price to include all differences
          if (productData['inventoryPriceList'] != null) {
            productData['inventoryPriceList']['price'] = actualPrice;
          }

          // Build changeableContains.actual array matching website structure
          // Populate all tab indices where items were selected
          final defaultItems = item.changeableContains?.defaultItems ?? [];
          Map<String, dynamic> actualArray = {};

          // Initialize all indices as null
          for (int i = 0; i < defaultItems.length; i++) {
            actualArray[i.toString()] = null;
          }

          // Populate changed items at their respective tab indices
          for (var change in itemChangesList) {
            actualArray[change.tabIndex.toString()] = change.changedItem
                .toJson();
          }

          // Update changeableContains structure
          if (productData['changeableContains'] == null) {
            productData['changeableContains'] = {};
          }
          productData['changeableContains']['actual'] = actualArray;
          productData['changeableContains']['status'] = 1;
        } else {
          // Remove changeableContains for items without changes (like pizza products)
          // to prevent API error about missing 'status' field
          productData.remove('changeableContains');
        }

        final orderItem = {
          'product_id': item.id.toString(),
          'product': productData,
          'quantity': quantity,
          'actual_price': actualPrice.toString(),
        };

        // Add comment/note if exists (matching website behavior)
        final comment = _itemComments[itemId];
        if (comment != null && comment.isNotEmpty) {
          orderItem['note'] = comment;
        }

        orderItems.add(orderItem);
      }

      final employeeId = _authManager.currentEmployeeId;
      final branchId = _authManager.currentIdentity?.employee?.branchId;
      final totalValue = _getCartTotal();

      print('');
      print('   Employee ID: $employeeId');
      print('   Branch ID: $branchId');
      print('   Break Photo ID: $photoId');
      print('   Total Value: $totalValue UZS');

      if (employeeId == null || branchId == null) {
        print('❌ Missing employee or branch information');
        throw Exception('Employee or branch information not available');
      }
      print('✅ Order data prepared');
      print('');

      // ═══════════════════════════════════════════════════════════════
      // STEP 7: CREATE BREAK ORDER
      // ═══════════════════════════════════════════════════════════════
      print('┌─────────────────────────────────────────────────────────────┐');
      print('│ STEP 7: Creating break order                               │');
      print('└─────────────────────────────────────────────────────────────┘');
      print('   Endpoint: POST /v1/order');

      final step7Start = DateTime.now();
      final orderResult = await _authManager.apiService.createBreakOrder(
        branchId: branchId,
        breakEmployeeId: employeeId,
        breakPhotoId: photoId,
        employeeId: employeeId,
        orderItems: orderItems,
        totalValue: totalValue,
      );
      final step7Duration = DateTime.now().difference(step7Start);

      if (orderResult == null) {
        print('❌ Order creation failed');
        throw Exception('Failed to create break order');
      }

      print('✅ Order created in ${step7Duration.inMilliseconds}ms');
      print('   Order response: $orderResult');
      print('');

      // ═══════════════════════════════════════════════════════════════
      // SUCCESS
      // ═══════════════════════════════════════════════════════════════
      final totalDuration = DateTime.now().difference(startTime);
      print('╔══════════════════════════════════════════════════════════════╗');
      print('║           ✅ ORDER SUBMISSION COMPLETED                      ║');
      print('╚══════════════════════════════════════════════════════════════╝');
      print('⏱️ Total duration: ${totalDuration.inMilliseconds}ms');
      print('');

      setState(() {
        _cart.clear();
        _itemChanges.clear();
        _itemPrices.clear();
        _itemComments.clear();
        _hasOrderedToday =
            true; // Mark as ordered today to prevent duplicate orders
      });

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => SuccessDialog(
            title: 'Order Placed Successfully!',
            message:
                'Your break order has been submitted and is being processed.',
            totalAmount: totalValue,
            itemCount: _getCartItemCount(),
          ),
        );
      }
    } catch (e, stackTrace) {
      final totalDuration = DateTime.now().difference(startTime);
      print('');
      print('╔══════════════════════════════════════════════════════════════╗');
      print('║           ❌ ORDER SUBMISSION FAILED                         ║');
      print('╚══════════════════════════════════════════════════════════════╝');
      print('⏱️ Failed after: ${totalDuration.inMilliseconds}ms');
      print('❌ Error: $e');
      print('📋 Stack trace:');
      print(stackTrace);
      print('');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingOrder = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final buildStart = DateTime.now();
    print(
      '🎨 [BREAK PAGE] Build started - isLoading: $_isLoading, items: ${_menuItems.length}, categories: ${_categories.length}',
    );

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final widget = Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(theme, isDark),
                Expanded(
                  child: _isLoading
                      ? _buildSkeletonLoader(theme, isDark)
                      : _errorMessage != null
                      ? _buildErrorState(theme)
                      : _buildMenuGrid(theme, isDark),
                ),
                if (!_isLoading && _categories.isNotEmpty)
                  _buildCategoryFooter(theme, isDark),
                if (_cart.isNotEmpty) _buildCartFooter(theme, isDark),
              ],
            ),
            // Show subtle refresh indicator when updating in background
            if (_isRefreshing)
              Positioned(
                top: 80.h,
                right: 20.w,
                child: _buildRefreshIndicator(theme),
              ),
            // Show loading overlay for first-time load
            if (_isLoading && _menuItems.isEmpty)
              _buildLoadingOverlay(theme, isDark),
          ],
        ),
      ),
    );

    final buildDuration = DateTime.now().difference(buildStart);
    print(
      '🎨 [BREAK PAGE] Build completed in ${buildDuration.inMilliseconds}ms',
    );

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
                decoration: BoxDecoration(
                  color: AppColors.cxWhite.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: AppColors.cxWhite.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: IconButton(
                  onPressed: _isLoading
                      ? null
                      : () => _fetchMenuItems(forceRefresh: true),
                  icon: _isLoading
                      ? SizedBox(
                          width: 24.sp,
                          height: 24.sp,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.cxWhite,
                            ),
                          ),
                        )
                      : Icon(
                          Icons.refresh_rounded,
                          color: AppColors.cxWhite,
                          size: 24.sp,
                        ),
                  tooltip: 'Refresh Menu',
                ),
              ),
              if (_cart.isNotEmpty) ...[
                SizedBox(width: 8.w),
                GestureDetector(
                  onTap: _showCartDialog,
                  child: Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: AppColors.cxWhite.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: AppColors.cxWhite.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(
                          Icons.shopping_cart_rounded,
                          color: AppColors.cxWhite,
                          size: 24.sp,
                        ),
                        Positioned(
                          top: -6.h,
                          right: -6.w,
                          child: Container(
                            padding: EdgeInsets.all(4.w),
                            decoration: BoxDecoration(
                              color: AppColors.cxWarning,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.cxWhite,
                                width: 2,
                              ),
                            ),
                            constraints: BoxConstraints(
                              minWidth: 20.w,
                              minHeight: 20.w,
                            ),
                            child: Center(
                              child: Text(
                                '${_getCartItemCount()}',
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.cxWhite,
                                  height: 1,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              SizedBox(width: 8.w),
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
        ? _menuItems
              .where((item) => item.posCategoryId == _selectedCategoryId)
              .toList()
        : [];
    final filterDuration = DateTime.now().difference(filterStart);
    print(
      '🔍 [BREAK PAGE] Filtering items for category $_selectedCategoryId took: ${filterDuration.inMilliseconds}ms (found ${categoryItems.length} items)',
    );

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

    print(
      '📋 [BREAK PAGE] Building GridView with ${categoryItems.length} items',
    );
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
    final itemChangesList = _itemChanges[item.id];
    final hasChanges = itemChangesList != null && itemChangesList.isNotEmpty;

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
                          cacheWidth:
                              300, // Cache smaller version for better performance
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value:
                                    loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                    : null,
                                strokeWidth: 2,
                                color: AppColors.cxWarning,
                              ),
                            );
                          },
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
              if (item.hasChangeableItems)
                Positioned(
                  top: 8.h,
                  right: 8.w,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF6366F1),
                          const Color(0xFF8B5CF6),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(8.r),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.cxBlack.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.swap_horiz_rounded,
                          size: 12.sp,
                          color: AppColors.cxWhite,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          'Change',
                          style: TextStyle(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.cxWhite,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
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
                    maxLines: hasChanges ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (hasChanges) ...[
                    ...itemChangesList
                        .map(
                          (change) => Container(
                            margin: EdgeInsets.only(top: 4.h),
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
                                    change.changedItem.name,
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
                        )
                        .toList(),
                  ],
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
                          onTap: () => _handleProductClick(item),
                          child: Container(
                            padding: EdgeInsets.all(8.w),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.cxWarning,
                                  AppColors.cxFEDA84,
                                ],
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
                                    colors: [
                                      AppColors.cxWarning,
                                      AppColors.cxFEDA84,
                                    ],
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
                    ? (isDark
                          ? const Color(0xFF6366F1)
                          : const Color(0xFF0071E3))
                    : theme.colorScheme.surfaceVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: isSelected
                      ? (isDark
                            ? const Color(0xFF6366F1)
                            : const Color(0xFF0071E3))
                      : theme.colorScheme.outline.withOpacity(0.2),
                  width: isSelected ? 1.5 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color:
                              (isDark
                                      ? const Color(0xFF6366F1)
                                      : const Color(0xFF0071E3))
                                  .withOpacity(0.3),
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
                    padding: EdgeInsets.symmetric(
                      horizontal: 6.w,
                      vertical: 1.h,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.cxWhite.withOpacity(0.3)
                          : (isDark
                                    ? const Color(0xFF6366F1)
                                    : const Color(0xFF0071E3))
                                .withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Text(
                      '$itemCount',
                      style: TextStyle(
                        fontSize: 9.sp,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? AppColors.cxWhite
                            : (isDark
                                  ? const Color(0xFF6366F1)
                                  : const Color(0xFF0071E3)),
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
    final canOrder =
        _isWithinOrderTime() && !_hasOrderedToday && !_isCheckingDailyOrder;

    // Determine restriction message
    String? restrictionMessage;
    if (_isCheckingDailyOrder) {
      restrictionMessage = null; // Still checking
    } else if (_hasOrderedToday) {
      restrictionMessage = 'Already ordered today';
    } else if (!_isWithinOrderTime()) {
      restrictionMessage = 'Outside order hours';
    }

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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (restrictionMessage != null)
            Container(
              width: double.infinity,
              margin: EdgeInsets.only(bottom: 12.h),
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(
                  color: Colors.orange.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    color: Colors.orange,
                    size: 18.sp,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      restrictionMessage,
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Row(
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
                        color: isDark
                            ? const Color(0xFF6366F1)
                            : const Color(0xFF0071E3),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: GestureDetector(
                  onTap: (_isSubmittingOrder || !canOrder)
                      ? null
                      : _handleOrderSubmission,
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: canOrder
                            ? (isDark
                                  ? [
                                      const Color(0xFF6366F1),
                                      const Color(0xFF8B5CF6),
                                    ]
                                  : [
                                      const Color(0xFF0071E3),
                                      const Color(0xFF5E5CE6),
                                    ])
                            : [Colors.grey.shade400, Colors.grey.shade500],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16.r),
                      boxShadow: canOrder
                          ? [
                              BoxShadow(
                                color:
                                    (isDark
                                            ? const Color(0xFF6366F1)
                                            : const Color(0xFF0071E3))
                                        .withOpacity(0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ]
                          : null,
                    ),
                    child: _isSubmittingOrder
                        ? Center(
                            child: SizedBox(
                              height: 24.h,
                              width: 24.w,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.cxWhite,
                                ),
                              ),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                canOrder
                                    ? Icons.shopping_cart_checkout_rounded
                                    : Icons.lock_outline_rounded,
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
                      AppColors.cxPlatinumGray.withOpacity(
                        _shimmerAnimation.value,
                      ),
                      AppColors.cxSilverTint.withOpacity(
                        _shimmerAnimation.value * 0.5,
                      ),
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
                        color: AppColors.cxPlatinumGray.withOpacity(
                          _shimmerAnimation.value,
                        ),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Container(
                      width: 60.w,
                      height: 12.h,
                      decoration: BoxDecoration(
                        color: AppColors.cxPlatinumGray.withOpacity(
                          _shimmerAnimation.value,
                        ),
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
          Icon(Icons.error_outline, size: 64.sp, color: AppColors.cxWarning),
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

  Widget _buildLoadingOverlay(ThemeData theme, bool isDark) {
    return Container(
      color: theme.scaffoldBackgroundColor.withOpacity(0.95),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(32.w),
              decoration: BoxDecoration(
                color: isDark ? theme.colorScheme.surface : AppColors.cxWhite,
                borderRadius: BorderRadius.circular(24.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.4 : 0.1),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [const Color(0xFF6366F1), const Color(0xFF8B5CF6)]
                            : [
                                const Color(0xFF0071E3),
                                const Color(0xFF5E5CE6),
                              ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.restaurant_menu_rounded,
                      size: 48.sp,
                      color: AppColors.cxWhite,
                    ),
                  ),
                  SizedBox(height: 24.h),
                  SizedBox(
                    width: 40.w,
                    height: 40.w,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isDark
                            ? const Color(0xFF6366F1)
                            : const Color(0xFF0071E3),
                      ),
                    ),
                  ),
                  SizedBox(height: 24.h),
                  Text(
                    _loadingMessage,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'This may take up to a minute',
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRefreshIndicator(ThemeData theme) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: AppColors.cxWhite,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16.w,
            height: 16.w,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                const Color(0xFF0071E3),
              ),
            ),
          ),
          SizedBox(width: 10.w),
          Text(
            'Updating menu...',
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0071E3),
            ),
          ),
        ],
      ),
    );
  }
}
