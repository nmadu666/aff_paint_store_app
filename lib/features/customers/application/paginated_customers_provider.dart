import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/customer_model.dart';
import '../../../data/repositories/customer_repository.dart';
import 'customer_providers.dart';

const _customersPerPage = 20;

/// Một record cho bộ lọc khách hàng. Hiện tại chỉ chứa `searchTerm`.
typedef CustomerFilter = ({String? searchTerm});

/// Lớp trạng thái cho danh sách khách hàng có phân trang.
class PaginatedCustomersState extends Equatable {
  final List<Customer> customers;
  final bool hasMore; // Còn khách hàng để tải nữa không
  final DocumentSnapshot? lastDoc; // Document cuối cùng của trang hiện tại

  const PaginatedCustomersState({
    this.customers = const [],
    this.hasMore = true,
    this.lastDoc,
  });

  PaginatedCustomersState copyWith({
    List<Customer>? customers,
    bool? hasMore,
    DocumentSnapshot? lastDoc,
  }) {
    return PaginatedCustomersState(
      customers: customers ?? this.customers,
      hasMore: hasMore ?? this.hasMore,
      lastDoc: lastDoc ?? this.lastDoc,
    );
  }

  @override
  List<Object?> get props => [customers, hasMore, lastDoc];
}

/// Notifier quản lý việc tải và cập nhật trạng thái của danh sách khách hàng.
class PaginatedCustomersNotifier
    extends StateNotifier<AsyncValue<PaginatedCustomersState>> {
  final ICustomerRepository _repository;
  PaginatedCustomersNotifier(this._repository)
    : super(const AsyncValue.loading());

  bool _isFetching = false;

  /// Tải trang đầu tiên hoặc tải lại dữ liệu với bộ lọc mới.
  Future<void> fetchFirstPage(CustomerFilter filter) async {
    state = const AsyncValue.loading();
    _isFetching = true;
    try {
      final page = await _repository.getCustomers(
        searchTerm: filter.searchTerm,
        limit: _customersPerPage,
      );
      state = AsyncValue.data(
        PaginatedCustomersState(
          customers: page.customers,
          hasMore: page.hasMore,
          lastDoc: page.lastDoc,
        ),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    } finally {
      _isFetching = false;
    }
  }

  /// Tải trang dữ liệu tiếp theo.
  Future<void> fetchNextPage(CustomerFilter filter) async {
    if (_isFetching || !state.value!.hasMore) return;
    _isFetching = true;

    final currentState = state.value!;
    try {
      final nextPage = await _repository.getCustomers(
        searchTerm: filter.searchTerm,
        limit: _customersPerPage,
        lastDoc: currentState.lastDoc,
      );
      state = AsyncValue.data(
        currentState.copyWith(
          customers: [...currentState.customers, ...nextPage.customers],
          hasMore: nextPage.hasMore,
          lastDoc: nextPage.lastDoc,
        ),
      );
    } finally {
      _isFetching = false;
    }
  }
}
