import 'package:flutter_test/flutter_test.dart';
import 'package:don3txt/domain/priority_colors.dart';

void main() {
  group('PriorityColors', () {
    test('supportedLetters is A through F', () {
      expect(PriorityColors.supportedLetters, ['A', 'B', 'C', 'D', 'E', 'F']);
    });

    test('defaults go from red (A) to green (F)', () {
      final colors = PriorityColors.defaults();

      expect(colors.colorFor('A'), 0xFFE53935);
      expect(colors.colorFor('B'), 0xFFFB8C00);
      expect(colors.colorFor('C'), 0xFFFDD835);
      expect(colors.colorFor('D'), 0xFFC0CA33);
      expect(colors.colorFor('E'), 0xFF7CB342);
      expect(colors.colorFor('F'), 0xFF43A047);
    });

    test('colorFor returns null for letters outside A-F', () {
      final colors = PriorityColors.defaults();

      expect(colors.colorFor('G'), isNull);
      expect(colors.colorFor('Z'), isNull);
      expect(colors.colorFor(''), isNull);
    });

    test('withColor returns a new instance with the updated letter', () {
      final original = PriorityColors.defaults();
      final updated = original.withColor('A', 0xFF123456);

      expect(updated.colorFor('A'), 0xFF123456);
      expect(original.colorFor('A'), 0xFFE53935);
    });

    test('withColor on an unsupported letter throws ArgumentError', () {
      final colors = PriorityColors.defaults();

      expect(() => colors.withColor('G', 0xFF000000),
          throwsA(isA<ArgumentError>()));
    });

    test('toMap serializes A-F entries', () {
      final colors = PriorityColors.defaults();
      final map = colors.toMap();

      expect(map.keys.toSet(), {'A', 'B', 'C', 'D', 'E', 'F'});
      expect(map['A'], 0xFFE53935);
    });

    test('fromMap hydrates from a partial map and falls back to defaults', () {
      final colors = PriorityColors.fromMap({'A': 0xFF111111});

      expect(colors.colorFor('A'), 0xFF111111);
      expect(colors.colorFor('B'), 0xFFFB8C00);
    });

    test('fromMap ignores letters outside A-F', () {
      final colors = PriorityColors.fromMap({'G': 0xFF000000});

      expect(colors.colorFor('G'), isNull);
    });

    test('equality is structural', () {
      final a = PriorityColors.defaults();
      final b = PriorityColors.defaults();
      final c = a.withColor('A', 0xFF000000);

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
      expect(a.hashCode, b.hashCode);
    });
  });
}
