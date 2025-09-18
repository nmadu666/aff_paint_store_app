import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/branch_model.dart';

/// Lớp trừu tượng định nghĩa các phương thức để lấy dữ liệu chi nhánh.
abstract class IBranchRepository {
  /// Lấy thông tin chi tiết của một chi nhánh từ Firestore bằng ID document.
  Future<Branch?> getBranchById(String id);

  /// Lấy danh sách tất cả các chi nhánh.
  Future<List<Branch>> getAllBranches();
}

/// Triển khai repository sử dụng Firebase Firestore để tương tác với collection `branches`.
class FirebaseBranchRepository implements IBranchRepository {
  final FirebaseFirestore _firestore;

  FirebaseBranchRepository(this._firestore);

  @override
  Future<Branch?> getBranchById(String id) async {
    // Kiểm tra xem ID có rỗng không để tránh lỗi không cần thiết.
    if (id.isEmpty) return null;

    final doc = await _firestore.collection('branches').doc(id).get();
    if (doc.exists && doc.data() != null) {
      return Branch.fromFirestore(doc);
    }
    return null;
  }

  @override
  Future<List<Branch>> getAllBranches() async {
    final snapshot = await _firestore.collection('branches').get();
    return snapshot.docs.map((doc) => Branch.fromFirestore(doc)).toList();
  }
}
