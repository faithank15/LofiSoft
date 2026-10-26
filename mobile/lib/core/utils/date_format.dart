/// Formatage court et lisible des dates en français, sans dépendance externe.
abstract final class AppDateFormat {
  static const _months = [
    'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
    'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
  ];
  static const _monthsShort = [
    'janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin',
    'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.',
  ];

  /// `novembre` (mois de 1 à 12)
  static String monthName(int month) => _months[month - 1];

  /// `nov.`
  static String monthShort(int month) => _monthsShort[month - 1];

  /// `22 oct. 2026`
  static String short(DateTime d) => '${d.day} ${monthShort(d.month)} ${d.year}';

  /// `22 octobre 2026` (et `1er mars 2026`)
  static String long(DateTime d) =>
      '${d.day == 1 ? '1er' : d.day} ${monthName(d.month)} ${d.year}';

  /// `Novembre 2026`
  static String monthYear(DateTime d) {
    final name = monthName(d.month);
    return '${name[0].toUpperCase()}${name.substring(1)} ${d.year}';
  }

  /// `08` (jour sur 2 chiffres)
  static String day(DateTime d) => d.day.toString().padLeft(2, '0');
}
