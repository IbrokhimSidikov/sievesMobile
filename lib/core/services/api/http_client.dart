import 'dart:convert';
import 'package:http/http.dart' as http;
import '../auth/auth_service.dart';

/// HTTP client with automatic token refresh on 401/403 responses
class AuthHttpClient extends http.BaseClient {
  final http.Client _inner;
  final AuthService _authService;
  final Function()? onRefreshFailed;
  
  AuthHttpClient(this._authService, {this.onRefreshFailed}) : _inner = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    // Make the initial request
    final response = await _inner.send(request);
    
    // Log the request for debugging
    print('🌐 HTTP Request: ${request.method} ${request.url}');
    print('   Response Status: ${response.statusCode}');
    
    // If unauthorized, try to refresh token and retry once
    if (response.statusCode == 401 || response.statusCode == 403) {
      print('🔒 Received ${response.statusCode} response - token may be expired');
      print('   URL: ${request.url}');
      
      // Try to refresh the token
      print('🔄 Attempting token refresh...');
      final refreshed = await _authService.refreshToken();
      
      if (refreshed) {
        print('✅ Token refreshed successfully, retrying request...');
        
        // Get the new token
        final newToken = await _authService.getAccessToken();
        
        if (newToken != null) {
          print('   New token obtained, cloning request...');
          // Clone the request with new token
          final newRequest = _copyRequest(request, newToken);
          
          // Retry the request
          final retryResponse = await _inner.send(newRequest);
          print('📡 Retry response status: ${retryResponse.statusCode}');
          
          if (retryResponse.statusCode == 401 || retryResponse.statusCode == 403) {
            print('❌ Retry also failed with ${retryResponse.statusCode} - refresh token may be expired');
          } else if (retryResponse.statusCode >= 200 && retryResponse.statusCode < 300) {
            print('✅ Retry successful');
          }
          
          return retryResponse;
        } else {
          print('❌ Failed to get new access token after refresh');
          onRefreshFailed?.call();
        }
      } else {
        print('❌ Token refresh failed - refresh token likely expired');
        // Notify that refresh failed (user should be logged out)
        onRefreshFailed?.call();
      }
    } else if (response.statusCode >= 200 && response.statusCode < 300) {
      print('✅ Request successful');
    } else {
      print('⚠️ Request failed with status ${response.statusCode}');
    }
    
    return response;
  }

  /// Clone a request with updated authorization header
  http.BaseRequest _copyRequest(http.BaseRequest request, String newToken) {
    http.BaseRequest newRequest;
    
    if (request is http.Request) {
      newRequest = http.Request(request.method, request.url)
        ..bodyBytes = request.bodyBytes
        ..encoding = request.encoding;
    } else if (request is http.MultipartRequest) {
      newRequest = http.MultipartRequest(request.method, request.url)
        ..fields.addAll(request.fields)
        ..files.addAll(request.files);
    } else if (request is http.StreamedRequest) {
      throw Exception('StreamedRequest cannot be retried');
    } else {
      throw Exception('Unknown request type');
    }
    
    // Copy headers and update Authorization
    newRequest.headers.addAll(request.headers);
    newRequest.headers['Authorization'] = 'Bearer $newToken';
    
    return newRequest;
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }
}
