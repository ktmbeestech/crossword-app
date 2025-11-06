/// Represents the direction of a clue.
enum Direction { across, down }

/// Defines a single clue in the crossword.
class Clue {
  final String id; // e.g., "1-across"
  final int number; // e.g., 1
  final Direction direction;
  final String clue;
  final String answer;
  final int startRow;
  final int startCol;

  Clue({
    required this.id,
    required this.number,
    required this.direction,
    required this.clue,
    required this.answer,
    required this.startRow,
    required this.startCol,
  });
}

/// Defines an entire crossword level.
/// This is your "dataset" for a level.
class CrosswordLevel {
  final String id;
  final int rows;
  final int cols;
  final List<Clue> clues;

  CrosswordLevel({
    required this.id,
    required this.rows,
    required this.cols,
    required this.clues,
  });
}