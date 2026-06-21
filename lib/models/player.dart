class Player {
  final String id;
  final String name;
  final DateTime createdAt;
  final bool isPresent;

  Player({
    required this.id,
    required this.name,
    required this.createdAt,
    this.isPresent = true,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'created_at': createdAt.millisecondsSinceEpoch,
        'is_present': isPresent ? 1 : 0,
      };

  factory Player.fromMap(Map<String, dynamic> m) => Player(
        id: m['id'] as String,
        name: m['name'] as String,
        createdAt: DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int),
        isPresent: (m['is_present'] as int) == 1,
      );

  Player copyWith({String? name, bool? isPresent}) => Player(
        id: id,
        name: name ?? this.name,
        createdAt: createdAt,
        isPresent: isPresent ?? this.isPresent,
      );
}
