import 'package:flutter/material.dart';

/// The Custom Crossword Keyboard Widget.
///
/// It displays a full QWERTY layout optimized for touch,
/// including a DEL (Delete) button.
class CustomKeyboard extends StatelessWidget {
  /// Callback function invoked when any key is pressed.
  final ValueChanged<String> onKeyPress;

  const CustomKeyboard({
    super.key,
    required this.onKeyPress,
  });

  // Define the keyboard layout rows
  static const List<List<String>> _keyRows = [
    ['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P'],
    ['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L'],
    ['Z', 'X', 'C', 'V', 'B', 'N', 'M', 'DEL'],
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Compute a dynamic key height that fits within available height
        // Account for container padding (top+bottom=12) and per-row vertical padding (3*2*rows=18)
        final verticalChrome = 12.0 + (3.0 * 2.0 * _keyRows.length);
        final availableForKeys = (constraints.maxHeight - verticalChrome).clamp(60.0, constraints.maxHeight);
        final perRowHeight = (availableForKeys / _keyRows.length).clamp(30.0, 56.0);

        return Container(
          color: Colors.black,
          padding: const EdgeInsets.only(top: 6.0, bottom: 6.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: _keyRows.map((row) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3.0, horizontal: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: row.map((key) {
                    final isSpecialKey = key == 'DEL';
                    return Expanded(
                      flex: isSpecialKey ? 2 : 1,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2.0),
                        child: _KeyButton(
                          label: key,
                          isSpecialKey: isSpecialKey,
                          height: perRowHeight,
                          onTap: () => onKeyPress(key),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

/// Helper widget for an individual keyboard key button.
class _KeyButton extends StatelessWidget {
  final String label;
  final bool isSpecialKey;
  final VoidCallback onTap;
  final double height;

  const _KeyButton({
    required this.label,
    required this.isSpecialKey,
    required this.onTap,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isSpecialKey ? Colors.grey[700] : const Color(0xFF253153);
    final foregroundColor = isSpecialKey ? Colors.white : Colors.white;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              spreadRadius: 1,
              blurRadius: 2,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: foregroundColor,
            fontSize: isSpecialKey ? 14 : 16,
            fontWeight: isSpecialKey ? FontWeight.w500 : FontWeight.bold,
          ),
        ),
      ),
    );
  }
}