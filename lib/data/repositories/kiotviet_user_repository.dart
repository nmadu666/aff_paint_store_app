import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/kiotviet_user_model.dart';

/// Lớp trừu tượng định nghĩa các phương thức để lấy dữ liệu người dùng KiotViet.
abstract class IKiotVietUserRepository {
  /// Lấy thông tin chi tiết của một người dùng KiotViet từ Firestore bằng ID document.
  Future<KiotVietUser?> getKiotVietUserById(String id);

  /// Lấy danh sách tất cả người dùng KiotViet dưới dạng Map<String, String>.
  Future<List<MapEntry<String, String>>> getAllKiotVietUsersAsMap();
}

/// Triển khai repository sử dụng Firebase Firestore để tương tác với collection `kiotviet_users`.
class FirebaseKiotVietUserRepository implements IKiotVietUserRepository {
  final FirebaseFirestore _firestore;

  FirebaseKiotVietUserRepository(this._firestore);

  @override
  Future<KiotVietUser?> getKiotVietUserById(String id) async {
    final doc = await _firestore.collection('kiotviet_users').doc(id).get();
    if (doc.exists && doc.data() != null) {
      return KiotVietUser.fromMap(doc.data()!);
    }
    return null;
  }

  @override
  Future<List<MapEntry<String, String>>> getAllKiotVietUsersAsMap() async {
    final snapshot = await _firestore.collection('kiotviet_users').get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      // Key là ID document, Value là tên người dùng.
      // Cung cấp giá trị fallback nếu 'givenName' là null.
      final displayName = data['givenName'] as String? ?? 'Người dùng không tên';
      return MapEntry(doc.id, displayName);
    }).toList();
  }
}
