import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/customer_model.dart';
import '../../../data/repositories/kiotviet_customer_repository.dart';
import '../../../data/repositories/customer_repository.dart';
import 'paginated_customers_provider.dart';

/// Provider cho CustomerRepository.
final customerRepositoryProvider = Provider<ICustomerRepository>((ref) {
  // Chuyển sang sử dụng KiotViet Repository
  return KiotVietCustomerRepository(KiotVietApiService());
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

/// Provider để lấy thông tin một khách hàng bằng ID của họ.
///
/// Trả về một Future, sẽ tự động cập nhật UI khi được làm mới (invalidate).
final customerByIdProvider = FutureProvider.autoDispose
    .family<Customer, String>((ref, customerId) {
      final repository = ref.watch(customerRepositoryProvider);
      return repository.getCustomerById(customerId);
    });
