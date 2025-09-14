import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../application/product_providers.dart';
import '../../filters/application/filter_providers.dart';
import '../application/paginated_products_provider.dart';
import 'product_detail_page.dart';
class ProductListPage extends ConsumerStatefulWidget {
  const ProductListPage({super.key});

  @override
  ConsumerState<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends ConsumerState<ProductListPage>
    with AutomaticKeepAliveClientMixin {
  // Local state để lưu trữ các giá trị bộ lọc hiện tại
  String? _selectedCategoryId;
  String? _selectedTrademarkId;
  String? _searchTerm;

  // Controller cho ô tìm kiếm và timer cho việc debounce
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  bool get wantKeepAlive => true; // Yêu cầu giữ lại trạng thái của widget này.

  // Tạo một record cho bộ lọc hiện tại để dễ dàng truyền đi.
  ProductFilter get _currentFilter => (
        categoryId: _selectedCategoryId,
        trademarkId: _selectedTrademarkId,
        searchTerm: _searchTerm,
      );

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  /// Xử lý sự kiện gõ phím với debouncing để tránh gọi API liên tục.
  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      // Chỉ cập nhật nếu text thực sự thay đổi
      if (mounted && _searchTerm != _searchController.text) {
        setState(() {
          _searchTerm = _searchController.text;
        });
      }
    });
  }

  void _onScroll() {
    // Kiểm tra nếu người dùng đã cuộn gần đến cuối danh sách
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // Gọi notifier để tải trang tiếp theo
      ref.read(paginatedProductsProvider(_currentFilter).notifier).fetchNextPage(_currentFilter);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Quan trọng: phải gọi super.build khi dùng mixin.

    // 1. "Watch" the provider với các bộ lọc hiện tại.
    // Riverpod sẽ tự động gọi lại repository và rebuild widget này
    final productsState = ref.watch(paginatedProductsProvider(_currentFilter));

    return Column(
      children: [
        // Khu vực chứa các bộ lọc (ví dụ: Dropdowns)
        _buildFilterSection(),
        const Divider(),
        // Khu vực hiển thị danh sách sản phẩm
        Expanded(
          // 2. Sử dụng `when` để xử lý các trạng thái (loading, data, error)
          child: productsState.when(
            data: (state) {
              if (state.products.isEmpty) {
                return const Center(
                  child: Text('Không tìm thấy sản phẩm nào.'),
                );
              }
              // Nếu có dữ liệu, hiển thị ListView
              return RefreshIndicator(
                onRefresh: () => ref.read(paginatedProductsProvider(_currentFilter).notifier).fetchFirstPage(_currentFilter),
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(8.0),
                  // Thêm 1 item cho loading indicator nếu còn dữ liệu để tải
                  itemCount: state.products.length + (state.hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    // Nếu là item cuối cùng và còn dữ liệu, hiển thị loading
                    if (index == state.products.length) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.0),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    final product = state.products[index];
                    final basePriceText = product.basePrice != null
                        ? '${product.basePrice!.toStringAsFixed(0)}đ'
                        : 'Chưa có giá';
                    final baseText = product.base != null ? 'Gốc: ${product.base}' : '';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8.0),
                      child: ListTile(
                        title: Text(product.name),
                        subtitle: Text('Giá gốc: $basePriceText'),
                        trailing: Text(baseText),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => ProductDetailPage(product: product),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Đã xảy ra lỗi: $err')),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterSection() {
    final categoriesAsync = ref.watch(categoriesProvider);
    final trademarksAsync = ref.watch(trademarksProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12.0),
      scrollDirection: Axis.vertical, // Thay đổi để cuộn dọc khi không đủ chỗ
      child: Wrap(
        spacing: 12.0,
        runSpacing: 8.0,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // Ô tìm kiếm
          SizedBox(
            width: 200,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm tên, mã sản phẩm...',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8.0)),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 8.0),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          // Không cần gọi setState ở đây vì listener đã xử lý
                        },
                      )
                    : null,
              ),
            ),
          ),
          // Dropdown cho Danh mục
          categoriesAsync.when(
            data: (categories) => DropdownButton<String>(
              hint: const Text('Tất cả danh mục'),
              value: _selectedCategoryId,
              onChanged: (newValue) {
                // Chỉ rebuild nếu giá trị thay đổi
                if (_selectedCategoryId != newValue) {
                  setState(() {
                    _selectedCategoryId = newValue;
                  });
                }
              },
              items: categories.map((category) {
                return DropdownMenuItem(
                  value: category.id,
                  child: Text(category.name),
                );
              }).toList(),
            ),
            loading: () => const SizedBox(
              width: 120,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (err, stack) => const Text('Lỗi tải danh mục'),
          ),
          // Dropdown cho Thương hiệu
          trademarksAsync.when(
            data: (trademarks) => DropdownButton<String>(
              hint: const Text('Tất cả thương hiệu'),
              value: _selectedTrademarkId,
              onChanged: (newValue) {
                if (_selectedTrademarkId != newValue) {
                  setState(() {
                    _selectedTrademarkId = newValue;
                  });
                }
              },
              items: trademarks.map((trademark) {
                return DropdownMenuItem(
                  value: trademark.id,
                  child: Text(trademark.name),
                );
              }).toList(),
            ),
            loading: () => const SizedBox(
              width: 120,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (err, stack) => const Text('Lỗi tải thương hiệu'),
          ),
          // Nút xóa bộ lọc chỉ hiển thị khi có bộ lọc được áp dụng
          if (_selectedCategoryId != null || _selectedTrademarkId != null || (_searchTerm != null && _searchTerm!.isNotEmpty))
            ElevatedButton(
              onPressed: () {
                // Xóa tất cả các bộ lọc đang được áp dụng
                setState(() {
                  _selectedCategoryId = null;
                  _selectedTrademarkId = null;
                  _searchController.clear();
                });
              },
              child: const Text('Xóa lọc'),
            ),
        ],
      ),
    );
  }
}
