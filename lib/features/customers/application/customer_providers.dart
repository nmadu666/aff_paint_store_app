import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/customer_repository.dart';
import 'paginated_customers_provider.dart';

/// Provider cho CustomerRepository.
final customerRepositoryProvider = Provider<ICustomerRepository>((ref) {
  return FirebaseCustomerRepository();
});

/// Provider chính cho danh sách khách hàng có phân trang.
///
/// Sử dụng `.family` để có thể khởi tạo Notifier với một bộ lọc ban đầu.
final paginatedCustomersProvider = StateNotifierProvider.autoDispose
    .family<
      PaginatedCustomersNotifier,
      AsyncValue<PaginatedCustomersState>,
      CustomerFilter
    >((ref, filter) {
      final repository = ref.watch(customerRepositoryProvider);
      final notifier = PaginatedCustomersNotifier(repository);
      notifier.fetchFirstPage(
        filter,
      ); // Tải trang đầu tiên khi provider được tạo.
      return notifier;
    });
