import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:biliardino/services/data_management_coordinator.dart';
import '../support/design_fixture.dart';

void main() {
  for (final empty in [true, false]) {
    test(
      'JSON/CSV payloads and restore refresh boundary, empty=$empty',
      () async {
        final fixture = DesignFixture(empty: empty);
        await fixture.load();
        addTearDown(fixture.dispose);
        var refreshed = 0;
        final coordinator = DataManagementCoordinator(
          database: fixture.database,
          clock: () => DateTime(2026, 9, 13, 12, 34, 56),
          refresh: () async {
            refreshed++;
          },
        );
        final json = await coordinator.export(csv: false);
        expect(json.fileName, 'biliardino_backup_20260913_123456.json');
        expect(json.mimeType, 'application/json');
        expect(jsonDecode(json.content)['version'], 2);
        final parsed = coordinator.parse(json.content);
        expect(parsed.players.length, fixture.database.players.length);
        expect(parsed.matches.length, fixture.database.matches.length);
        final csv = await coordinator.export(csv: true);
        expect(csv.fileName, 'storico_biliardino_20260913_123456.csv');
        expect(csv.mimeType, 'text/csv');
        expect(csv.content, isNotEmpty);
        if (!empty) expect(csv.content, contains('Andrea'));
        await coordinator.restore(parsed);
        expect(refreshed, 0);
        expect(coordinator.needsRefresh, isTrue);
        await coordinator.refresh();
        expect(refreshed, 1);
        expect(coordinator.needsRefresh, isFalse);
        expect(
          () => coordinator.parse('{"version":999}'),
          throwsFormatException,
        );
      },
    );
  }
}
