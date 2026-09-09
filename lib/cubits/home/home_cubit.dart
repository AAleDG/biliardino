import 'package:flutter_bloc/flutter_bloc.dart';

enum HomeDestination { home, players, match, leaderboard, more }

class HomeCubit extends Cubit<HomeDestination> {
  HomeCubit() : super(HomeDestination.home);

  void select(HomeDestination destination) {
    if (destination == state) return;
    emit(destination);
  }
}
