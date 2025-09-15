import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/customer_providers.dart';
import '../application/paginated_customers_provider.dart';

/// Trang hiển thị danh sách khách hàng.
class CustomerListPage extends ConsumerStatefulWidget {
  const CustomerListPage({super.key});

  @override
  ConsumerState<CustomerListPage> createState() => _CustomerListPageState();
}

class _CustomerListPageState extends ConsumerState<CustomerListPage>
    with AutomaticKeepAliveClientMixin {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  Timer? _debounce;

  String? _searchTerm;

  // Tạo một record cho bộ lọc hiện tại để dễ dàng truyền đi.
  CustomerFilter get _currentFilter => (searchTerm: _searchTerm);

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
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

  void _onScroll() {
    // Kiểm tra nếu người dùng đã cuộn gần đến cuối danh sách
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // Gọi notifier để tải trang tiếp theo
      ref
          .read(paginatedCustomersProvider(_currentFilter).notifier)
          .fetchNextPage(_currentFilter);
    }
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted && _searchTerm != _searchController.text) {
        setState(() {
          _searchTerm = _searchController.text.isNotEmpty
              ? _searchController.text
              : null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final customersState = ref.watch(
      paginatedCustomersProvider(_currentFilter),
    );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              labelText: 'Tìm theo tên hoặc SĐT',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
          ),
        ),
        Expanded(
          child: customersState.when(
            data: (state) {
              if (state.customers.isEmpty) {
                return const Center(
                  child: Text('Không tìm thấy khách hàng nào.'),
                );
              }
              return RefreshIndicator(
                onRefresh: () => ref
                    .read(paginatedCustomersProvider(_currentFilter).notifier)
                    .fetchFirstPage(_currentFilter),
                child: ListView.builder(
                  controller: _scrollController,
                  // Thêm 1 item cho loading indicator nếu còn dữ liệu để tải
                  itemCount: state.customers.length + (state.hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    // Nếu là item cuối cùng và còn dữ liệu, hiển thị loading
                    if (index == state.customers.length) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.0),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    final customer = state.customers[index];
                    return ListTile(
                      leading: const Icon(Icons.person_outline),
                      title: Text(customer.name),
                      subtitle: Text(customer.phone ?? 'Chưa có SĐT'),
                      onTap: () {
                        // TODO: Navigate to customer detail page
                      },
                    );
                  },
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Lỗi: $err')),
          ),
        ),
      ],
    );
  }
}
