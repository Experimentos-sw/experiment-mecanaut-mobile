import 'dart:async';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:mecanaut_mobile/core/network/ApiException.dart';
import 'package:mecanaut_mobile/core/storage/SecureSessionStorage.dart';
import 'package:mecanaut_mobile/features/auth/data/dtos/sign_in_request.dart';
import 'package:mecanaut_mobile/features/auth/data/dtos/sign_up_request.dart';
import 'package:mecanaut_mobile/features/auth/data/dtos/user_profile.dart';
import 'package:mecanaut_mobile/features/auth/data/services/AuthService.dart';

class AuthSession extends ChangeNotifier {
  AuthSession({
    required SecureSessionStorage storage,
    required AuthService authService,
  }) : _storage = storage,
       _authService = authService {
    _bootstrap();
  }

  final SecureSessionStorage _storage;
  final AuthService _authService;

  bool _isInitialized = false;
  bool _isLoading = false;
  bool _isSessionReady = false;
  String? _token;
  UserProfile? _user;
  int? _userId;
  String? _username;
  String? _tenantId;
  String? _role;
  String? _errorMessage;

  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  bool get isSessionReady => _isSessionReady;
  bool get isAuthenticated => _token != null && _token!.isNotEmpty;
  String? get token => _token;
  UserProfile? get user => _user;
  int? get userId => _userId ?? _user?.id;
  String? get username => _username ?? _user?.username;
  String? get tenantId => _tenantId;
  String? get role => _role;
  List<String> get roles => _user?.roles ?? <String>[];
  String? get errorMessage => _errorMessage;

  bool hasRole(String role) => roles.contains(role);

  Future<void> _bootstrap() async {
    _setLoading(true);
    try {
      _token = await _storage.readToken();
      _userId = await _storage.readUserId();
      _username = await _storage.readUsername();
      final String? userJson = await _storage.readUserJson();
      if (userJson != null && userJson.isNotEmpty) {
        _user = UserProfile.fromJson(userJson);
      }

      if (_token == null || _token!.isEmpty) {
        _resetSessionState();
        return;
      }

      _extractClaimsFromJwt(_token!);

      _userId ??= _user?.id;
      _username ??= _user?.username;
      if ((_userId == null || _userId! <= 0) && _claimsUserId != null) {
        _userId = _claimsUserId;
      }
      if ((_username == null || _username!.isEmpty) && _claimsUsername != null) {
        _username = _claimsUsername;
      }

      if (_userId == null || _userId! <= 0 || _username == null || _username!.isEmpty) {
        await signOut();
        return;
      }

      _user ??= UserProfile(id: _userId!, username: _username!, roles: _role == null ? const [] : <String>[_role!]);
      await _storage.saveUserId(_userId!);
      await _storage.saveUsername(_username!);
      await _storage.saveUserJson(_user!.toJson());
      _isSessionReady = true;
      _errorMessage = null;

      unawaited(_refreshProfileOptional());
    } catch (_) {
      _isSessionReady = false;
      _errorMessage = 'No se pudo restaurar la sesion.';
    } finally {
      _isInitialized = true;
      _setLoading(false);
    }
  }

  Future<bool> signIn({
    required String username,
    required String password,
  }) async {
    _setLoading(true);
    try {
      await _storage.clearAll();
      _token = null;
      _resetSessionState();
      if (kDebugMode) debugPrint('[MECANAUT AUTH] Storage cleared');

      final credential = username.trim();
      final signInResponse = await _authService.signIn(
        SignInRequest(username: credential, password: password),
      );

      _token = signInResponse.token;
      _userId = signInResponse.id;
      _username = signInResponse.username;
      _extractClaimsFromJwt(signInResponse.token);
      _user = UserProfile(
        id: signInResponse.id,
        username: signInResponse.username,
        roles: _role == null ? const [] : <String>[_role!],
      );

      await _storage.saveToken(signInResponse.token);
      await _storage.saveUserId(signInResponse.id);
      await _storage.saveUsername(signInResponse.username);
      await _storage.saveUserJson(_user!.toJson());
      _isSessionReady = true;

      _errorMessage = null;
      if (kDebugMode) {
        debugPrint('[MECANAUT AUTH] Session ready from sign-in response');
        debugPrint('userId: $_userId');
        debugPrint('username: $_username');
        debugPrint('tenantId: $_tenantId');
        debugPrint('role: $_role');
      }
      unawaited(_refreshProfileOptional());
      return true;
    } on ApiException catch (error) {
      _isSessionReady = false;
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _isSessionReady = false;
      _errorMessage = 'Unexpected error while signing in.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signUp(SignUpRequest request) async {
    _setLoading(true);
    try {
      await _authService.signUp(request);
      _errorMessage = null;
      return true;
    } on ApiException catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage = 'Unexpected error while registering.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    _setLoading(true);
    await _storage.clearAll();
    _token = null;
    _resetSessionState();
    _errorMessage = null;
    if (kDebugMode) debugPrint('[MECANAUT AUTH] Storage cleared');
    _setLoading(false);
  }

  Future<void> retrySessionInitialization() async => _bootstrap();

  Future<void> handleUnauthorized() async {
    await signOut();
  }

  Future<void> setTokenForDebug(String token) async {
    _token = token;
    await _storage.saveToken(token);
    _isSessionReady = false;
    notifyListeners();
  }

  Future<void> overwriteUserProfile(UserProfile profile) async {
    _user = profile;
    _userId = profile.id;
    _username = profile.username;
    await _storage.saveUserJson(profile.toJson());
    await _storage.saveUserId(profile.id);
    await _storage.saveUsername(profile.username);
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  int? _claimsUserId;
  String? _claimsUsername;

  void _extractClaimsFromJwt(String token) {
    _claimsUserId = null;
    _claimsUsername = null;
    _tenantId = null;
    _role = null;
    try {
      final parts = token.split('.');
      if (parts.length < 2) return;
      final normalized = base64Url.normalize(parts[1]);
      final jsonPayload = utf8.decode(base64Url.decode(normalized));
      final payload = jsonDecode(jsonPayload) as Map<String, dynamic>;

      _tenantId = payload['tenant_id']?.toString();
      _role = payload['http://schemas.microsoft.com/ws/2008/06/identity/claims/role']?.toString() ??
          payload['role']?.toString();

      final sid = payload['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/sid']?.toString() ??
          payload['sid']?.toString();
      _claimsUserId = int.tryParse(sid ?? '');

      _claimsUsername =
          payload['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name']?.toString() ??
          payload['name']?.toString();
    } catch (_) {}
  }

  Future<void> _refreshProfileOptional() async {
    if (_token == null || _token!.isEmpty || _userId == null || _userId! <= 0) {
      return;
    }
    try {
      final profile = await _authService.getUserById(
        userId: _userId!,
        token: _token!,
      );
      _user = profile;
      await _storage.saveUserJson(profile.toJson());
      await _storage.saveUserId(profile.id);
      await _storage.saveUsername(profile.username);
      notifyListeners();
    } on ApiException {
      if (kDebugMode) {
        debugPrint(
          '[MECANAUT AUTH] Perfil remoto no disponible; se conserva sesion basica.',
        );
      }
    } catch (_) {}
  }

  void _resetSessionState() {
    _user = null;
    _userId = null;
    _username = null;
    _tenantId = null;
    _role = null;
    _claimsUserId = null;
    _claimsUsername = null;
    _isSessionReady = false;
  }
}
