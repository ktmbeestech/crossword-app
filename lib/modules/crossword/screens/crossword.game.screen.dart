import 'package:crosswords/constant/sizedbox/sized_box.constants.dart';
import 'package:crosswords/modules/crossword/data/crossword.level.data2.dart';
import 'package:crosswords/modules/crossword/widgets/pause.crossword.widget.dart';
import 'package:crosswords/modules/landing/screens/landing.shell.page.dart';
import 'level.select.screen.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:crosswords/services/audio/audio.service.dart';
import 'package:crosswords/modules/crossword/services/level.progress.service.dart';
import 'package:crosswords/modules/landing/services/hint.service.dart';
import 'package:crosswords/modules/landing/services/daily_reward.service.dart';
import 'package:crosswords/services/analytics/analytics.service.dart';
import 'package:crosswords/services/local_storage/local_storage.services.dart';

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
  CrosswordGrid? gridData;
  late Clue? activeClue;
  late Set<int> highlightedCellIndices;
  int? selectedCellIndex;
  final Map<int, String> _userInput = {}; // Stores user's letters
  final Set<int> _incorrectCells = {}; // Tracks cells with incorrect letters
  bool _isGenerating = false; // Show overlay while generating grid
  final Set<int> _pulsingCells = {};

  // --- Level & Timer State ---
  int _levelIndex = 0;
  int _hintsRemaining = 3;
  int _seconds = 0;
  bool _isPaused = false;
  Timer? _timer;
  bool _isInputSheetOpen = false;
  int _autosaveTick = 0; // seconds since last autosave

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

  /// Toggle the active clue direction (across/down) for the current selected cell,
  /// if that cell belongs to multiple clues.
  void _toggleClueDirection() {
    if (selectedCellIndex == null) return;
    final cell = gridData!.grid[selectedCellIndex!];
    if (cell.clueIds.length < 2) return;

    if (activeClue == null) {
      final id = cell.clueIds.first;
      final newClue = currentLevel.clues.firstWhere((c) => c.id == id);
      _setActiveClue(newClue);
      return;
    }

    final otherId = cell.clueIds.firstWhere(
      (id) => id != activeClue!.id,
      orElse: () => activeClue!.id,
    );
    if (otherId != activeClue!.id) {
      final newClue = currentLevel.clues.firstWhere((c) => c.id == otherId,
          orElse: () => activeClue!);
      if (newClue.id != activeClue!.id) {
        _setActiveClue(newClue);
        // If input sheet is open, refresh it so header reflects new clue
        if (_isInputSheetOpen) {
          Navigator.of(context).pop();
          Future.delayed(const Duration(milliseconds: 20), () {
            if (mounted) _openInputSheet();
          });
        }
      }
    }
  }

  Future<void> _loadHintCount() async {
    final n = await HintService.instance.getCount();
    if (!mounted) return;
    setState(() => _hintsRemaining = n);
  }

  Future<void> _loadLevel(CrosswordLevel level) async {
    setState(() {
      _isGenerating = true;
    });

    // Small delay so the overlay is visible before heavy work
    await Future.delayed(const Duration(milliseconds: 50));

    // Generate grid synchronously
    final generated = CrosswordGenerator.generateGrid(level);

    setState(() {
      currentLevel = level;
      gridData = generated;

      // Reset state
      activeClue = null;
      selectedCellIndex = null;
      highlightedCellIndices = {};
      _userInput.clear();
      _incorrectCells.clear();
      // do not reset hints here; they are global and persisted via HintService

      // Automatically select the first clue
      if (level.clues.isNotEmpty) {
        _setActiveClue(level.clues.first);
      }
    });

    // Restore any saved progress for this level (time and letters)
    await _restoreProgress(level.id);
    _startTimer();

    // Analytics: reached level
    try {
      await AnalyticsService.instance.trackReachedLevel(level.id);
    } catch (_) {}

    // Keep overlay briefly to feel responsive
    await Future.delayed(const Duration(milliseconds: 200));
    if (mounted) {
      setState(() => _isGenerating = false);
    }
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
        final index = (r * gridData!.cols) + c;
        highlightedCellIndices.add(index);

        if (clue.direction == Direction.across) {
          c++;
        } else {
          r++;
        }
      }

      // Select first not-correct cell of the clue (skip already-correct intersections)
      final cells = _cellsForClue(clue);
      int target = cells.first;
      for (final idx in cells) {
        final correct = (gridData!.grid[idx].correctLetter ?? '').toUpperCase();
        final current = (_userInput[idx] ?? '').toUpperCase();
        if (current != correct) {
          target = idx;
          break;
        }
      }
      _setSelectedCell(target);
    });

    final cells = _cellsForClue(clue);
    for (int i = 0; i < cells.length; i++) {
      final idx = cells[i];
      Future.delayed(Duration(milliseconds: 120 * i), () {
        if (!mounted) return;
        setState(() {
          _pulsingCells.add(idx);
        });
        Future.delayed(const Duration(milliseconds: 320), () {
          if (!mounted) return;
          setState(() {
            _pulsingCells.remove(idx);
          });
        });
      });
    }
  }

  Future<void> _openInputSheet() async {
    // Removed
  }

  // Returns the ordered list of cell indices for a clue from start to end.
  List<int> _cellsForClue(Clue clue) {
    final indices = <int>[];
    int r = clue.startRow;
    int c = clue.startCol;
    for (int i = 0; i < clue.answer.length; i++) {
      indices.add((r * gridData!.cols) + c);
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
      final cell = gridData!.grid[index];

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

    // Briefly pulse the newly selected cell so it visibly enlarges
    if (mounted) {
      setState(() {
        _pulsingCells.add(index);
      });
      Future.delayed(const Duration(milliseconds: 320), () {
        if (!mounted) return;
        setState(() {
          _pulsingCells.remove(index);
        });
      });
    }
  }

  /// Handles input from the keyboard widget.
  void _handleKeyPress(String key) {
    if (_isPaused || selectedCellIndex == null) return;

    setState(() {
      if (key == 'DEL') {
        _handleDelete();
      } else {
        
        final idx = selectedCellIndex!;
        final expected = gridData!.grid[idx].correctLetter?.toUpperCase();
        final value = key.toUpperCase();
        _userInput[idx] = value;
        if (expected != null && value == expected) {
          _incorrectCells.remove(idx);
          _autoAdvanceCursor();
        } else {
          
          _incorrectCells.add(idx);
          // Play mistake sound on wrong input
          AudioService.instance.playMistake();
        }
      }
    });
    _saveProgress();
    _checkForCompletion();
  }

  /// Logic to delete the current letter and move the cursor back.
  void _handleDelete() {
    if (selectedCellIndex == null) return;

  
    _userInput.remove(selectedCellIndex);
    _incorrectCells.remove(selectedCellIndex);

    final clueCells = activeClue == null ? const <int>[] : _cellsForClue(activeClue!);
    final currentIndexInClue = clueCells.indexOf(selectedCellIndex!);

   
    if (currentIndexInClue > 0) {
      final prevCellIndex = clueCells[currentIndexInClue - 1];
      
      _setSelectedCell(prevCellIndex);
    }
    
    _saveProgress();
  }

  // --- Persistence: save/load progress per level ---
  Future<void> _saveProgress() async {
    if (gridData == null) return;
    final id = currentLevel.id;
    final inputMap = <String, String>{};
    _userInput.forEach((k, v) {
      if ((v).isNotEmpty) inputMap[k.toString()] = v;
    });
    final payload = jsonEncode(inputMap);
    await storageInstance.setData(key: 'cw_${id}_seconds', value: _seconds.toString());
    await storageInstance.setData(key: 'cw_${id}_input', value: payload);
  }

  Future<void> _restoreProgress(String levelId) async {
    final secStr = await storageInstance.getData(key: 'cw_${levelId}_seconds');
    final inputStr = await storageInstance.getData(key: 'cw_${levelId}_input');
    int restoredSec = int.tryParse(secStr ?? '') ?? 0;
    Map<int, String> restoredInput = {};
    if ((inputStr ?? '').isNotEmpty) {
      try {
        final decoded = jsonDecode(inputStr!) as Map<String, dynamic>;
        decoded.forEach((k, v) {
          final idx = int.tryParse(k);
          if (idx != null && idx >= 0 && idx < (gridData!.grid.length)) {
            final s = (v as String?) ?? '';
            if (s.isNotEmpty) restoredInput[idx] = s;
          }
        });
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() {
      _seconds = restoredSec.clamp(0, 1 << 30);
      _userInput.addAll(restoredInput);
      // Recompute incorrect cells based on restored input
      _incorrectCells.clear();
      for (final e in _userInput.entries) {
        final correct = (gridData!.grid[e.key].correctLetter ?? '').toUpperCase();
        final current = (e.value).toUpperCase();
        if (current.isNotEmpty && current != correct) {
          _incorrectCells.add(e.key);
        }
      }
    });
  }

  /// Logic to automatically advance the cursor to the next cell in the active clue.
  void _autoAdvanceCursor() {
    if (activeClue == null || selectedCellIndex == null) return;

    final clueCells = _cellsForClue(activeClue!);
    final currentIndexInClue = clueCells.indexOf(selectedCellIndex!);
    // Find next not-correct cell within this clue
    int? nextIdx;
    for (int i = currentIndexInClue + 1; i < clueCells.length; i++) {
      final idx = clueCells[i];
      final correct = (gridData!.grid[idx].correctLetter ?? '').toUpperCase();
      final current = (_userInput[idx] ?? '').toUpperCase();
      if (current != correct) {
        nextIdx = idx;
        break;
      }
    }

    if (nextIdx != null) {
      _setSelectedCell(nextIdx, fromUserTap: false);
    } else {
      
      print('Word ${activeClue!.answer} is complete.');
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
        _autosaveTick += 1;
      });
      if (_autosaveTick >= 5) {
        _autosaveTick = 0;
        _saveProgress();
      }
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
      final correct = gridData!.grid[idx].correctLetter?.toUpperCase();
      final current = _userInput[idx];
      if (current != correct) {
        setState(() {
          _userInput[idx] = correct ?? '';
          selectedCellIndex = idx;
          _hintsRemaining = (_hintsRemaining - 1).clamp(0, 1 << 30);
          _incorrectCells.remove(idx);
        });
        // Play idea sound on successful hint use
        AudioService.instance.playIdea();
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
      barrierColor: Colors.transparent,
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
                                  onTap: () async {
                                    await AudioService.instance.playClick();
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
    for (int i = 0; i < gridData!.grid.length; i++) {
      final cell = gridData!.grid[i];
      if (cell.isBlocked) continue;
      if ((_userInput[i] ?? '').toUpperCase() !=
          (cell.correctLetter ?? '').toUpperCase()) {
        return; // not complete
      }
    }
    _pauseTimer();

    // Analytics: level completed
    try {
      AnalyticsService.instance.trackLevelCompleted(currentLevel.id, timeSeconds: _seconds, mistakes: _incorrectCells.length);
    } catch (_) {}

    // Dismiss any open overlays (keyboard bottom sheet, clue dialog)
    // Pop any remaining dialogs to ensure a clean completion dialog
    Navigator.of(context).popUntil((route) => route is PageRoute);
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
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Time: ${_formatTime(_seconds)}',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 8),
              const Text(
                'Reward: 5 hints',
                style: TextStyle(color: Colors.yellowAccent, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await AudioService.instance.playClick();
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
      _levelIndex = (
        _levelIndex + 1
      ) % allLevels.length;
    });
    _loadLevel(allLevels[_levelIndex]);
    _resumeTimer();
  }

  void _skipLevel() {
    // If last level, prompt to go to Levels page instead of wrapping
    if (_levelIndex >= allLevels.length - 1) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF253153),
          title: const Text('End of Levels', style: TextStyle(color: Colors.white)),
          content: const Text(
            'You\'ve reached the end of available levels. Go to the Level Select page?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await AudioService.instance.playClick();
                Navigator.of(context).pop();
              },
              child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
            ),
            TextButton(
              onPressed: () async {
                await AudioService.instance.playClick();
                Navigator.of(context).pop();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LevelSelectScreen()),
                );
              },
              child: const Text('Go to Levels', style: TextStyle(color: Colors.yellow)),
            ),
          ],
        ),
      );
      return;
    }

    // Analytics: level skipped
    try {
      AnalyticsService.instance.trackLevelSkipped(currentLevel.id);
    } catch (_) {}

    // Mark skipped and advance to next level, also update current index
    LevelProgressService.instance.markSkipped(currentLevel.id);
    LevelProgressService.instance
        .setCurrentIndex((_levelIndex + 1).clamp(0, allLevels.length - 1));
    _nextLevel();
  }

  void onHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => CrosswordLandingPage()),
    );
  }

  void onResume() {
    _resumeTimer();
  }

  void onToggleSound() async {
    await AudioService.instance.toggleSfx();
    if (mounted) setState(() {});
  }

  void onToggleMusic() async {
    await AudioService.instance.toggleMusic();
    if (mounted) setState(() {});
  }
  @override
  void dispose() {
    _timer?.cancel();
    _saveProgress();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
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
                isSoundMuted: !AudioService.instance.isSfxEnabled,
              ),
        );
        return false; // prevent popping the page
      },
      child: Scaffold(
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
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
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
                        onPressed: () async {
                          await AudioService.instance.playClick();
                          _skipLevel();
                        },
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
                        onPressed: () async {
                          await AudioService.instance.playClick();
                          _showCluesSheet();
                        },
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
                    onTap: () async {
                      await AudioService.instance.playClick();
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
                              isSoundMuted: !AudioService.instance.isSfxEnabled,
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
                            onPressed: () async {
                              await AudioService.instance.playClick();
                              _useHint();
                            },
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
                child: Stack(
                  children: [
                    Center(
                      child: AspectRatio(
                        aspectRatio: 1.0,
                        child: gridData == null
                            ? const Center(
                                child: CircularProgressIndicator(),
                              )
                            : GridView.builder(
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: gridData!.cols,
                                  crossAxisSpacing: 4,
                                  mainAxisSpacing: 4,
                                ),
                                itemCount: gridData!.rows * gridData!.cols,
                                itemBuilder: (context, index) {
                                  final cellData = gridData!.grid[index];

                                  if (cellData.isBlocked) {
                                    return Container(color: Colors.transparent);
                                  }

                                  final correct =
                                      (cellData.correctLetter ?? '').toUpperCase();
                                  final current =
                                      (_userInput[index] ?? '').toUpperCase();
                                  final showCorner =
                                      ((cellData.clueIds.length >= 2) ||
                                              (cellData.clueNumber != null)) &&
                                          current != correct;

                                  return CellWidget(
                                    letter: _userInput[index] ?? '',
                                    clueNumber: cellData.clueNumber,
                                    isSelected: index == selectedCellIndex,
                                    isHighlighted:
                                        highlightedCellIndices.contains(index),
                                    isIncorrect: _incorrectCells.contains(index),
                                    cornerHint: showCorner ? correct : null,
                                    isPulsing: _pulsingCells.contains(index),
                                    onTap: () async {
                                      await AudioService.instance.playClick();
                                      _setSelectedCell(index, fromUserTap: true);
                                    },
                                  );
                                },
                              ),
                      ),
                    ),

                    // --- Generating Overlay ---
                    Positioned.fill(
                      child: IgnorePointer(
                        ignoring: !_isGenerating,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 150),
                          opacity: _isGenerating ? 1.0 : 0.0,
                          child: Container(
                            color: Colors.black54,
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  SizedBox(
                                    width: 48,
                                    height: 48,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 4,
                                      color: Colors.yellow,
                                    ),
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    'Generating level...',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // --- 2. Fixed Current Clue + Keyboard at Bottom ---
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.32,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: CurrentClueWidget(clue: activeClue)),
                        IconButton(
                          tooltip: 'Toggle Across/Down',
                          onPressed: () async {
                            await AudioService.instance.playClick();
                            _toggleClueDirection();
                          },
                          icon: const Icon(
                            Icons.swap_horiz,
                            color: Colors.yellowAccent,
                          ),
                        ),
                      ],
                    ),
                    Expanded(
                      child: CustomKeyboard(onKeyPress: _handleKeyPress),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      )
    );
  }
}
