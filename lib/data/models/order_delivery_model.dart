class OrderDeliveryModel {
  String? deliveryCode; // Mã vận đơn (optional)
  int? type; // Loại hình giao hàng (optional)
  double? price; // Giá giao hàng (optional)
  String? receiver; // Người nhận (optional)
  String? contactNumber; // Số điện thoại liên hệ (optional)
  String? address; // Địa chỉ giao hàng (optional)
  int? locationId; // Id khu vực (optional)
  String? locationName; // Tên khu vực (optional)
  String? wardName; // Tên phường/xã (optional)
  double? weight; // Trọng lượng (optional)
  double? length; // Chiều dài (optional)
  double? width; // Chiều rộng (optional)
  double? height; // Chiều cao (optional)
  int? partnerDeliveryId; // Id đối tác giao hàng (optional)
  DateTime? expectedDelivery; // Thời gian giao hàng dự kiến (optional)
  PartnerDeliveryModel? partnerDelivery; // Chi tiết đối tác giao hàng (optional)

  OrderDeliveryModel({
    this.deliveryCode,
    this.type,
    this.price,
    this.receiver,
    this.contactNumber,
    this.address,
    this.locationId,
    this.locationName,
    this.wardName,
    this.weight,
    this.length,
    this.width,
    this.height,
    this.partnerDeliveryId,
    this.expectedDelivery,
    this.partnerDelivery,
  });

  Map<String, dynamic> toJson() {
    return {
      'deliveryCode': deliveryCode,
      'type': type,
      'price': price,
      'receiver': receiver,
      'contactNumber': contactNumber,
      'address': address,
      'locationId': locationId,
      'locationName': locationName,
      'wardName': wardName,
      'weight': weight,
      'length': length,
      'width': width,
      'height': height,
      'partnerDeliveryId': partnerDeliveryId,
      'expectedDelivery': expectedDelivery?.toIso8601String(),
      'partnerDelivery': partnerDelivery?.toJson(),
    };
  }
}

class PartnerDeliveryModel {
  String? code; // Mã đối tác giao hàng (optional)
  String? name; // Tên đối tác giao hàng (optional)
  String? address; // Địa chỉ đối tác giao hàng (optional)
  String? contactNumber; // Số điện thoại đối tác giao hàng (optional)
  String? email; // Email đối tác giao hàng (optional)

  PartnerDeliveryModel({
    this.code,
    this.name,
    this.address,
    this.contactNumber,
    this.email,
  });

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      'address': address,
      'contactNumber': contactNumber,
      'email': email,
    };
  }
}
