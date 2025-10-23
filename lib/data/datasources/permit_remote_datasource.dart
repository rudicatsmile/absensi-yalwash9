import 'dart:convert';
import 'dart:developer';

import 'package:dartz/dartz.dart';
import 'package:flutter_absensi_app/core/constants/variables.dart';
import 'package:flutter_absensi_app/data/datasources/auth_local_datasource.dart';
import 'package:flutter_absensi_app/data/models/request/create_permit_request_model.dart';
import 'package:flutter_absensi_app/data/models/response/permit_balance_response_model.dart';
import 'package:flutter_absensi_app/data/models/response/permit_response_model.dart';
import 'package:flutter_absensi_app/data/models/response/permit_type_response_model.dart';
import 'package:http/http.dart' as http;

class PermitRemoteDatasource {
  // Get Permit Types
  Future<Either<String, PermitTypeResponseModel>> getPermitTypes() async {
    final authData = await AuthLocalDatasource().getAuthData();
    final url = Uri.parse('${Variables.baseUrl}/api/permit-types');

    final response = await http.get(
      url,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${authData?.token}',
      },
    );

    if (response.statusCode == 200) {
      return Right(PermitTypeResponseModel.fromJson(response.body));
    } else {
      try {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        return Left(
            decoded['message']?.toString() ?? 'Failed to fetch permit types');
      } catch (_) {
        return const Left('Failed to fetch permit types');
      }
    }
  }

  // Get Permit Balance
  Future<Either<String, PermitBalanceResponseModel>> getPermitBalance({
    String? year,
  }) async {
    final authData = await AuthLocalDatasource().getAuthData();
    final queryParams = year != null ? '?year=$year' : '';
    final url =
        Uri.parse('${Variables.baseUrl}/api/permits/balance$queryParams');

    final response = await http.get(
      url,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${authData?.token}',
      },
    );

    if (response.statusCode == 200) {
      return Right(PermitBalanceResponseModel.fromJson(response.body));
    } else {
      try {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        return Left(
            decoded['message']?.toString() ?? 'Failed to fetch permit balance');
      } catch (_) {
        return const Left('Failed to fetch permit balance');
      }
    }
  }

  // Get All Permits
  Future<Either<String, PermitResponseModel>> getPermits({
    String? status,
  }) async {
    final authData = await AuthLocalDatasource().getAuthData();
    final queryParams = status != null ? '?status=$status' : '';
    final url = Uri.parse('${Variables.baseUrl}/api/permits$queryParams');

    final response = await http.get(
      url,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${authData?.token}',
      },
    );
    log("GET PERMITS RESPONSE: ${response.body}");
    if (response.statusCode == 200) {
      return Right(PermitResponseModel.fromJson(response.body));
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
  // class PermitRemoteDatasource
  Future<Either<String, String>> createPermit(
    CreatePermitRequestModel request,
  ) async {
    final authData = await AuthLocalDatasource().getAuthData();
    final url = Uri.parse('${Variables.baseUrl}/api/permits');

    final multipartRequest = http.MultipartRequest('POST', url)
      ..headers['Authorization'] = 'Bearer ${authData?.token}'
      ..headers['Accept'] = 'application/json';

    // Add fields - convert all values to String
    final fields = request.toMap();
    fields.forEach((key, value) {
      multipartRequest.fields[key] = value.toString();
    });

    // Add file if exists
    if (request.attachmentPath != null && request.attachmentPath!.isNotEmpty) {
      final file = await http.MultipartFile.fromPath(
        'attachment',
        request.attachmentPath!,
      );
      multipartRequest.files.add(file);
    }

    final streamedResponse = await multipartRequest.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 201 || response.statusCode == 200) {
      return Right('Permit created successfully');
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