import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/color_collection_model.dart';
import '../../../data/models/color_data_model.dart';
import '../application/color_providers.dart';
import '../../products/presentation/sku_selection_page.dart';
import 'widgets/compatible_parent_product_list.dart';

/// Hàm tiện ích để chuyển đổi chuỗi hex thành đối tượng Color của Flutter.
Color _hexToColor(String hexCode) {
  final buffer = StringBuffer();
  if (hexCode.length == 6 || hexCode.length == 7) buffer.write('ff');
  buffer.write(hexCode.replaceFirst('#', ''));
  try {
    // Trả về màu từ mã hex.
    return Color(int.parse(buffer.toString(), radix: 16));
  } catch (e) {
    // Nếu có lỗi (ví dụ: mã hex không hợp lệ), trả về một màu mặc định.
    return Colors.grey;
  }
}

/// Một trang hiển thị chi tiết các màu trong một bộ sưu tập cụ thể.
class ColorDetailPage extends ConsumerWidget {
  final ColorCollection collection;

  const ColorDetailPage({super.key, required this.collection});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Sử dụng provider `colorsByIdsProvider` để lấy dữ liệu các màu
    // dựa trên danh sách `colorRefs` từ bộ sưu tập.
    final colorsAsyncValue = ref.watch(
      colorsByIdsProvider(collection.colorRefs),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(collection.name),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: colorsAsyncValue.when(
        data: (colors) {
          if (colors.isEmpty) {
            return const Center(
              child: Text('Bộ sưu tập này không có màu nào.'),
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(8.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, // Hiển thị 3 màu trên một hàng
              crossAxisSpacing: 8.0,
              mainAxisSpacing: 8.0,
              childAspectRatio: 0.8, // Tỉ lệ của mỗi ô màu
            ),
            itemCount: colors.length,
            itemBuilder: (context, index) {
              final color = colors[index];
              return _ColorTile(color: color, onColorSelected: _showProductSelectionSheet);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Đã xảy ra lỗi khi tải màu: $err'),
          ),
        ),
      ),
    );
  }

  // Hàm này có thể được đặt trong trang ColorDetailPage
  // và được gọi từ sự kiện onTap của _ColorTile.
  void _showProductSelectionSheet(BuildContext context, ColorData selectedColor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Cho phép bottom sheet cao hơn
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.5, // Bắt đầu ở 50% chiều cao màn hình
          maxChildSize: 0.9,      // Tối đa 90%
          minChildSize: 0.3,      // Tối thiểu 30%
          builder: (BuildContext context, ScrollController scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16.0),
                  topRight: Radius.circular(16.0),
                ),
              ),
              child: Column(
                children: [
                  // Tay cầm để kéo
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
                    child: Text(
                      'Chọn dòng sản phẩm',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    // Sử dụng widget mới tạo
                    child: CompatibleParentProductList(
                      color: selectedColor,
                      onParentProductSelected: (parentProduct) {
                        // Xử lý khi người dùng chọn một sản phẩm
                        print('Đã chọn: ${parentProduct.name}');
                        // Đóng bottom sheet trước khi điều hướng.
                        Navigator.of(context).pop(); 
                        // Điều hướng đến trang chọn SKU.
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => SkuSelectionPage(
                                color: selectedColor, parentProduct: parentProduct),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
  
}

/// Widget riêng để hiển thị một ô màu.
class _ColorTile extends StatelessWidget {
  final ColorData color;
  // Thêm callback để gọi hàm từ ColorDetailPage
  final Function(BuildContext, ColorData) onColorSelected;

  const _ColorTile({required this.color, required this.onColorSelected});

  @override
  Widget build(BuildContext context) {
    final colorSwatch = _hexToColor(color.hexCode);
    // Tự động chọn màu chữ (trắng hoặc đen) dựa trên độ sáng của màu nền.
    final textColor = colorSwatch.computeLuminance() > 0.5
        ? Colors.black
        : Colors.white;

    return InkWell(
      onTap: () => onColorSelected(context, color),
      borderRadius: BorderRadius.circular(8.0),
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 2.0,
        child: Container(
          color: colorSwatch,
          padding: const EdgeInsets.all(8.0),
          alignment: Alignment.bottomCenter,
          child: Text(
            color.code,
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
