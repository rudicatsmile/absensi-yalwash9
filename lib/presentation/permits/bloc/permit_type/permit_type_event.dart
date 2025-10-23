part of 'permit_type_bloc.dart';

@freezed
class PermitTypeEvent with _$PermitTypeEvent {
  const factory PermitTypeEvent.started() = _Started;
  const factory PermitTypeEvent.getPermitTypes() = _GetPermitTypes;
}