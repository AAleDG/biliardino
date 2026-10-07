import 'dart:async';
import 'package:biliardino/main.dart';
import 'package:biliardino/repositories/app_style_repository.dart';
import 'package:flutter/material.dart';
import 'design_fixture.dart';
import 'fake_database.dart';

class ControlledStyleDatabase extends FakeDatabaseHelper {
  int writes = 0;
  bool fail = false;
  Completer<void>? barrier;
  @override
  Future<void> setSettings(Map<String, String> values) async {
    writes++;
    await barrier?.future;
    if (fail) throw StateError('write');
    await super.setSettings(values);
  }
}

class ControlledStyleFixture extends DesignFixture {
  ControlledStyleFixture(ControlledStyleDatabase database)
    : repository = AppStyleRepository(database);
  final AppStyleRepository repository;
  @override
  Future<void> load() async {
    await super.load();
    await repository.load();
  }

  @override
  Widget get app => BiliardinoApp(
    playerRepository: playersRepository,
    matchRepository: matchesRepository,
    matchRulesRepository: rulesRepository,
    dataManagementRepository: dataCoordinator,
    appStyleRepository: repository,
  );
}
