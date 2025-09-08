import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/cart_provider.dart';
import '../cart_page.dart';

/// Một widget hiển thị icon giỏ hàng cùng với số lượng sản phẩm hiện có.
class CartIconWidget extends ConsumerWidget {
  const CartIconWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Theo dõi số lượng sản phẩm trong giỏ hàng.
    // Chỉ lấy `length` để widget chỉ build lại khi số lượng thay đổi.
    final itemCount = ref.watch(cartProvider.select((cart) => cart.length));

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Stack(
        alignment: Alignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const CartPage()),
              );
            },
          ),
          if (itemCount > 0)
            Positioned(
              right: 5,
              top: 5,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                child: Text(
                  '$itemCount',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}