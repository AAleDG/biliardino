import 'package:biliardino/theme/app_theme.dart';
import 'package:biliardino/widgets/avatar.dart';
import 'package:biliardino/widgets/design/brand_header.dart';
import 'package:biliardino/widgets/design/south_africa_artwork.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    for (final (family, files) in [
      ('Barlow', ['Barlow-Regular.ttf', 'Barlow-SemiBold.ttf']),
      (
        'Barlow Condensed',
        ['BarlowCondensed-ExtraBold.ttf', 'BarlowCondensed-Black.ttf'],
      ),
    ]) {
      final loader = FontLoader(family);
      for (final file in files) {
        loader.addFont(rootBundle.load('assets/fonts/$file'));
      }
      await loader.load();
    }
  });
  for (final (width, height, scale) in [
    (402.0, 874.0, 1.0),
    (320.0, 568.0, 2.0),
  ]) {
    testWidgets('Loaded-font foundation at ${width.toInt()} / $scale', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, height);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.southAfrica(),
          home: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(scale)),
              child: Builder(
                builder: (context) => RepaintBoundary(
                  key: const ValueKey('golden'),
                  child: Scaffold(
                    appBar: brandAppBar(context, title: 'GIOCATORI'),
                    body: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        const Card(
                          child: ListTile(
                            leading: PlayerAvatar(name: 'Èlia'),
                            title: Text('Èlia Rossi'),
                            subtitle: Text('In ufficio'),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {},
                          child: const Text('NUOVO'),
                        ),
                        const SizedBox(height: 8),
                        const ElevatedButton(
                          onPressed: null,
                          child: Text('INIZIA PARTITA'),
                        ),
                        const SizedBox(height: 16),
                        const TextField(
                          decoration: InputDecoration(
                            labelText: 'Nome',
                            helperText: 'Nome del giocatore',
                          ),
                        ),
                        const SizedBox(height: 24),
                        for (final size in [24.0, 48.0, 96.0])
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              SouthAfricaArtwork(
                                mark: ArtworkMark.figure,
                                width: size / 2,
                                height: size,
                              ),
                              SouthAfricaArtwork(
                                mark: ArtworkMark.football,
                                width: size,
                                height: size,
                              ),
                              ColoredBox(
                                color: AppColors.primary,
                                child: SouthAfricaArtwork(
                                  mark: ArtworkMark.football,
                                  width: size,
                                  height: size,
                                  monochrome: AppColors.surface,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(const ValueKey('golden')),
        matchesGoldenFile(
          'south-africa-${width.toInt()}-${scale.toInt()}x.png',
        ),
      );
    });
  }
}
