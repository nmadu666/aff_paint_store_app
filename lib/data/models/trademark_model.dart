import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class Trademark extends Equatable {
  final String id;
  final String name;

  const Trademark({required this.id, required this.name});

  @override
  List<Object?> get props => [id, name];

  factory Trademark.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data();
    if (data == null) {
      throw "Dữ liệu Trademark không tồn tại từ snapshot: ${snapshot.id}";
    }
    return Trademark(
      id: snapshot.id,
      name: data['name'] as String? ?? 'Chưa có tên',
    );
  }
}