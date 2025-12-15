class InventoryItem {
  final int id;
  final String name;
  final int? inventoryGroupId;
  final int? posCategoryId;
  final int? photoId;
  final InventoryGroup? inventoryGroup;
  final InventoryPhoto? photo;
  final InventoryPriceItem? inventoryPriceList;
  final ChangeableContains? changeableContains;
  final List<ChangeableCategory> changeableCategories;

  InventoryItem({
    required this.id,
    required this.name,
    this.inventoryGroupId,
    this.posCategoryId,
    this.photoId,
    this.inventoryGroup,
    this.photo,
    this.inventoryPriceList,
    this.changeableContains,
    this.changeableCategories = const [],
  });

  bool get hasChangeableItems =>
      changeableContains != null && changeableContains!.defaultItems.isNotEmpty;

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    final categoriesList = json['changeableCategories'] as List<dynamic>? ?? [];
    return InventoryItem(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      inventoryGroupId: json['inventory_group_id'],
      posCategoryId: json['pos_category_id'],
      photoId: json['photo_id'],
      inventoryGroup: json['inventoryGroup'] != null
          ? InventoryGroup.fromJson(json['inventoryGroup'])
          : null,
      photo: json['photo'] != null
          ? InventoryPhoto.fromJson(json['photo'])
          : null,
      inventoryPriceList: json['inventoryPriceList'] != null
          ? InventoryPriceItem.fromJson(json['inventoryPriceList'])
          : null,
      changeableContains: json['changeableContains'] != null
          ? ChangeableContains.fromJson(json['changeableContains'])
          : null,
      changeableCategories: categoriesList
          .map((item) => ChangeableCategory.fromJson(item))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'inventory_group_id': inventoryGroupId,
      'pos_category_id': posCategoryId,
      'photo_id': photoId,
      'inventoryGroup': inventoryGroup?.toJson(),
      'photo': photo?.toJson(),
      'inventoryPriceList': inventoryPriceList?.toJson(),
      'changeableContains': changeableContains?.toJson(),
      'changeableCategories': changeableCategories
          .map((item) => item.toJson())
          .toList(),
    };
  }
}

class ChangeableContains {
  final List<ChangeableItem> defaultItems;
  final List<ChangeableCategory> changeableCategories;

  ChangeableContains({
    required this.defaultItems,
    required this.changeableCategories,
  });

  factory ChangeableContains.fromJson(Map<String, dynamic> json) {
    print('🔍 [MODEL] ChangeableContains.fromJson keys: ${json.keys.toList()}');
    final defaultList = json['default'] as List<dynamic>? ?? [];
    final categoriesList = json['changeableCategories'] as List<dynamic>? ?? [];
    print(
      '🔍 [MODEL] default items: ${defaultList.length}, changeableCategories: ${categoriesList.length}',
    );
    return ChangeableContains(
      defaultItems: defaultList
          .map((item) => ChangeableItem.fromJson(item))
          .toList(),
      changeableCategories: categoriesList
          .map((item) => ChangeableCategory.fromJson(item))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'default': defaultItems.map((item) => item.toJson()).toList(),
      'changeableCategories': changeableCategories
          .map((item) => item.toJson())
          .toList(),
    };
  }
}

class ChangeableCategory {
  final int id;
  final int inventoryId;
  final int posCategoryId;
  final String? createdAt;
  final PosCategory? posCategory;

  ChangeableCategory({
    required this.id,
    required this.inventoryId,
    required this.posCategoryId,
    this.createdAt,
    this.posCategory,
  });

  factory ChangeableCategory.fromJson(Map<String, dynamic> json) {
    return ChangeableCategory(
      id: json['id'] ?? 0,
      inventoryId: json['inventory_id'] ?? 0,
      posCategoryId: json['pos_category_id'] ?? 0,
      createdAt: json['created_at'],
      posCategory: json['posCategory'] != null
          ? PosCategory.fromJson(json['posCategory'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'inventory_id': inventoryId,
      'pos_category_id': posCategoryId,
      'created_at': createdAt,
      'posCategory': posCategory?.toJson(),
    };
  }
}

class ChangeableItem {
  final int id;
  final String name;
  final int? photoId;
  final int? posCategoryId;
  final InventoryPhoto? photo;
  final InventoryPriceItem? inventoryPriceList;
  final String? description;
  final List<ChangeableCategory> changeableCategories;

  ChangeableItem({
    required this.id,
    required this.name,
    this.photoId,
    this.posCategoryId,
    this.photo,
    this.inventoryPriceList,
    this.description,
    this.changeableCategories = const [],
  });

  factory ChangeableItem.fromJson(Map<String, dynamic> json) {
    final categoriesList = json['changeableCategories'] as List<dynamic>? ?? [];
    return ChangeableItem(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      photoId: json['photo_id'],
      posCategoryId: json['pos_category_id'],
      photo: json['photo'] != null
          ? InventoryPhoto.fromJson(json['photo'])
          : null,
      inventoryPriceList: json['inventoryPriceList'] != null
          ? InventoryPriceItem.fromJson(json['inventoryPriceList'])
          : null,
      description: json['description'],
      changeableCategories: categoriesList
          .map((item) => ChangeableCategory.fromJson(item))
          .toList(),
    );
  }

  String? get imageUrl {
    if (photo != null) {
      return photo!.url;
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'photo_id': photoId,
      'pos_category_id': posCategoryId,
      'photo': photo?.toJson(),
      'inventoryPriceList': inventoryPriceList?.toJson(),
      'description': description,
      'changeableCategories': changeableCategories
          .map((item) => item.toJson())
          .toList(),
    };
  }
}

class InventoryGroup {
  final int id;
  final String name;
  final String createdAt;

  InventoryGroup({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  factory InventoryGroup.fromJson(Map<String, dynamic> json) {
    return InventoryGroup(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      createdAt: json['created_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'created_at': createdAt};
  }
}

class InventoryPhoto {
  final int id;
  final String path;
  final String? thumbnail;
  final String name;
  final String format;

  InventoryPhoto({
    required this.id,
    required this.path,
    this.thumbnail,
    required this.name,
    required this.format,
  });

  factory InventoryPhoto.fromJson(Map<String, dynamic> json) {
    return InventoryPhoto(
      id: json['id'] ?? 0,
      path: json['path'] ?? '',
      thumbnail: json['thumbnail'],
      name: json['name'] ?? '',
      format: json['format'] ?? '',
    );
  }

  String? get url {
    if (path.isNotEmpty && name.isNotEmpty && format.isNotEmpty) {
      return 'https://sieveserp.ams3.cdn.digitaloceanspaces.com/$path/$name.$format';
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'path': path,
      'thumbnail': thumbnail,
      'name': name,
      'format': format,
    };
  }
}

class InventoryPriceItem {
  final int id;
  final int inventoryId;
  final int price;
  final int? branchId;

  InventoryPriceItem({
    required this.id,
    required this.inventoryId,
    required this.price,
    this.branchId,
  });

  factory InventoryPriceItem.fromJson(Map<String, dynamic> json) {
    return InventoryPriceItem(
      id: json['id'] ?? 0,
      inventoryId: json['inventory_id'] ?? 0,
      price: json['price'] ?? 0,
      branchId: json['branch_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'inventory_id': inventoryId,
      'price': price,
      'branch_id': branchId,
    };
  }
}

class PosCategory {
  final int id;
  final String name;
  final String? icon;
  final int? photoId;
  final String index;

  PosCategory({
    required this.id,
    required this.name,
    this.icon,
    this.photoId,
    required this.index,
  });

  factory PosCategory.fromJson(Map<String, dynamic> json) {
    return PosCategory(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      icon: json['icon'],
      photoId: json['photo_id'],
      index: json['index'] ?? '0',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'photo_id': photoId,
      'index': index,
    };
  }
}

class PosActiveCategory {
  final int id;
  final int posId;
  final int posCategoryId;
  final PosCategory? posCategory;

  PosActiveCategory({
    required this.id,
    required this.posId,
    required this.posCategoryId,
    this.posCategory,
  });

  factory PosActiveCategory.fromJson(Map<String, dynamic> json) {
    return PosActiveCategory(
      id: json['id'] ?? 0,
      posId: json['pos_id'] ?? 0,
      posCategoryId: json['pos_category_id'] ?? 0,
      posCategory: json['posCategory'] != null
          ? PosCategory.fromJson(json['posCategory'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pos_id': posId,
      'pos_category_id': posCategoryId,
      'posCategory': posCategory?.toJson(),
    };
  }
}
