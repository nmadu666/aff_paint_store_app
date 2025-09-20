import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/order_model.dart';
import '../../../data/repositories/order_repository.dart';
import '../../../data/services/kiotviet_api_service.dart';
import '../../../data/sources/local/user_local_data_source.dart';
import '../domain/order_filter.dart';
import 'order_filter_notifier.dart';
import 'paginated_orders_provider.dart';

/// Provider for UserLocalDataSource
final userLocalDataSourceProvider = Provider<UserLocalDataSource>((ref) {
  return UserLocalDataSource();
});

/// Provider for the order filter state.
final orderFilterProvider =
    StateNotifierProvider<OrderFilterNotifier, OrderFilter>((ref) {
      return OrderFilterNotifier(ref.watch(userLocalDataSourceProvider));
    });

final kiotVietApiServiceProvider = Provider((ref) => KiotVietApiService());

final orderRepositoryProvider = Provider<IOrderRepository>((ref) {
  final apiService = ref.watch(kiotVietApiServiceProvider);
  return KiotVietOrderRepository(apiService);
});

/// Provider để lấy một đơn hàng duy nhất bằng ID của nó.
///
/// Tự động làm mới khi bị vô hiệu hóa (invalidate).
final orderByIdProvider =
    FutureProvider.autoDispose.family<OrderModel, int>((ref, orderId) {
  final repository = ref.watch(orderRepositoryProvider);
  return repository.getOrderById(orderId);
});
/// Provider for the paginated list of orders.
final paginatedOrdersProvider = StateNotifierProvider.autoDispose
    .family<
      PaginatedOrdersNotifier,
      AsyncValue<PaginatedOrdersState>,
      OrderFilter
    >((ref, filter) {
      final repository = ref.watch(orderRepositoryProvider);
      final notifier = PaginatedOrdersNotifier(repository);
      notifier.fetchFirstPage(filter);
      return notifier;
    });
