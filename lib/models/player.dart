class Player {
  final String id;
  final String name;
  final DateTime createdAt;
  final bool isPresent;
  final bool isArchived;

  Player({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.isPresent,
    this.isArchived = false,
  });

  bool get isEligibleForMatch => isPresent && !isArchived;

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'name_key': normalizedNameKey(name),
    'created_at': createdAt.millisecondsSinceEpoch,
    'is_present': isPresent ? 1 : 0,
    'is_archived': isArchived ? 1 : 0,
  };

  factory Player.fromMap(Map<String, dynamic> m) => Player(
    id: m['id'] as String,
    name: m['name'] as String,
    createdAt: DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int),
    isPresent: (m['is_present'] as int) == 1,
    isArchived: (m['is_archived'] as int? ?? 0) == 1,
  );

  Player copyWith({String? name, bool? isPresent, bool? isArchived}) => Player(
    id: id,
    name: name ?? this.name,
    createdAt: createdAt,
    isPresent: isPresent ?? this.isPresent,
    isArchived: isArchived ?? this.isArchived,
  );

  static String normalizedNameKey(String name) {
    // Equality policy: collapse Unicode whitespace, remove canonical combining
    // marks, then apply the locale-independent case-fold mappings used by
    // player names. This makes composed/decomposed accents and ß/SS equal.
    final folded = name
        .replaceAll(_nameWhitespacePattern, ' ')
        .trim()
        .replaceAll(RegExp(r'\u00DF|\u1E9E'), 'ss')
        .toLowerCase();
    return folded
        .replaceAll(RegExp(r'[\u0300-\u036F]'), '')
        .replaceAllMapped(_latinDiacriticsPattern, (match) =>
            _latinDiacritics[match[0]!]!);
  }
}

final RegExp _nameWhitespacePattern = RegExp(
  r'[\s\u00A0\u1680\u2000-\u200A\u2028\u2029\u202F\u205F\u3000]+',
  unicode: true,
);

final RegExp _latinDiacriticsPattern = RegExp('[àáâãäåæçèéêëìíîïñòóôõöøùúûüýÿ]');
const _latinDiacritics = {
  'à': 'a', 'á': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a', 'å': 'a', 'æ': 'ae',
  'ç': 'c', 'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e', 'ì': 'i', 'í': 'i',
  'î': 'i', 'ï': 'i', 'ñ': 'n', 'ò': 'o', 'ó': 'o', 'ô': 'o', 'õ': 'o',
  'ö': 'o', 'ø': 'o', 'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u', 'ý': 'y',
  'ÿ': 'y',
};
