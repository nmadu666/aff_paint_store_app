import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/product_model.dart';
import '../../../data/repositories/product_repository.dart';
import 'product_providers.dart';

const _productsPerPage = 20;

/// Lớp trạng thái cho danh sách sản phẩm có phân trang.
class PaginatedProductsState extends Equatable {
  final List<Product> products;
  final bool hasMore; // Còn sản phẩm để tải nữa không
  final DocumentSnapshot? lastDoc; // Document cuối cùng của trang hiện tại

  const PaginatedProductsState({
    this.products = const [],
    this.hasMore = true,
    this.lastDoc,
  });

  PaginatedProductsState copyWith({
    List<Product>? products,
    bool? hasMore,
    DocumentSnapshot? lastDoc,
  }) {
    return PaginatedProductsState(
      products: products ?? this.products,
      hasMore: hasMore ?? this.hasMore,
      lastDoc: lastDoc ?? this.lastDoc,
    );
  }

  @override
  List<Object?> get props => [products, hasMore, lastDoc];
}

/// Notifier quản lý việc tải và cập nhật trạng thái của danh sách sản phẩm.
class PaginatedProductsNotifier
    extends StateNotifier<AsyncValue<PaginatedProductsState>> {
  final IProductRepository _repository;

  PaginatedProductsNotifier(this._repository)
      : super(const AsyncValue.loading());

  bool _isFetching = false;

  /// Tải trang đầu tiên hoặc tải lại dữ liệu với bộ lọc mới.
  Future<void> fetchFirstPage(ProductFilter filter) async {
    state = const AsyncValue.loading();
    _isFetching = true;
    try {
      final page = await _repository.getProducts(
        categoryId: filter.categoryId,
        trademarkId: filter.trademarkId,
        searchTerm: filter.searchTerm,
        limit: _productsPerPage,
      );
      state = AsyncValue.data(PaginatedProductsState(
        products: page.products,
        hasMore: page.hasMore,
        lastDoc: page.lastDoc,
      ));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    } finally {
      _isFetching = false;
    }
  }

  /// Tải trang dữ liệu tiếp theo.
  Future<void> fetchNextPage(ProductFilter filter) async {
    // Ngăn chặn việc gọi fetch liên tục khi đang tải.
    if (_isFetching || !state.value!.hasMore) return;

    _isFetching = true;

    final currentState = state.value!;
    try {
      final nextPage = await _repository.getProducts(
        categoryId: filter.categoryId,
        trademarkId: filter.trademarkId,
        searchTerm: filter.searchTerm,
        limit: _productsPerPage,
        lastDoc: currentState.lastDoc,
      );

      state = AsyncValue.data(currentState.copyWith(
        products: [...currentState.products, ...nextPage.products],
        hasMore: nextPage.hasMore,
        lastDoc: nextPage.lastDoc,
      ));
    } catch (e, st) {
      // Nếu có lỗi, giữ lại dữ liệu cũ và hiển thị lỗi.
      // Có thể thêm một trường lỗi vào state để hiển thị SnackBar thay vì thay thế toàn bộ UI.
      print('Error fetching next page: $e');
    } finally {
      _isFetching = false;
    }
  }
}

/// Provider chính cho danh sách sản phẩm có phân trang.
/// Sử dụng `.family` để có thể khởi tạo Notifier với một bộ lọc ban đầu.
final paginatedProductsProvider = StateNotifierProvider.autoDispose
    .family<PaginatedProductsNotifier, AsyncValue<PaginatedProductsState>, ProductFilter>(
        (ref, filter) {
  final repository = ref.watch(productRepositoryProvider);
  final notifier = PaginatedProductsNotifier(repository);
  notifier.fetchFirstPage(filter); // Tải trang đầu tiên ngay khi provider được tạo.
  return notifier;
});

