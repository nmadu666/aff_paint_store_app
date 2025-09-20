import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../data/models/color_data_model.dart';
import '../../../data/models/order_model.dart';
import '../../../data/models/customer_model.dart' as app_customer;
import '../../../data/models/product_model.dart';
import '../../../data/models/parent_product_model.dart';
import '../../orders/application/order_providers.dart';
import '../../products/application/product_providers.dart';
import '../../products/presentation/widgets/compatible_parent_product_list.dart';
import 'widgets/customer_search_delegate.dart';
import 'widgets/color_lookup_drawer.dart';
import 'widgets/product_search_delegate.dart';

class PosScreen extends ConsumerStatefulWidget {
  const PosScreen({super.key, this.order});

  final OrderModel? order;

  @override
  ConsumerState<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends ConsumerState<PosScreen> {
  // Key để điều khiển Scaffold (mở drawer)
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Chế độ
  bool get _isEditMode => widget.order != null;

  // Controllers
  late final TextEditingController _paymentAmountController;
  late final TextEditingController _discountController;

  // Trạng thái đơn hàng
  late List<OrderDetailModel> _currentOrderDetails;
  double _subTotal = 0;
  double _finalTotal = 0;
  double _orderDiscountAmount = 0;
  bool _isDiscountPercentage = false; // false = ₫, true = %
  double _amountToPay = 0;
  String? _selectedPaymentMethod; // e.g., 'CASH', 'TRANSFER'
  app_customer.Customer? _selectedCustomer;

  @override
  void initState() {
    super.initState();
    _paymentAmountController = TextEditingController();
    _discountController = TextEditingController(text: '0');

    if (_isEditMode) {
      // Chế độ chỉnh sửa: tải dữ liệu từ đơn hàng có sẵn
      _currentOrderDetails = List.from(widget.order!.orderDetails ?? []);
      _orderDiscountAmount = widget.order!.discount ?? 0;
      _isDiscountPercentage = widget.order!.discountRatio != null && widget.order!.discountRatio! > 0;

      if (_isDiscountPercentage) {
        _discountController.text = (widget.order!.discountRatio! * 100).toStringAsFixed(0);
      } else {
        _discountController.text = _orderDiscountAmount.toStringAsFixed(0);
      }
      // Tạm thời gán customer từ order model
      // _selectedCustomer = widget.order!.customer;
    } else {
      // Chế độ tạo mới: khởi tạo giá trị rỗng
      _currentOrderDetails = [];
    }

    _recalculateTotals();
  }

  void _recalculateTotals() {
    _subTotal = _currentOrderDetails.fold<double>(
      0,
      (sum, item) => sum + (item.price * item.quantity),
    );

    // Calculate discount amount from user input
    final discountValue = double.tryParse(_discountController.text) ?? 0;
    if (_isDiscountPercentage) {
      // If percentage, discountRatio is value/100
      _orderDiscountAmount = _subTotal * (discountValue / 100);
    } else {
      _orderDiscountAmount = discountValue;
    }

    _finalTotal = _subTotal - _orderDiscountAmount;
    final totalPayment = widget.order?.totalPayment ?? 0;

    setState(() {
      _amountToPay = _finalTotal - totalPayment;
      if (_amountToPay < 0) _amountToPay = 0;

      final amountText = _amountToPay.truncateToDouble() == _amountToPay
          ? _amountToPay.toInt().toString()
          : _amountToPay.toStringAsFixed(0);

      _paymentAmountController.text = amountText;
    });
  }

  @override
  void dispose() {
    _paymentAmountController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  void _saveOrder() {
    // Hiển thị số nguyên nếu không có phần thập phân
    // Basic validation
    if (_selectedPaymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn phương thức thanh toán.')),
      );
      return;
    }

    final amount = double.tryParse(_paymentAmountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập số tiền hợp lệ.')),
      );
      return;
    }

    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận thanh toán'),
        content: Text(
          'Xác nhận thanh toán ${NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(amount)} cho đơn hàng ${widget.order?.code ?? 'mới'}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () async {
              // 1. Create the new payment object
              final newPayment = PaymentModel(
                method: _selectedPaymentMethod!,
                methodStr: _selectedPaymentMethod == 'CASH'
                    ? 'Tiền mặt'
                    : 'Chuyển khoản',
                amount: amount,
                id: 0, // ID = 0 for new payment
              );

              try {
                if (_isEditMode) {
                  // Logic cập nhật đơn hàng
                  final updatedOrder = widget.order!.copyWith(
                    orderDetails: _currentOrderDetails,
                    total: _finalTotal,
                    discount: _orderDiscountAmount,
                    discountRatio: _isDiscountPercentage
                        ? (double.tryParse(_discountController.text) ?? 0) / 100
                        : 0,
                    payments: [...?widget.order!.payments, newPayment],
                  );
                  final resultOrder = await ref.read(orderRepositoryProvider).updateOrder(updatedOrder);
                  ref.invalidate(orderByIdProvider(resultOrder.id!));
                } else {
                  // Logic tạo đơn hàng mới
                  final newOrder = OrderModel(
                    purchaseDate: DateTime.now(),
                    branchId: 1, // TODO: Get current user's branchId
                    status: 1, // Trạng thái "Phiếu tạm"
                    orderDetails: _currentOrderDetails,
                    total: _finalTotal,
                    discount: _orderDiscountAmount,
                    discountRatio: _isDiscountPercentage
                        ? (double.tryParse(_discountController.text) ?? 0) / 100
                        : 0,
                    payments: [newPayment],
                    customerId: _selectedCustomer != null ? int.tryParse(_selectedCustomer!.id) : null,
                    customerName: _selectedCustomer?.name,
                    customerCode: _selectedCustomer?.code,
                  );
                  await ref.read(orderRepositoryProvider).addOrder(newOrder);
                }

                Navigator.of(ctx).pop(); // Close dialog
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${_isEditMode ? 'Cập nhật' : 'Tạo'} đơn hàng thành công!')),
                );

                // Invalidate a provider to force a refresh on the list screen
                ref.invalidate(paginatedOrdersProvider);

                // Pop 2 lần nếu là tạo mới (đóng POS và dialog), 1 lần nếu là sửa
                if (_isEditMode) {
                  Navigator.of(context).pop(); // Pop back to order details
                } else {
                  // Quay về màn hình danh sách đơn hàng
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
              } catch (e) {
                Navigator.of(ctx).pop(); // Close dialog
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Lỗi cập nhật đơn hàng: $e')),
                );
              }
            },
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }

  Future<void> _showProductSearch({int? replacingIndex}) async {
    final selectedProduct = await showSearch<Product?>(
      context: context,
      delegate: ProductSearchDelegate(ref),
    );

    if (selectedProduct != null && mounted) {
      final newDetail = OrderDetailModel(
        productId: int.tryParse(selectedProduct.id) ?? 0,
        productCode: selectedProduct.code,
        productName: selectedProduct.name,
        quantity: 1,
        price: selectedProduct.basePrice ?? 0,
        isMaster: true, // Default assumption
      );

      setState(() {
        if (replacingIndex != null) {
          _currentOrderDetails[replacingIndex] = newDetail;
        } else {
          _currentOrderDetails.add(newDetail);
        }
        _recalculateTotals();
      });
    }
  }

  Future<void> _showCustomerSearch() async {
    final selectedCustomer = await showSearch<app_customer.Customer?>(
      context: context,
      delegate: CustomerSearchDelegate(ref),
    );

    if (selectedCustomer != null && mounted) {
      setState(() => _selectedCustomer = selectedCustomer);
    }
  }

  void _removeProduct(int index) {
    setState(() {
      _currentOrderDetails.removeAt(index);
      _recalculateTotals();
    });
  }

  Future<void> _showEditProductDialog(int index) async {
    final detail = _currentOrderDetails[index];
    final quantityController =
        TextEditingController(text: detail.quantity.toString());
    final priceController =
        TextEditingController(text: detail.price.toStringAsFixed(0));

    final result = await showDialog<Map<String, double>>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Sửa sản phẩm'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: quantityController,
                decoration: const InputDecoration(labelText: 'Số lượng'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: priceController,
                decoration:
                    const InputDecoration(labelText: 'Đơn giá', suffixText: '₫'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () {
                final newQuantity = double.tryParse(quantityController.text);
                final newPrice = double.tryParse(priceController.text);
                if (newQuantity != null && newPrice != null && newQuantity > 0) {
                  Navigator.of(context).pop({
                    'quantity': newQuantity,
                    'price': newPrice,
                  });
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vui lòng nhập số hợp lệ.')),
                  );
                }
              },
              child: const Text('Lưu'),
            ),
          ],
        );
      },
    );

    if (result != null) {
      setState(() {
        _currentOrderDetails[index] = _currentOrderDetails[index].copyWith(
          quantity: result['quantity'],
          price: result['price'],
        );
        _recalculateTotals();
      });
    }
  }

  void _handleColorSelection(ColorData color) {
    // Đóng drawer trước
    Navigator.of(context).pop();
    // Hiển thị bottom sheet chọn dòng sản phẩm
    _showCompatibleProductsForColor(color);
  }

  void _showCompatibleProductsForColor(ColorData selectedColor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.5,
          maxChildSize: 0.9,
          builder: (BuildContext context, ScrollController scrollController) {
            return CompatibleParentProductList(
              color: selectedColor,
              scrollController: scrollController,
              onParentProductSelected: (parentProduct) {
                Navigator.of(ctx).pop(); // Đóng bottom sheet chọn dòng SP
                _showSkuSelectionForProduct(selectedColor, parentProduct);
              },
            );
          },
        );
      },
    );
  }

  void _showSkuSelectionForProduct(ColorData color, ParentProduct parentProduct) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        final skusAsync = ref.watch(skusForParentProvider(parentProduct.id));
        return skusAsync.when(
          data: (skus) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text('Chọn quy cách', style: Theme.of(context).textTheme.titleLarge),
                ),
                ...skus.map((sku) => ListTile(
                      title: Text(sku.name),
                      trailing: Text(NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(sku.basePrice ?? 0)),
                      onTap: () {
                        final newDetail = OrderDetailModel(
                          productId: int.tryParse(sku.id) ?? 0,
                          productCode: sku.code,
                          productName: '${parentProduct.name} - ${sku.unitValue}L - Màu ${color.code}',
                          quantity: 1,
                          price: sku.basePrice ?? 0, // TODO: Lấy giá pha màu
                          isMaster: true,
                        );
                        setState(() {
                          _currentOrderDetails.add(newDetail);
                          _recalculateTotals();
                        });
                        Navigator.of(ctx).pop(); // Đóng bottom sheet chọn SKU
                      },
                    )),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Lỗi tải SKU: $e'),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    final customerDisplayName = _selectedCustomer?.name ?? widget.order?.customerName ?? 'Khách lẻ';
    return Scaffold(
      appBar: AppBar(
        title: const Text('POS Bán hàng'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_shopping_cart),
            tooltip: 'Thêm sản phẩm',
            onPressed: () => _showProductSearch(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 80.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Info
            Text(
              'Đơn hàng: ${widget.order?.code ?? 'Đơn hàng mới'}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: Text('Khách hàng: $customerDisplayName')),
                TextButton(
                  onPressed: _showCustomerSearch,
                  child: Text(_selectedCustomer != null || widget.order?.customerId != null
                      ? 'Thay đổi'
                      : 'Chọn khách hàng'),
                ),
              ],
            ),
            const Divider(height: 32),
            // Product List
            Text(
              'Sản phẩm trong đơn',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _currentOrderDetails.length,
              itemBuilder: (context, index) {
                final detail = _currentOrderDetails[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    onTap: () => _showEditProductDialog(index),
                    title: Text(detail.productName),
                    subtitle: Text(
                      'SL: ${detail.quantity} x ${currencyFormat.format(detail.price)}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.edit_outlined,
                            color: Colors.blue,
                          ),
                          tooltip: 'Thay đổi',
                          onPressed: () =>
                              _showProductSearch(replacingIndex: index),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                          tooltip: 'Xóa',
                          onPressed: () => _removeProduct(index),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const Divider(height: 32),

            // Discount Section
            Text(
              'Chiết khấu đơn hàng',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _discountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Giá trị',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      _recalculateTotals();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Wrap(
                  spacing: 8.0,
                  children: [
                    ChoiceChip(
                      label: const Text('₫'),
                      selected: !_isDiscountPercentage,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _isDiscountPercentage = false);
                          _recalculateTotals();
                        }
                      },
                    ),
                    ChoiceChip(
                      label: const Text('%'),
                      selected: _isDiscountPercentage,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _isDiscountPercentage = true);
                          _recalculateTotals();
                        }
                      },
                    ),
                  ],
                )
              ],
            ),
            const Divider(height: 32),

            // Financial Info
            _buildFinancialRow(
              'Tổng tiền:',
              currencyFormat.format(_subTotal),
            ),
            _buildFinancialRow(
              'Đã thanh toán:',
              currencyFormat.format(widget.order?.totalPayment ?? 0),
              color: Colors.green,
            ),
            _buildFinancialRow(
              'Giảm giá:',
              '-${currencyFormat.format(_orderDiscountAmount)}',
            ),
            const Divider(),
            _buildFinancialRow(
              'Thành tiền:',
              currencyFormat.format(_finalTotal),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            _buildFinancialRow(
              'Cần thanh toán:',
              currencyFormat.format(_amountToPay),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 24),

            // Payment Input
            TextFormField(
              controller: _paymentAmountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Số tiền thanh toán',
                border: OutlineInputBorder(),
                suffixText: '₫',
              ),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),

            // Payment Methods
            Text(
              'Phương thức thanh toán',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8.0,
              children: [
                ChoiceChip(
                  label: const Text('Tiền mặt'),
                  selected: _selectedPaymentMethod == 'CASH',
                  onSelected: (selected) {
                    setState(() {
                      _selectedPaymentMethod = selected ? 'CASH' : null;
                    });
                  },
                ),
                ChoiceChip(
                  label: const Text('Chuyển khoản'),
                  selected: _selectedPaymentMethod == 'TRANSFER',
                  onSelected: (selected) {
                    setState(() {
                      _selectedPaymentMethod = selected ? 'TRANSFER' : null;
                    });
                  },
                ),
                // Add other payment methods if needed
              ],
            ),
          ],
        ),
      ),
      bottomSheet: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _saveOrder,
            icon: const Icon(Icons.check_circle_outline),
            label: Text(_isEditMode ? 'Lưu thay đổi' : 'Tạo đơn hàng'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFinancialRow(
    String label,
    String value, {
    TextStyle? style,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyLarge),
          Text(
            value,
            style:
                style ??
                Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}
