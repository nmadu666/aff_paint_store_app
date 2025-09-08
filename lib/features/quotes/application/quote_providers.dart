import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/color_data_model.dart';
import '../../../data/models/parent_product_model.dart';
import '../../../data/models/product_model.dart';
import '../../colors/application/color_providers.dart';
import '../presentation/quote_calculator.dart'
    show QuoteCalculator, QuotePriceDetails;

/// Một record để giữ tất cả các tham số cần thiết cho việc tính báo giá.
/// Việc sử dụng record giúp cho provider family trở nên sạch sẽ và dễ đọc hơn.
typedef QuoteCalculationParams = ({
  Product sku,
  ParentProduct parentProduct,
  ColorData color,
});

/// Provider cho instance của `QuoteCalculator`.
///
/// `QuoteCalculator` phụ thuộc vào `IColorRepository` để lấy thông tin giá màu,
/// vì vậy chúng ta inject `colorRepositoryProvider` vào đây.
final quoteCalculatorProvider = Provider<QuoteCalculator>((ref) {
  final colorRepository = ref.watch(colorRepositoryProvider);
  return QuoteCalculator(colorRepository);
});

/// Provider để tính toán giá cuối cùng của sản phẩm sơn pha màu.
///
/// Đây là một `FutureProvider` vì việc tính toán bao gồm một lệnh gọi bất đồng bộ
/// đến repository để lấy `ColorPricing`.
/// `.family` cho phép chúng ta truyền vào các tham số cần thiết.
/// `.autoDispose` đảm bảo trạng thái của provider sẽ được dọn dẹp khi không còn được sử dụng.
final finalPriceProvider = FutureProvider.autoDispose
    .family<QuotePriceDetails, QuoteCalculationParams>((ref, params) async {
      final calculator = ref.watch(quoteCalculatorProvider);
      return calculator.calculateMixedPaintPrice(
        sku: params.sku,
        parentProduct: params.parentProduct,
        color: params.color,
      );
    });
