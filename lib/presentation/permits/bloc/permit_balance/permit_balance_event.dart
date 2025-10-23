part of 'permit_balance_bloc.dart';

@freezed
class PermitBalanceEvent with _$PermitBalanceEvent {
  const factory PermitBalanceEvent.started() = _Started;
  const factory PermitBalanceEvent.getPermitBalance({String? year}) = _GetPermitBalance;
}