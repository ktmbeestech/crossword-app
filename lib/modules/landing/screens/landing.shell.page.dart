import 'package:flutter/foundation.dart';
import 'package:crosswords/constant/style/app.style.constant.dart';
import 'package:crosswords/services/audio/audio.service.dart';
import 'package:crosswords/modules/landing/widgets/glowing_animation.widget.dart';
import 'package:crosswords/modules/crossword/widgets/daily.rewards.dialog.dart';
import 'package:crosswords/modules/landing/widgets/setting.widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:crosswords/modules/landing/services/hint.service.dart';
import 'package:crosswords/modules/landing/services/daily_reward.service.dart';

import '../../../constant/sizedbox/sized_box.constants.dart';
import '../../crossword/services/level.progress.service.dart';
import '../../crossword/screens/crossword.game.screen.dart';
import '../../crossword/screens/level.select.screen.dart';

class CrosswordLandingPage extends StatefulWidget {
  const CrosswordLandingPage({super.key});

  @override
  State<CrosswordLandingPage> createState() => _CrosswordLandingPageState();
}

class _CrosswordLandingPageState extends State<CrosswordLandingPage> {
  bool _debugMode = false;

  void onToggleSound() async {
    await AudioService.instance.toggleSfx();
    if (mounted) setState(() {});
  }

  int _hintCount = 0;

  @override
  void initState() {
    super.initState();
    AudioService.instance.initialize();
    _loadHintCount();
  }

  Future<void> _loadHintCount() async {
    final n = await HintService.instance.getCount();
    if (!mounted) return;
    setState(() => _hintCount = n);
  }

  void onToggleMusic() async {
    await AudioService.instance.toggleMusic();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final shouldExit = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder:
              (ctx) => AlertDialog(
                backgroundColor: AppTheme.darkBackground,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                title: Text(
                  'Exit',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                content: Text(
                  'Are you sure you want to exit?',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white70,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    child: const Text(
                      'No',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    style: TextButton.styleFrom(
                      backgroundColor: AppTheme.primaryIndigo,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Yes',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
        );
        if (shouldExit == true) {
          SystemNavigator.pop();
        }
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -0.2),
              radius: 1.0,
              colors: [Color(0xFF100D49), Color(0xFF050318)],
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 14.0),
                    child: SizedBox(
                      height: 180,
                      child: Image.asset("assets/images/landing_title.png"),
                    ),
                  ),
                ),

                Positioned(
                  left: 18,
                  top: 170,
                  child: Column(
                    children: [
                      InkWell(
                        onTap: () async {
                          await AudioService.instance.playClick();
                          showDialog(
                            context: context,
                            builder:
                                (context) => SettingCrosswordWidget(
                                  onToggleMusic: onToggleMusic,
                                  onToggleSound: onToggleSound,
                                  isMusicMuted:
                                      !AudioService.instance.isMusicEnabled,
                                  isSoundMuted:
                                      !AudioService.instance.isSfxEnabled,
                                ),
                          );
                        },
                        child: Image.asset(
                          'assets/images/setting.png',
                          height: 60,
                        ),
                      ),
                      sboxH30,
                      InkWell(
                        onTap: () async {
                          await AudioService.instance.playClick();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LevelSelectScreen(),
                            ),
                          );
                        },
                        child: Image.asset(
                          'assets/images/tasks.png',
                          height: 60,
                        ),
                      ),
                    ],
                  ),
                ),

                Positioned(
                  right: 18,
                  top: 170,
                  child: GestureDetector(
                    onTap: () async {
                      await AudioService.instance.playClick();
                      final svc = DailyRewardService();
                      final currentDayIndex = await svc.currentDayIndex();
                      final claimed = <int>{};

                      // Get the actual claim history to determine claimed days
                      final history = await svc.history(limit: 7);
                      final dailyClaims =
                          history.where((e) => e['type'] == 'daily').toList();

                      // Sort daily claims by claimed_utc to ensure correct order
                      dailyClaims.sort(
                        (a, b) => (a['claimed_utc'] as int).compareTo(
                          b['claimed_utc'] as int,
                        ),
                      );

                      // Add claimed days based on actual history
                      for (int i = 0; i < dailyClaims.length; i++) {
                        claimed.add(i);
                      }
                      await showDailyRewardsDialog(
                        context,
                        currentDayIndex: currentDayIndex,
                        claimedDays: claimed,
                        onClaim: () async {
                          final n = await svc.claimDailyAndGrantHints();
                          if (n != null && mounted)
                            setState(() => _hintCount = n);
                          Navigator.of(context).pop();
                        },
                      );
                    },
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Image.asset('assets/images/idea_hint.png', height: 60),
                        Positioned(
                          right: -6,
                          top: -6,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Color(0xFFE53935),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '$_hintCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // DEBUG TOGGLE BUTTON (only in debug mode)
                if (kDebugMode)
                  Positioned(
                    right: 18,
                    top: 440,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _debugMode = !_debugMode;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade800,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'DEBUG',
                          style: TextStyle(color: Colors.white, fontSize: 8),
                        ),
                      ),
                    ),
                  ),

                // DEBUG TESTING CONTROLS (only in debug mode)
                if (kDebugMode && _debugMode)
                  Positioned(
                    right: 18,
                    top: 460,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Test Daily Rewards',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: List.generate(7, (dayIndex) {
                              return GestureDetector(
                                onTap: () async {
                                  final svc = DailyRewardService();
                                  await svc.debugShiftToDay(
                                    targetDay: dayIndex + 1,
                                  );
                                  setState(() {});
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade600,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'D${dayIndex + 1}U',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: List.generate(7, (dayIndex) {
                              return GestureDetector(
                                onTap: () async {
                                  final svc = DailyRewardService();
                                  await svc.debugTestScenario(
                                    dayIndex: dayIndex,
                                    isClaimed: true,
                                  );
                                  setState(() {});
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade600,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'D${dayIndex + 1}C',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                          const SizedBox(height: 4),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Shift to Day:',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 4,
                                runSpacing: 4,
                                children: List.generate(7, (dayIndex) {
                                  final dayNumber = dayIndex + 1;
                                  return GestureDetector(
                                    onTap: () async {
                                      final svc = DailyRewardService();
                                      await svc.debugShiftToDay(
                                        targetDay: dayNumber,
                                      );
                                      setState(() {});
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade600,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'Day $dayNumber',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                Align(
                  alignment: const Alignment(0, -0.05),
                  child: SizedBox(
                    height: 200,
                    width: 170,
                    child: GlowingWordWidgets(width: 140, height: 240),
                  ),
                ),

                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 92),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF253153),
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        minimumSize: const Size(280, 56),
                      ),
                      onPressed: () async {
                        await AudioService.instance.playClick();
                        final index =
                            await LevelProgressService.instance
                                .nextPlayableIndex();
                        if (!mounted) return;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) =>
                                    CrosswordPage(startLevelIndex: index),
                          ),
                        );
                      },
                      child: SizedBox(
                        width: 280,
                        height: 56,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Positioned(
                              left: 16,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.yellow[700],
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                child: const Text(
                                  'A',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ),
                            const Text(
                              'Play',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
