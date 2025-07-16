import 'login_localizations.dart';

class LoginLocalizationsEn extends LoginLocalizations {
  LoginLocalizationsEn() : super('en');

  @override
  String get loginTitle => 'Login';

  @override
  String get emailHint => 'Email';

  @override
  String get passwordHint => 'Password';

  @override
  String get loginButton => 'Sign In';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get registerPrompt => 'Don\'t have an account?';

  @override
  String get registerButton => 'Register';

  @override
  String get nameHint => 'Name';

  @override
  String get confirmPasswordHint => 'Confirm Password';

  @override
  String get passwordMismatchError => 'Passwords do not match';

  @override
  String get invalidEmailError => 'Please enter a valid email';

  @override
  String get weakPasswordError => 'Password is too weak';

  @override
  String get emailAlreadyInUseError => 'Email is already in use';

  @override
  String get userNotFoundError => 'User not found';

  @override
  String get wrongPasswordError => 'Wrong password';

  @override
  String get verificationSentMessage => 'Verification email sent';

  @override
  String get verificationEmailSubject => 'Verify your email';

  @override
  String get verificationEmailBody =>
      'Please click the link to verify your email';

  @override
  String get resetPasswordEmailSubject => 'Reset your password';

  @override
  String get resetPasswordEmailBody =>
      'Please click the link to reset your password';

  @override
  String get resetPasswordSuccessMessage => 'Password reset successfully';

  @override
  String get continueButton => 'Continue';

  @override
  String get verificationCodeHint => 'Verification Code';

  @override
  String get resendCodeButton => 'Resend Code';

  @override
  String get verificationSuccessMessage => 'Email verified successfully';

  @override
  String get completeRegistration => 'Complete Registration';

  @override
  String get nextStep => 'Next Step';

  @override
  String get passwordLogin => 'Password Login';

  @override
  String get phoneLogin => 'Phone Login';

  @override
  String get registerTitle => 'Register';

  @override
  String get loginFailed => 'Login Failed';

  @override
  String get loginSuccess => 'Login Success';

  @override
  String get invalidPhoneNumber => 'Invalid phone number';

  @override
  String get invalidCredentials => 'Invalid phone number or password';

  @override
  String get networkError => 'Network error, please try again later';

  @override
  String get serverError => 'Server error, please try again later';

  @override
  String get unknownError => 'Unknown error occurred';
}
