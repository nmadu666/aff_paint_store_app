import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/cart_item.dart';

/// Lớp trừu tượng định nghĩa các phương thức cho giỏ hàng từ xa.
abstract class IRemoteCartRepository {
  /// Lấy giỏ hàng của người dùng từ Firestore.
  Future<List<CartItem>> getCart(String userId);

  /// Lưu/Ghi đè toàn bộ giỏ hàng của người dùng lên Firestore.
  Future<void> saveCart(String userId, List<CartItem> cart);

  /// Xóa giỏ hàng của người dùng trên Firestore.
  Future<void> clearCart(String userId);
}

/// Triển khai repository sử dụng Firebase Firestore.
class FirestoreCartRepository implements IRemoteCartRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Lấy tham chiếu đến document giỏ hàng của người dùng.
  DocumentReference _getCartDocRef(String userId) {
    return _firestore.collection('users').doc(userId).collection('cart').doc('current');
  }

  @override
  Future<List<CartItem>> getCart(String userId) async {
    final doc = await _getCartDocRef(userId).get();
    if (!doc.exists || doc.data() == null) {
      return [];
    }
    final data = doc.data() as Map<String, dynamic>;
    final cartString = data['items_json'] as String?;
    if (cartString == null || cartString.isEmpty) {
      return [];
    }
    final List<dynamic> cartJson = json.decode(cartString);
    return cartJson.map((jsonItem) => CartItem.fromJson(jsonItem as Map<String, dynamic>)).toList();
  }

  @override
  Future<void> saveCart(String userId, List<CartItem> cart) async {
    final List<Map<String, dynamic>> cartJson = cart.map((item) => item.toJson()).toList();
    await _getCartDocRef(userId).set({'items_json': json.encode(cartJson)});
  }

  @override
  Future<void> clearCart(String userId) async {
    await _getCartDocRef(userId).delete();
  }
}