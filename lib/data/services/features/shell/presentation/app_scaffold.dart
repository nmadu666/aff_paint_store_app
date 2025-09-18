import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../features/account/presentation/account_page.dart';
import '../../../../../features/cart/presentation/cart_page.dart';
import '../../../../../features/colors/presentation/color_collection_list_page.dart';
import '../../../../../features/customers/presentation/customer_list_page.dart';

/// Khung sườn chính của ứng dụng, chứa BottomNavigationBar.
class AppScaffold extends ConsumerStatefulWidget {
  const AppScaffold({super.key});

  @override
  ConsumerState<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends ConsumerState<AppScaffold> {
  int _selectedIndex = 0;

  // Danh sách các trang tương ứng với các mục trong BottomNavigationBar.
  static const List<Widget> _widgetOptions = <Widget>[
    ColorCollectionListPage(),
    CustomerListPage(),
    CartPage(),
    AccountPage(),
  ];

  // Danh sách các tiêu đề cho AppBar.
  static const List<String> _appBarTitles = <String>[
    'Bộ sưu tập màu',
    'Khách hàng',
    'Giỏ hàng',
    'Tài khoản',
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_appBarTitles[_selectedIndex]),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(child: _widgetOptions.elementAt(_selectedIndex)),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.color_lens),
            label: 'Màu sắc',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Khách hàng',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Giỏ hàng',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: 'Tài khoản',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        showUnselectedLabels: true,
      ),
    );
  }
}
