import 'package:flutter/material.dart';
import 'package:crosswords/modules/crossword/screens/crossword.game.screen.dart';
import 'package:crosswords/modules/crossword/services/level.progress.service.dart';

import '../data/crossword.level.data2.dart';

class LevelSelectScreen extends StatefulWidget {
  const LevelSelectScreen({super.key});

  @override
  State<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends State<LevelSelectScreen> {
  Set<String> _completed = {};
  Set<String> _skipped = {};
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final svc = LevelProgressService.instance;
    final completed = await svc.getCompleted();
    final skipped = await svc.getSkipped();
    final current = await svc.nextPlayableIndex();
    setState(() {
      _completed = completed;
      _skipped = skipped;
      _currentIndex = current;
    });
  }

  String _rankName(int completedCount) {
    if (completedCount >= allLevels.length) return 'Word Master';
    if (completedCount >= 15) return 'Word Sage';
    if (completedCount >= 10) return 'Lexicon Ace';
    if (completedCount >= 5) return 'Word Explorer';
    return 'Beginner';
  }

  @override
  Widget build(BuildContext context) {
    final completedCount = _completed.length;
    return Scaffold(
      backgroundColor: const Color(0xFF050318),
      appBar: AppBar(
        backgroundColor: const Color(0xFF050318),
        title: const Text('Puzzle Sets', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -0.2),
              radius: 1.0,
              colors: [Color(0xFF100D49), Color(0xFF050318)],
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.only(top: 8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 1,
                  ),
                  itemCount: allLevels.length,
                  itemBuilder: (context, index) {
                    final level = allLevels[index];
                    final id = level.id;
                    final isCompleted = _completed.contains(id);
                    final isCurrent = index == _currentIndex;
                    final isUnlocked = index <= _currentIndex || isCompleted;
                    final isSkipped = _skipped.contains(id);

                    Color bg;
                    if (isCompleted) {
                      bg = Colors.lightGreenAccent.shade700;
                    } else if (isSkipped) {
                      bg = Colors.red.shade300;
                    } else if (isCurrent) {
                      bg = Colors.lightBlue.shade300;
                    } else {
                      bg = Colors.green.shade300;
                    }
                    return GestureDetector(
                      onTap: !isUnlocked
                          ? null
                          : () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CrosswordPage(startLevelIndex: index),
                                ),
                              );
                              await _load();
                            },
                      child: Stack(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            decoration: BoxDecoration(
                              color: isUnlocked ? bg : Colors.grey.shade600,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: isUnlocked ? Colors.black : Colors.black54,
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          if (!isUnlocked)
                            const Positioned(
                              bottom: 4,
                              right: 4,
                              child: Icon(Icons.lock, size: 14, color: Colors.black87),
                            ),
                          if (isSkipped)
                            const Positioned(
                              top: 4,
                              right: 4,
                              child: Icon(Icons.flag, size: 14, color: Colors.redAccent),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Text('Rank: ${_rankName(completedCount)}', style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 6),
              Text('Skipped: ${_skipped.length}', style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 6),
              Text('Completed: $completedCount/${allLevels.length}', style: const TextStyle(color: Colors.white70)),
            ],
          ),
        ),
      ),
    );
  }
}
