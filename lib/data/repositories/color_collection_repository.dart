import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/color_collection_model.dart';

/// Lớp trừu tượng định nghĩa các phương thức cần có để lấy dữ liệu bộ sưu tập màu.
abstract class IColorCollectionRepository {
  /// Lấy danh sách bộ sưu tập màu, có thể lọc theo ID của thương hiệu.
  ///
  /// Nếu [trademarkId] là null hoặc rỗng, nó sẽ trả về tất cả các bộ sưu tập.
  Future<List<ColorCollection>> getColorCollections({String? trademarkId});
}

/// Triển khai repository sử dụng Firebase Firestore.
class FirebaseColorCollectionRepository implements IColorCollectionRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<List<ColorCollection>> getColorCollections({
    String? trademarkId,
  }) async {
    // Bắt đầu với collection 'color_collections'
    Query query = _firestore.collection('color_collections');

    // Nếu có trademarkId, thêm điều kiện lọc vào truy vấn
    if (trademarkId != null && trademarkId.isNotEmpty) {
      query = query.where('trademark_ref', isEqualTo: trademarkId);
    }

    final snapshot = await query.get();

    // Chuyển đổi các documents thành danh sách các đối tượng ColorCollection
    return snapshot.docs
        .map(
          (doc) => ColorCollection.fromFirestore(
            doc as DocumentSnapshot<Map<String, dynamic>>,
          ),
        )
        .toList();
  }
}
