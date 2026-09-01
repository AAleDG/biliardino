import 'package:unorm_dart/unorm_dart.dart' as unorm;

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
    // Equality policy: Unicode NFKD, remove combining marks, and apply the
    // explicitly supported case-insensitive mappings below. This is not a
    // claim of complete Unicode case folding.
    final folded = unorm
        .nfkd(name)
        .replaceAll(_nameWhitespacePattern, ' ')
        .trim()
        .toLowerCase()
        .replaceAllMapped(
          _caseFoldPattern,
          (match) => _caseFoldMappings[match.group(0)]!,
        );
    return folded.replaceAll(RegExp(r'[\u0300-\u036F]'), '');
  }
}

final RegExp _nameWhitespacePattern = RegExp(
  r'[\s\u00A0\u1680\u2000-\u200A\u2028\u2029\u202F\u205F\u3000]+',
  unicode: true,
);

final RegExp _caseFoldPattern = RegExp('[ßς]');

const Map<String, String> _caseFoldMappings = {'ß': 'ss', 'ς': 'σ'};
