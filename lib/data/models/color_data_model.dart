import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

// Đặt tên là ColorData để tránh trùng với lớp Color của Flutter
class ColorData extends Equatable {
  final String id;
  final String code;
  final String name;
  final String ncs;
  final String hexCode;
  // --- Fields from Apps Script Sync ---
  final String trademarkRef;
  final List<String> collectionRefs;
  final String? tone;
  final int? lightness;

  const ColorData({
    required this.id,
    required this.code,
    required this.name,
    required this.ncs,
    required this.hexCode,
    required this.trademarkRef,
    required this.collectionRefs,
    this.tone,
    this.lightness,
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
      collectionRefs: data['collection_refs'] != null
          ? List<String>.from(data['collection_refs'])
          : [],
      tone: data['tone'],
      lightness: data['lightness'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'code': code,
      'name': name,
      'ncs': ncs,
      'hexCode': hexCode,
      'trademark_ref': trademarkRef,
      'collection_refs': collectionRefs,
      'tone': tone,
      'lightness': lightness,
    };
  }

  @override
  List<Object?> get props => [
        id,
        code,
        name,
        ncs,
        hexCode,
        trademarkRef,
        collectionRefs,
        tone,
        lightness
      ];
}
