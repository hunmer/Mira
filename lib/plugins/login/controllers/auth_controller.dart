import 'package:flutter/material.dart';
import 'package:mira/core/storage/storage_manager.dart';
import 'package:mira/core/utils/api.dart';
import 'package:mira/core/utils/utils.dart';
import 'package:mira/plugins/login/api.dart';
import 'package:mira/plugins/login/models/user_model.dart';
import 'package:mira/plugins/login/models/login_state.dart';

/// 自定义异常类型
class InvalidCredentialsException implements Exception {
  final String message;
  InvalidCredentialsException(this.message);

  @override
  String toString() => 'InvalidCredentialsException: $message';
}

enum LoginErrorCode {
  invalidPhoneNumber,
  invalidCredentials,
  networkError,
  serverError,
  unknownError,
  success,
}

class AuthController with ChangeNotifier {
  final StorageManager storage;
  late final LoginApi loginApi;
  LoginState _state = LoginState(isLoggedIn: false);
  AuthController({required this.storage}) {
    loginApi = LoginApi(apiClient: ApiClient());
  }

  LoginState get state => _state;

  Future<void> init() async {
    final isLoggedIn = (await storage.readJson('currentUser')) != null;
    debugPrint('isLoggedIn: $isLoggedIn');
    if (isLoggedIn) {
      final userJson = await storage.readJson('currentUser');
      if (userJson != null) {
        _state = _state.copyWith(
          isLoggedIn: true,
          currentUser: UserModel.fromJson(userJson),
        );
      }
    }
    notifyListeners();
  }

  Future<LoginErrorCode> loginWithPassword(
    String phone,
    String password,
  ) async {
    if (!isValidPhoneNumber(phone)) {
      return LoginErrorCode.invalidPhoneNumber;
    }

    _state = _state.copyWith(isLoading: true);
    notifyListeners();

    try {
      final response =
          await loginApi.loginWithPassword(phone, password)
              as Map<String, dynamic>;

      if (response['success'] == true) {
        final userData = response['data']['user'] as Map<String, dynamic>;
        final user = UserModel(
          id: userData['id'] as String,
          phone: phone,
          password: password,
        );

        await storage.writeJson('currentUser', user.toJson());

        _state = _state.copyWith(
          isLoggedIn: true,
          currentUser: user,
          isLoading: false,
        );
        notifyListeners();
        return LoginErrorCode.success;
      }

      _state = _state.copyWith(isLoading: false);
      notifyListeners();
      return LoginErrorCode.invalidCredentials;
    } catch (e) {
      _state = _state.copyWith(isLoading: false);
      notifyListeners();
      return getErrorType(e);
    }
  }

  getErrorType(e) {
    if (e is NetworkException) {
      return LoginErrorCode.networkError;
    } else if (e is ServerException) {
      return LoginErrorCode.serverError;
    } else if (e is InvalidCredentialsException) {
      return LoginErrorCode.invalidCredentials;
    }
    return LoginErrorCode.unknownError;
  }

  Future<LoginErrorCode> sendVerificationCode(String phone) async {
    if (!isValidPhoneNumber(phone)) {
      return LoginErrorCode.invalidPhoneNumber;
    }

    _state = _state.copyWith(isLoading: true);
    notifyListeners();

    try {
      final response =
          await loginApi.sendVerificationCode(phone) as Map<String, dynamic>;
      _state = _state.copyWith(isLoading: false);
      notifyListeners();
      return response['success'] == true
          ? LoginErrorCode.success
          : LoginErrorCode.serverError;
    } catch (e) {
      _state = _state.copyWith(isLoading: false);
      notifyListeners();
      return getErrorType(e);
    }
  }

  Future<LoginErrorCode> verifyCodeAndRegister(
    String phone,
    String code,
  ) async {
    _state = _state.copyWith(isLoading: true);
    notifyListeners();

    try {
      final response =
          await loginApi.verifyCodeAndRegister(phone, code)
              as Map<String, dynamic>;
      if (response['success'] == true) {
        final userData = response['data']['user'] as Map<String, dynamic>;
        final user = UserModel(id: userData['id'] as String, phone: phone);

        await storage.writeJson('currentUser', user.toJson());

        _state = _state.copyWith(
          isLoggedIn: true,
          currentUser: user,
          isLoading: false,
        );
        notifyListeners();
        return LoginErrorCode.success;
      } else {
        _state = _state.copyWith(isLoading: false);
        notifyListeners();
        return LoginErrorCode.invalidCredentials;
      }
    } catch (e) {
      _state = _state.copyWith(isLoading: false);
      notifyListeners();
      return getErrorType(e);
    }
  }

  Future<void> completeRegistration(
    String phoneNumber,
    String nickname,
    String? avatar,
  ) async {
    _state = _state.copyWith(isLoading: true);
    notifyListeners();

    try {
      if (state.currentUser == null) {
        throw Exception('User not initialized');
      }

      final response =
          await loginApi.completeRegistration(
                state.currentUser!.id,
                nickname,
                avatar,
              )
              as Map<String, dynamic>;

      if (response['success'] == true) {
        final userData = response['data']['user'] as Map<String, dynamic>;
        final updatedUser = UserModel(
          id: userData['id'] as String,
          phone: phoneNumber,
          nickname: nickname,
          avatar: avatar,
        );

        await storage.writeJson('currentUser', updatedUser.toJson());

        _state = _state.copyWith(
          isLoggedIn: true,
          currentUser: updatedUser,
          isLoading: false,
        );
      } else {
        _state = _state.copyWith(isLoading: false);
        throw Exception(
          response['message'] ?? 'Failed to complete registration',
        );
      }
    } catch (e) {
      _state = _state.copyWith(isLoading: false);
      debugPrint('注册完成失败: $e');
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await storage.remove('isLoggedIn');
    await storage.remove('currentUser');
    _state = LoginState(isLoggedIn: false);
    notifyListeners();
  }
}
