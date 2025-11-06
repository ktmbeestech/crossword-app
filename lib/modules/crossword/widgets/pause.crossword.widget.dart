import 'package:flutter/material.dart';

import 'circle.icon.widget.dart';

class PauseCrosswordWidget extends StatelessWidget {
  final VoidCallback onHome;
  final VoidCallback onResume;
  final VoidCallback onToggleMusic;
  final VoidCallback onToggleSound;
  final bool isMusicMuted;
  final bool isSoundMuted;

  const PauseCrosswordWidget({
    super.key,
    required this.onHome,
    required this.onResume,
    required this.onToggleMusic,
    required this.onToggleSound,
    this.isMusicMuted = false,
    this.isSoundMuted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          // Main card
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF7ED957), // light-green card
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icons row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    circleIcon(
                      context,
                      icon: AssetImage("assets/images/home_icon.png"),
                      onTap: onHome,
                    ),
                    circleIcon(
                      context,
                      icon: AssetImage( isMusicMuted? "assets/images/music_off_icon.png" : "assets/images/music_on_icon.png"),
                      onTap: onToggleMusic,
                    ),
                    circleIcon(
                      context,
                      icon: AssetImage(isSoundMuted ? "assets/images/sound_off_icon.png" : "assets/images/sound_on_icon.png"),
                      onTap: onToggleSound,
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Back button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF253153),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      onResume();
                      Navigator.of(context).maybePop();
                    },
                    child: const Text(
                      'Back',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Ribbon-like title
          Positioned(
            top: -22,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF78C850),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Text(
                'Paused',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

}
