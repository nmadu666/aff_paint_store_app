import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class ParentProduct extends Equatable {
  final String id;
  final String name;

  /// Tên danh mục. Đây là một chuỗi giá trị độc lập và không liên kết với collection 'categories'.
  final String category;

  /// ID của document trong collection 'trademarks'. Dùng để liên kết.
  final String trademarkRef;

  /// Một chuỗi giống enum đại diện cho loại sản phẩm để tính toán pha màu (ví dụ: "int_1", "ext_1").
  final String colorMixingProductType;

  const ParentProduct({
    required this.id,
    required this.name,
    required this.category,
    required this.trademarkRef,
    required this.colorMixingProductType,
  });

  factory ParentProduct.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data();
    if (data == null) {
      throw "Dữ liệu ParentProduct không tồn tại từ snapshot: ${snapshot.id}";
    }

    // Hàm tiện ích để lấy một trường chuỗi bắt buộc hoặc ném ra lỗi chi tiết.
    String _getRequiredString(String key) {
      final value = data[key];
      if (value == null || value is! String || value.isEmpty) {
        throw FormatException(
          'Trường "$key" bị thiếu hoặc không hợp lệ trong tài liệu ParentProduct: ${snapshot.id}',
        );
      }
      return value;
    }

    return ParentProduct(
      id: snapshot.id,
      name: _getRequiredString('name'),
      // 'category' là một trường độc lập, có thể là rỗng.
      category: data['category'] as String? ?? '',
      trademarkRef: _getRequiredString('trademark_ref'),
      colorMixingProductType: _getRequiredString('color_mixing_product_type'),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'category': category,
      'trademark_ref': trademarkRef,
      'color_mixing_product_type': colorMixingProductType,
    };
  }

  @override
  List<Object?> get props => [
        id,
        name,
        category,
        trademarkRef,
        colorMixingProductType,
      ];
}
