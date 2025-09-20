import 'order_model.dart';

class PaginatedOrdersResponse {
  final List<OrderModel> orders;
  final int total;
  final int pageSize;

  PaginatedOrdersResponse({
    required this.orders,
    required this.total,
    required this.pageSize,
  });
}