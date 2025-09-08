import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a product, with data synced from KiotViet and custom fields for the app.
/// This model is designed to be compatible with the data structure from the AdminPanel Appsheet sync script.
class Product {
  // --- Firestore Document ID ---
  final String id;

  // --- Fields from KiotViet Sync ---
  final String code;
  final String name;
  final String? fullName;
  final String? barCode;
  final String? categoryId;
  final String? categoryName;
  final String? tradeMarkId;
  final String? tradeMarkName;
  final String? unit;
  final double? basePrice;
  final String? description;
  final double? weight;
  final bool hasVariants;
  final String inventoriesJson; // Storing as raw JSON string
  final List<String>? images;
  final DateTime? createdDate;
  final DateTime? modifiedDate;

  // --- Custom fields for this App ---
  final DocumentReference? parentProductRef;
  final String? base; // Loại gốc sơn (e.g., "A", "B", "C")
  final double? unitValue; // Dung tích (e.g., 1, 5, 18 Liters)

  Product({
    required this.id,
    required this.code,
    required this.name,
    this.fullName,
    this.barCode,
    this.categoryId,
    this.categoryName,
    this.tradeMarkId,
    this.tradeMarkName,
    this.unit,
    this.basePrice,
    this.description,
    this.weight,
    required this.hasVariants,
    required this.inventoriesJson,
    this.images,
    this.createdDate,
    this.modifiedDate,
    this.parentProductRef,
    this.base,
    this.unitValue,
  });

  /// A getter to safely decode the `inventoriesJson` string into a List.
  List<Map<String, dynamic>> get inventories {
    try {
      if (inventoriesJson.isEmpty) return [];
      final decoded = jsonDecode(inventoriesJson);
      return List<Map<String, dynamic>>.from(decoded);
    } catch (e) {
      // Log the error or handle it gracefully in a real app
      print('Error decoding inventories_json for product $id: $e');
      return [];
    }
  }

  factory Product.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data();
    if (data == null) {
      throw "Dữ liệu Product không tồn tại từ snapshot: ${snapshot.id}";
    }

    // Helper to safely parse a string into a DateTime object.
    DateTime? _parseDate(dynamic value) {
      if (value is String && value.isNotEmpty) {
        return DateTime.tryParse(value);
      }
      if (value is Timestamp) {
        return value.toDate();
      }
      return null;
    }

    // *** FIX ***
    // Helper to safely parse a dynamic value (which can be a String or a num) into a double.
    double? _parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null; // Return null for other unexpected types
    }

    // Helper to create a DocumentReference from a string path.
    DocumentReference? _parseRef(dynamic ref) {
      if (ref is DocumentReference) {
        return ref;
      }
      if (ref is String && ref.isNotEmpty) {
        return FirebaseFirestore.instance.doc(ref);
      }
      return null;
    }

    return Product(
      id: snapshot.id,
      code: data['code'] ?? '',
      name: data['name'] ?? '',
      fullName: data['fullName'],
      barCode: data['barCode'],
      categoryId: data['categoryId'],
      categoryName: data['categoryName'],
      tradeMarkId: data['tradeMarkId'],
      tradeMarkName: data['tradeMarkName'],
      unit: data['unit'],
      basePrice: _parseDouble(data['basePrice']),
      description: data['description'],
      weight: _parseDouble(data['weight']),
      hasVariants: data['hasVariants'] ?? false,
      inventoriesJson: data['inventories_json'] ?? '[]',
      images: data['images'] != null ? List<String>.from(data['images']) : null,
      createdDate: _parseDate(data['createdDate']),
      modifiedDate: _parseDate(data['modifiedDate']),

      // Custom fields with null-safety
      parentProductRef: _parseRef(data['parent_product_ref']),
      base: data['base'],
      unitValue: _parseDouble(data['unit_value']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      // KiotViet fields
      'id': id, // The script uses 'id' as the KiotViet ID column
      'kiot_id': id, // And also 'kiot_id'
      'code': code,
      'name': name,
      'fullName': fullName,
      'barCode': barCode,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'tradeMarkId': tradeMarkId,
      'tradeMarkName': tradeMarkName,
      'unit': unit,
      'basePrice': basePrice,
      'description': description,
      'weight': weight,
      'hasVariants': hasVariants,
      'inventories_json': inventoriesJson,
      'images': images,
      'createdDate': createdDate?.toIso8601String(),
      'modifiedDate': modifiedDate?.toIso8601String(),

      // Custom fields
      'parent_product_ref': parentProductRef?.path,
      'base': base,
      'unit_value': unitValue,
    };
  }

  Product copyWith({
    String? id,
    String? code,
    String? name,
    String? fullName,
    String? barCode,
    String? categoryId,
    String? categoryName,
    String? tradeMarkId,
    String? tradeMarkName,
    String? unit,
    double? basePrice,
    String? description,
    double? weight,
    bool? hasVariants,
    String? inventoriesJson,
    List<String>? images,
    DateTime? createdDate,
    DateTime? modifiedDate,
    DocumentReference? parentProductRef,
    String? base,
    double? unitValue,
  }) {
    return Product(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      fullName: fullName ?? this.fullName,
      barCode: barCode ?? this.barCode,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      tradeMarkId: tradeMarkId ?? this.tradeMarkId,
      tradeMarkName: tradeMarkName ?? this.tradeMarkName,
      unit: unit ?? this.unit,
      basePrice: basePrice ?? this.basePrice,
      description: description ?? this.description,
      weight: weight ?? this.weight,
      hasVariants: hasVariants ?? this.hasVariants,
      inventoriesJson: inventoriesJson ?? this.inventoriesJson,
      images: images ?? this.images,
      createdDate: createdDate ?? this.createdDate,
      modifiedDate: modifiedDate ?? this.modifiedDate,
      parentProductRef: parentProductRef ?? this.parentProductRef,
      base: base ?? this.base,
      unitValue: unitValue ?? this.unitValue,
    );
  }
}
