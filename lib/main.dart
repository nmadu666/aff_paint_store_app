import 'package:aff_paint_store_app/features/cart/application/cart_provider.dart';
import 'package:aff_paint_store_app/features/cart/application/cart_sync_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aff_paint_store_app/features/auth/presentation/auth_wrapper.dart';

import 'features/auth/application/auth_providers.dart';
import 'data/services/cart_storage_service.dart';
import 'firebase_options.dart';

Future<void> main() async {
  // 1. Phải gọi ensureInitialized() trước khi sử dụng các plugin như Firebase.
  WidgetsFlutterBinding.ensureInitialized();
  // Khởi tạo Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Tải giỏ hàng ban đầu từ bộ nhớ cục bộ.
  final cartStorage = SharedPreferencesCartStorage();
  final initialCartItems = await cartStorage.loadCart();

  // 2. Chỉ gọi runApp một lần duy nhất, và bọc MyApp trong ProviderScope
  // để tất cả các widget con có thể truy cập providers.
  runApp(
    ProviderScope(
      overrides: [
        // Ghi đè cartStorageProvider để sử dụng lại instance đã tạo.
        cartStorageProvider.overrideWithValue(cartStorage),
        // Ghi đè cartProvider với Notifier đã được khởi tạo với dữ liệu đã lưu.
        cartProvider.overrideWith(
          (ref) => CartNotifier(
            ref.watch(authRepositoryProvider),
            cartStorage, // Sử dụng trực tiếp instance đã có.
            ref.watch(remoteCartRepositoryProvider),
            initialCartItems,
          ),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Kích hoạt cartSyncProvider để nó bắt đầu lắng nghe trạng thái đăng nhập.
    ref.watch(cartSyncProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AFF Paint Store',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      // AuthWrapper sẽ quyết định hiển thị AuthPage hay AppScaffold
      home: const AuthWrapper(),
    );
  }
}
