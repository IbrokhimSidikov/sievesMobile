import 'dart:io';
import 'package:http/http.dart' as http;

class FaceVerificationService {
  static const String _baseUrl = 'https://face-id.sievesapp.com';
  static const String _bearerToken = '3BUpSfYms0Ne54kWY7267ODiw2u86ECl';

  Future<FaceVerificationResult> verifyFace({
    required File profileImage,
    required File capturedImage,
  }) async {
    try {
      print('🔐 [FACE VERIFICATION] Starting face verification...');
      
      final uri = Uri.parse('$_baseUrl/verify');
      final request = http.MultipartRequest('POST', uri);
      
      // Add bearer token
      request.headers['Authorization'] = 'Bearer $_bearerToken';
      
      // Add images as multipart form data
      request.files.add(
        await http.MultipartFile.fromPath(
          'img1',
          profileImage.path,
        ),
      );
      
      request.files.add(
        await http.MultipartFile.fromPath(
          'img2',
          capturedImage.path,
        ),
      );
      
      print('📤 [FACE VERIFICATION] Sending request to: $uri');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      print('📥 [FACE VERIFICATION] Response status: ${response.statusCode}');
      print('📥 [FACE VERIFICATION] Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        print('✅ [FACE VERIFICATION] Verification successful');
        return FaceVerificationResult(
          success: true,
          message: 'Face verification successful',
        );
      } else {
        print('❌ [FACE VERIFICATION] Verification failed: ${response.statusCode}');
        return FaceVerificationResult(
          success: false,
          message: 'Face verification failed. Please try again.',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      print('❌ [FACE VERIFICATION] Exception: $e');
      return FaceVerificationResult(
        success: false,
        message: 'An error occurred during face verification: $e',
      );
    }
  }
}

class FaceVerificationResult {
  final bool success;
  final String message;
  final int? statusCode;

  FaceVerificationResult({
    required this.success,
    required this.message,
    this.statusCode,
  });
}
