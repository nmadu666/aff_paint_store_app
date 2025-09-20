class OrderDetailModel {
  int productId; // Id hàng hóa
  String productCode; // Mã hàng hóa
  String productName; // Tên hàng hóa
  bool isMaster; // Tính năng thêm dòng, true: hàng hóa ở dòng chính, false: hàng hóa ở dòng phụ
  double quantity; // Số lượng hàng hóa
  double price; // Giá trị
  double? discount; // Giảm giá trên sản phẩm theo tiền (optional)
  double? discountRatio; // Giảm giá trên sản phẩm theo % (optional)
  String? note; // Ghi chú hàng hóa (optional)

  OrderDetailModel({
    required this.productId,
    required this.productCode,
    required this.productName,
    required this.isMaster,
    required this.quantity,
    required this.price,
    this.discount,
    this.discountRatio,
    this.note,
  });

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productCode': productCode,
      'productName': productName,
      'isMaster': isMaster,
      'quantity': quantity,
      'price': price,
      'discount': discount,
      'discountRatio': discountRatio,
      'note': note,
    };
  }
}
