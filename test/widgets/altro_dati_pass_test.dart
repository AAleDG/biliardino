import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:biliardino/screens/data_management_screen.dart';
import 'package:biliardino/repositories/data_management_repository.dart';
import 'package:biliardino/services/backup_file_picker.dart';
import 'package:biliardino/services/data_file_share_service.dart';
import 'package:biliardino/theme/app_theme.dart';
import '../support/fake_data_management.dart';

class Picker extends BackupFilePicker {
  int calls = 0;
  Completer<String?> result = Completer();
  @override
  Future<String?> pickJson() {
    calls++;
    return result.future;
  }
}

void main() {
  testWidgets('picker single flight, cancel and confirm cancel preserve data', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(402, 874);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final data = FakeData();
    final picker = Picker();
    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<DataManagementRepository>.value(value: data),
          RepositoryProvider<BackupFilePicker>.value(value: picker),
          RepositoryProvider<DataFileShareService>(
            create: (_) => DataFileShareService.platform(),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.southAfrica(),
          home: const DataManagementScreen(),
        ),
      ),
    );
    final restore = find.byKey(const ValueKey('restore-json'));
    await tester.ensureVisible(restore);
    await tester.pumpAndSettle();
    await tester.tap(restore);
    await tester.pump();
    await tester.tap(restore);
    await tester.pump();
    expect(picker.calls, 1);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    picker.result.complete(null);
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(data.writes, 0);
    picker.result = Completer();
    await tester.tap(restore);
    await tester.pump();
    picker.result.complete('{}');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Ripristinare il backup?'), findsOneWidget);
    await tester.tap(find.text('Annulla'));
    await tester.pumpAndSettle();
    expect(data.writes, 0);
    picker.result = Completer();
    await tester.tap(restore);
    await tester.pump();
    picker.result.complete('{}');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Ripristina'));
    await tester.pumpAndSettle();
    expect(data.writes, 1);
    expect(data.refreshes, 1);
  });
}
