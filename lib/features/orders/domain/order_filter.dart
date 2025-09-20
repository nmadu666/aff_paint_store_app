import 'package:equatable/equatable.dart';

class OrderFilter extends Equatable {
  final List<int>? branchIds;
  final List<int>? customerIds;
  final String? customerCode;
  final List<int>? status;
  final DateTime? createdDateFrom;
  final DateTime? toDate;
  final int? saleChannelId;

  const OrderFilter({
    this.branchIds,
    this.customerIds,
    this.customerCode,
    this.status,
    this.createdDateFrom,
    this.toDate,
    this.saleChannelId,
  });

  // Method to convert to query params
  Map<String, String> toQueryParameters() {
    final Map<String, String> params = {};
    if (branchIds != null && branchIds!.isNotEmpty) {
      params['branchIds'] = branchIds!.join(',');
    }
    if (customerIds != null && customerIds!.isNotEmpty) {
      params['customerIds'] = customerIds!.join(',');
    }
    if (customerCode != null && customerCode!.isNotEmpty) {
      params['customerCode'] = customerCode!;
    }
    if (status != null && status!.isNotEmpty) {
      params['status'] = status!.join(',');
    }
    if (createdDateFrom != null) {
      params['createdDate'] = createdDateFrom!.toIso8601String();
    }
    if (toDate != null) {
      params['toDate'] = toDate!.toIso8601String();
    }
    if (saleChannelId != null) {
      params['saleChannelId'] = saleChannelId!.toString();
    }
    return params;
  }

  OrderFilter copyWith({
    List<int>? branchIds,
    List<int>? customerIds,
    String? customerCode,
    List<int>? status,
    DateTime? createdDateFrom,
    DateTime? toDate,
    int? saleChannelId,
  }) {
    return OrderFilter(
      branchIds: branchIds ?? this.branchIds,
      customerIds: customerIds ?? this.customerIds,
      customerCode: customerCode ?? this.customerCode,
      status: status ?? this.status,
      createdDateFrom: createdDateFrom ?? this.createdDateFrom,
      toDate: toDate ?? this.toDate,
      saleChannelId: saleChannelId ?? this.saleChannelId,
    );
  }

  @override
  List<Object?> get props => [
        branchIds,
        customerIds,
        customerCode,
        status,
        createdDateFrom,
        toDate,
        saleChannelId,
      ];
}
