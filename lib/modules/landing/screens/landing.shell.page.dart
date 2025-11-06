

import 'package:crosswords/modules/landing/widgets/glowing_animation.widget.dart';
import 'package:crosswords/modules/crossword/widgets/daily.rewards.dialog.dart';
import 'package:crosswords/modules/landing/widgets/setting.widget.dart';
import 'package:flutter/material.dart';

import '../../../constant/sizedbox/sized_box.constants.dart';
import '../../crossword/screens/crossword.game.screen.dart';

class CrosswordLandingPage extends StatefulWidget {
  const CrosswordLandingPage({super.key});

  @override
  State<CrosswordLandingPage> createState() => _CrosswordLandingPageState();
}

class _CrosswordLandingPageState extends State<CrosswordLandingPage> {

  void onToggleSound() {}

  void onToggleMusic() {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.2),
            radius: 1.0,
            colors: [
              Color(0xFF100D49),
              Color(0xFF050318),
            ],
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
                                (context) => SettingCrosswordWidget(onToggleMusic: onToggleMusic, onToggleSound: onToggleSound)
                          );
                      },
                      child: Image.asset(
                        'assets/images/setting.png',
                        height: 60,
                      ),
                    ),
                    sboxH30,
                    Image.asset(
                      'assets/images/tasks.png',
                      height: 60,
                    ),
                  ],
                ),
              ),

              Positioned(
                right: 18,
                top: 170,
                child: GestureDetector(
                  onTap: () async {
                    await showDailyRewardsDialog(
                      context,
                      currentDayIndex: 0,
                      claimedDays: const {0},
                      onClaim: () {
                        Navigator.of(context).pop();
                      },
                    );
                  },
                  child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Image.asset(
                      'assets/images/idea_hint.png',
                      height: 60,
                    ),
                    Positioned(
                      right: -6,
                      top: -6,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Color(0xFFE53935),
                          shape: BoxShape.circle,
                        ),
                        child: const Text(
                          '3',
                          style: TextStyle(
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
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CrosswordPage()),
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
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
