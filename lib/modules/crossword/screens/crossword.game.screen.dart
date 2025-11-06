import 'package:crosswords/constant/sizedbox/sized_box.constants.dart';
import 'package:crosswords/modules/crossword/widgets/pause.crossword.widget.dart';
import 'package:crosswords/modules/landing/screens/landing.shell.page.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import '../models/crossword.data.model.dart';
import '../services/crossword.grid.generator.dart';
import '../widgets/crossword.widgets.dart';
import '../widgets/custom.keyboard.widget.dart';
import '../data/crossword.level.data.dart';

class CrosswordPage extends StatefulWidget {
  const CrosswordPage({super.key});

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
    // Load the first level and start timer
    _levelIndex = 0;
    _loadLevel(allLevels[_levelIndex]);
    _startTimer();
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
      _hintsRemaining = 3;
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
                children: [
                  CurrentClueWidget(clue: activeClue),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 150,
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
      // CRITICAL FIX 2: Guard against self-recursion.
      if (selectedCellIndex == index) {
        return;
      }

      selectedCellIndex = index;
      final cell = gridData.grid[index];

      // Logic to set/change the active clue when a cell is tapped
      if (cell.clueIds.isNotEmpty) {
        // Behavior rules:
        // - When moving programmatically (typing/auto-advance), DO NOT toggle clue at intersections.
        // - When user taps a cell that is an intersection and already in active clue, toggle to the other clue.
        // - If there is no active clue or it doesn't include this cell, pick the first clue for the cell.
        String targetClueId = activeClue?.id ?? '';
        if (fromUserTap &&
            activeClue != null &&
            cell.clueIds.length > 1 &&
            cell.clueIds.contains(activeClue!.id)) {
          // Toggle to the other clue only on user tap
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
        // It's a non-clue cell (a black square)
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
        // Validate against correct letter for this cell
        final idx = selectedCellIndex!;
        final expected = gridData.grid[idx].correctLetter?.toUpperCase();
        final value = key.toUpperCase();
        _userInput[idx] = value;
        if (expected != null && value == expected) {
          _incorrectCells.remove(idx);
          _autoAdvanceCursor();
        } else {
          // mark incorrect and do not advance
          _incorrectCells.add(idx);
        }
      }
    });
    _checkForCompletion();
  }

  /// Logic to delete the current letter and move the cursor back.
  void _handleDelete() {
    if (selectedCellIndex == null) return;

    // 1. Clear the letter in the current cell
    _userInput.remove(selectedCellIndex);
    _incorrectCells.remove(selectedCellIndex);

    // 2. Find the index of the current cell in the active clue
    final clueCells =
        activeClue == null ? const <int>[] : _cellsForClue(activeClue!);
    final currentIndexInClue = clueCells.indexOf(selectedCellIndex!);

    // 3. Move the selection one cell back, if possible
    if (currentIndexInClue > 0) {
      final prevCellIndex = clueCells[currentIndexInClue - 1];
      // Note: We call _setSelectedCell which contains the setState.
      _setSelectedCell(prevCellIndex);
    }
    // If at the start of the clue, just clear the input and stay there.
  }

  /// Logic to automatically advance the cursor to the next cell in the active clue.
  void _autoAdvanceCursor() {
    if (activeClue == null || selectedCellIndex == null) return;

    // 1. Get the list of cell indices belonging to the active clue
    final clueCells = _cellsForClue(activeClue!);

    // 2. Find the index of the currently selected cell within that list
    final currentIndexInClue = clueCells.indexOf(selectedCellIndex!);

    // 3. If there is a next cell in the clue, move the selection there
    if (currentIndexInClue < clueCells.length - 1) {
      final nextCellIndex = clueCells[currentIndexInClue + 1];
      // Move without toggling clues
      _setSelectedCell(nextCellIndex, fromUserTap: false);
    } else {
      // Word is complete
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
          _hintsRemaining -= 1;
          _incorrectCells.remove(idx);
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
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Clues',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: currentLevel.clues.length,
                    itemBuilder: (context, i) {
                      final clue = currentLevel.clues[i];
                      return ListTile(
                        dense: true,
                        title: Text(
                          '${clue.number} ${clue.direction.name}'.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        subtitle: Text(
                          clue.clue,
                          style: const TextStyle(color: Colors.white),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          _setActiveClue(clue);
                        },
                      );
                    },
                  ),
                ),
              ],
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
              onPressed: () {
                Navigator.pop(context);
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
    _nextLevel();
  }

  void onHome() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CrosswordLandingPage()),
    );
  }

  void onResume() {
    Navigator.pop(context);
    _resumeTimer();
  }

  void onToggleSound() {}

  void onToggleMusic() {}
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
                            ),
                      );
                    },
                    child: Image.asset(
                      'assets/images/pause_button.png',
                      height: 48,
                    ),
                  ),

                  SizedBox(
                    height: 48,

                    child: IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: Image.asset('assets/images/idea_hint.png'),
                      onPressed: _useHint,
                      tooltip: 'Use hint',
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
