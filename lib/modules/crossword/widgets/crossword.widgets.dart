import 'package:flutter/material.dart';
import '../models/crossword.data.model.dart';

/// A widget to display a single cell in the crossword grid.
class CellWidget extends StatelessWidget {
  final String letter;
  final int? clueNumber;
  final bool isSelected;
  final bool isHighlighted;
  final bool isIncorrect;
  final VoidCallback onTap;

  const CellWidget({
    super.key,
    required this.letter,
    this.clueNumber,
    required this.isSelected,
    required this.isHighlighted,
    this.isIncorrect = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color getBackgroundColor() {
      // This logic defines the cell colors
      if (isIncorrect) {
        return Colors.redAccent;
      }
      if (isSelected) {
        // The currently active, selected cell
        return Colors.blueAccent;
      }
      if (isHighlighted) {
        // The other cells in the active clue
        return Colors.blue[800]!;
      }
      // A standard, non-active cell
      return Colors.blue[900]!;
    }

    return GestureDetector(
      onTap: onTap,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cellSide = constraints.biggest.shortestSide;
          final letterSize = cellSide * 0.58; // scales with cell size
          final clueBadgeSize = cellSide * 0.24;
          final clueTop = cellSide * 0.06;
          final clueLeft = cellSide * 0.08;

          return Container(
            decoration: BoxDecoration(
              color: getBackgroundColor(),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Stack(
              children: [
                // 1. Clue Number (scaled)
                if (clueNumber != null)
                  Positioned(
                    top: clueTop,
                    left: clueLeft,
                    child: Text(
                      clueNumber.toString(),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontSize: clueBadgeSize.clamp(8.0, 14.0),
                            color: Colors.white70,
                          ),
                    ),
                  ),
                // 2. User's Letter (scaled)
                Center(
                  child: Text(
                    letter,
                    maxLines: 1,
                    overflow: TextOverflow.visible,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: letterSize.clamp(14.0, 28.0),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// A widget to display the currently active clue.
class CurrentClueWidget extends StatelessWidget {
  final Clue? clue;

  const CurrentClueWidget({super.key, this.clue});

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    final base = screenH < 680 ? 13.0 : (screenH < 760 ? 14.0 : 16.0);

    return Container(
      padding: const EdgeInsets.all(4),
      margin: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          if (clue != null)
            Text(
              '${clue!.number} ${clue!.direction.name}: ',
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: base, color: Colors.orangeAccent),
            ),
          Expanded(
            child: Text(
              clue?.clue ?? 'Select a clue to begin.',
              style: TextStyle(fontSize: base, color: Colors.orangeAccent),
            ),
          ),
        ],
      ),
    );
  }
}