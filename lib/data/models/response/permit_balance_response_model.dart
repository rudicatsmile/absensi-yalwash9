import 'dart:convert';

class PermitBalanceResponseModel {
  final String? message;
  final List<PermitBalanceData>? data;

  PermitBalanceResponseModel({
    this.message,
    this.data,
  });

  factory PermitBalanceResponseModel.fromJson(String str) =>
      PermitBalanceResponseModel.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory PermitBalanceResponseModel.fromMap(Map<String, dynamic> json) =>
      PermitBalanceResponseModel(
        message: json['message'],
        data: json['data'] == null
            ? []
            : List<PermitBalanceData>.from(
                json['data']!.map((x) => PermitBalanceData.fromMap(x)),
              ),
      );

  Map<String, dynamic> toMap() => {
        'message': message,
        'data': data == null
            ? []
            : List<dynamic>.from(data!.map((x) => x.toMap())),
      };
}

class PermitBalanceData {
  final int? id;
  final int? employeeId;
  final int? permitTypeId;
  final int? year;
  final int? quotaDays;
  final int? usedDays;
  final int? remainingDays;
  final int? carryOverDays;
  final DateTime? lastUpdated;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final PermitTypeInBalance? permitType;

  PermitBalanceData({
    this.id,
    this.employeeId,
    this.permitTypeId,
    this.year,
    this.quotaDays,
    this.usedDays,
    this.remainingDays,
    this.carryOverDays,
    this.lastUpdated,
    this.createdAt,
    this.updatedAt,
    this.permitType,
  });

  factory PermitBalanceData.fromJson(String str) =>
      PermitBalanceData.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory PermitBalanceData.fromMap(Map<String, dynamic> json) =>
      PermitBalanceData(
        id: json['id'],
        employeeId: json['employee_id'],
        permitTypeId: json['permit_type_id'],
        year: json['year'],
        quotaDays: json['quota_days'],
        usedDays: json['used_days'],
        remainingDays: json['remaining_days'],
        carryOverDays: json['carry_over_days'],
        lastUpdated: json['last_updated'] == null
            ? null
            : DateTime.parse(json['last_updated']),
        createdAt: json['created_at'] == null
            ? null
            : DateTime.parse(json['created_at']),
        updatedAt: json['updated_at'] == null
            ? null
            : DateTime.parse(json['updated_at']),
        permitType: json['permit_type'] == null
            ? null
            : PermitTypeInBalance.fromMap(json['permit_type']),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'employee_id': employeeId,
        'permit_type_id': permitTypeId,
        'year': year,
        'quota_days': quotaDays,
        'used_days': usedDays,
        'remaining_days': remainingDays,
        'carry_over_days': carryOverDays,
        'last_updated': lastUpdated?.toIso8601String(),
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
        'permit_type': permitType?.toMap(),
      };
}

class PermitTypeInBalance {
  final int? id;
  final String? name;
  final int? quotaDays;
  final bool? isPaid;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PermitTypeInBalance({
    this.id,
    this.name,
    this.quotaDays,
    this.isPaid,
    this.createdAt,
    this.updatedAt,
  });

  factory PermitTypeInBalance.fromJson(String str) =>
      PermitTypeInBalance.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory PermitTypeInBalance.fromMap(Map<String, dynamic> json) =>
      PermitTypeInBalance(
        id: json['id'],
        name: json['name'],
        quotaDays: json['quota_days'],
        isPaid: json['is_paid'],
        createdAt: json['created_at'] == null
            ? null
            : DateTime.parse(json['created_at']),
        updatedAt: json['updated_at'] == null
            ? null
            : DateTime.parse(json['updated_at']),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'quota_days': quotaDays,
        'is_paid': isPaid,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };
}