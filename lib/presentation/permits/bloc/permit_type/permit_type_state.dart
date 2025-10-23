part of 'permit_type_bloc.dart';

@freezed
class PermitTypeState with _$PermitTypeState {
  const factory PermitTypeState.initial() = _Initial;
  const factory PermitTypeState.loading() = _Loading;
  const factory PermitTypeState.success(PermitTypeResponseModel response) = _Success;
  const factory PermitTypeState.error(String message) = _Error;
}