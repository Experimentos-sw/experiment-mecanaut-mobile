enum AppLanguage { es, en }

class LocalSettings {
  const LocalSettings({
    required this.language,
    required this.timezone,
    required this.notificationsEnabled,
    required this.initialView,
    this.lastPlantId,
    this.lastLineId,
    required this.cardHolder,
    required this.cardNumber,
    required this.cardExpiry,
    required this.cardCvv,
    required this.billingEmail,
  });

  final AppLanguage language;
  final String timezone;
  final bool notificationsEnabled;
  final String initialView;
  final int? lastPlantId;
  final int? lastLineId;
  final String cardHolder;
  final String cardNumber;
  final String cardExpiry;
  final String cardCvv;
  final String billingEmail;

  factory LocalSettings.defaults() {
    return const LocalSettings(
      language: AppLanguage.es,
      timezone: '(UTC-05:00)',
      notificationsEnabled: true,
      initialView: '/dashboard',
      lastPlantId: null,
      lastLineId: null,
      cardHolder: '',
      cardNumber: '',
      cardExpiry: '',
      cardCvv: '',
      billingEmail: '',
    );
  }

  LocalSettings copyWith({
    AppLanguage? language,
    String? timezone,
    bool? notificationsEnabled,
    String? initialView,
    int? lastPlantId,
    int? lastLineId,
    bool clearPlant = false,
    bool clearLine = false,
    String? cardHolder,
    String? cardNumber,
    String? cardExpiry,
    String? cardCvv,
    String? billingEmail,
  }) {
    return LocalSettings(
      language: language ?? this.language,
      timezone: timezone ?? this.timezone,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      initialView: initialView ?? this.initialView,
      lastPlantId: clearPlant ? null : (lastPlantId ?? this.lastPlantId),
      lastLineId: clearLine ? null : (lastLineId ?? this.lastLineId),
      cardHolder: cardHolder ?? this.cardHolder,
      cardNumber: cardNumber ?? this.cardNumber,
      cardExpiry: cardExpiry ?? this.cardExpiry,
      cardCvv: cardCvv ?? this.cardCvv,
      billingEmail: billingEmail ?? this.billingEmail,
    );
  }
}

