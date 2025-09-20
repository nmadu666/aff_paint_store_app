class SurchargeModel {
  int id; // Id thu khác
  String code; // Mã thu khác
  double price; // Giá trị thu khác

  SurchargeModel({
    required this.id,
    required this.code,
    required this.price,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'price': price,
    };
  }
}
