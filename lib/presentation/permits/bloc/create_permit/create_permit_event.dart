part of 'create_permit_bloc.dart';

@freezed
class CreatePermitEvent with _$CreatePermitEvent {
  const factory CreatePermitEvent.started() = _Started;
  const factory CreatePermitEvent.createPermit({
    required int permitTypeId,
    required String startDate,
    required String endDate,
    required String reason,
    String? attachmentPath,
  }) = _CreatePermit;
}