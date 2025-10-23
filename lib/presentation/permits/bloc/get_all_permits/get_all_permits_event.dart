part of 'get_all_permits_bloc.dart';

@freezed
class GetAllPermitsEvent with _$GetAllPermitsEvent {
  const factory GetAllPermitsEvent.started() = _Started;
  const factory GetAllPermitsEvent.getAllPermits({String? status}) = _GetAllPermits;
}