import 'dart:io';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();

  factory AuthService() {
    return _instance;
  }

  AuthService._internal();

  final String clientId = '';
  final String domain = '';
  final String androidCallbackUri = '';
  final String iosCallbackUri = '';
  final String callbackScheme = 'https';
  final storage = FlutterSecureStorage();

  Future<void> login() async {
    try {
      final url = 'https://$domain/authorize?'
          'audience=https://$domain/userinfo&'
          'scope=openid profile email offline_access&'
          'response_type=code&'
          'client_id=$clientId&'
          'redirect_uri=${callbackUri()}';

      print('Opening URL: $url');

      final result = await FlutterWebAuth2.authenticate(
          url: url, callbackUrlScheme: callbackScheme);

      print('Result: $result');

      final code = Uri.parse(result).queryParameters['code'];

      print('Authorization code: $code');

      final response = await http.post(
        Uri.parse('https://$domain/oauth/token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'grant_type': 'authorization_code',
          'client_id': clientId,
          'code': code,
          'redirect_uri': callbackUri(),
        }),
      );

      final body = jsonDecode(response.body);
      await storage.write(key: 'access_token', value: body['access_token']);
    } catch (e) {
      print('Login failed: $e');
    }
  }

  String callbackUri() {
    return Platform.isAndroid ? androidCallbackUri : iosCallbackUri;
  }

  Future<void> logout() async {
    await storage.delete(key: 'access_token');
  }

  Future<String?> getAccessToken() async {
    return await storage.read(key: 'access_token');
  }
}
