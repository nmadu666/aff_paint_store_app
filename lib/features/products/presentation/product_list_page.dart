import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../application/product_providers.dart';

class ProductListPage extends ConsumerStatefulWidget {
  const ProductListPage({super.key});

  @override
  ConsumerState<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends ConsumerState<ProductListPage> {
  // Local state để lưu trữ các giá trị bộ lọc hiện tại
  String? _selectedCategoryId;
  String? _selectedTrademarkId;

  @override
  Widget build(BuildContext context) {
    // 1. "Watch" the provider với các bộ lọc hiện tại.
    // Riverpod sẽ tự động gọi lại repository và rebuild widget này
    // mỗi khi giá trị của `_selectedCategoryId` hoặc `_selectedTrademarkId` thay đổi.
    final productsAsyncValue = ref.watch(
      productsProvider((
        // Sử dụng Dart Record để truyền bộ lọc
        categoryId: _selectedCategoryId,
        trademarkId: _selectedTrademarkId,
      )),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh mục sản phẩm'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          // Khu vực chứa các bộ lọc (ví dụ: Dropdowns)
          _buildFilterSection(),
          const Divider(),
          // Khu vực hiển thị danh sách sản phẩm
          Expanded(
            // 2. Sử dụng `when` để xử lý các trạng thái (loading, data, error)
            // một cách an toàn và rõ ràng.
            child: productsAsyncValue.when(
              data: (products) {
                if (products.isEmpty) {
                  return const Center(
                    child: Text('Không tìm thấy sản phẩm nào.'),
                  );
                }
                // Nếu có dữ liệu, hiển thị ListView
                return ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];

                    // Xử lý an toàn các giá trị có thể là null
                    final basePriceText = product.basePrice != null
                        ? '${product.basePrice!.toStringAsFixed(0)}đ'
                        : 'Chưa có giá';
                    final baseText = product.base != null
                        ? 'Gốc: ${product.base}'
                        : '';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8.0),
                      child: ListTile(
                        title: Text(product.name),
                        subtitle: Text('Giá gốc: $basePriceText'),
                        trailing: Text(baseText),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Đã xảy ra lỗi: $err')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    // Đây là nơi bạn sẽ đặt các DropdownButton hoặc các widget lọc khác.
    // Khi người dùng chọn một giá trị mới, hãy gọi `setState` để cập nhật
    // `_selectedCategoryId` hoặc `_selectedTrademarkId`.
    // Việc này sẽ tự động kích hoạt `ref.watch` ở trên để fetch lại dữ liệu.
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Wrap(
        spacing: 16.0,
        runSpacing: 8.0,
        alignment: WrapAlignment.center,
        children: [
          // TODO: Lấy danh sách danh mục và thương hiệu động từ Firestore
          DropdownButton<String>(
            hint: const Text('Tất cả danh mục'),
            value: _selectedCategoryId,
            onChanged: (newValue) {
              setState(() => _selectedCategoryId = newValue);
            },
            items: const [
              // Dữ liệu giả, sẽ được thay thế bằng dữ liệu thật
              DropdownMenuItem(value: '103320', child: Text('Sơn nội thất')),
              DropdownMenuItem(value: '103321', child: Text('Sơn ngoại thất')),
            ],
          ),
          DropdownButton<String>(
            hint: const Text('Tất cả thương hiệu'),
            value: _selectedTrademarkId,
            onChanged: (newValue) {
              setState(() => _selectedTrademarkId = newValue);
            },
            items: const [
              // Dữ liệu giả, sẽ được thay thế bằng dữ liệu thật
              DropdownMenuItem(value: '25643', child: Text('Mykolor')),
              DropdownMenuItem(value: '25644', child: Text('Spec')),
            ],
          ),
          ElevatedButton(
            onPressed: () {
              // Xóa tất cả các bộ lọc đang được áp dụng
              setState(() {
                _selectedCategoryId = null;
                _selectedTrademarkId = null;
              });
            },
            child: const Text('Xóa tất cả lọc'),
          ),
        ],
      ),
    );
  }
}
