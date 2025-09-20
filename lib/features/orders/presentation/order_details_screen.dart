import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../data/models/order_model.dart';
import '../../pos/presentation/pos_screen.dart';
import '../application/order_providers.dart';

class OrderDetailsScreen extends ConsumerWidget {
  const OrderDetailsScreen({super.key, required this.orderId});

  final int orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderByIdProvider(orderId));

    return orderAsync.when(
      data: (order) => _buildContent(context, ref, order),
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Đang tải...')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => Scaffold(
        appBar: AppBar(title: const Text('Lỗi')),
        body: Center(child: Text('Đã xảy ra lỗi: $err')),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, OrderModel order) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    // Theo API KiotViet, 'Hoàn thành' là status 2 và 'Đã hủy' là 3.
    // Chỉ hiển thị nút xử lý cho các đơn hàng chưa ở trạng thái cuối cùng.
    final isOrderProcessable = order.status != 2 && order.status != 3;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết đơn hàng'),
      ),
      floatingActionButton: isOrderProcessable
          ? FloatingActionButton.extended(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PosScreen(order: order),
                  ),
                );
                // Sau khi màn hình POS đóng lại, làm mới dữ liệu
                // của màn hình chi tiết này.
                // Điều này đảm bảo nếu người dùng quay lại mà không lưu,
                // dữ liệu vẫn được làm mới về trạng thái gốc.
                // Nếu họ đã lưu, provider đã được invalidate ở POS screen rồi.
                ref.invalidate(orderByIdProvider(orderId));
              },
              icon: const Icon(Icons.point_of_sale),
              label: const Text('Xử lý đơn'),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 80.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Mã đơn hàng:', order.code),
            _buildInfoRow('Trạng thái:', order.statusValue),
            _buildInfoRow(
                'Ngày đặt:',
                order.purchaseDate != null
                    ? dateFormat.format(order.purchaseDate!)
                    : null),
            _buildInfoRow(
                'Ngày tạo:',
                order.createdDate != null
                    ? dateFormat.format(order.createdDate!)
                    : null),
            const Divider(height: 20),
            _buildInfoRow('Khách hàng:', order.customerName ?? 'Khách lẻ'),
            _buildInfoRow('Mã KH:', order.customerCode),
            _buildInfoRow('Địa chỉ giao hàng:', order.orderDelivery?.address),
            _buildInfoRow('SĐT người nhận:', order.orderDelivery?.contactNumber),
            _buildInfoRow('Ghi chú:', order.description),
            const SizedBox(height: 20),
            Text(
              'Chi tiết sản phẩm:',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Divider(),
            ...(order.orderDetails ?? []).map((detail) {
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                child: ListTile(
                  title: Text(detail.productName),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Số lượng: ${detail.quantity}'),
                      Text('Đơn giá: ${currencyFormat.format(detail.price)}'),
                      if (detail.note != null && detail.note!.isNotEmpty)
                        Text('Ghi chú: ${detail.note}'),
                    ],
                  ),
                  trailing: Text(currencyFormat.format(detail.quantity * detail.price)),
                ),
              );
            }).toList(),
            const SizedBox(height: 20),
            _buildTotals(context, order, currencyFormat),
          ],
        ),
      ),
    );
  }

  Widget _buildTotals(BuildContext context, OrderModel order, NumberFormat currencyFormat) {
    final subtotal = (order.orderDetails ?? []).fold<double>(
      0,
      (sum, item) => sum + (item.price * item.quantity),
    );
    return Column(
      children: [
        const Divider(),
        _buildInfoRow('Tổng cộng:', currencyFormat.format(subtotal)),
        _buildInfoRow('Giảm giá:', currencyFormat.format(order.discount ?? 0)),
        if (order.surcharges != null)
          ...order.surcharges!.map(
            (s) => _buildInfoRow('Phụ phí (${s.code}):', currencyFormat.format(s.price)),
          ),
        const Divider(),
        _buildInfoRow(
          'Thành tiền:',
          currencyFormat.format(order.total ?? 0),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        _buildInfoRow(
          'Đã thanh toán:',
          currencyFormat.format(order.totalPayment ?? 0),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.green),
        ),
        _buildInfoRow(
          'Còn lại:',
          currencyFormat.format((order.total ?? 0) - (order.totalPayment ?? 0)),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String? value, {TextStyle? style}) {
    if (value == null || value.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(value, textAlign: TextAlign.end, style: style),
          ),
        ],
      ),
    );
  }
}
