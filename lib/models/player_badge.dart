import 'package:equatable/equatable.dart';

class PlayerBadge extends Equatable {
  const PlayerBadge({
    required this.code,
    required this.label,
    required this.description,
  });

  final String code;
  final String label;
  final String description;

  @override
  List<Object?> get props => [code, label, description];
}
