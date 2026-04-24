import 'package:flutter/foundation.dart';

@immutable
class PriorityColors {
  static const List<String> supportedLetters = ['A', 'B', 'C', 'D', 'E', 'F'];

  static const Map<String, int> _defaults = {
    'A': 0xFFE53935,
    'B': 0xFFFB8C00,
    'C': 0xFFFDD835,
    'D': 0xFFC0CA33,
    'E': 0xFF7CB342,
    'F': 0xFF43A047,
  };

  final Map<String, int> _byLetter;

  const PriorityColors._(this._byLetter);

  factory PriorityColors.defaults() =>
      PriorityColors._(Map.unmodifiable(_defaults));

  factory PriorityColors.fromMap(Map<String, int> map) {
    final merged = <String, int>{..._defaults};

    for (final letter in supportedLetters) {
      if (map.containsKey(letter)) {
        merged[letter] = map[letter]!;
      }
    }

    return PriorityColors._(Map.unmodifiable(merged));
  }

  int? colorFor(String letter) {
    if (!supportedLetters.contains(letter)) return null;

    return _byLetter[letter];
  }

  PriorityColors withColor(String letter, int color) {
    if (!supportedLetters.contains(letter)) {
      throw ArgumentError.value(letter, 'letter',
          'Not a supported priority letter (${supportedLetters.join(', ')})');
    }

    final next = <String, int>{..._byLetter, letter: color};

    return PriorityColors._(Map.unmodifiable(next));
  }

  Map<String, int> toMap() => Map.unmodifiable(_byLetter);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! PriorityColors) return false;

    return mapEquals(_byLetter, other._byLetter);
  }

  @override
  int get hashCode => Object.hashAll(
      supportedLetters.map((l) => _byLetter[l] ?? 0));
}
