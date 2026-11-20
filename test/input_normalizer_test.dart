import 'package:flutter_test/flutter_test.dart';
import 'package:smart_university/utils/input_normalizer.dart';

void main() {
  group('InputNormalizer Unit Tests', () {
    group('cleanUserCode tests', () {
      test('1. Arabic and Eastern digits conversion', () {
        expect(InputNormalizer.cleanUserCode('٢٣٠٠٠١'), '230001');
        expect(InputNormalizer.cleanUserCode('۲۳۰۰۰۱'), '230001');
        expect(InputNormalizer.cleanUserCode('١٠٠٠١.college@smart.com'), '10001');
      });

      test('2. Whitespace trimming', () {
        expect(InputNormalizer.cleanUserCode('  230001  '), '230001');
        expect(InputNormalizer.cleanUserCode('\tSTD_230001\n'), '230001');
      });

      test('3. Mixed prefixes, suffixes, and email stripping', () {
        expect(InputNormalizer.cleanUserCode('std_230001'), '230001');
        expect(InputNormalizer.cleanUserCode('DOC_101'), '101');
        expect(InputNormalizer.cleanUserCode('TA_105'), '105');
        expect(InputNormalizer.cleanUserCode('230001.college@smart.com'), '230001');
        expect(InputNormalizer.cleanUserCode('user@smart.edu.eg'), 'user');
        expect(InputNormalizer.cleanUserCode('admin@smart.com'), 'admin');
      });

      test('4. Empty and whitespace-only strings', () {
        expect(InputNormalizer.cleanUserCode(''), '');
        expect(InputNormalizer.cleanUserCode('   '), '');
      });
    });

    group('cleanPasswordVariant tests', () {
      test('1. Preserves exact password characters and symbols', () {
        expect(InputNormalizer.cleanPasswordVariant(' Pass@123! '), 'Pass@123!');
        expect(InputNormalizer.cleanPasswordVariant(r'My$Secret#Pass9'), r'My$Secret#Pass9');
      });

      test('2. Converts Arabic numerals in password without dropping characters', () {
        expect(InputNormalizer.cleanPasswordVariant('١٢٣Pass#'), '123Pass#');
        expect(InputNormalizer.cleanPasswordVariant('Pass١٢٣Word!'), 'Pass123Word!');
      });

      test('3. Empty password handling', () {
        expect(InputNormalizer.cleanPasswordVariant(''), '');
      });
    });
  });
}
