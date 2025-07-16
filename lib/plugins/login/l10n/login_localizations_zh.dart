import 'login_localizations.dart';

class LoginLocalizationsZh extends LoginLocalizations {
  LoginLocalizationsZh() : super('zh');

  @override
  String get loginTitle => '登录';

  @override
  String get emailHint => '邮箱';

  @override
  String get passwordHint => '密码';

  @override
  String get loginButton => '登录';

  @override
  String get forgotPassword => '忘记密码？';

  @override
  String get registerPrompt => '还没有账号？';

  @override
  String get registerButton => '注册';

  @override
  String get nameHint => '姓名';

  @override
  String get confirmPasswordHint => '确认密码';

  @override
  String get passwordMismatchError => '密码不匹配';

  @override
  String get invalidEmailError => '请输入有效的邮箱地址';

  @override
  String get weakPasswordError => '密码强度不足';

  @override
  String get emailAlreadyInUseError => '邮箱已被使用';

  @override
  String get userNotFoundError => '用户不存在';

  @override
  String get wrongPasswordError => '密码错误';

  @override
  String get verificationSentMessage => '验证邮件已发送';

  @override
  String get verificationEmailSubject => '验证您的邮箱';

  @override
  String get verificationEmailBody => '请点击链接验证您的邮箱';

  @override
  String get resetPasswordEmailSubject => '重置您的密码';

  @override
  String get resetPasswordEmailBody => '请点击链接重置您的密码';

  @override
  String get resetPasswordSuccessMessage => '密码重置成功';

  @override
  String get continueButton => '继续';

  @override
  String get verificationCodeHint => '验证码';

  @override
  String get resendCodeButton => '重新发送验证码';

  @override
  String get verificationSuccessMessage => '邮箱验证成功';

  @override
  String get completeRegistration => '完成注册';

  @override
  String get nextStep => '下一步';

  @override
  String get passwordLogin => '密码登录';

  @override
  String get phoneLogin => '手机号登录';

  @override
  String get registerTitle => '注册';

  @override
  String get loginFailed => '登录失败';

  @override
  String get loginSuccess => '登录成功';

  @override
  String get invalidPhoneNumber => '无效的手机号码';

  @override
  String get invalidCredentials => '手机号或密码错误';

  @override
  String get networkError => '网络错误，请稍后重试';

  @override
  String get serverError => '服务器错误，请稍后重试';

  @override
  String get unknownError => '发生未知错误';
}
