import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/color_collection_model.dart';
import '../../../data/models/color_data_model.dart';
import '../application/color_providers.dart';

/// Hàm tiện ích để chuyển đổi chuỗi hex thành đối tượng Color của Flutter.
Color _hexToColor(String hexCode) {
  final buffer = StringBuffer();
  if (hexCode.length == 6 || hexCode.length == 7) buffer.write('ff');
  buffer.write(hexCode.replaceFirst('#', ''));
  try {
    // Trả về màu từ mã hex.
    return Color(int.parse(buffer.toString(), radix: 16));
  } catch (e) {
    // Nếu có lỗi (ví dụ: mã hex không hợp lệ), trả về một màu mặc định.
    return Colors.grey;
  }
}

/// Một trang hiển thị chi tiết các màu trong một bộ sưu tập cụ thể.
class ColorDetailPage extends ConsumerWidget {
  final ColorCollection collection;

  const ColorDetailPage({super.key, required this.collection});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Sử dụng provider `colorsByIdsProvider` để lấy dữ liệu các màu
    // dựa trên danh sách `colorRefs` từ bộ sưu tập.
    final colorsAsyncValue = ref.watch(
      colorsByIdsProvider(collection.colorRefs),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(collection.name),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: colorsAsyncValue.when(
        data: (colors) {
          if (colors.isEmpty) {
            return const Center(
              child: Text('Bộ sưu tập này không có màu nào.'),
            );
          }
          // Sắp xếp các màu theo độ sáng để có giao diện đẹp mắt hơn.
          colors.sort((a, b) => (b.lightness ?? 0).compareTo(a.lightness ?? 0));

          return GridView.builder(
            padding: const EdgeInsets.all(8.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, // Hiển thị 3 màu trên một hàng
              crossAxisSpacing: 8.0,
              mainAxisSpacing: 8.0,
              childAspectRatio: 0.8, // Tỉ lệ của mỗi ô màu
            ),
            itemCount: colors.length,
            itemBuilder: (context, index) {
              final color = colors[index];
              return _ColorTile(color: color);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Đã xảy ra lỗi khi tải màu: $err'),
          ),
        ),
      ),
    );
  }
}

/// Widget riêng để hiển thị một ô màu.
class _ColorTile extends StatelessWidget {
  final ColorData color;

  const _ColorTile({required this.color});

  @override
  Widget build(BuildContext context) {
    final colorSwatch = _hexToColor(color.hexCode);
    // Tự động chọn màu chữ (trắng hoặc đen) dựa trên độ sáng của màu nền.
    final textColor = colorSwatch.computeLuminance() > 0.5
        ? Colors.black
        : Colors.white;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2.0,
      child: Container(
        color: colorSwatch,
        padding: const EdgeInsets.all(8.0),
        alignment: Alignment.bottomCenter,
        child: Text(
          color.code,
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
