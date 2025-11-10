import 'package:crosswords/services/audio/audio.service.dart';
import 'package:crosswords/modules/landing/widgets/glowing_animation.widget.dart';
import 'package:crosswords/modules/crossword/widgets/daily.rewards.dialog.dart';
import 'package:crosswords/modules/landing/widgets/setting.widget.dart';
import 'package:flutter/material.dart';
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
  void onToggleSound() {}
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
    return Scaffold(
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
                  padding: const EdgeInsets.only(top: 14),
                  child: SizedBox(
                    height: 120,
                    width: 280,
                    child: Stack(
                      children: [
                        Center(
                          child: Text(
                            'CROSSWORDS',
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                        Positioned(
                          right: 79,
                          top: 28,
                          child: Image.asset(
                            'assets/images/graduation_cap.png',
                            height: 38,
                          ),
                        ),
                        Positioned(
                          left: 36,
                          top: 72,
                          child: Transform.rotate(
                            angle: -0.25,
                            child: Image.asset(
                              'assets/images/only_sticker.png',
                              height: 28,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Column(
                            children: [
                              sboxH8,
                              const Text(
                                'for wordmasters',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              Positioned(
                left: 18,
                top: 170,
                child: Column(
                  children: [
                    InkWell(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder:
                              (context) => SettingCrosswordWidget(
                                onToggleMusic: onToggleMusic,
                                onToggleSound: onToggleSound,
                                isMusicMuted:
                                    !AudioService.instance.isMusicEnabled,
                                isSoundMuted: false,
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
                      onTap: (){
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const LevelSelectScreen()),
                        );
                      },
                        child: Image.asset('assets/images/tasks.png', height: 60)
                    ),
                  ],
                ),
              ),

              Positioned(
                right: 18,
                top: 170,
                child: GestureDetector(
                  onTap: () async {
                    final svc = DailyRewardService();
                    final streak = await svc.currentStreak();
                    final alreadyClaimed = await svc.isClaimedToday();
                    final base = streak % 7; // 0..6 index for current cycle
                    final claimed = <int>{};
                    if (alreadyClaimed) {
                      for (var i = 0; i <= base; i++) {
                        claimed.add(i);
                      }
                    } else {
                      for (var i = 0; i < base; i++) {
                        claimed.add(i);
                      }
                    }
                    await showDailyRewardsDialog(
                      context,
                      currentDayIndex: base,
                      claimedDays: claimed,
                      onClaim: () async {
                        final n = await svc.claimDailyAndGrantHints();
                        if (n != null && mounted) setState(() => _hintCount = n);
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
                      final index = await LevelProgressService.instance.nextPlayableIndex();
                      if (!mounted) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CrosswordPage(startLevelIndex: index),
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
    );
  }
}
