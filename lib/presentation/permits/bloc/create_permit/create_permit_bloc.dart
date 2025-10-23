import 'dart:io';

// class CreatePermitBloc { ... }
import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:flutter_absensi_app/data/datasources/permit_remote_datasource.dart';
import 'package:flutter_absensi_app/data/models/request/create_permit_request_model.dart';
import 'package:flutter_absensi_app/data/models/response/permit_response_model.dart';

part 'create_permit_bloc.freezed.dart';
part 'create_permit_event.dart';
part 'create_permit_state.dart';

class CreatePermitBloc extends Bloc<CreatePermitEvent, CreatePermitState> {
  final PermitRemoteDatasource datasource;
  CreatePermitBloc(
    this.datasource,
  ) : super(const _Initial()) {
    on<_CreatePermit>((event, emit) async {
      emit(const _Loading());
      final request = CreatePermitRequestModel(
        permitTypeId: event.permitTypeId,
        startDate: event.startDate,
        endDate: event.endDate,
        reason: event.reason,
        attachmentPath: event.attachmentPath,
      );
      final result = await datasource.createPermit(request);
      result.fold(
        (l) => emit(_Error(l)),
        (r) => emit(_Success(r)),
      );
    });
  }
}