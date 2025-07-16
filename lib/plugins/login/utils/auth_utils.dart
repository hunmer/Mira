import 'package:flutter/material.dart';
import 'package:mira/plugins/login/controllers/auth_controller.dart';
import 'package:mira/plugins/login/l10n/login_localizations.dart';

class AuthUtils {
  static bool validatePhoneNumber(String phone) {
    // Simple validation for Chinese phone numbers
    final regex = RegExp(r'^1[3-9]\d{9}$');
    return regex.hasMatch(phone);
  }

  static bool validatePassword(String password) {
    // Password should be at least 6 characters
    return password.length >= 6;
  }

  static bool validateVerificationCode(String code) {
    // Verification code should be 6 digits
    final regex = RegExp(r'^\d{6}$');
    return regex.hasMatch(code);
  }

  static String generateMockVerificationCode() {
    // For demo purposes only
    return '123456';
  }

  static void showCodeMessage(code, context) {
    switch (code) {
      case LoginErrorCode.success:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(LoginLocalizations.of(context).loginSuccess)),
        );
        break;
      case LoginErrorCode.invalidPhoneNumber:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(LoginLocalizations.of(context).invalidPhoneNumber),
          ),
        );
        break;
      case LoginErrorCode.invalidCredentials:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(LoginLocalizations.of(context).invalidCredentials),
          ),
        );
        break;
      case LoginErrorCode.networkError:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(LoginLocalizations.of(context).networkError)),
        );
        break;
      case LoginErrorCode.serverError:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(LoginLocalizations.of(context).serverError)),
        );
        break;
      case LoginErrorCode.unknownError:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(LoginLocalizations.of(context).unknownError)),
        );
        break;
    }
  }
}
