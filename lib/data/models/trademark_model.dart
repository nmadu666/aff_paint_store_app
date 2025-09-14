import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Đại diện cho một thương hiệu (ví dụ: Mykolor, Spec).
class Trademark extends Equatable {
  final String id;
  final String name;

  const Trademark({required this.id, required this.name});

  /// Tạo một đối tượng Trademark từ một DocumentSnapshot của Firestore.
  factory Trademark.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data();
    if (data == null) {
      throw "Dữ liệu Trademark không tồn tại từ snapshot: ${snapshot.id}";
    }
    return Trademark(
      id: snapshot.id,
      name: data['name'] as String? ?? 'Thương hiệu không tên',
    );
  }

  @override
  List<Object?> get props => [id, name];
}

