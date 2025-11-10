

import '../models/crossword.data.model.dart';

/// Represents the data for a single cell in the generated grid.
class CellData {
  bool isBlocked; // Is this a black or white square?
  String? correctLetter; // The correct answer for this cell
  int? clueNumber; // The number to display (if a clue starts here)
  List<String> clueIds; // List of clues this cell belongs to (e.g., "1-across", "2-down")

  CellData({
    this.isBlocked = false,
    this.correctLetter,
    this.clueNumber,
    List<String>? clueIds,
  }) : clueIds = clueIds ?? [];
}

/// Represents the entire generated grid.
class CrosswordGrid {
  final int rows;
  final int cols;
  /// A 1D list representing the 2D grid.
  /// Access with: grid[row * cols + col]
  final List<CellData> grid;
  /// Map of clueId -> (otherClueId -> common uppercase letter at intersection)
  final Map<String, Map<String, String>> commonLetters;

  CrosswordGrid({
    required this.rows,
    required this.cols,
    required this.grid,
    Map<String, Map<String, String>>? commonLetters,
  }) : commonLetters = commonLetters ?? <String, Map<String, String>>{};
}

class CrosswordGenerator {

  /// Takes a [CrosswordLevel] dataset and generates the 2D grid data.
  static CrosswordGrid generateGrid(CrosswordLevel level) {
    // 1. Create a grid of the specified size, initially all "blocked".
    final grid = List.generate(
      level.rows * level.cols,
          (_) => CellData(isBlocked: true),
    );

    // 2. "Carve out" the cells for each clue.
    for (final clue in level.clues) {
      int r = clue.startRow;
      int c = clue.startCol;

      for (int i = 0; i < clue.answer.length; i++) {
        // Bounds check: stop if placement would go out of grid
        if (r < 0 || r >= level.rows || c < 0 || c >= level.cols) {
          // ignore: avoid_print
          print('[CrosswordGenerator] Bounds exceeded for clue ${clue.id} at step $i (r:$r c:$c) in ${level.rows}x${level.cols}');
          break;
        }
        // Calculate the 1D index from the 2D row/col
        final index = (r * level.cols) + c;

        // This should always be true if your data is valid
        if (index < grid.length) {
          final letter = clue.answer[i];

          // This is now an active cell
          grid[index].isBlocked = false;

          // Validate intersections: if an existing letter is present and differs, keep the original
          final existing = grid[index].correctLetter;
          if (existing == null) {
            grid[index].correctLetter = letter;
          } else if (existing.toUpperCase() != letter.toUpperCase()) {
            // Conflict detected – keep the original to avoid flip-flopping and log for data fix
            // ignore: avoid_print
            print('[CrosswordGenerator] Conflict at index $index: existing "$existing" vs "$letter" for clue ${clue.id}.');
          }

          // Add a reference to the clue this cell belongs to
          if (!grid[index].clueIds.contains(clue.id)) {
            grid[index].clueIds.add(clue.id);
          }

          // If this is the first letter of the clue, add the clue number
          if (i == 0) {
            grid[index].clueNumber = clue.number;
          }
        }

        // Move to the next cell for this clue
        if (clue.direction == Direction.across) {
          c++;
        } else {
          r++;
        }
      }
    }

    // 3. Compute common letters between intersecting clues
    final Map<String, Map<String, String>> commons = {};
    for (final cell in grid) {
      if (cell.isBlocked) continue;
      if ((cell.clueIds.length) < 2) continue;
      final letter = (cell.correctLetter ?? '').toUpperCase();
      if (letter.isEmpty) continue;

      // For all pairs
      for (int i = 0; i < cell.clueIds.length; i++) {
        for (int j = i + 1; j < cell.clueIds.length; j++) {
          final a = cell.clueIds[i];
          final b = cell.clueIds[j];
          commons.putIfAbsent(a, () => {});
          commons.putIfAbsent(b, () => {});
          commons[a]![b] = letter;
          commons[b]![a] = letter;
        }
      }
    }

    return CrosswordGrid(
      rows: level.rows,
      cols: level.cols,
      grid: grid,
      commonLetters: commons,
    );
  }
}