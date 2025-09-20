import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/sources/local/user_local_data_source.dart';
import '../domain/order_filter.dart';

class OrderFilterNotifier extends StateNotifier<OrderFilter> {
  final UserLocalDataSource _localDataSource;

  OrderFilterNotifier(this._localDataSource) : super(const OrderFilter()) {
    _init();
  }

  Future<void> _init() async {
    final userData = await _localDataSource.getUserData();
    final branchId = userData['branchId'];
    final branchIds = branchId != null ? [int.parse(branchId)] : null;

    state = state.copyWith(
      branchIds: branchIds,
      status: [1, 2, 3, 5],
    );
  }

  void updateFilter(OrderFilter newFilter) {
    state = newFilter;
  }
}
