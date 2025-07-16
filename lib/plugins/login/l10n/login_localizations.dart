import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'login_localizations_en.dart';
import 'login_localizations_zh.dart';

/// 登录插件的本地化支持类
abstract class LoginLocalizations {
  LoginLocalizations(String locale) : localeName = locale;

  final String localeName;
  static LoginLocalizations of(BuildContext context) {
    final localizations = Localizations.of<LoginLocalizations>(
      context,
      LoginLocalizations,
    );
    if (localizations == null) {
      throw FlutterError('No LoginLocalizations found in context');
    }
    return localizations;
  }

  static const LocalizationsDelegate<LoginLocalizations> delegate =
      _LoginLocalizationsDelegate();

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  // 登录相关字符串
  String get loginTitle;
  String get emailHint;
  String get passwordHint;
  String get loginButton;
  String get forgotPassword;
  String get registerPrompt;
  String get registerButton;
  String get nameHint;
  String get confirmPasswordHint;
  String get passwordMismatchError;
  String get invalidEmailError;
  String get weakPasswordError;
  String get emailAlreadyInUseError;
  String get userNotFoundError;
  String get wrongPasswordError;
  String get verificationSentMessage;
  String get verificationEmailSubject;
  String get verificationEmailBody;
  String get resetPasswordEmailSubject;
  String get resetPasswordEmailBody;
  String get resetPasswordSuccessMessage;
  String get continueButton;
  String get verificationCodeHint;
  String get resendCodeButton;
  String get verificationSuccessMessage;

  String get phoneLogin;

  String get passwordLogin;

  String get completeRegistration;

  String get registerTitle;

  String get nextStep;

  String get loginSuccess;
  String get loginFailed;
  String get invalidPhoneNumber;
  String get invalidCredentials;
  String get networkError;
  String get serverError;
  String get unknownError;
}

class _LoginLocalizationsDelegate
    extends LocalizationsDelegate<LoginLocalizations> {
  const _LoginLocalizationsDelegate();

  @override
  Future<LoginLocalizations> load(Locale locale) {
    return SynchronousFuture<LoginLocalizations>(
      lookupLoginLocalizations(locale),
    );
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_LoginLocalizationsDelegate old) => false;
}

LoginLocalizations lookupLoginLocalizations(Locale locale) {
  // 支持的语言代码
  switch (locale.languageCode) {
    case 'en':
      return LoginLocalizationsEn();
    case 'zh':
      return LoginLocalizationsZh();
  }

  throw FlutterError(
    'LoginLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localization\'s implementation.',
  );
}
