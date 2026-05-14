import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mecanaut_mobile/features/settings/data/models/local_settings.dart';

class LocalSettingsStorage {
  LocalSettingsStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _languageKey = 'settings_language';
  static const _timezoneKey = 'settings_timezone';
  static const _notificationsKey = 'settings_notifications';
  static const _initialViewKey = 'settings_initial_view';
  static const _lastPlantIdKey = 'settings_last_plant_id';
  static const _lastLineIdKey = 'settings_last_line_id';
  static const _cardHolderKey = 'settings_card_holder';
  static const _cardNumberKey = 'settings_card_number';
  static const _cardExpiryKey = 'settings_card_expiry';
  static const _cardCvvKey = 'settings_card_cvv';
  static const _billingEmailKey = 'settings_billing_email';

  Future<LocalSettings> read() async {
    final languageRaw = await _storage.read(key: _languageKey);
    final timezone = await _storage.read(key: _timezoneKey);
    final notificationsRaw = await _storage.read(key: _notificationsKey);
    final initialView = await _storage.read(key: _initialViewKey);
    final lastPlantIdRaw = await _storage.read(key: _lastPlantIdKey);
    final lastLineIdRaw = await _storage.read(key: _lastLineIdKey);
    final cardHolder = await _storage.read(key: _cardHolderKey);
    final cardNumber = await _storage.read(key: _cardNumberKey);
    final cardExpiry = await _storage.read(key: _cardExpiryKey);
    final cardCvv = await _storage.read(key: _cardCvvKey);
    final billingEmail = await _storage.read(key: _billingEmailKey);

    return LocalSettings(
      language: languageRaw == 'en' ? AppLanguage.en : AppLanguage.es,
      timezone: timezone ?? '(UTC-05:00)',
      notificationsEnabled: notificationsRaw == null ? true : notificationsRaw == 'true',
      initialView: initialView ?? '/dashboard',
      lastPlantId: int.tryParse(lastPlantIdRaw ?? ''),
      lastLineId: int.tryParse(lastLineIdRaw ?? ''),
      cardHolder: cardHolder ?? '',
      cardNumber: cardNumber ?? '',
      cardExpiry: cardExpiry ?? '',
      cardCvv: cardCvv ?? '',
      billingEmail: billingEmail ?? '',
    );
  }

  Future<void> write(LocalSettings settings) async {
    await Future.wait(<Future<void>>[
      _storage.write(key: _languageKey, value: settings.language == AppLanguage.en ? 'en' : 'es'),
      _storage.write(key: _timezoneKey, value: settings.timezone),
      _storage.write(key: _notificationsKey, value: settings.notificationsEnabled.toString()),
      _storage.write(key: _initialViewKey, value: settings.initialView),
      _storage.write(key: _lastPlantIdKey, value: settings.lastPlantId?.toString()),
      _storage.write(key: _lastLineIdKey, value: settings.lastLineId?.toString()),
      _storage.write(key: _cardHolderKey, value: settings.cardHolder),
      _storage.write(key: _cardNumberKey, value: settings.cardNumber),
      _storage.write(key: _cardExpiryKey, value: settings.cardExpiry),
      _storage.write(key: _cardCvvKey, value: settings.cardCvv),
      _storage.write(key: _billingEmailKey, value: settings.billingEmail),
    ]);
  }
}

