import 'package:crosswords/modules/landing/repository/level.repos.dart';
import 'package:crosswords/modules/landing/repository/reward.repos.dart';

class Repos {
  Repos._();
  static final level = LevelRepository();
  static final reward = RewardRepository();
}
