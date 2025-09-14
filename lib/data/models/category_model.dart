import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Đại diện cho một danh mục sản phẩm (ví dụ: Sơn nội thất).
class Category extends Equatable {
  final String id;
  final String name;

  const Category({required this.id, required this.name});

  /// Tạo một đối tượng Category từ một DocumentSnapshot của Firestore.
  factory Category.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data();
    if (data == null) {
      throw "Dữ liệu Category không tồn tại từ snapshot: ${snapshot.id}";
    }
    return Category(
      id: snapshot.id,
      name: data['name'] as String? ?? 'Danh mục không tên',
    );
  }

  @override
  List<Object?> get props => [id, name];
}

