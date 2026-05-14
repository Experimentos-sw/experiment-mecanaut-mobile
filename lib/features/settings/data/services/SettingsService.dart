import 'package:mecanaut_mobile/features/settings/data/models/local_settings.dart';
import 'package:mecanaut_mobile/features/settings/data/services/LocalSettingsStorage.dart';

class SettingsService {
  SettingsService(this._storage);

  final LocalSettingsStorage _storage;

  Future<LocalSettings> loadLocalSettings() => _storage.read();

  Future<void> saveLocalSettings(LocalSettings settings) => _storage.write(settings);
}

