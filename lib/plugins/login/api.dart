import 'package:mira/core/utils/api.dart';
import 'package:mira/core/exceptions/auth_exceptions.dart';

class LoginApi {
  final ApiClient _apiClient;

  LoginApi({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<dynamic> loginWithPassword(String phone, String password) async {
    try {
      final response = await _apiClient.post(
        '/auth/login',
        body: {'phone': phone, 'password': password},
        mockResponse: {
          'success': true,
          'data': {
            'token': 'mock_token_${DateTime.now().millisecondsSinceEpoch}',
            'user': {
              'id': 'mock_user_${DateTime.now().millisecondsSinceEpoch}',
              'phone': phone,
            },
          },
        },
      );

      if (response is Map && response['success'] == false) {
        throw InvalidCredentialsException(
          response['message']?.toString() ?? 'Invalid phone or password',
        );
      }

      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> sendVerificationCode(String phone) async {
    try {
      final response = await _apiClient.post(
        '/auth/send-code',
        body: {'phone': phone},
        mockResponse: {
          'success': true,
          'data': {
            'code': '123456', // 模拟验证码
            'expires_in': 300, // 5分钟过期
          },
        },
      );

      if (response is Map && response['success'] == false) {
        throw InvalidCredentialsException(
          response['message']?.toString() ?? 'Failed to send verification code',
        );
      }

      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> verifyCodeAndRegister(String phone, String code) async {
    try {
      final response = await _apiClient.post(
        '/auth/verify-code',
        body: {'phone': phone, 'code': code},
        mockResponse: {
          'success': true,
          'data': {
            'token': 'mock_token_${DateTime.now().millisecondsSinceEpoch}',
            'user': {
              'id': 'mock_user_${DateTime.now().millisecondsSinceEpoch}',
              'phone': phone,
            },
          },
        },
      );

      if (response is Map && response['success'] == false) {
        throw InvalidCredentialsException(
          response['message']?.toString() ?? 'Invalid verification code',
        );
      }

      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> completeRegistration(
    String userId,
    String nickname,
    String? avatar,
  ) async {
    try {
      final response = await _apiClient.post(
        '/auth/complete-registration',
        body: {'userId': userId, 'nickname': nickname, 'avatar': avatar},
        mockResponse: {
          'success': true,
          'data': {
            'user': {'id': userId, 'nickname': nickname, 'avatar': avatar},
          },
        },
      );

      if (response is Map && response['success'] == false) {
        throw InvalidCredentialsException(
          response['message']?.toString() ?? 'Failed to complete registration',
        );
      }

      return response;
    } catch (e) {
      rethrow;
    }
  }
}
