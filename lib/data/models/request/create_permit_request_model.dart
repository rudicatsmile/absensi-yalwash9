// class CreatePermitRequestModel
import 'dart:convert';

class CreatePermitRequestModel {
  final int permitTypeId;
  final String startDate;
  final String endDate;
  final String? reason;
  final String? attachmentPath;

  CreatePermitRequestModel({
    required this.permitTypeId,
    required this.startDate,
    required this.endDate,
    this.reason,
    this.attachmentPath,
  });

  factory CreatePermitRequestModel.fromJson(String str) =>
      CreatePermitRequestModel.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory CreatePermitRequestModel.fromMap(Map<String, dynamic> json) =>
      CreatePermitRequestModel(
        permitTypeId: json['permit_type_id'],
        startDate: json['start_date'],
        endDate: json['end_date'],
        reason: json['reason'],
        attachmentPath: json['attachment_path'],
      );

  Map<String, dynamic> toMap() => {
        'permit_type_id': permitTypeId.toString(),
        'start_date': startDate,
        'end_date': endDate,
        if (reason != null && reason!.isNotEmpty) 'reason': reason,
      };
}