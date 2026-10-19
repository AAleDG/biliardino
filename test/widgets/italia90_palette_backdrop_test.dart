import 'package:biliardino/presentation/italia90/theme/app_theme.dart';
import 'package:biliardino/presentation/italia90/theme/italia90_tokens.dart';
import 'package:biliardino/presentation/italia90/widgets/italia_graphic_backdrop.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Italia palette assigns semantic petrol, amaranto and green roles', () {
    expect(Italia90.teamOne, const Color(0xFF17656B));
    expect(Italia90.teamTwo, Italia90.primary);
    expect(AppColors.homeAction, Italia90.green);
    expect(AppColors.homeActionPressed, AppColors.successPressed);
    expect(Italia90.petrolContainer, isNotNull);

    for (final color in [
      Italia90.teamOne,
      Italia90.teamTwo,
      AppColors.homeAction,
    ]) {
      final luminance = color.computeLuminance();
      final contrast = (1.05) / (luminance + .05);
      expect(contrast, greaterThanOrEqualTo(4.5), reason: '$color on white');
    }
  });

  testWidgets(
    'working backdrop changes while the Home artwork stays isolated',
    (tester) async {
      Future<String> assetFor(ItaliaBackdropVariant variant) async {
        await tester.pumpWidget(
          MaterialApp(
            home: ItaliaGraphicBackdrop(
              variant: variant,
              child: const SizedBox.shrink(),
            ),
          ),
        );
        await tester.pump();
        final image = tester.widget<Image>(find.byType(Image));
        return (image.image as AssetImage).assetName;
      }

      expect(
        await assetFor(ItaliaBackdropVariant.working),
        'assets/italia90/backdrop-working-petrol-amaranto.png',
      );
      expect(
        await assetFor(ItaliaBackdropVariant.live),
        'assets/italia90/backdrop-working-petrol-amaranto.png',
      );
      expect(
        await assetFor(ItaliaBackdropVariant.homeDashboard),
        'assets/italia90/backdrop-home-proposal-7.png',
      );
    },
  );
}
