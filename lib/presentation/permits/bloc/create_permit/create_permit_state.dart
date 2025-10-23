part of 'create_permit_bloc.dart';

@freezed
class CreatePermitState with _$CreatePermitState {
  const factory CreatePermitState.initial() = _Initial;
  const factory CreatePermitState.loading() = _Loading;
  const factory CreatePermitState.success(String response) = _Success;
  const factory CreatePermitState.error(String message) = _Error;
}