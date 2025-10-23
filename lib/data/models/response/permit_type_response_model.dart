import 'dart:convert';

class PermitTypeResponseModel {
  final String? message;
  final List<PermitTypeData>? data;

  PermitTypeResponseModel({
    this.message,
    this.data,
  });

  factory PermitTypeResponseModel.fromJson(String str) =>
      PermitTypeResponseModel.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory PermitTypeResponseModel.fromMap(Map<String, dynamic> json) =>
      PermitTypeResponseModel(
        message: json['message'],
        data: json['data'] == null
            ? []
            : List<PermitTypeData>.from(
                json['data']!.map((x) => PermitTypeData.fromMap(x)),
              ),
      );

  Map<String, dynamic> toMap() => {
        'message': message,
        'data':
            data == null ? [] : List<dynamic>.from(data!.map((x) => x.toMap())),
      };
}

class PermitTypeData {
  final int? id;
  final String? name;
  final int? quotaDays;
  final bool? isPaid;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PermitTypeData({
    this.id,
    this.name,
    this.quotaDays,
    this.isPaid,
    this.createdAt,
    this.updatedAt,
  });

  factory PermitTypeData.fromJson(String str) =>
      PermitTypeData.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory PermitTypeData.fromMap(Map<String, dynamic> json) => PermitTypeData(
        id: json['id'],
        name: json['name'],
        // quotaDays: json['quota_days'],
        quotaDays: json['quota_days'] is int
            ? json['quota_days'] as int
            : json['quota_days'] is String
                ? int.tryParse(json['quota_days'] as String)
                : json['quota_days'] is num
                    ? (json['quota_days'] as num).toInt()
                    : null,
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