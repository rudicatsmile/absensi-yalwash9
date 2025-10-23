import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:flutter_absensi_app/data/datasources/permit_remote_datasource.dart';
import 'package:flutter_absensi_app/data/models/response/permit_type_response_model.dart';

part 'permit_type_bloc.freezed.dart';
part 'permit_type_event.dart';
part 'permit_type_state.dart';

class PermitTypeBloc extends Bloc<PermitTypeEvent, PermitTypeState> {
  final PermitRemoteDatasource datasource;
  PermitTypeBloc(
    this.datasource,
  ) : super(const _Initial()) {
    on<_GetPermitTypes>((event, emit) async {
      emit(const _Loading());
      final result = await datasource.getPermitTypes();
      result.fold(
        (l) => emit(_Error(l)),
        (r) => emit(_Success(r)),
      );
    });
  }
}