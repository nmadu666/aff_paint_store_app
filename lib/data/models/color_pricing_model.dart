import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class ColorPricing extends Equatable {
  final String id;
  final String colorRef;
  final String colorMixingProductType;
  final String base;
  final double pricePerMl;

  const ColorPricing({
    required this.id,
    required this.colorRef,
    required this.colorMixingProductType,
    required this.base,
    required this.pricePerMl,
  });

  factory ColorPricing.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data();
    if (data == null) {
      throw "Dữ liệu ColorPricing không tồn tại từ snapshot: ${snapshot.id}";
    }
    return ColorPricing(
      id: snapshot.id,
      colorRef: data['color_ref'] ?? '',
      colorMixingProductType: data['color_mixing_product_type'] ?? '',
      base: data['base'] ?? '',
      pricePerMl: (data['pricePerMl'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'color_ref': colorRef,
      'color_mixing_product_type': colorMixingProductType,
      'base': base,
      'pricePerMl': pricePerMl,
    };
  }

  @override
  List<Object?> get props =>
      [id, colorRef, colorMixingProductType, base, pricePerMl];
}
