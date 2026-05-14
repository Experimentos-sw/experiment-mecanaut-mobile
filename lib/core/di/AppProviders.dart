import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:mecanaut_mobile/core/auth/AuthSession.dart';
import 'package:mecanaut_mobile/core/network/ApiClient.dart';
import 'package:mecanaut_mobile/core/storage/SecureSessionStorage.dart';
import 'package:mecanaut_mobile/features/auth/data/services/AuthService.dart';

final secureSessionStorageProvider = Provider<SecureSessionStorage>((ref) {
  return SecureSessionStorage();
});

final authSessionProvider = ChangeNotifierProvider<AuthSession>((ref) {
  final storage = ref.read(secureSessionStorageProvider);
  return AuthSession(storage: storage, authService: AuthService());
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final ApiClient client = ApiClient(
    getAuthToken: () => ref.read(authSessionProvider).token,
    onUnauthorized: () => ref.read(authSessionProvider).handleUnauthorized(),
  );
  return client;
});

final apiDioProvider = Provider<Dio>((ref) {
  return ref.read(apiClientProvider).dio;
});
