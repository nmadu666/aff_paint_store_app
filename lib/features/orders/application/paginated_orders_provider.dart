import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/order_model.dart';
import '../../../data/repositories/order_repository.dart';
import '../domain/order_filter.dart';

const _ordersPerPage = 20;

class PaginatedOrdersState extends Equatable {
  final List<OrderModel> orders;
  final bool hasMore;
  final int total;
  final int currentPage;

  const PaginatedOrdersState({
    this.orders = const [],
    this.hasMore = true,
    this.total = 0,
    this.currentPage = 0,
  });

  PaginatedOrdersState copyWith({
    List<OrderModel>? orders,
    bool? hasMore,
    int? total,
    int? currentPage,
  }) {
    return PaginatedOrdersState(
      orders: orders ?? this.orders,
      hasMore: hasMore ?? this.hasMore,
      total: total ?? this.total,
      currentPage: currentPage ?? this.currentPage,
    );
  }

  @override
  List<Object?> get props => [orders, hasMore, total, currentPage];
}

class PaginatedOrdersNotifier
    extends StateNotifier<AsyncValue<PaginatedOrdersState>> {
  final IOrderRepository _repository;
  bool _isFetching = false;
  bool _disposed = false;

  PaginatedOrdersNotifier(this._repository)
      : super(const AsyncValue.loading());

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> fetchFirstPage(OrderFilter filter) async {
    state = const AsyncValue.loading();
    _isFetching = true;
    try {
      final response = await _repository.getOrders(
        filter: filter,
        pageSize: _ordersPerPage,
        currentItem: 0,
        orderBy: 'createdDate',
        orderDirection: 'Desc',
      );

      if (_disposed) return;

      final hasMore = response.orders.length < response.total;
      state = AsyncValue.data(
        PaginatedOrdersState(
          orders: response.orders,
          hasMore: hasMore,
          total: response.total,
          currentPage: 0,
        ),
      );
    } catch (e, st) {
      if (_disposed) return;
      state = AsyncValue.error(e, st);
    } finally {
      _isFetching = false;
    }
  }

  Future<void> fetchNextPage(OrderFilter filter) async {
    final value = state.valueOrNull;
    if (_isFetching || value == null || !value.hasMore) return;

    _isFetching = true;

    final currentState = value;
    final nextPage = currentState.currentPage + 1;
    final currentItem = nextPage * _ordersPerPage;

    try {
      final response = await _repository.getOrders(
        filter: filter,
        pageSize: _ordersPerPage,
        currentItem: currentItem,
        orderBy: 'createdDate',
        orderDirection: 'Desc',
      );

      if (_disposed) return;

      final newOrders = [...currentState.orders, ...response.orders];
      final hasMore = newOrders.length < response.total;

      state = AsyncValue.data(
        currentState.copyWith(
          orders: newOrders,
          hasMore: hasMore,
          currentPage: nextPage,
        ),
      );
    } catch (e, st) {
      if (_disposed) return;
      state = AsyncValue.error(e, st);
    } finally {
      _isFetching = false;
    }
  }
}