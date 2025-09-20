class PaymentModel {
  String method; // Giá trị mặc định là Voucher (không đổi)
  String methodStr; // Giá trị mặc định là Voucher (không đổi)
  double amount; // Giá trị của voucher
  int id; // Giá trị mặc định là -1 (không đổi)
  int? accountId; // Giá trị mặc định là null (không đổi)
  int? voucherId; // Id của voucher (optional)
  int? voucherCampaignId; // Id của đợt phát hành voucher (optional)

  PaymentModel({
    required this.method,
    required this.methodStr,
    required this.amount,
    required this.id,
    this.accountId,
    this.voucherId,
    this.voucherCampaignId,
  });

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
}
