import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/cart_item.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/remote_cart_repository.dart';
import '../../../data/services/cart_storage_service.dart';
import '../../auth/application/auth_providers.dart';

/// Provider cho dịch vụ lưu trữ giỏ hàng cục bộ.
final cartStorageProvider = Provider<ICartStorageService>((ref) {
  return SharedPreferencesCartStorage();
});

/// Provider cho repository giỏ hàng từ xa (Firestore).
final remoteCartRepositoryProvider = Provider<IRemoteCartRepository>((ref) {
  return FirestoreCartRepository();
});

/// Quản lý trạng thái của giỏ hàng (danh sách các CartItem).
class CartNotifier extends StateNotifier<List<CartItem>> {
  // Các dependency được inject qua constructor để dễ dàng testing.
  final IAuthRepository _authRepository;
  final ICartStorageService _localCartStorage;
  final IRemoteCartRepository _remoteCartRepository;

  CartNotifier(
    this._authRepository,
    this._localCartStorage,
    this._remoteCartRepository,
    List<CartItem> initialItems,
  ) : super(initialItems);

  /// Lưu giỏ hàng vào đúng nơi (local hoặc remote) dựa trên trạng thái đăng nhập.
  Future<void> _persistCart() async {
    final user = _authRepository.currentUser;
    if (user != null) {
      await _remoteCartRepository.saveCart(user.uid, state);
    } else {
      await _localCartStorage.saveCart(state);
    }
  }


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
    unawaited(_persistCart());
  }

  /// Xóa một sản phẩm khỏi giỏ hàng bằng ID của nó.
  void removeItem(String itemId) {
    state = state.where((item) => item.id != itemId).toList();
    unawaited(_persistCart());
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
    unawaited(_persistCart());
  }

  /// Gộp giỏ hàng cục bộ và từ xa, sau đó xóa giỏ hàng cục bộ.
  Future<void> mergeAndSyncCart(String userId) async {
    final localCart = await _localCartStorage.loadCart();
    if (localCart.isEmpty) {
      // Nếu không có giỏ hàng cục bộ, chỉ cần tải giỏ hàng từ xa.
      state = await _remoteCartRepository.getCart(userId);
      return;
    }

    final remoteCart = await _remoteCartRepository.getCart(userId);

    // Logic gộp: Thêm các sản phẩm từ giỏ hàng cục bộ vào giỏ hàng từ xa.
    // Nếu sản phẩm đã tồn tại, tăng số lượng.
    final mergedCart = List<CartItem>.from(remoteCart);
    for (final localItem in localCart) {
      final existingIndex = mergedCart.indexWhere(
        (remoteItem) => remoteItem.sku.id == localItem.sku.id && remoteItem.color.id == localItem.color.id,
      );
      if (existingIndex != -1) {
        final updatedItem = mergedCart[existingIndex].copyWith(
          quantity: mergedCart[existingIndex].quantity + localItem.quantity,
        );
        mergedCart[existingIndex] = updatedItem;
      } else {
        mergedCart.add(localItem);
      }
    }

    state = mergedCart;
    await _persistCart(); // Lưu giỏ hàng đã gộp lên Firestore
    await _localCartStorage.saveCart([]); // Xóa giỏ hàng cục bộ
  }

  /// Lưu giỏ hàng từ xa vào cục bộ khi đăng xuất.
  Future<void> persistRemoteCartToLocal(String userId) async {
    final remoteCart = await _remoteCartRepository.getCart(userId);
    await _localCartStorage.saveCart(remoteCart);
    state = remoteCart;
  }
}

/// Provider để truy cập vào CartNotifier và trạng thái của nó.
final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  // Việc khởi tạo ban đầu sẽ được xử lý trong main.dart
  throw UnimplementedError('cartProvider must be overridden');
});

/// Provider để tính tổng giá trị của giỏ hàng.
final cartTotalProvider = Provider<double>((ref) {
  final cart = ref.watch(cartProvider);
  return cart.fold(0, (total, item) => total + (item.priceDetails.finalPrice * item.quantity));
});