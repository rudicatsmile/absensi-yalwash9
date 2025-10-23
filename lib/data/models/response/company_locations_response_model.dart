import 'dart:convert';

class CompanyLocationsResponseModel {
  final bool? success;
  final List<CompanyLocation>? data;

  CompanyLocationsResponseModel({
    this.success,
    this.data,
  });

  factory CompanyLocationsResponseModel.fromJson(String str) =>
      CompanyLocationsResponseModel.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory CompanyLocationsResponseModel.fromMap(Map<String, dynamic> json) =>
      CompanyLocationsResponseModel(
        success: json['success'],
        data: json['data'] == null
            ? []
            : List<CompanyLocation>.from(
                json['data'].map((x) => CompanyLocation.fromMap(x)),
              ),
      );

  Map<String, dynamic> toMap() => {
        'success': success,
        'data': data == null
            ? []
            : List<dynamic>.from(data!.map((x) => x.toMap())),
      };
}

class CompanyLocation {
  final int? id;
  final int? companyId;
  final String? name;
  final String? address;
  final String? latitude;
  final String? longitude;
  final String? radiusKm;
  final String? attendanceType;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? attendanceType0;

  CompanyLocation({
    this.id,
    this.companyId,
    this.name,
    this.address,
    this.latitude,
    this.longitude,
    this.radiusKm,
    this.attendanceType,
    this.createdAt,
    this.updatedAt,
    this.attendanceType0,
  });

  factory CompanyLocation.fromJson(String str) =>
      CompanyLocation.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory CompanyLocation.fromMap(Map<String, dynamic> json) => CompanyLocation(
        id: _parseInt(json['id']),
        companyId: _parseInt(json['company_id']),
        name: json['name']?.toString(),
        address: json['address']?.toString(),
        latitude: json['latitude']?.toString(),
        longitude: json['longitude']?.toString(),
        radiusKm: json['radius_km']?.toString(),
        attendanceType: json['attendance_type']?.toString(),
        createdAt: _parseDate(json['created_at']),
        updatedAt: _parseDate(json['updated_at']),
        attendanceType0: json['attendance_type0']?.toString(),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'company_id': companyId,
        'name': name,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'radius_km': radiusKm,
        'attendance_type': attendanceType,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
        'attendance_type0': attendanceType0,
      };
}

int? _parseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is String) return int.tryParse(value);
  return null;
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String) {
    try {
      return DateTime.parse(value);
    } catch (_) {
      return null;
    }
  }
  return null;
}