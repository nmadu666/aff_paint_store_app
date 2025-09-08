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
  final ParentProduct parentProduct;
  final ColorData color;
  final QuotePriceDetails priceDetails;
  final int quantity;

  CartItem({
    String? id,
    required this.sku,
    required this.parentProduct,
    required this.color,
    required this.priceDetails,
    this.quantity = 1,
  }) : id = id ?? const Uuid().v4(); // Tự động tạo ID nếu không được cung cấp.

  @override
  List<Object?> get props => [id, sku, parentProduct, color, quantity];

  /// Tạo một bản sao của CartItem với các giá trị được cập nhật.
  CartItem copyWith({
    int? quantity,
  }) {
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

