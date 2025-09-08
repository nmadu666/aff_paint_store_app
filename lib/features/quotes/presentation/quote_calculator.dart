import 'dart:math';
import '../../../data/models/color_data_model.dart';
import '../../../data/models/parent_product_model.dart';
import '../../../data/models/product_model.dart';
import '../../../data/repositories/color_repository.dart';

/// Một record chứa chi tiết các thành phần giá.
typedef QuotePriceDetails = ({
  double basePrice,
  double colorPrice,
  double finalPrice,
});

class QuoteCalculator {
  final IColorRepository _colorRepository;

  QuoteCalculator(this._colorRepository);

  /// Tính toán giá cuối cùng cho một sản phẩm sơn pha màu.
  ///
  /// [sku]: Sản phẩm cụ thể được chọn (ví dụ: Lon 5L - Gốc A).
  /// [parentProduct]: Sản phẩm cha của SKU (ví dụ: Mykolor Semigloss Finish).
  /// [color]: Màu được chọn.
  Future<QuotePriceDetails> calculateMixedPaintPrice({
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

    // e. Tính giá cuối cùng với logic nghiệp vụ phức tạp.

    // e.1. Xác định hệ số markup dựa trên điều kiện nghiệp vụ.
    // Điều kiện: Nếu (dung tích * giá/ml) > 500, dùng hệ số thấp hơn.
    final double markupFactor;
    if ((unitValue * pricePerMl) > 500) {
      markupFactor = 1150;
    } else {
      markupFactor = 1200; // Mặc định
    }

    // e.2. Tính giá màu sau khi đã áp dụng markup.
    // Công thức: (giá/ml) * (dung tích L) * (hệ số)
    final calculatedColorPrice = pricePerMl * unitValue * markupFactor;

    // e.3. Xác định giá màu tối thiểu dựa trên dung tích lon sơn.
    // Điều này đảm bảo lợi nhuận tối thiểu cho các lon sơn nhỏ.
    double minimumColorPrice = 0;
    if (unitValue < 3) {
      minimumColorPrice = 10000;
    } else if (unitValue < 7) {
      minimumColorPrice = 20000;
    } else if (unitValue < 20) {
      // Áp dụng cho các lon từ 7L đến dưới 20L
      minimumColorPrice = 30000;
    }

    // e.4. Giá màu cuối cùng là giá lớn hơn giữa giá tính toán và giá tối thiểu.
    final finalColorPrice = max(calculatedColorPrice, minimumColorPrice);

    // e.5. Giá thành phẩm = Giá gốc lon sơn + Giá màu cuối cùng.
    final finalPrice = basePrice + finalColorPrice;

    return (
      basePrice: basePrice,
      colorPrice: finalColorPrice,
      finalPrice: finalPrice,
    );
  }
}
