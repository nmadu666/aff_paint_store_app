import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../application/order_providers.dart';
import '../domain/order_filter.dart';
import '../../pos/presentation/pos_screen.dart';
import 'order_details_screen.dart';

class OrdersListScreen extends ConsumerStatefulWidget {
  const OrdersListScreen({super.key});

  @override
  ConsumerState<OrdersListScreen> createState() => _OrdersListScreenState();
}

class _OrdersListScreenState extends ConsumerState<OrdersListScreen> {
  final _scrollController = ScrollController();

  // Text editing controllers for filters
  final _branchIdsController = TextEditingController();
  final _customerIdsController = TextEditingController();
  final _customerCodeController = TextEditingController();
  final _statusController = TextEditingController();
  final _saleChannelIdController = TextEditingController();

  // State for date filters
  DateTime? _createdDateFrom;
  DateTime? _toDate;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_isBottom) {
      final filter = ref.read(orderFilterProvider);
      ref.read(paginatedOrdersProvider(filter).notifier).fetchNextPage(filter);
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _branchIdsController.dispose();
    _customerIdsController.dispose();
    _customerCodeController.dispose();
    _statusController.dispose();
    _saleChannelIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<OrderFilter>(orderFilterProvider, (previous, next) {
      _branchIdsController.text = next.branchIds?.join(',') ?? '';
      _statusController.text = next.status?.join(',') ?? '';
      _customerCodeController.text = next.customerCode ?? '';
      _customerIdsController.text = next.customerIds?.join(',') ?? '';
      _saleChannelIdController.text = next.saleChannelId?.toString() ?? '';
      setState(() {
        _createdDateFrom = next.createdDateFrom;
        _toDate = next.toDate;
      });
    });

    final filter = ref.watch(orderFilterProvider);
    final state = ref.watch(paginatedOrdersProvider(filter));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Điều hướng đến màn hình POS ở chế độ tạo đơn mới (không truyền order)
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PosScreen(),
            ),
          );
        },
        tooltip: 'Tạo đơn hàng mới',
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          _buildFilter(),
          Expanded(
            child: state.when(
              data: (data) {
                if (data.orders.isEmpty) {
                  return const Center(child: Text('No orders found.'));
                }
                return ListView.builder(
                  controller: _scrollController,
                  itemCount: data.hasMore
                      ? data.orders.length + 1
                      : data.orders.length,
                  itemBuilder: (context, index) {
                    if (index >= data.orders.length) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final order = data.orders[index];
                    final currencyFormat =
                        NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      child: ListTile(
                        title: Text(
                          'Đơn hàng: ${order.code ?? 'N/A'}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                'KH: ${order.customerName ?? order.customer?.name ?? 'Khách lẻ'}'),
                            if (order.purchaseDate != null)
                              Text(
                                  'Ngày: ${DateFormat('dd/MM/yyyy HH:mm').format(order.purchaseDate!)}'),
                            Text(
                                'Trạng thái: ${order.statusValue ?? 'N/A'}'),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              currencyFormat.format(order.total ?? 0),
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ],
                        ),
                        isThreeLine: true,
                        onTap: () {
                          if (order.id != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    OrderDetailsScreen(orderId: order.id!),
                              ),
                            );
                          }
                        },
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Center(
                child: Text('Error: $error'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilter() {
    return ExpansionTile(
      title: const Text('Filters'),
      initiallyExpanded: true,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              _buildTextField(_branchIdsController, 'Branch IDs (comma-separated)'),
              _buildTextField(
                  _customerIdsController, 'Customer IDs (comma-separated)'),
              _buildTextField(_customerCodeController, 'Customer Code'),
              _buildTextField(_statusController, 'Status IDs (comma-separated)'),
              _buildTextField(_saleChannelIdController, 'Sale Channel ID'),
              _buildDateFilters(),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _applyFilters,
                child: const Text('Apply Filters'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildDateFilters() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () => _selectDate(true),
            child: Text(_createdDateFrom == null
                ? 'From Date'
                : DateFormat.yMd().format(_createdDateFrom!))),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton(
            onPressed: () => _selectDate(false),
            child: Text(_toDate == null
                ? 'To Date'
                : DateFormat.yMd().format(_toDate!))),
        ),
      ],
    );
  }

  Future<void> _selectDate(bool isFromDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        if (isFromDate) {
          _createdDateFrom = picked;
        } else {
          _toDate = picked;
        }
      });
    }
  }

  void _applyFilters() {
    final branchIds = _branchIdsController.text
        .split(',')
        .map((e) => int.tryParse(e.trim()))
        .where((e) => e != null)
        .cast<int>()
        .toList();
    final customerIds = _customerIdsController.text
        .split(',')
        .map((e) => int.tryParse(e.trim()))
        .where((e) => e != null)
        .cast<int>()
        .toList();
    final status = _statusController.text
        .split(',')
        .map((e) => int.tryParse(e.trim()))
        .where((e) => e != null)
        .cast<int>()
        .toList();
    final saleChannelId = int.tryParse(_saleChannelIdController.text);

    final newFilter = OrderFilter(
      branchIds: branchIds.isNotEmpty ? branchIds : null,
      customerIds: customerIds.isNotEmpty ? customerIds : null,
      customerCode: _customerCodeController.text,
      status: status.isNotEmpty ? status : null,
      createdDateFrom: _createdDateFrom,
      toDate: _toDate,
      saleChannelId: saleChannelId,
    );

    ref.read(orderFilterProvider.notifier).updateFilter(newFilter);
  }
}
