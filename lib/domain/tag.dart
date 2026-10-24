class Tag {
  final String key;
  final String? value;

  static const _reservedKeys = {'due', 't', 'rec'};

  Tag(this.key, [this.value]) {
    if (isReserved(key)) {
      throw ArgumentError.value(key, 'key', 'is reserved by the app');
    }
  }

  static bool isReserved(String key) => _reservedKeys.contains(key);

  String get label => value == null ? key : '$key:$value';

  bool isIn(Map<String, String> metadata) {
    if (!metadata.containsKey(key)) return false;

    return value == null || metadata[key] == value;
  }

  @override
  bool operator ==(Object other) =>
      other is Tag && other.key == key && other.value == value;

  @override
  int get hashCode => Object.hash(key, value);
}
