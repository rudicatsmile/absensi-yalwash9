import 'dart:convert';
import 'dart:developer' as developer;

import 'package:dartz/dartz.dart';
import 'package:flutter_absensi_app/core/constants/variables.dart';
import 'package:flutter_absensi_app/data/datasources/auth_local_datasource.dart';
import 'package:flutter_absensi_app/data/models/request/create_leave_request_model.dart';
import 'package:flutter_absensi_app/data/models/response/leave_balance_response_model.dart';
import 'package:flutter_absensi_app/data/models/response/leave_response_model.dart';
import 'package:flutter_absensi_app/data/models/response/leave_type_response_model.dart';
import 'package:http/http.dart' as http;

class PermitsDataSource {
  // Get Permit Types
  Future<Either<String, LeaveTypeResponseModel>> getPermitTypes() async {
    final authData = await AuthLocalDatasource().getAuthData();
    final url = Uri.parse('${Variables.baseUrl}/api/permit-types');

    developer.log('➡️ GET $url', name: 'PermitsDataSource');
    final response = await http.get(
      url,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${authData?.token}',
      },
    );
    developer.log('📥 Status=${response.statusCode}', name: 'PermitsDataSource');
    developer.log('📦 Body=${response.body}', name: 'PermitsDataSource');

    if (response.statusCode == 200) {
      return Right(LeaveTypeResponseModel.fromJson(response.body));
    } else {
      try {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        return Left(decoded['message']?.toString() ?? 'Failed to fetch permit types');
      } catch (_) {
        return const Left('Failed to fetch permit types');
      }
    }
  }

  // Get Permit Balance
  Future<Either<String, LeaveBalanceResponseModel>> getPermitBalance({
    String? year,
  }) async {
    final authData = await AuthLocalDatasource().getAuthData();
    final queryParams = year != null ? '?year=$year' : '';
    final url = Uri.parse('${Variables.baseUrl}/api/permits/balance$queryParams');

    developer.log('➡️ GET $url', name: 'PermitsDataSource');
    final response = await http.get(
      url,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${authData?.token}',
      },
    );
    developer.log('📥 Status=${response.statusCode}', name: 'PermitsDataSource');

    if (response.statusCode == 200) {
      return Right(LeaveBalanceResponseModel.fromJson(response.body));
    } else {
      try {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        return Left(decoded['message']?.toString() ?? 'Failed to fetch permit balance');
      } catch (_) {
        return const Left('Failed to fetch permit balance');
      }
    }
  }

  // Get All Permits
  Future<Either<String, LeaveResponseModel>> getPermits({
    String? status,
  }) async {
    final authData = await AuthLocalDatasource().getAuthData();
    final queryParams = status != null ? '?status=$status' : '';
    final url = Uri.parse('${Variables.baseUrl}/api/permits$queryParams');

    developer.log('➡️ GET $url', name: 'PermitsDataSource');
    final response = await http.get(
      url,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${authData?.token}',
      },
    );
    developer.log('📥 Status=${response.statusCode}', name: 'PermitsDataSource');
    developer.log('📦 Body=${response.body}', name: 'PermitsDataSource');

    if (response.statusCode == 200) {
      return Right(LeaveResponseModel.fromJson(response.body));
    } else {
      try {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        return Left(decoded['message']?.toString() ?? 'Failed to fetch permits');
      } catch (_) {
        return const Left('Failed to fetch permits');
      }
    }
  }

  // Create Permit Request
  Future<Either<String, String>> createPermit(
    CreateLeaveRequestModel request,
  ) async {
    final authData = await AuthLocalDatasource().getAuthData();
    final url = Uri.parse('${Variables.baseUrl}/api/permits');

    developer.log('➡️ POST $url', name: 'PermitsDataSource');

    final multipartRequest = http.MultipartRequest('POST', url)
      ..headers['Authorization'] = 'Bearer ${authData?.token}'
      ..headers['Accept'] = 'application/json';

    final fields = request.toMap();
    fields.forEach((key, value) {
      multipartRequest.fields[key] = value.toString();
    });

    if (request.attachment != null) {
      final file = await http.MultipartFile.fromPath(
        'attachment',
        request.attachment!.path,
      );
      multipartRequest.files.add(file);
    }

    final streamedResponse = await multipartRequest.send();
    final response = await http.Response.fromStream(streamedResponse);
    developer.log('📥 Status=${response.statusCode}', name: 'PermitsDataSource');
    developer.log('📦 Body=${response.body}', name: 'PermitsDataSource');

    if (response.statusCode == 201 || response.statusCode == 200) {
      return const Right('Permit created successfully');
    } else {
      try {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        return Left(decoded['message']?.toString() ?? 'Failed to create permit');
      } catch (_) {
        return const Left('Failed to create permit');
      }
    }
  }
}