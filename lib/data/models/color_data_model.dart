import 'package:cloud_firestore/cloud_firestore.dart';

// Đặt tên là ColorData để tránh trùng với lớp Color của Flutter
class ColorData {
  final String id;
  final String code;
  final String name;
  final String ncs;
  final String hexCode;
  final String trademarkRef;

  ColorData({
    required this.id,
    required this.code,
    required this.name,
    required this.ncs,
    required this.hexCode,
    required this.trademarkRef,
  });

  factory ColorData.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data();
    if (data == null) {
      throw "Dữ liệu ColorData không tồn tại từ snapshot: ${snapshot.id}";
    }
    return ColorData(
      id: snapshot.id,
      code: data['code'] ?? '',
      name: data['name'] ?? '',
      ncs: data['ncs'] ?? '',
      hexCode: data['hexCode'] ?? '',
      trademarkRef: data['trademark_ref'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'code': code,
      'name': name,
      'ncs': ncs,
      'hexCode': hexCode,
      'trademark_ref': trademarkRef,
    };
  }
}
