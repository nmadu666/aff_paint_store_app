import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../cart/presentation/cart_page.dart';
import '../../cart/presentation/widgets/cart_icon_widget.dart';
import '../../account/presentation/account_page.dart';
import '../../colors/presentation/color_collection_list_page.dart';
import '../../products/presentation/product_list_page.dart';

/// Provider để quản lý chỉ mục (index) của trang đang được chọn.
final selectedIndexProvider = StateProvider<int>((ref) => 0);

/// Hằng số cho các chỉ mục của tab để tránh hard-coding.
class AppTabs {
  static const int colors = 0;
  static const int products = 1;
  static const int cart = 2;
  static const int account = 3;
}

/// Lớp dữ liệu cho một đích đến trong thanh điều hướng.
class _NavigationDestination {
  const _NavigationDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.body,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Widget body;
}

/// Danh sách các trang chính của ứng dụng.
const _destinations = [
  _NavigationDestination(
    label: 'Màu sắc',
    icon: Icons.color_lens_outlined,
    selectedIcon: Icons.color_lens,
    body: ColorCollectionListPage(),
  ),
  _NavigationDestination(
    label: 'Sản phẩm',
    icon: Icons.category_outlined,
    selectedIcon: Icons.category,
    body: ProductListPage(),
  ),
  _NavigationDestination(
    label: 'Giỏ hàng',
    icon: Icons.shopping_cart_outlined,
    selectedIcon: Icons.shopping_cart,
    body: CartPage(),
  ),
  _NavigationDestination(
    label: 'Tài khoản',
    icon: Icons.person_outline,
    selectedIcon: Icons.person,
    body: AccountPage(),
  ),
];

/// Widget khung sườn chính của ứng dụng, chứa thanh điều hướng
/// và có khả năng thích ứng với các kích thước màn hình khác nhau.
class AppScaffold extends ConsumerWidget {
  const AppScaffold({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(selectedIndexProvider);

    // Tạo danh sách các widget body một lần để cung cấp cho IndexedStack.
    final pageBodies = _destinations.map((d) => d.body).toList();

    // Sử dụng LayoutBuilder để quyết định hiển thị NavigationRail hay NavigationBar.
    return LayoutBuilder(
      builder: (context, constraints) {
        // Màn hình rộng (desktop/tablet ngang)
        if (constraints.maxWidth >= 640) {
          return Scaffold(
            appBar: AppBar(
              // Lấy tiêu đề từ destination tương ứng với index đang chọn.
              title: Text(_destinations[selectedIndex].label),
              backgroundColor: Theme.of(context).colorScheme.inversePrimary,
              actions: const [
                // CartIconWidget vẫn nằm ở đây để truy cập nhanh
                CartIconWidget(),
              ],
            ),
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: selectedIndex,
                  onDestinationSelected: (index) =>
                      ref.read(selectedIndexProvider.notifier).state = index,
                  labelType: NavigationRailLabelType.all,
                  destinations: _destinations.map((d) {
                    return NavigationRailDestination(
                      icon: Icon(d.icon),
                      selectedIcon: Icon(d.selectedIcon),
                      label: Text(d.label),
                    );
                  }).toList(),
                ),
                const VerticalDivider(thickness: 1, width: 1),
                // Sử dụng IndexedStack để giữ trạng thái của các trang.
                Expanded(
                  // Thay thế IndexedStack bằng AnimatedSwitcher để có hiệu ứng.
                  // Key của child (pageBodies[selectedIndex]) là khác nhau cho mỗi tab,
                  // điều này kích hoạt animation.
                  child: AnimatedSwitcher(
                    duration: const Duration(
                      milliseconds: 250,
                    ), // Thời gian chuyển đổi
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      // Xác định hướng trượt dựa trên index của child.
                      // Chúng ta cần key để xác định child nào là child mới.
                      final newIndex = _destinations.indexWhere(
                        (d) => d.body.key == child.key,
                      );
                      final oldIndex = selectedIndex;

                      // Nếu không tìm thấy (trường hợp hiếm), dùng hiệu ứng fade mặc định.
                      if (newIndex == -1) {
                        return FadeTransition(opacity: animation, child: child);
                      }

                      // +1.0: trượt từ phải sang, -1.0: trượt từ trái sang.
                      final offset = (newIndex > oldIndex) ? 1.0 : -1.0;

                      final slideAnimation = Tween<Offset>(
                        begin: Offset(offset, 0),
                        end: Offset.zero,
                      ).animate(animation);
                      return SlideTransition(
                        position: slideAnimation,
                        child: child,
                      );
                    },
                    // Widget con sẽ thay đổi dựa trên selectedIndex
                    child: pageBodies[selectedIndex],
                  ),
                ),
              ],
            ),
          );
        }

        // Màn hình hẹp (mobile)
        return Scaffold(
          appBar: AppBar(
            title: Text(_destinations[selectedIndex].label),
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            // Trên mobile, icon giỏ hàng đã có ở thanh điều hướng dưới
            // nên có thể ẩn đi ở AppBar để tránh lặp lại.
            // actions: const [ CartIconWidget() ],
          ),
          // Sử dụng IndexedStack để giữ trạng thái của các trang.
          body: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (Widget child, Animation<double> animation) {
              final newIndex = _destinations.indexWhere(
                (d) => d.body.key == child.key,
              );
              final oldIndex = selectedIndex;

              if (newIndex == -1) {
                return FadeTransition(opacity: animation, child: child);
              }

              final offset = (newIndex > oldIndex) ? 1.0 : -1.0;

              final slideAnimation = Tween<Offset>(
                begin: Offset(offset, 0),
                end: Offset.zero,
              ).animate(animation);
              return SlideTransition(position: slideAnimation, child: child);
            },
            // Key của child rất quan trọng để AnimatedSwitcher biết widget nào là mới/cũ.
            child: pageBodies[selectedIndex],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: selectedIndex,
            onDestinationSelected: (index) =>
                ref.read(selectedIndexProvider.notifier).state = index,
            destinations: _destinations.map((d) {
              return NavigationDestination(
                icon: Icon(d.icon),
                selectedIcon: Icon(d.selectedIcon),
                label: d.label,
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

/// Để hoàn tất, bạn cần cập nhật file `main.dart`
/// để sử dụng `AppScaffold` làm widget `home` của `MaterialApp`.
///
/// Ví dụ trong `main.dart`:
///
/// home: const AppScaffold(),
