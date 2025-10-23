import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:flutter_absensi_app/data/datasources/permits_data_source.dart';
import 'package:flutter_absensi_app/data/models/response/leave_response_model.dart';

part 'permits_bloc.freezed.dart';
part 'permits_event.dart';
part 'permits_state.dart';

class PermitsBloc extends Bloc<PermitsEvent, PermitsState> {
  final PermitsDataSource datasource;
  PermitsBloc(this.datasource) : super(const _Initial()) {
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