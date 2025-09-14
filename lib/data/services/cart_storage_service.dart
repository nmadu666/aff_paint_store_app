import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cart_item.dart';

/// Lớp trừu tượng định nghĩa các phương thức lưu trữ giỏ hàng.
abstract class ICartStorageService {
  Future<void> saveCart(List<CartItem> cart);
  Future<List<CartItem>> loadCart();
}

/// Triển khai dịch vụ lưu trữ giỏ hàng bằng SharedPreferences.
class SharedPreferencesCartStorage implements ICartStorageService {
  static const _cartKey = 'shopping_cart';

  @override
  Future<void> saveCart(List<CartItem> cart) async {
    final prefs = await SharedPreferences.getInstance();
    // Chuyển đổi danh sách CartItem thành danh sách Map, sau đó thành chuỗi JSON.
    final List<Map<String, dynamic>> cartJson = cart.map((item) => item.toJson()).toList();
    await prefs.setString(_cartKey, json.encode(cartJson));
  }

  @override
  Future<List<CartItem>> loadCart() async {
    final prefs = await SharedPreferences.getInstance();
    final String? cartString = prefs.getString(_cartKey);

    if (cartString == null) {
      return []; // Nếu không có dữ liệu, trả về giỏ hàng rỗng.
    }

    // Giải mã chuỗi JSON thành danh sách Map, sau đó thành danh sách CartItem.
    final List<dynamic> cartJson = json.decode(cartString);
    return cartJson.map((jsonItem) => CartItem.fromJson(jsonItem as Map<String, dynamic>)).toList();
  }
}

