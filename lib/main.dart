import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aff_paint_store_app/features/colors/presentation/color_collection_list_page.dart';

import 'firebase_options.dart';

Future<void> main() async {
  // 1. Phải gọi ensureInitialized() trước khi sử dụng các plugin như Firebase.
  WidgetsFlutterBinding.ensureInitialized();
  // Khởi tạo Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 2. Chỉ gọi runApp một lần duy nhất, và bọc MyApp trong ProviderScope
  // để tất cả các widget con có thể truy cập providers.
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AFF Paint Store',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      // Đặt trang danh sách bộ sưu tập màu làm trang chủ để demo
      home: const ColorCollectionListPage(),
    );
  }
}
