import 'package:crosswords/constant/sizedbox/sized_box.constants.dart';
import 'package:crosswords/modules/crossword/data/crossword.level.data2.dart';
import 'package:crosswords/modules/crossword/widgets/pause.crossword.widget.dart';
import 'package:crosswords/modules/landing/screens/landing.shell.page.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:crosswords/services/audio/audio.service.dart';
import 'package:crosswords/modules/crossword/services/level.progress.service.dart';
import 'package:crosswords/modules/landing/services/hint.service.dart';
import 'package:crosswords/modules/landing/services/daily_reward.service.dart';

import '../models/crossword.data.model.dart';
import '../services/crossword.grid.generator.dart';
import '../widgets/crossword.widgets.dart';
import '../widgets/custom.keyboard.widget.dart';

class CrosswordPage extends StatefulWidget {
  final int startLevelIndex;
  const CrosswordPage({super.key, this.startLevelIndex = 0});

  @override
  State<CrosswordPage> createState() => _CrosswordPageState();
}

class _CrosswordPageState extends State<CrosswordPage> {
  // --- Game State ---

  late CrosswordLevel currentLevel;
  late CrosswordGrid gridData;
  late Clue? activeClue;
  late Set<int> highlightedCellIndices;
  int? selectedCellIndex;
  final Map<int, String> _userInput = {}; // Stores user's letters
  final Set<int> _incorrectCells = {}; // Tracks cells with incorrect letters

  // --- Level & Timer State ---
  int _levelIndex = 0;
  int _hintsRemaining = 3;
  int _seconds = 0;
  bool _isPaused = false;
  Timer? _timer;
  bool _isInputSheetOpen = false;

  // --- Initialization ---

  @override
  void initState() {
    super.initState();
    // Initialize from provided start index or saved progress
    _levelIndex = widget.startLevelIndex;
    _levelIndex = _levelIndex.clamp(0, allLevels.length - 1);
    _loadLevel(allLevels[_levelIndex]);
    _startTimer();
    // Ensure audio service is initialized if entering directly
    AudioService.instance.initialize();
    _loadHintCount();
  }

  Future<void> _loadHintCount() async {
    final n = await HintService.instance.getCount();
    if (!mounted) return;
    setState(() => _hintsRemaining = n);
  }

  void _loadLevel(CrosswordLevel level) {
    setState(() {
      currentLevel = level;
      gridData = CrosswordGenerator.generateGrid(level);

      // Reset state
      activeClue = null;
      selectedCellIndex = null;
      highlightedCellIndices = {};
      _userInput.clear();
      _incorrectCells.clear();
      // do not reset hints here; they are global and persisted via HintService
      _resetTimer();

      // Automatically select the first clue
      if (currentLevel.clues.isNotEmpty) {
        _setActiveClue(currentLevel.clues.first);
      }
    });
  }

  // --- Game Logic ---

  void _setActiveClue(Clue clue) {
    setState(() {
      // CRITICAL FIX 1: Guard against self-recursion.
      if (activeClue?.id == clue.id) return;

      activeClue = clue;
      highlightedCellIndices = {};

      int r = clue.startRow;
      int c = clue.startCol;

      for (int i = 0; i < clue.answer.length; i++) {
        final index = (r * gridData.cols) + c;
        highlightedCellIndices.add(index);

        if (clue.direction == Direction.across) {
          c++;
        } else {
          r++;
        }
      }

      // Select the first cell of the new clue
      _setSelectedCell((clue.startRow * gridData.cols) + clue.startCol);
    });
  }

  Future<void> _openInputSheet() async {
    if (_isInputSheetOpen) return;
    setState(() {
      _isInputSheetOpen = true;
    });
    await showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1B45),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.35,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CurrentClueWidget(clue: activeClue),
                  const SizedBox(height: 8),
                  Flexible(
                    child: CustomKeyboard(onKeyPress: _handleKeyPress),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    if (mounted) {
      setState(() {
        _isInputSheetOpen = false;
      });
    }
  }

  // Returns the ordered list of cell indices for a clue from start to end.
  List<int> _cellsForClue(Clue clue) {
    final indices = <int>[];
    int r = clue.startRow;
    int c = clue.startCol;
    for (int i = 0; i < clue.answer.length; i++) {
      indices.add((r * gridData.cols) + c);
      if (clue.direction == Direction.across) {
        c++;
      } else {
        r++;
      }
    }
    return indices;
  }

  void _setSelectedCell(int index, {bool fromUserTap = false}) {
    setState(() {
      
      if (selectedCellIndex == index) {
        return;
      }

      selectedCellIndex = index;
      final cell = gridData.grid[index];

      // Logic to set/change the active clue when a cell is tapped
      if (cell.clueIds.isNotEmpty) {
        
        String targetClueId = activeClue?.id ?? '';
        if (fromUserTap &&
            activeClue != null &&
            cell.clueIds.length > 1 &&
            cell.clueIds.contains(activeClue!.id)) {
         
          targetClueId = cell.clueIds.firstWhere(
            (id) => id != activeClue!.id,
            orElse: () => activeClue!.id,
          );
        } else if (activeClue == null ||
            !cell.clueIds.contains(activeClue!.id)) {
          targetClueId = cell.clueIds.first;
        }

        if (targetClueId.isNotEmpty) {
          final newClue = currentLevel.clues.firstWhere(
            (c) => c.id == targetClueId,
          );
          if (activeClue?.id != newClue.id) {
            _setActiveClue(newClue);
          }
        }
      } else {
        
        activeClue = null;
        highlightedCellIndices = {};
      }
    });
  }

  /// Handles input from the keyboard widget.
  void _handleKeyPress(String key) {
    if (_isPaused || selectedCellIndex == null) return;

    setState(() {
      if (key == 'DEL') {
        _handleDelete();
      } else {
        
        final idx = selectedCellIndex!;
        final expected = gridData.grid[idx].correctLetter?.toUpperCase();
        final value = key.toUpperCase();
        _userInput[idx] = value;
        if (expected != null && value == expected) {
          _incorrectCells.remove(idx);
          _autoAdvanceCursor();
        } else {
          
          _incorrectCells.add(idx);
        }
      }
    });
    _checkForCompletion();
  }

  /// Logic to delete the current letter and move the cursor back.
  void _handleDelete() {
    if (selectedCellIndex == null) return;

  
    _userInput.remove(selectedCellIndex);
    _incorrectCells.remove(selectedCellIndex);

    final clueCells =
        activeClue == null ? const <int>[] : _cellsForClue(activeClue!);
    final currentIndexInClue = clueCells.indexOf(selectedCellIndex!);

   
    if (currentIndexInClue > 0) {
      final prevCellIndex = clueCells[currentIndexInClue - 1];
      
      _setSelectedCell(prevCellIndex);
    }
    
  }

  /// Logic to automatically advance the cursor to the next cell in the active clue.
  void _autoAdvanceCursor() {
    if (activeClue == null || selectedCellIndex == null) return;

    
    final clueCells = _cellsForClue(activeClue!);

    
    final currentIndexInClue = clueCells.indexOf(selectedCellIndex!);

    
    if (currentIndexInClue < clueCells.length - 1) {
      final nextCellIndex = clueCells[currentIndexInClue + 1];
      
      _setSelectedCell(nextCellIndex, fromUserTap: false);
    } else {
      
      print('Word ${activeClue!.answer} is complete.');
      if (_isInputSheetOpen) {
        // Close the keyboard/input sheet when a word completes
        Navigator.of(context).maybePop();
        if (mounted) {
          setState(() {
            _isInputSheetOpen = false;
          });
        }
      }
    }
  }

  // --- Timer Logic ---
  void _startTimer() {
    _timer?.cancel();
    _isPaused = false;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_isPaused) return;
      setState(() {
        _seconds += 1;
      });
    });
  }

  void _resetTimer() {
    _seconds = 0;
    _isPaused = false;
    _startTimer();
  }

  void _pauseTimer() {
    setState(() {
      _isPaused = true;
    });
  }

  void _resumeTimer() {
    setState(() {
      _isPaused = false;
    });
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // --- Hints & Clues ---
  void _useHint() {
    if (_hintsRemaining <= 0 || activeClue == null) return;
    // find first incorrect or empty cell in current clue
    final cells = _cellsForClue(activeClue!);
    for (final idx in cells) {
      final correct = gridData.grid[idx].correctLetter?.toUpperCase();
      final current = _userInput[idx];
      if (current != correct) {
        setState(() {
          _userInput[idx] = correct ?? '';
          selectedCellIndex = idx;
          _hintsRemaining = (_hintsRemaining - 1).clamp(0, 1 << 30);
          _incorrectCells.remove(idx);
        });
        // persist consumption
        HintService.instance.consume(1).then((n) {
          if (mounted) {
            setState(() => _hintsRemaining = n);
          }
        });
        _autoAdvanceCursor();
        _checkForCompletion();
        return;
      }
    }
  }

  void _showCluesSheet() {
    showDialog(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Material(
            color: Colors.transparent,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 420,
                ),
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF0D0B2E), Color(0xFF0F0B4A)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                    border: Border.all(color: Colors.white24, width: 1),
                  ),
                  child: Builder(
                    builder: (context) {
                      final across = currentLevel.clues
                          .where((c) => c.direction == Direction.across)
                          .toList();
                      final down = currentLevel.clues
                          .where((c) => c.direction == Direction.down)
                          .toList();

                      TextStyle headerStyle = const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      );
                      TextStyle clueStyle = const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      );

                      Widget buildSection(String title, List<Clue> items) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title, style: headerStyle),
                            const SizedBox(height: 8),
                            ...items.map((clue) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(8),
                                  onTap: () {
                                    Navigator.pop(context);
                                    _setActiveClue(clue);
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 4, horizontal: 4),
                                    child: Text(
                                      '${clue.number}. ${clue.clue}',
                                      style: clueStyle,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ],
                        );
                      }

                      return SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            buildSection('Across', across),
                            const SizedBox(height: 14),
                            buildSection('Down', down),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // --- Completion & Level progression ---
  void _checkForCompletion() {
    for (int i = 0; i < gridData.grid.length; i++) {
      final cell = gridData.grid[i];
      if (cell.isBlocked) continue;
      if ((_userInput[i] ?? '').toUpperCase() !=
          (cell.correctLetter ?? '').toUpperCase()) {
        return; // not complete
      }
    }
    _pauseTimer();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF253153),
          title: const Text(
            'Level Complete',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            'Time: ${_formatTime(_seconds)}',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                // Save progress
                await LevelProgressService.instance
                    .markCompleted(currentLevel.id);
                // Grant one-time completion bonus (5 hints)
                final bonus = await DailyRewardService()
                    .grantLevelCompletionBonus(currentLevel.id, amount: 5);
                if (bonus != null && mounted) {
                  setState(() => _hintsRemaining = bonus);
                }
                // Move current index forward if we just finished the current gate
                final nextIndex = (_levelIndex + 1).clamp(0, allLevels.length - 1);
                await LevelProgressService.instance.setCurrentIndex(nextIndex);
                _nextLevel();
              },
              child: const Text('Next', style: TextStyle(color: Colors.yellow)),
            ),
          ],
        );
      },
    );
  }

  void _nextLevel() {
    setState(() {
      _levelIndex = (_levelIndex + 1) % allLevels.length;
    });
    _loadLevel(allLevels[_levelIndex]);
    _resumeTimer();
  }

  void _skipLevel() {
    // Mark skipped and advance, also update current index
    LevelProgressService.instance.markSkipped(currentLevel.id);
    LevelProgressService.instance
        .setCurrentIndex((_levelIndex + 1).clamp(0, allLevels.length - 1));
    _nextLevel();
  }

  void onHome() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CrosswordLandingPage()),
    );
  }

  void onResume() {
    _resumeTimer();
  }

  void onToggleSound() {}

  void onToggleMusic() async {
    await AudioService.instance.toggleMusic();
    if (mounted) setState(() {});
  }
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050318),
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -0.2),
              radius: 1.0,
              colors: [Color(0xFF100D49), Color(0xFF050318)],
            ),
          ),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // --- Header: Skip, Level, Timer, Clues ---
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0, top: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Skip Level button
                    TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFF253153),
                        foregroundColor: Colors.yellow,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _skipLevel,
                      child: const Text(
                        'Skip Level',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    // Pause/Resume button

                    // Level and Timer center
                    Column(
                      children: [
                        Text(
                          'Level ${_levelIndex + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatTime(_seconds),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    // Clues/Hints button with bulb and counter
                    TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFF253153),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _showCluesSheet,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Clues',
                            style: TextStyle(
                              color: Colors.greenAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          sboxW8,
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: () {
                      _pauseTimer();
                      showDialog(
                        context: context,
                        builder:
                            (context) => PauseCrosswordWidget(
                              onHome: onHome,
                              onResume: onResume,
                              onToggleMusic: onToggleMusic,
                              onToggleSound: onToggleSound,
                              isMusicMuted: !AudioService.instance.isMusicEnabled,
                              isSoundMuted: false,
                            ),
                      );
                    },
                    child: Image.asset(
                      'assets/images/pause_button.png',
                      height: 48,
                    ),
                  ),

                  SizedBox(
                    width: 48,
                    height: 48,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned.fill(
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: Image.asset('assets/images/idea_hint.png'),
                            onPressed: _useHint,
                            tooltip: 'Use hint',
                          ),
                        ),
                        Positioned(
                          right: -6,
                          top: -6,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Color(0xFFE53935),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '$_hintsRemaining',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              sboxH8,

              // --- 1. The Crossword Grid (expanded) ---
              Expanded(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom:
                          _isInputSheetOpen
                              ? (MediaQuery.of(context).size.height * 0.36)
                              : 0,
                    ),
                    child: AspectRatio(
                      aspectRatio: 1.0,
                      child: GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: gridData.cols,
                          crossAxisSpacing: 2,
                          mainAxisSpacing: 2,
                        ),
                        itemCount: gridData.rows * gridData.cols,
                        itemBuilder: (context, index) {
                          final cellData = gridData.grid[index];

                          if (cellData.isBlocked) {
                            return Container(color: Colors.transparent);
                          }

                          return CellWidget(
                            letter: _userInput[index] ?? '',
                            clueNumber: cellData.clueNumber,
                            isSelected: index == selectedCellIndex,
                            isHighlighted: highlightedCellIndices.contains(
                              index,
                            ),
                            isIncorrect: _incorrectCells.contains(index),
                            onTap: () {
                              _setSelectedCell(index, fromUserTap: true);
                              _openInputSheet();
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ),

                // // --- 3. Clue List (Simplified) ---
                // Container(
                //   height: 100,
                //   padding: const EdgeInsets.symmetric(vertical: 16),
                //   child: ListView(
                //     scrollDirection: Axis.horizontal,
                //     children: currentLevel.clues.map((clue) {
                //       return Padding(
                //         padding: const EdgeInsets.only(right: 8.0),
                //         child: ActionChip(
                //           label: Text('${clue.number}. ${clue.direction.name}'),
                //           backgroundColor: activeClue?.id == clue.id ? Colors.blueAccent : Colors.grey[700],
                //           onPressed: () {
                //             _setActiveClue(clue);
                //           },
                //         ),
                //       );
                //     }).toList(),
                //   ),
                // ),

                // --- 4. The Custom Keyboard ---
                // Moved to Scaffold.bottomNavigationBar to pin at bottom
              ),
            ],
          ),
        ),
      ),
    );
  }
}
