import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/cart_item.dart';

/// Quản lý trạng thái của giỏ hàng (danh sách các CartItem).
class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]);

  /// Thêm một sản phẩm vào giỏ hàng.
  /// Nếu sản phẩm đã tồn tại, chỉ tăng số lượng.
  void addItem(CartItem newItem) {
    // Kiểm tra xem sản phẩm (cùng SKU và màu) đã có trong giỏ chưa.
    final existingItemIndex = state.indexWhere(
      (item) => item.sku.id == newItem.sku.id && item.color.id == newItem.color.id,
    );

    if (existingItemIndex != -1) {
      // Nếu đã tồn tại, cập nhật số lượng.
      final existingItem = state[existingItemIndex];
      final updatedItem = existingItem.copyWith(
        quantity: existingItem.quantity + newItem.quantity,
      );
      state = [
        for (int i = 0; i < state.length; i++)
          if (i == existingItemIndex) updatedItem else state[i],
      ];
    } else {
      // Nếu là sản phẩm mới, thêm vào danh sách.
      state = [...state, newItem];
    }
  }

  /// Xóa một sản phẩm khỏi giỏ hàng bằng ID của nó.
  void removeItem(String itemId) {
    state = state.where((item) => item.id != itemId).toList();
  }

  /// Cập nhật số lượng của một sản phẩm. Nếu số lượng <= 0, xóa sản phẩm.
  void updateQuantity(String itemId, int newQuantity) {
    if (newQuantity <= 0) {
      removeItem(itemId);
      return;
    }
    state = [
      for (final item in state)
        if (item.id == itemId) item.copyWith(quantity: newQuantity) else item,
    ];
  }
}

/// Provider để truy cập vào CartNotifier và trạng thái của nó.
final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  return CartNotifier();
});

/// Provider để tính tổng giá trị của giỏ hàng.
final cartTotalProvider = Provider<double>((ref) {
  final cart = ref.watch(cartProvider);
  return cart.fold(0, (total, item) => total + (item.priceDetails.finalPrice * item.quantity));
});