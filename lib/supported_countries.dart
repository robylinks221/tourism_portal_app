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
  static const uganda = SupportedCountry(
    name: 'Uganda',
    code: 'UG',
    currencyCode: 'UGX',
    currencySymbol: 'UGX',
  );

  static const rwanda = SupportedCountry(
    name: 'Rwanda',
    code: 'RW',
    currencyCode: 'RWF',
    currencySymbol: 'RWF',
  );

  static const kenya = SupportedCountry(
    name: 'Kenya',
    code: 'KE',
    currencyCode: 'KES',
    currencySymbol: 'KES',
  );

  static const tanzania = SupportedCountry(
    name: 'Tanzania',
    code: 'TZ',
    currencyCode: 'TZS',
    currencySymbol: 'TZS',
  );

  static const all = <SupportedCountry>[
    uganda,
    rwanda,
    kenya,
    tanzania,
  ];

  static const names = <String>[
    'Uganda',
    'Rwanda',
    'Kenya',
    'Tanzania',
  ];

  static SupportedCountry? byName(
      String? name,
      ) {
    if (name == null) {
      return null;
    }

    final normalized =
    name.trim().toLowerCase();

    for (final country in all) {
      if (country.name.toLowerCase() ==
          normalized) {
        return country;
      }
    }

    return null;
  }
}