import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/utils/cloudinary.dart';
import 'package:mobile/core/utils/currency_formatter.dart';
import 'package:mobile/core/utils/date_format.dart';
import 'package:mobile/core/utils/validators.dart';

void main() {
  group('Validators.phone (format 01 + 8 chiffres, sans +229)', () {
    for (final ok in ['0197123456', '01 97 12 34 56', '01.97.12.34.56', '01-97-12-34-56', ' 0197123456 ']) {
      test('accepte "$ok"', () => expect(Validators.phone(ok), isNull));
    }
    for (final bad in ['', '   ', '0297123456', '019712345', '01971234567', '+22997123456', '0197abc456', '97123456']) {
      test('refuse "$bad"', () => expect(Validators.phone(bad), isNotNull));
    }
    test('null refusé', () => expect(Validators.phone(null), isNotNull));
  });

  group('Validators.email', () {
    for (final ok in ['a@b.co', 'patrick@lofi.bj', 'a.b+c@d.example.com', '  a@b.co  ']) {
      test('accepte "$ok"', () => expect(Validators.email(ok), isNull));
    }
    for (final bad in ['', 'abc', 'a@', '@b.co', 'a@b', 'a b@c.de', 'a@b.c', null]) {
      test('refuse "$bad"', () => expect(Validators.email(bad), isNotNull));
    }
  });

  group('Validators.strongPassword', () {
    test('accepte lettres + chiffres, 8 caractères', () => expect(Validators.strongPassword('Test1234'), isNull));
    test('refuse vide, court, sans chiffre, sans lettre', () {
      expect(Validators.strongPassword(''), isNotNull);
      expect(Validators.strongPassword('Ab1'), isNotNull);
      expect(Validators.strongPassword('abcdefgh'), isNotNull);
      expect(Validators.strongPassword('12345678'), isNotNull);
      expect(Validators.strongPassword(null), isNotNull);
    });
    test('7 caractères refusés, 8 acceptés (limite alignée sur le back)', () {
      expect(Validators.strongPassword('Abcde12'), isNotNull);
      expect(Validators.strongPassword('Abcde123'), isNull);
    });
  });

  test('Validators : mot de passe de connexion, nom, champ requis', () {
    expect(Validators.passwordPresent(''), isNotNull);
    expect(Validators.passwordPresent('x'), isNull);
    expect(Validators.fullName(' '), isNotNull);
    expect(Validators.fullName('A'), isNotNull);
    expect(Validators.fullName('Patrick Agossa'), isNull);
    expect(Validators.requiredField('  '), isNotNull);
    expect(Validators.requiredField('x'), isNull);
  });

  group('CurrencyFormatter', () {
    const nb = ' ';
    test('regroupe par milliers avec espace insécable', () {
      expect(CurrencyFormatter.number(0), '0');
      expect(CurrencyFormatter.number(999), '999');
      expect(CurrencyFormatter.number(1000), '1${nb}000');
      expect(CurrencyFormatter.number(75000), '75${nb}000');
      expect(CurrencyFormatter.number(1234567), '1${nb}234${nb}567');
    });
    test('négatif et arrondi', () {
      expect(CurrencyFormatter.number(-1500), '-1${nb}500');
      expect(CurrencyFormatter.number(1999.6), '2${nb}000');
    });
    test('format ajoute FCFA', () => expect(CurrencyFormatter.format(150000), '150${nb}000${nb}FCFA'));
  });

  group('AppDateFormat', () {
    test('noms de mois', () {
      expect(AppDateFormat.monthName(1), 'janvier');
      expect(AppDateFormat.monthName(12), 'décembre');
      expect(AppDateFormat.monthShort(10), 'oct.');
    });
    test('formats courts et longs', () {
      expect(AppDateFormat.short(DateTime(2026, 10, 22)), '22 oct. 2026');
      expect(AppDateFormat.long(DateTime(2026, 3, 1)), '1er mars 2026');
      expect(AppDateFormat.long(DateTime(2026, 10, 22)), '22 octobre 2026');
      expect(AppDateFormat.monthYear(DateTime(2026, 11, 5)), 'Novembre 2026');
      expect(AppDateFormat.day(DateTime(2026, 11, 5)), '05');
    });
  });

  group('Cloudinary.optimize', () {
    const url = 'https://res.cloudinary.com/demo/image/upload/v1/a.jpg';
    test('insère les options après /upload/', () {
      expect(Cloudinary.optimize(url, width: 800), 'https://res.cloudinary.com/demo/image/upload/f_auto,q_auto,c_fill,w_800/v1/a.jpg');
    });
    test('hauteur optionnelle', () => expect(Cloudinary.optimize(url, width: 400, height: 300), contains('w_400,h_300')));
    test('URL non Cloudinary (ex. stockage local du back) inchangée', () {
      const local = 'http://10.0.2.2:8000/storage/uploads/a.jpg';
      expect(Cloudinary.optimize(local, width: 800), local);
    });
    test('URL Cloudinary sans /upload/ inchangée', () {
      const odd = 'https://res.cloudinary.com/demo/raw/a.jpg';
      expect(Cloudinary.optimize(odd, width: 800), odd);
    });
  });
}
