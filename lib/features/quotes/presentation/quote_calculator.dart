import '../../../data/models/color_data_model.dart';
import '../../../data/models/parent_product_model.dart';
import '../../../data/models/product_model.dart';
import '../../../data/repositories/color_repository.dart';

class QuoteCalculator {
  final IColorRepository _colorRepository;

  QuoteCalculator(this._colorRepository);

  /// Tính toán giá cuối cùng cho một sản phẩm sơn pha màu.
  ///
  /// [sku]: Sản phẩm cụ thể được chọn (ví dụ: Lon 5L - Gốc A).
  /// [parentProduct]: Sản phẩm cha của SKU (ví dụ: Mykolor Semigloss Finish).
  /// [color]: Màu được chọn.
  Future<double> calculateMixedPaintPrice({
    required Product sku,
    required ParentProduct parentProduct,
    required ColorData color,
  }) async {
    // a. Lấy và xác thực các giá trị cần thiết từ SKU.
    final basePrice = sku.basePrice;
    if (basePrice == null) {
      throw Exception(
        'Sản phẩm "${sku.name}" thiếu thông tin giá gốc (basePrice). Không thể tính toán.',
      );
    }

    final base = sku.base;
    if (base == null || base.isEmpty) {
      throw Exception(
        'Sản phẩm "${sku.name}" thiếu thông tin loại gốc (base). Không thể tính toán.',
      );
    }

    final unitValue = sku.unitValue;
    if (unitValue == null || unitValue <= 0) {
      throw Exception(
        'Sản phẩm "${sku.name}" thiếu thông tin dung tích (unitValue). Không thể tính toán.',
      );
    }

    // b. Lấy color_mixing_product_type.
    final colorMixingProductType = parentProduct.colorMixingProductType;

    // c. Truy vấn sub-collection color_pricings.
    final colorPricing = await _colorRepository.getColorPricing(
      colorId: color.id,
      colorMixingProductType: colorMixingProductType,
      base: base, // `base` đã được xác thực là không null.
    );

    if (colorPricing == null) {
      // Xử lý trường hợp không tìm thấy giá pha màu phù hợp.
      throw Exception(
        'Không tìm thấy bảng giá pha màu phù hợp cho màu "${color.name}" và sản phẩm "${parentProduct.name}" (Gốc $base).',
      );
    }

    // d. Lấy pricePerMl.
    final pricePerMl = colorPricing.pricePerMl;

    // e. Tính giá cuối cùng.
    // Các giá trị đã được xác thực là không null ở trên.
    final finalPrice = basePrice + (pricePerMl * unitValue * 1000);

    return finalPrice;
  }
}
