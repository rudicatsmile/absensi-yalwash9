part of 'get_all_permits_bloc.dart';

@freezed
class GetAllPermitsState with _$GetAllPermitsState {
  const factory GetAllPermitsState.initial() = _Initial;
  const factory GetAllPermitsState.loading() = _Loading;
  const factory GetAllPermitsState.success(PermitResponseModel response) = _Success;
  const factory GetAllPermitsState.error(String message) = _Error;
}