/// 认证相关异常
class InvalidCredentialsException implements Exception {
  final String message;
  InvalidCredentialsException(this.message);
  
  @override
  String toString() => 'InvalidCredentialsException: $message';
}