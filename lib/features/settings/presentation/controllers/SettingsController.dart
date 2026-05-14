import 'package:flutter/foundation.dart';
import 'package:mecanaut_mobile/core/auth/AuthSession.dart';
import 'package:mecanaut_mobile/core/network/ApiException.dart';
import 'package:mecanaut_mobile/features/auth/data/dtos/user_profile.dart';
import 'package:mecanaut_mobile/features/personnel/data/models/update_user_request.dart';
import 'package:mecanaut_mobile/features/personnel/data/models/user_item.dart';
import 'package:mecanaut_mobile/features/settings/data/models/local_settings.dart';
import 'package:mecanaut_mobile/features/settings/data/services/ProfileService.dart';
import 'package:mecanaut_mobile/features/settings/data/services/SettingsService.dart';

class SettingsController extends ChangeNotifier {
  SettingsController({
    required SettingsService settingsService,
    required ProfileService profileService,
    required AuthSession session,
  }) : _settingsService = settingsService,
       _profileService = profileService,
       _session = session;

  final SettingsService _settingsService;
  final ProfileService _profileService;
  final AuthSession _session;

  bool _isLoading = false;
  bool _isSaving = false;
  String? _error;
  LocalSettings _localSettings = LocalSettings.defaults();
  UserItem? _profile;

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get error => _error;
  LocalSettings get localSettings => _localSettings;
  UserItem? get profile => _profile;
  bool get hasProfile => _profile != null;
  AuthSession get session => _session;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _localSettings = await _settingsService.loadLocalSettings();
      final user = _session.user;
      if (user != null) {
        try {
          _profile = await _profileService.getById(user.id);
        } on ApiException {
          _profile = UserItem(
            id: user.id,
            username: user.username,
            fullName: user.fullName ?? user.username,
            email: user.email ?? '',
            roles: user.roles,
          );
          _error =
              'No se pudo cargar el perfil completo. Se muestra la informacion basica de sesion.';
        }
      }
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'No se pudo cargar la configuracion.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveLocal(LocalSettings settings) async {
    _isSaving = true;
    _error = null;
    notifyListeners();
    try {
      await _settingsService.saveLocalSettings(settings);
      _localSettings = settings;
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'No se pudieron guardar preferencias locales.';
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> saveProfile({
    required String fullName,
    required String email,
  }) async {
    final current = _profile;
    if (current == null) return false;
    _isSaving = true;
    _error = null;
    notifyListeners();
    try {
      final split = _splitName(fullName);
      final updated = await _profileService.update(
        current.id,
        UpdateUserRequest(
          email: email.trim(),
          firstName: split.$1,
          lastName: split.$2,
          roles: current.roles,
        ),
      );
      _profile = updated;
      final userProfile = UserProfile(
        id: updated.id,
        username: updated.username,
        fullName: updated.fullName,
        email: updated.email,
        roles: updated.roles,
      );
      await _session.overwriteUserProfile(userProfile);
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      return false;
    } catch (_) {
      _error = 'No se pudo actualizar perfil.';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _session.signOut();
  }

  (String, String) _splitName(String fullName) {
    final parts = fullName
        .trim()
        .split(' ')
        .where((e) => e.trim().isNotEmpty)
        .toList();
    if (parts.isEmpty) return ('', '');
    if (parts.length == 1) return (parts.first, '.');
    return (parts.first, parts.sublist(1).join(' '));
  }
}
