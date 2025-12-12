import 'package:flutter/material.dart';
import 'package:crosswords/services/audio/audio.service.dart';

Future<void> showDailyRewardsDialog(
  BuildContext context, {
  required int currentDayIndex,
  required Set<int> claimedDays,
  required bool isTodayClaimed,
  required VoidCallback onClaim,
}) {
  return showDialog(
    context: context,
    barrierDismissible: true,
    builder:
        (_) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          child: DailyRewardsDialog(
            currentDayIndex: currentDayIndex,
            claimedDays: claimedDays,
            onClaim: onClaim,
            isTodayClaimed: isTodayClaimed,
          ),
        ),
  );
}

class DailyRewardsDialog extends StatelessWidget {
  final int currentDayIndex;
  final Set<int> claimedDays;
  final bool isTodayClaimed;
  final VoidCallback onClaim;

  const DailyRewardsDialog({
    super.key,
    required this.currentDayIndex,
    required this.claimedDays,
    required this.isTodayClaimed,
    required this.onClaim,
  });

  @override
  Widget build(BuildContext context) {
    final alreadyClaimedToday = isTodayClaimed;
    final canClaim = !alreadyClaimedToday;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1D1B3A),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.45),
                blurRadius: 20,
                spreadRadius: 2,
                offset: const Offset(0, 10),
              ),
            ],
            border: Border.all(color: const Color(0xFF5AC8FA), width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 10),
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF69D2FF), Color(0xFF2BA2FF)],
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 6),
                    Text(
                      'Play everyday and get rewards',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.black.withOpacity(0.95),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  runSpacing: 12,
                  spacing: 12,
                  children: List.generate(7, (i) {
                    final day = i + 1;
                    final isActive = i == currentDayIndex;
                    final isClaimed = claimedDays.contains(i);
                    final isMissed = i < currentDayIndex && !isClaimed;
                    final rewardMultiplier =
                        i == 0
                            ? 'x1'
                            : i == 1
                            ? 'x2'
                            : i == 2
                            ? 'x3'
                            : i == 3
                            ? 'x4'
                            : i == 4
                            ? 'x5'
                            : i == 5
                            ? 'x6'
                            : 'x7';
                    return DayRewardTile(
                      dayLabel: 'Day $day',
                      rewardLabel: rewardMultiplier,
                      isActive: isActive,
                      isClaimed: isClaimed,
                      isMissed: isMissed,
                    );
                  }),
                ),
              ),
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      await AudioService.instance.playClick();
                      if (alreadyClaimedToday) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Already claimed. Come back tomorrow!',
                            ),
                          ),
                        );
                        return Navigator.of(context).pop();
                      }
                      onClaim();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD166),
                      foregroundColor: const Color(0xFF3B2F00),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        letterSpacing: 0.3,
                      ),
                    ),
                    child: const Text('Claim'),
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: -26,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              width: 130,
              height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF69D2FF), Color(0xFF2BA2FF)],
                ),
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 6),
                  ),
                ],
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Daily Rewards',
                      maxLines: 1,
                      overflow: TextOverflow.visible,
                      softWrap: false,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class DayRewardTile extends StatelessWidget {
  final String dayLabel;
  final String rewardLabel;
  final bool isActive;
  final bool isClaimed;
  final bool isMissed;

  const DayRewardTile({
    super.key,
    required this.dayLabel,
    required this.rewardLabel,
    required this.isActive,
    required this.isClaimed,
    this.isMissed = false,
  });

  @override
  Widget build(BuildContext context) {
    final baseColor =
        isActive ? const Color(0xFF3C8CE7) : const Color(0xFF3F3A60);
    final topGrad =
        isActive ? const Color(0xFF80D0C7) : const Color(0xFF5A5580);
    final bg = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [topGrad, baseColor],
    );

    return Container(
      width: 92,
      height: 88,
      decoration: BoxDecoration(
        gradient: bg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isActive ? const Color(0xFFB3F1FF) : Colors.white24,
          width: isActive ? 2 : 1,
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.06,
              child: Icon(Icons.emoji_events, size: 100, color: Colors.white),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                dayLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.22),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white24, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.lightbulb,
                      color: Colors.amber.shade300,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      rewardLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (isClaimed)
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.greenAccent.shade400,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(2),
                child: const Icon(Icons.check, size: 16, color: Colors.black),
              ),
            ),
          if (isMissed && !isClaimed)
            Positioned(
              right: 6,
              top: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.redAccent.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Missed',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
