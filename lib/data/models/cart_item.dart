import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

import '../../../data/models/color_data_model.dart';
import '../../../data/models/parent_product_model.dart';
import '../../../data/models/product_model.dart';
import '../../features/quotes/presentation/quote_calculator.dart';

/// Đại diện cho một sản phẩm trong giỏ hàng.
class CartItem extends Equatable {
  /// ID duy nhất cho mỗi mục trong giỏ hàng, được tạo tự động.
  final String id;
  final Product sku;
  final ParentProduct? parentProduct;
  final ColorData color;
  final QuotePriceDetails priceDetails;
  final int quantity;

  CartItem({
    String? id,
    required this.sku,
    this.parentProduct,
    required this.color,
    required this.priceDetails,
    this.quantity = 1,
  }) : id = id ?? const Uuid().v4(); // Tự động tạo ID nếu không được cung cấp.

  @override
  List<Object?> get props => [id, sku, parentProduct, color, quantity];

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'] as String,
      sku: Product.fromJson(json['sku'] as Map<String, dynamic>),
      parentProduct: json['parentProduct'] != null
          ? ParentProduct.fromJson(
              json['parentProduct'] as Map<String, dynamic>,
            )
          : null,
      color: ColorData.fromJson(json['color'] as Map<String, dynamic>),
      priceDetails: (
        basePrice: (json['priceDetails']['basePrice'] as num).toDouble(),
        colorPrice: (json['priceDetails']['colorPrice'] as num).toDouble(),
        finalPrice: (json['priceDetails']['finalPrice'] as num).toDouble(),
      ),
      quantity: json['quantity'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sku': sku.toJson(),
      'parentProduct': parentProduct?.toJson(),
      'color': color.toJson(),
      'priceDetails': {
        'basePrice': priceDetails.basePrice,
        'colorPrice': priceDetails.colorPrice,
        'finalPrice': priceDetails.finalPrice,
      },
      'quantity': quantity,
    };
  }

  /// Tạo một bản sao của CartItem với các giá trị được cập nhật.
  CartItem copyWith({int? quantity}) {
    return CartItem(
      id: id,
      sku: sku,
      parentProduct: parentProduct,
      color: color,
      priceDetails: priceDetails,
      quantity: quantity ?? this.quantity,
    );
  }
}
