import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/color_pricing_model.dart';
import '../models/color_data_model.dart';

/// Lớp trừu tượng định nghĩa các phương thức cần có để lấy dữ liệu màu sắc.
abstract class IColorRepository {
  Future<ColorPricing?> getColorPricing({
    required String colorId,
    required String colorMixingProductType,
    required String base,
  });

  /// Lấy danh sách các đối tượng ColorData dựa trên danh sách ID.
  Future<List<ColorData>> getColorsByIds(List<String> colorIds);

  /// Lấy danh sách các loại gốc sơn ('A', 'B'...) có sẵn cho một màu và một loại sản phẩm.
  Future<List<String>> getAvailableBasesForColor({
    required String colorId,
    required String colorMixingProductType,
  });
}

/// Triển khai repository sử dụng Firebase Firestore.
class FirebaseColorRepository implements IColorRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<ColorPricing?> getColorPricing({
    required String colorId,
    required String colorMixingProductType,
    required String base,
  }) async {
    final querySnapshot = await _firestore
        .collection('colors')
        .doc(colorId)
        .collection('color_pricings')
        .where('color_mixing_product_type', isEqualTo: colorMixingProductType)
        .where('base', isEqualTo: base)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      return ColorPricing.fromFirestore(querySnapshot.docs.first);
    }

    return null;
  }

  @override
  Future<List<ColorData>> getColorsByIds(List<String> colorIds) async {
    if (colorIds.isEmpty) {
      return [];
    }

    final List<ColorData> allColors = [];
    const chunkSize = 30; // Giới hạn của truy vấn 'whereIn' trong Firestore

    for (var i = 0; i < colorIds.length; i += chunkSize) {
      final chunk = colorIds.sublist(
        i,
        i + chunkSize > colorIds.length ? colorIds.length : i + chunkSize,
      );

      final snapshot = await _firestore
          .collection('colors')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();

      allColors.addAll(
        snapshot.docs
            .map(
              (doc) => ColorData.fromFirestore(
                doc as DocumentSnapshot<Map<String, dynamic>>,
              ),
            )
            .toList(),
      );
    }

    return allColors;
  }

  @override
  Future<List<String>> getAvailableBasesForColor({
    required String colorId,
    required String colorMixingProductType,
  }) async {
    print(
      '🔍 [ColorRepo] Lấy các gốc sơn có sẵn cho colorId=$colorId, productType=$colorMixingProductType',
    );
    final snapshot = await _firestore
        .collection('colors')
        .doc(colorId)
        .collection('color_pricings')
        .where('color_mixing_product_type', isEqualTo: colorMixingProductType)
        .get();

    if (snapshot.docs.isEmpty) {
      print(
        'ℹ️ [ColorRepo] Không tìm thấy thông tin giá nào, trả về danh sách gốc sơn rỗng.',
      );
      return [];
    }

    // Lấy danh sách các gốc sơn và loại bỏ các giá trị trùng lặp.
    final bases = snapshot.docs
        .map((doc) => doc.data()['base'] as String?)
        .whereType<String>() // Lọc bỏ null và chỉ giữ lại String
        .toSet() // Sử dụng Set để tự động loại bỏ các giá trị trùng lặp
        .toList();

    print('✅ [ColorRepo] Các gốc sơn tìm thấy: $bases');
    return bases;
  }
}
