/// Formatage des montants en francs CFA : `75 000 FCFA`.
/// Les espaces sont insécables : un montant ne se coupe jamais en fin de ligne.
abstract final class CurrencyFormatter {
  static const _nbsp = ' ';

  /// `75000` -> `75 000`
  static String number(num amount) {
    final value = amount.round();
    final digits = value.abs().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(_nbsp);
      buffer.write(digits[i]);
    }
    return '${value < 0 ? '-' : ''}$buffer';
  }

  /// `75000` -> `75 000 FCFA`
  static String format(num amount) => '${number(amount)}${_nbsp}FCFA';
}
