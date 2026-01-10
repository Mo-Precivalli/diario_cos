import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/notebook_provider.dart';
import '../theme/colors.dart';

class AlphabetSidebar extends StatelessWidget {
  const AlphabetSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NotebookProvider>(
      builder: (context, provider, child) {
        // Only show if active tab is Monsters (Bestiário)
        if (provider.activeTab?.id != 'monsters') {
          return const SizedBox.shrink();
        }

        // List of letters A-Z plus "..." for reset
        final List<String> letters = List.generate(
          26,
          (index) => String.fromCharCode(index + 65),
        );
        letters.add('...'); // Add reset option

        return Container(
          width: 30, // Narrow sidebar for letters
          margin: const EdgeInsets.only(
            top: 25,
            bottom: 40,
          ), // Spacing for corners
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween, // Distribute available space
            children: letters.map((letter) {
              final isSelected = provider.selectedLetter == letter;
              final isReset = letter == '...';

              return _AlphabetTab(
                letter: letter,
                isSelected:
                    isSelected && !isReset, // Don't highlight reset permanently
                onTap: () {
                  if (isReset) {
                    provider.filterByLetter(null);
                  } else {
                    provider.filterByLetter(letter);
                  }
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

class _AlphabetTab extends StatefulWidget {
  final String letter;
  final bool isSelected;
  final VoidCallback onTap;

  const _AlphabetTab({
    required this.letter,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  State<_AlphabetTab> createState() => _AlphabetTabState();
}

class _AlphabetTabState extends State<_AlphabetTab> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          // Allow flexible height or fixed small height?
          // Since we use spaceBetween, fixed height is safer to avoid overlap
          height: 20,
          width: _isHovered ? 28 : 24,
          decoration: BoxDecoration(
            color: (widget.isSelected || _isHovered)
                ? AppColors.accentGold
                : AppColors.primaryBlue.withOpacity(0.6),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              bottomLeft: Radius.circular(4),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 2,
                offset: const Offset(-1, 1),
              ),
            ],
            border: Border.all(
              color: Colors.black.withOpacity(0.1),
              width: 0.5,
            ),
          ),
          child: Center(
            child: Text(
              widget.letter,
              style: GoogleFonts.lato(
                color: Colors.white.withOpacity(0.9),
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
