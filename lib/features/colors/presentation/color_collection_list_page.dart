import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/color_collection_providers.dart';
import 'color_detail_page.dart';

/// Một trang hiển thị danh sách các bộ sưu tập màu từ Firestore.
class ColorCollectionListPage extends ConsumerStatefulWidget {
  const ColorCollectionListPage({super.key});

  @override
  ConsumerState<ColorCollectionListPage> createState() =>
      _ColorCollectionListPageState();
}

class _ColorCollectionListPageState extends ConsumerState<ColorCollectionListPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // Yêu cầu giữ lại trạng thái của widget này.

  @override
  Widget build(BuildContext context) {
    super.build(context); // Quan trọng: phải gọi super.build khi dùng mixin.

    // 1. "Watch" the provider.
    // Chúng ta truyền `null` vào `family` provider để yêu cầu lấy tất cả các bộ sưu tập,
    // không lọc theo thương hiệu.
    final collectionsAsyncValue = ref.watch(colorCollectionsProvider(null));

    // 2. Sử dụng `when` để xử lý các trạng thái một cách an toàn.
    return collectionsAsyncValue.when(
      data: (collections) {
        // Nếu không có dữ liệu, hiển thị thông báo.
        if (collections.isEmpty) {
          return const Center(
            child: Text('Không có bộ sưu tập màu nào được tìm thấy.'),
          );
        }
        // Nếu có dữ liệu, hiển thị ListView.
        return ListView.builder(
          padding: const EdgeInsets.all(8.0),
          itemCount: collections.length,
          itemBuilder: (context, index) {
            final collection = collections[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8.0),
              child: ListTile(
                title: Text(collection.name),
                subtitle:
                    collection.description != null &&
                        collection.description!.isNotEmpty
                    ? Text(collection.description!)
                    : null,
                trailing: Chip(
                  label: Text('${collection.colorRefs.length} màu'),
                ),
                onTap: () {
                  // Điều hướng đến trang chi tiết bộ sưu tập,
                  // truyền vào đối tượng `collection` đã chọn.
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) =>
                          ColorDetailPage(collection: collection),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('Đã xảy ra lỗi: $err'),
        ),
      ),
    );
  }
}
