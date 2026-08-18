class SupportedCountry {
  const SupportedCountry({
    required this.name,
    required this.code,
    required this.currencyCode,
    required this.currencySymbol,
  });

  final String name;
  final String code;
  final String currencyCode;
  final String currencySymbol;
}

abstract class TourismCountries {
  static const SupportedCountry uganda = SupportedCountry(
    name: 'Uganda',
    code: 'UG',
    currencyCode: 'UGX',
    currencySymbol: 'UGX',
  );

  static const SupportedCountry rwanda = SupportedCountry(
    name: 'Rwanda',
    code: 'RW',
    currencyCode: 'RWF',
    currencySymbol: 'RWF',
  );

  static const SupportedCountry kenya = SupportedCountry(
    name: 'Kenya',
    code: 'KE',
    currencyCode: 'KES',
    currencySymbol: 'KES',
  );

  static const SupportedCountry tanzania = SupportedCountry(
    name: 'Tanzania',
    code: 'TZ',
    currencyCode: 'TZS',
    currencySymbol: 'TZS',
  );

  static const List<SupportedCountry> all = [uganda, rwanda, kenya, tanzania];

  static const List<String> names = ['Uganda', 'Rwanda', 'Kenya', 'Tanzania'];

  static SupportedCountry? byName(String? name) {
    if (name == null) {
      return null;
    }

    final normalized = name.trim().toLowerCase();

    for (final country in all) {
      if (country.name.toLowerCase() == normalized) {
        return country;
      }
    }

    return null;
  }

  static SupportedCountry? byCode(String? code) {
    if (code == null) {
      return null;
    }

    final normalized = code.trim().toUpperCase();

    for (final country in all) {
      if (country.code == normalized) {
        return country;
      }
    }

    return null;
  }

  static String currencyForCountry(String? countryName) {
    return byName(countryName)?.currencyCode ?? 'USD';
  }

  static String flagForCountry(String? countryName) {
    final country = byName(countryName);

    if (country == null) {
      return '🌍';
    }

    return _flagFromCode(country.code);
  }

  static String destinationLabel({
    required String destinationName,
    String? countryName,
  }) {
    final flag = flagForCountry(countryName);
    return '$flag $destinationName';
  }

  static String _flagFromCode(String code) {
    final normalized = code.trim().toUpperCase();

    if (normalized.length != 2) {
      return '🌍';
    }

    const regionalIndicatorOffset = 0x1F1E6 - 0x41;

    return String.fromCharCodes(
      normalized.codeUnits.map((unit) => unit + regionalIndicatorOffset),
    );
  }

  static bool isSupported(String? countryName) {
    return byName(countryName) != null;
  }
}
