import 'package:biliardino/cubits/home/home_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'uses the named five-destination order with Home initially selected',
    () {
      final cubit = HomeCubit();

      expect(cubit.state, HomeDestination.home);
      expect(HomeDestination.values, [
        HomeDestination.home,
        HomeDestination.players,
        HomeDestination.match,
        HomeDestination.leaderboard,
        HomeDestination.more,
      ]);

      cubit.select(HomeDestination.match);
      expect(cubit.state, HomeDestination.match);
      cubit.select(HomeDestination.match);
      expect(cubit.state, HomeDestination.match);
    },
  );
}
