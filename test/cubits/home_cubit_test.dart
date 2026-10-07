import 'package:biliardino/cubits/home/home_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'starts at Home and selects typed destinations without duplicate events',
    () async {
      final cubit = HomeCubit();
      expect(cubit.state, HomeDestination.home);
      final events = <HomeDestination>[];
      final subscription = cubit.stream.listen(events.add);
      cubit.select(HomeDestination.match);
      cubit.select(HomeDestination.match);
      cubit.select(HomeDestination.history);
      cubit.select(HomeDestination.data);
      cubit.select(HomeDestination.home);
      await Future<void>.delayed(Duration.zero);
      expect(events, [
        HomeDestination.match,
        HomeDestination.history,
        HomeDestination.data,
        HomeDestination.home,
      ]);
      expect(cubit.state, HomeDestination.home);
      await subscription.cancel();
      await cubit.close();
    },
  );
}
