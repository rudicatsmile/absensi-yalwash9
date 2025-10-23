part of 'permit_balance_bloc.dart';

@freezed
class PermitBalanceState with _$PermitBalanceState {
  const factory PermitBalanceState.initial() = _Initial;
  const factory PermitBalanceState.loading() = _Loading;
  const factory PermitBalanceState.success(PermitBalanceResponseModel response) = _Success;
  const factory PermitBalanceState.error(String message) = _Error;
}