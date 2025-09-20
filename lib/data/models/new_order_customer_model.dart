class CustomerModel {
  int? id; // ID khách hàng (optional)
  String? code; // Mã khách hàng (optional)
  String? name; // Tên khách hàng (optional)
  bool? gender; // Giới tính (true: nam, false: nữ) (optional)
  DateTime? birthDate; // Ngày sinh khách hàng (optional)
  String? contactNumber; // Số điện thoại khách hàng (optional)
  String? address; // Địa chỉ khách hàng (optional)
  String? wardName; // Tên phường/xã (optional)
  String? email; // Email của khách hàng (optional)
  String? comments; // Ghi chú (optional)

  CustomerModel({
    this.id,
    this.code,
    this.name,
    this.gender,
    this.birthDate,
    this.contactNumber,
    this.address,
    this.wardName,
    this.email,
    this.comments,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'gender': gender,
      'birthDate': birthDate?.toIso8601String(),
      'contactNumber': contactNumber,
      'address': address,
      'wardName': wardName,
      'email': email,
      'comments': comments,
    };
  }
}
