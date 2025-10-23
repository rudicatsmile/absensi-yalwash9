part of 'permits_bloc.dart';

@freezed
class PermitsState with _$PermitsState {
  const factory PermitsState.initial() = _Initial;
  const factory PermitsState.loading() = _Loading;
  const factory PermitsState.success(LeaveResponseModel response) = _Success;
  const factory PermitsState.error(String message) = _Error;
}