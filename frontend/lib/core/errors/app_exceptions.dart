class AppException implements Exception {
  final String message;
  final String? code;
  AppException(this.message, {this.code});
  @override
  String toString() => 'AppException: $message (code: $code)';
}

class AuthException extends AppException {
  AuthException(super.message, {super.code});
}

class FirestoreException extends AppException {
  FirestoreException(super.message, {super.code});
}

class StorageException extends AppException {
  StorageException(super.message, {super.code});
}

class NetworkException extends AppException {
  NetworkException(super.message, {super.code});
}

class PermissionException extends AppException {
  PermissionException(super.message, {super.code});
}
