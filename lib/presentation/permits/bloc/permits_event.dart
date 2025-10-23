part of 'permits_bloc.dart';

@freezed
class PermitsEvent with _$PermitsEvent {
  const factory PermitsEvent.started() = _Started;
  const factory PermitsEvent.getAllPermits({String? status}) = _GetAllPermits;
}