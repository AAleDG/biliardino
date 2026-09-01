import 'package:biliardino/models/player.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uses canonical accent equivalence and case folding for name keys', () {
    expect(Player.normalizedNameKey('José'), 'jose');
    expect(Player.normalizedNameKey('Jose\u0301'), 'jose');
    expect(Player.normalizedNameKey('Straße'), 'strasse');
    expect(Player.normalizedNameKey('STRASSE'), 'strasse');
    expect(Player.normalizedNameKey('Č'), Player.normalizedNameKey('C\u030C'));
  });

  test('folds Greek final sigma to the regular sigma', () {
    expect(Player.normalizedNameKey('ΟΣ'), 'οσ');
    expect(Player.normalizedNameKey('Ος'), 'οσ');
    expect(Player.normalizedNameKey('ΟΣ'), Player.normalizedNameKey('Ος'));
  });
}
