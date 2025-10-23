import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:flutter_absensi_app/data/datasources/permit_remote_datasource.dart';
import 'package:flutter_absensi_app/data/models/response/permit_response_model.dart';

part 'get_all_permits_bloc.freezed.dart';
part 'get_all_permits_event.dart';
part 'get_all_permits_state.dart';

class GetAllPermitsBloc extends Bloc<GetAllPermitsEvent, GetAllPermitsState> {
  final PermitRemoteDatasource datasource;
  GetAllPermitsBloc(
    this.datasource,
  ) : super(const _Initial()) {
    on<_GetAllPermits>((event, emit) async {
      emit(const _Loading());
      final result = await datasource.getPermits(status: event.status);
      result.fold(
        (l) => emit(_Error(l)),
        (r) => emit(_Success(r)),
      );
    });
  }
}