class Currency {
  final String code;
  final String symbol;
  final String name;

  Currency({
    required this.code,
    required this.symbol,
    required this.name,
  });

  Map<String, dynamic> toJson() => {
    'code': code,
    'symbol': symbol,
    'name': name,
  };

  factory Currency.fromJson(Map<String, dynamic> json) => Currency(
    code: json['code'],
    symbol: json['symbol'],
    name: json['name'],
  );
}

final List<Currency> availableCurrencies = [
  Currency(code: 'TRY', symbol: '₺', name: 'Türk Lirası'),
  Currency(code: 'USD', symbol: '\$', name: 'Amerikan Doları'),
  Currency(code: 'EUR', symbol: '€', name: 'Euro'),
  Currency(code: 'GBP', symbol: '£', name: 'İngiliz Sterlini'),
  Currency(code: 'JPY', symbol: '¥', name: 'Japon Yeni'),
  Currency(code: 'CHF', symbol: 'Fr', name: 'İsviçre Frangı'),
  Currency(code: 'CAD', symbol: 'C\$', name: 'Kanada Doları'),
  Currency(code: 'AUD', symbol: 'A\$', name: 'Avustralya Doları'),
  Currency(code: 'CNY', symbol: '¥', name: 'Çin Yuanı'),
  Currency(code: 'RUB', symbol: '₽', name: 'Rus Rublesi'),
  Currency(code: 'SAR', symbol: '﷼', name: 'Suudi Riyali'),
  Currency(code: 'AED', symbol: 'د.إ', name: 'BAE Dirhemi'),
];

Currency get defaultCurrency => availableCurrencies.first; // TRY
