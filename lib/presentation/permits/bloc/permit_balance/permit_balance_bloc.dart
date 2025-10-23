import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:flutter_absensi_app/data/datasources/permit_remote_datasource.dart';
import 'package:flutter_absensi_app/data/models/response/permit_balance_response_model.dart';

part 'permit_balance_bloc.freezed.dart';
part 'permit_balance_event.dart';
part 'permit_balance_state.dart';

class PermitBalanceBloc extends Bloc<PermitBalanceEvent, PermitBalanceState> {
  final PermitRemoteDatasource datasource;
  PermitBalanceBloc(
    this.datasource,
  ) : super(const _Initial()) {
    on<_GetPermitBalance>((event, emit) async {
      emit(const _Loading());
      final result = await datasource.getPermitBalance(year: event.year);
      result.fold(
        (l) => emit(_Error(l)),
        (r) => emit(_Success(r)),
      );
    });
  }
}