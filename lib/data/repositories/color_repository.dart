import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/color_pricing_model.dart';

/// Lớp trừu tượng định nghĩa các phương thức cần có để lấy dữ liệu màu sắc.
abstract class IColorRepository {
  Future<ColorPricing?> getColorPricing({
    required String colorId,
    required String colorMixingProductType,
    required String base,
  });
  // Thêm các phương thức khác ở đây, ví dụ:
  // Future<List<ColorData>> getAllColors();
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
}
