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
  final String? cornerHint; // e.g., intersection common letter
  final bool isPulsing;

  const CellWidget({
    super.key,
    required this.letter,
    this.clueNumber,
    required this.isSelected,
    required this.isHighlighted,
    this.isIncorrect = false,
    required this.onTap,
    this.cornerHint,
    this.isPulsing = false,
  });

  @override
  Widget build(BuildContext context) {
    Color getBackgroundColor() {
      
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
          final cellSide = constraints.biggest.longestSide;
          final letterSize = cellSide * 0.58; // scales with cell size
          final clueBadgeSize = cellSide * 0.24;
          final clueTop = cellSide * 0.06;
          final clueLeft = cellSide * 0.08;
          final hintBadgeSize = cellSide * 0.22;
          final hintTop = cellSide * 0.06;
          final hintRight = cellSide * 0.08;

          return AnimatedScale(
            scale: isPulsing ? 1.15 : 1.0,
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutBack,
            child: Container(
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
                  if ((cornerHint ?? '').isNotEmpty)
                    Positioned(
                      top: hintTop,
                      right: hintRight,
                      child: Text(
                        cornerHint!,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontSize: hintBadgeSize.clamp(8.0, 13.0),
                          color: Colors.yellowAccent,
                          fontWeight: FontWeight.w700,
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
            ),
          );
        },
      ),
    );
  }
}



class CurrentClueWidget extends StatelessWidget {
  final Clue? clue;

  const CurrentClueWidget({super.key, this.clue});

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    final base = screenH < 680 ? 13.0 : (screenH < 760 ? 14.0 : 16.0);

    final text =
        clue == null
            ? 'Select a clue to begin.'
            : '${clue!.number} ${clue!.direction.name}: ${clue!.clue}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        textAlign: TextAlign.justify,
        softWrap: true,
        style: TextStyle(
          fontSize: base,
          color: Colors.orangeAccent,
          fontWeight: clue == null ? FontWeight.w600 : FontWeight.w700,
          height: 1.25,
        ),
      ),
    );
  }
}
