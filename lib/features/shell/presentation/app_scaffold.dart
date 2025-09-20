import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../cart/presentation/cart_page.dart';
import '../../cart/presentation/widgets/cart_icon_widget.dart';
import '../../account/presentation/account_page.dart';
import '../../colors/presentation/color_collection_list_page.dart';
import '../../customers/presentation/customer_list_page.dart';
import '../../orders/presentation/orders_list_screen.dart';
import '../../products/presentation/product_list_page.dart';

/// Provider to manage the selected page index.
final selectedIndexProvider = StateProvider<int>((ref) => 0);

/// Constants for tab indices to avoid hard-coding.
class AppTabs {
  static const int colors = 0;
  static const int products = 1;
  static const int customers = 2;
  static const int orders = 3; // Add new tab for orders
  static const int cart = 4;
  static const int account = 5;
}

/// Data class for a destination in the navigation bar.
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

/// List of the main pages of the app.
final _destinations = [
  _NavigationDestination(
    label: 'Màu sắc',
    icon: Icons.color_lens_outlined,
    selectedIcon: Icons.color_lens,
    body: const ColorCollectionListPage(),
  ),
  _NavigationDestination(
    label: 'Sản phẩm',
    icon: Icons.category_outlined,
    selectedIcon: Icons.category,
    body: ProductListPage(),
  ),
  _NavigationDestination(
    label: 'Khách hàng',
    icon: Icons.people_outline,
    selectedIcon: Icons.people,
    body: CustomerListPage(),
  ),
  _NavigationDestination( // Add the new destination for Orders
    label: 'Đơn hàng',
    icon: Icons.receipt_long_outlined,
    selectedIcon: Icons.receipt_long,
    body: const OrdersListScreen(),
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

/// Main scaffold widget of the app, containing the navigation bar
/// and adaptable to different screen sizes.
class AppScaffold extends ConsumerWidget {
  const AppScaffold({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(selectedIndexProvider);

    // Create the list of body widgets once to provide to IndexedStack.
    final pageBodies = _destinations.map((d) => d.body).toList();

    // Use LayoutBuilder to decide whether to show NavigationRail or NavigationBar.
    return LayoutBuilder(
      builder: (context, constraints) {
        // Wide screen (desktop/landscape tablet)
        if (constraints.maxWidth >= 640) {
          return Scaffold(
            appBar: AppBar(
              // Get the title from the destination corresponding to the selected index.
              title: Text(_destinations[selectedIndex].label),
              backgroundColor: Theme.of(context).colorScheme.inversePrimary,
              actions: const [
                // CartIconWidget is still here for quick access
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
                // Use IndexedStack to preserve the state of the pages.
                Expanded(
                  // Replace IndexedStack with AnimatedSwitcher for an effect.
                  // The key of the child (pageBodies[selectedIndex]) is different for each tab,
                  // which triggers the animation.
                  child: AnimatedSwitcher(
                    duration: const Duration(
                      milliseconds: 250,
                    ), // Transition duration
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      // Determine the slide direction based on the child's index.
                      // We need the key to identify which child is the new one.
                      final newIndex = _destinations.indexWhere(
                        (d) => d.body.key == child.key,
                      );
                      final oldIndex = selectedIndex;

                      // If not found (rare case), use the default fade effect.
                      if (newIndex == -1) {
                        return FadeTransition(opacity: animation, child: child);
                      }

                      // +1.0: slide from right to left, -1.0: slide from left to right.
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
                    // The child widget will change based on selectedIndex
                    child: pageBodies[selectedIndex],
                  ),
                ),
              ],
            ),
          );
        }

        // Narrow screen (mobile)
        return Scaffold(
          appBar: AppBar(
            title: Text(_destinations[selectedIndex].label),
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            // On mobile, the cart icon is already in the bottom navigation bar
            // so it can be hidden from the AppBar to avoid repetition.
            // actions: const [ CartIconWidget() ],
          ),
          // Use IndexedStack to preserve the state of the pages.
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
            // The key of the child is very important for AnimatedSwitcher to know which widget is new/old.
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

/// To complete, you need to update the `main.dart` file
/// to use `AppScaffold` as the `home` widget of `MaterialApp`.
///
/// Example in `main.dart`:
///
/// home: const AppScaffold(),
