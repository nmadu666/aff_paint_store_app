import 'package:equatable/equatable.dart';

class OrderModel extends Equatable {
  final int? id;
  final String? code;
  final bool? isApplyVoucher;
  final DateTime? purchaseDate;
  final int? branchId;
  final String? branchName;
  final int? soldById;
  final int? cashierId;
  final double? discountRatio;
  final double? discount;
  final int? status;
  final String? statusValue;
  final String? description;
  final String? method;
  final double? total;
  final double? totalPayment;
  final int? accountId;
  final bool? makeInvoice;
  final bool? usingCod;
  final int? saleChannelId;
  final DateTime? createdDate;
  final DateTime? modifiedDate;

  // Customer info (can be flattened or in a nested object)
  final int? customerId;
  final String? customerCode;
  final String? customerName;

  final List<OrderDetailModel>? orderDetails;
  final OrderDeliveryModel? orderDelivery;
  final CustomerModel? customer;
  final List<SurchargeModel>? surcharges;
  final List<PaymentModel>? payments;

  const OrderModel({
    this.isApplyVoucher,
    this.id,
    this.code,
    this.purchaseDate,
    this.branchId,
    this.branchName,
    this.soldById,
    this.cashierId,
    this.discountRatio,
    this.discount,
    this.status,
    this.statusValue,
    this.description,
    this.method,
    this.total,
    this.totalPayment,
    this.accountId,
    this.usingCod,
    this.createdDate,
    this.modifiedDate,
    this.customerId,
    this.customerCode,
    this.customerName,
    this.makeInvoice,
    this.saleChannelId,
    required this.orderDetails,
    this.orderDelivery,
    this.customer,
    this.surcharges,
    this.payments,
  });

  OrderModel copyWith({
    int? id,
    String? code,
    bool? isApplyVoucher,
    DateTime? purchaseDate,
    int? branchId,
    String? branchName,
    int? soldById,
    int? cashierId,
    double? discountRatio,
    double? discount,
    int? status,
    String? statusValue,
    String? description,
    String? method,
    double? total,
    double? totalPayment,
    int? accountId,
    bool? makeInvoice,
    bool? usingCod,
    int? saleChannelId,
    DateTime? createdDate,
    DateTime? modifiedDate,
    int? customerId,
    String? customerCode,
    String? customerName,
    List<OrderDetailModel>? orderDetails,
    OrderDeliveryModel? orderDelivery,
    CustomerModel? customer,
    List<SurchargeModel>? surcharges,
    List<PaymentModel>? payments,
  }) {
    return OrderModel(
      id: id ?? this.id,
      code: code ?? this.code,
      isApplyVoucher: isApplyVoucher ?? this.isApplyVoucher,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      branchId: branchId ?? this.branchId,
      branchName: branchName ?? this.branchName,
      soldById: soldById ?? this.soldById,
      cashierId: cashierId ?? this.cashierId,
      discountRatio: discountRatio ?? this.discountRatio,
      discount: discount ?? this.discount,
      status: status ?? this.status,
      statusValue: statusValue ?? this.statusValue,
      description: description ?? this.description,
      method: method ?? this.method,
      total: total ?? this.total,
      totalPayment: totalPayment ?? this.totalPayment,
      accountId: accountId ?? this.accountId,
      makeInvoice: makeInvoice ?? this.makeInvoice,
      usingCod: usingCod ?? this.usingCod,
      saleChannelId: saleChannelId ?? this.saleChannelId,
      createdDate: createdDate ?? this.createdDate,
      modifiedDate: modifiedDate ?? this.modifiedDate,
      customerId: customerId ?? this.customerId,
      customerCode: customerCode ?? this.customerCode,
      customerName: customerName ?? this.customerName,
      orderDetails: orderDetails ?? this.orderDetails,
      orderDelivery: orderDelivery ?? this.orderDelivery,
      customer: customer ?? this.customer,
      surcharges: surcharges ?? this.surcharges,
      payments: payments ?? this.payments,
    );
  }

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'],
      code: json['code'],
      isApplyVoucher: json['isApplyVoucher'],
      purchaseDate: json['purchaseDate'] != null ? DateTime.parse(json['purchaseDate']) : null,
      branchId: json['branchId'],
      branchName: json['branchName'],
      soldById: json['soldById'],
      cashierId: json['cashierId'],
      discountRatio: (json['discountRatio'] as num?)?.toDouble(),
      discount: (json['discount'] as num?)?.toDouble(),
      status: json['status'],
      statusValue: json['statusValue'],
      description: json['description'],
      method: json['method'],
      total: (json['total'] as num?)?.toDouble(),
      totalPayment: (json['totalPayment'] as num?)?.toDouble(),
      accountId: json['accountId'],
      makeInvoice: json['makeInvoice'],
      usingCod: json['usingCod'],
      saleChannelId: json['saleChannelId'] ?? json['SaleChannelId'],
      createdDate: json['createdDate'] != null ? DateTime.parse(json['createdDate']) : null,
      modifiedDate: json['modifiedDate'] != null ? DateTime.parse(json['modifiedDate']) : null,
      customerId: json['customerId'],
      customerCode: json['customerCode'],
      customerName: json['customerName'],
      orderDetails: (json['orderDetails'] as List?)
          ?.map((i) => OrderDetailModel.fromJson(i))
          .toList(),
      orderDelivery: json['orderDelivery'] != null
          ? OrderDeliveryModel.fromJson(json['orderDelivery'])
          : null,
      customer: json['customer'] != null
          ? CustomerModel.fromJson(json['customer'])
          : (json['customerId'] != null
              ? CustomerModel(
                  id: json['customerId'],
                  code: json['customerCode'],
                  name: json['customerName'])
              : null),
      surcharges: (json['surcharges'] as List?)
          ?.map((i) => SurchargeModel.fromJson(i))
          .toList(),
      payments: (json['payments'] as List?)
          ?.map((i) => PaymentModel.fromJson(i))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'isApplyVoucher': isApplyVoucher,
      'purchaseDate': purchaseDate?.toIso8601String(),
      'branchId': branchId,
      'branchName': branchName,
      'soldById': soldById,
      'cashierId': cashierId,
      'discountRatio': discountRatio,
      'discount': discount,
      'status': status,
      'statusValue': statusValue,
      'description': description,
      'method': method,
      'total': total,
      'totalPayment': totalPayment,
      'accountId': accountId,
      'makeInvoice': makeInvoice,
      'usingCod': usingCod,
      'saleChannelId': saleChannelId,
      'createdDate': createdDate?.toIso8601String(),
      'modifiedDate': modifiedDate?.toIso8601String(),
      'customerId': customerId,
      'customerCode': customerCode,
      'customerName': customerName,
      'orderDetails': orderDetails?.map((detail) => detail.toJson()).toList(),
      'orderDelivery': orderDelivery?.toJson(),
      'customer': customer?.toJson(),
      'surcharges': surcharges?.map((s) => s.toJson()).toList(),
      'payments': payments?.map((p) => p.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        code,
        isApplyVoucher,
        purchaseDate,
        branchId,
        branchName,
        soldById,
        cashierId,
        discountRatio,
        discount,
        status,
        statusValue,
        description,
        method,
        total,
        totalPayment,
        accountId,
        makeInvoice,
        usingCod,
        saleChannelId,
        createdDate,
        modifiedDate,
        customerId,
        customerCode,
        customerName,
        orderDetails,
        orderDelivery,
        customer,
        surcharges,
        payments,
      ];
}

class OrderDetailModel extends Equatable {
  final int productId;
  final String productCode;
  final String productName;
  final bool? isMaster;
  final double quantity;
  final double price;
  final double? discount;
  final double? discountRatio;
  final String? note;

  const OrderDetailModel({
    required this.productId,
    required this.productCode,
    required this.productName,
    this.isMaster,
    required this.quantity,
    required this.price,
    this.discount,
    this.discountRatio,
    this.note,
  });

  OrderDetailModel copyWith({
    int? productId,
    String? productCode,
    String? productName,
    bool? isMaster,
    double? quantity,
    double? price,
    double? discount,
    double? discountRatio,
    String? note,
  }) {
    return OrderDetailModel(
      productId: productId ?? this.productId,
      productCode: productCode ?? this.productCode,
      productName: productName ?? this.productName,
      isMaster: isMaster ?? this.isMaster,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      discount: discount ?? this.discount,
      discountRatio: discountRatio ?? this.discountRatio,
      note: note ?? this.note,
    );
  }

  factory OrderDetailModel.fromJson(Map<String, dynamic> json) {
    return OrderDetailModel(
      productId: json['productId'],
      productCode: json['productCode'],
      productName: json['productName'],
      isMaster: json['isMaster'],
      quantity: (json['quantity'] as num).toDouble(),
      price: (json['price'] as num).toDouble(),
      discount: (json['discount'] as num?)?.toDouble(),
      discountRatio: (json['discountRatio'] as num?)?.toDouble(),
      note: json['note'],
    );
  }

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

  @override
  List<Object?> get props => [
        productId,
        productCode,
        productName,
        isMaster,
        quantity,
        price,
        discount,
        discountRatio,
        note,
      ];
}

class OrderDeliveryModel extends Equatable {
  final String? deliveryCode;
  final int? type;
  final double? price;
  final String? receiver;
  final String? contactNumber;
  final String? address;
  final int? locationId;
  final String? locationName;
  final String? wardName;
  final double? weight;
  final double? length;
  final double? width;
  final double? height;
  final int? partnerDeliveryId;
  final DateTime? expectedDelivery;
  final PartnerDeliveryModel? partnerDelivery;

  const OrderDeliveryModel({
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

  factory OrderDeliveryModel.fromJson(Map<String, dynamic> json) {
    return OrderDeliveryModel(
      deliveryCode: json['deliveryCode'],
      type: json['type'],
      price: (json['price'] as num?)?.toDouble(),
      receiver: json['receiver'],
      contactNumber: json['contactNumber'],
      address: json['address'],
      locationId: json['locationId'],
      locationName: json['locationName'],
      wardName: json['wardName'],
      weight: (json['weight'] as num?)?.toDouble(),
      length: (json['length'] as num?)?.toDouble(),
      width: (json['width'] as num?)?.toDouble(),
      height: (json['height'] as num?)?.toDouble(),
      partnerDeliveryId: json['partnerDeliveryId'],
      expectedDelivery: json['expectedDelivery'] != null
          ? DateTime.parse(json['expectedDelivery'])
          : null,
      partnerDelivery: json['partnerDelivery'] != null
          ? PartnerDeliveryModel.fromJson(json['partnerDelivery'])
          : null,
    );
  }

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

  @override
  List<Object?> get props => [
        deliveryCode,
        type,
        price,
        receiver,
        contactNumber,
        address,
        locationId,
        locationName,
        wardName,
        weight,
        length,
        width,
        height,
        partnerDeliveryId,
        expectedDelivery,
        partnerDelivery,
      ];
}

class PartnerDeliveryModel extends Equatable {
  final String? code;
  final String? name;
  final String? address;
  final String? contactNumber;
  final String? email;

  const PartnerDeliveryModel({
    this.code,
    this.name,
    this.address,
    this.contactNumber,
    this.email,
  });

  factory PartnerDeliveryModel.fromJson(Map<String, dynamic> json) {
    return PartnerDeliveryModel(
      code: json['code'],
      name: json['name'],
      address: json['address'],
      contactNumber: json['contactNumber'],
      email: json['email'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      'address': address,
      'contactNumber': contactNumber,
      'email': email,
    };
  }

  @override
  List<Object?> get props => [code, name, address, contactNumber, email];
}

class CustomerModel extends Equatable {
  final int? id;
  final String? code;
  final String? name;
  final bool? gender;
  final DateTime? birthDate;
  final String? contactNumber;
  final String? address;
  final String? wardName;
  final String? email;
  final String? comments;

  const CustomerModel({
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

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['id'],
      code: json['code'],
      name: json['name'],
      gender: json['gender'],
      birthDate:
          json['birthDate'] != null ? DateTime.parse(json['birthDate']) : null,
      contactNumber: json['contactNumber'],
      address: json['address'],
      wardName: json['wardName'],
      email: json['email'],
      comments: json['comments'],
    );
  }

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

  @override
  List<Object?> get props => [
        id,
        code,
        name,
        gender,
        birthDate,
        contactNumber,
        address,
        wardName,
        email,
        comments,
      ];
}

class SurchargeModel extends Equatable {
  final int id;
  final String code;
  final double price;

  const SurchargeModel({
    required this.id,
    required this.code,
    required this.price,
  });

  factory SurchargeModel.fromJson(Map<String, dynamic> json) {
    return SurchargeModel(
      id: json['id'],
      code: json['code'],
      price: (json['price'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'price': price,
    };
  }

  @override
  List<Object?> get props => [id, code, price];
}

class PaymentModel extends Equatable {
  final String method;
  final String methodStr;
  final double amount;
  final int id;
  final int? accountId;
  final int? voucherId;
  final int? voucherCampaignId;

  const PaymentModel({
    required this.method,
    required this.methodStr,
    required this.amount,
    required this.id,
    this.accountId,
    this.voucherId,
    this.voucherCampaignId,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      method: json['method'],
      methodStr: json['methodStr'],
      amount: (json['amount'] as num).toDouble(),
      id: json['id'],
      accountId: json['accountId'],
      voucherId: json['voucherId'],
      voucherCampaignId: json['voucherCampaignId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Method': method,
      'MethodStr': methodStr,
      'Amount': amount,
      'Id': id,
      'AccountId': accountId,
      'VoucherId': voucherId,
      'VoucherCampaignId': voucherCampaignId,
    };
  }

  @override
  List<Object?> get props =>
      [method, methodStr, amount, id, accountId, voucherId, voucherCampaignId];
}
