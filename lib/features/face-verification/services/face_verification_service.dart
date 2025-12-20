import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../models/face_verification_result.dart';

class FaceVerificationService {
  static const String _baseUrl = 'https://app.sievesapp.com/v1';
  
  // TODO: Replace with actual API endpoint
  static const String _verificationEndpoint = '$_baseUrl/face-verification/verify';

  Future<FaceVerificationResult> verifyFace({
    required Uint8List imageData,
    String? deviceId,
    Map<String, dynamic>? additionalParams,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(_verificationEndpoint),
      );

      // Add image file
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          imageData,
          filename: 'face_capture.jpg',
        ),
      );

      // Add device ID if provided
      if (deviceId != null) {
        request.fields['deviceId'] = deviceId;
      }

      // Add any additional parameters
      if (additionalParams != null) {
        additionalParams.forEach((key, value) {
          request.fields[key] = value.toString();
        });
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return FaceVerificationResult.fromJson(data);
      } else {
        return FaceVerificationResult(
          success: false,
          message: 'Verification failed: ${response.statusCode}',
        );
      }
    } catch (e) {
      return FaceVerificationResult(
        success: false,
        message: 'Error during verification: $e',
      );
    }
  }

  Future<Map<String, dynamic>> getDeviceStatus(String deviceId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/face-verification/device/$deviceId/status'),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get device status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting device status: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getVerificationHistory({
    required String deviceId,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    try {
      final queryParams = <String, String>{
        'deviceId': deviceId,
      };

      if (startDate != null) {
        queryParams['startDate'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        queryParams['endDate'] = endDate.toIso8601String();
      }
      if (limit != null) {
        queryParams['limit'] = limit.toString();
      }

      final uri = Uri.parse('$_baseUrl/face-verification/history')
          .replace(queryParameters: queryParams);

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['history'] ?? []);
      } else {
        throw Exception('Failed to get verification history: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting verification history: $e');
    }
  }

  Future<bool> recordWorkEntry({
    required String employeeId,
    required String entryType, // 'check_in' or 'check_out'
    String? deviceId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/work-entry/record'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'employeeId': employeeId,
          'entryType': entryType,
          'deviceId': deviceId,
          'timestamp': DateTime.now().toIso8601String(),
          'metadata': metadata,
        }),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      throw Exception('Error recording work entry: $e');
    }
  }
}
