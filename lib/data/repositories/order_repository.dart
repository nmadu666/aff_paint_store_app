import 'dart:convert';
import 'dart:developer';

import '../../features/orders/domain/order_filter.dart';
import '../models/order_model.dart';
import '../models/paginated_orders_response.dart';
import '../services/kiotviet_api_service.dart';

abstract class IOrderRepository {
  Future<PaginatedOrdersResponse> getOrders({
    OrderFilter? filter,
    String? orderBy,
    String? orderDirection,
    int? pageSize,
    int? currentItem,
  });
  Future<void> addOrder(OrderModel order);
  Future<OrderModel> updateOrder(OrderModel order);
  Future<OrderModel> getOrderById(int id);
}

class KiotVietOrderRepository implements IOrderRepository {
  final KiotVietApiService _apiService;

  KiotVietOrderRepository(this._apiService);

  @override
  Future<PaginatedOrdersResponse> getOrders({
    OrderFilter? filter,
    String? orderBy,
    String? orderDirection,
    int? pageSize,
    int? currentItem,
  }) async {
    final queryParams = <String, String>{};

    if (filter != null) {
      queryParams.addAll(filter.toQueryParameters());
    }

    if (orderBy != null) {
      queryParams['orderBy'] = orderBy;
    }
    if (orderDirection != null) {
      queryParams['orderDirection'] = orderDirection;
    }
    if (pageSize != null) {
      queryParams['pageSize'] = pageSize.toString();
    }
    if (currentItem != null) {
      queryParams['currentItem'] = currentItem.toString();
    }

    final response = await _apiService.get('/orders', queryParams: queryParams);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      log('KiotViet Orders Response: ${response.body}');

      try {
        final jsonResponse = json.decode(response.body);
        final List<dynamic> data = jsonResponse['data'];
        final orders = data.map((json) => OrderModel.fromJson(json)).toList();
        return PaginatedOrdersResponse(
          orders: orders,
          total: jsonResponse['total'],
          pageSize: jsonResponse['pageSize'],
        );
      } catch (e, s) {
        log('Error parsing orders JSON', error: e, stackTrace: s);
        throw Exception('Error parsing orders JSON: $e');
      }
    } else {
      throw Exception('Failed to load orders from KiotViet: ${response.body}');
    }
  }

  @override
  Future<void> addOrder(OrderModel order) async {
    final response = await _apiService.post(
      '/orders',
      body: order.toJson(),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to add order to KiotViet: ${response.body}');
    }
  }

  @override
  Future<OrderModel> updateOrder(OrderModel order) async {
    if (order.id == null) {
      throw Exception('Order ID is required for updating.');
    }
    final response = await _apiService.put(
      '/orders/${order.id}',
      body: order.toJson(),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      log('KiotViet Update Order Response: ${response.body}');
      final jsonResponse = json.decode(response.body);
      return OrderModel.fromJson(jsonResponse);
    } else {
      throw Exception('Failed to update order on KiotViet: ${response.body}');
    }
  }

  @override
  Future<OrderModel> getOrderById(int id) async {
    final response = await _apiService.get('/orders/$id');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      log('KiotViet Get Order By ID Response: ${response.body}');
      final jsonResponse = json.decode(response.body);
      return OrderModel.fromJson(jsonResponse);
    } else {
      throw Exception('Failed to load order $id from KiotViet: ${response.body}');
    }
  }
}
