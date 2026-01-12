import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:diario_mestre/features/notebook/models/notebook_tab.dart';
import 'package:diario_mestre/providers/notebook_provider.dart';
import 'package:diario_mestre/core/theme/colors.dart'; // Import AppColors
import 'package:google_fonts/google_fonts.dart';

class TabSidebar extends StatelessWidget {
  const TabSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NotebookProvider>(
      builder: (context, provider, child) {
        return Container(
          width: 50,
          margin: const EdgeInsets.only(
            top: 25,
            bottom: 20,
          ), // Top 30 for "curvinha"
          // Sem decoração de fundo para parecer que sai do caderno
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: provider.tabs.map((tab) {
                final isActive = provider.activeTab?.id == tab.id;
                return _TabButton(
                  tab: tab,
                  isActive: isActive,
                  onTap: () => provider.setActiveTab(tab),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}

class _TabButton extends StatefulWidget {
  final NotebookTab tab;
  final bool isActive;
  final VoidCallback onTap;

  const _TabButton({
    required this.tab,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_TabButton> createState() => _TabButtonState();
}

class _TabButtonState extends State<_TabButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 2,
      ), // Espaço menor entre abas
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutBack,
            // Remove fixed height to let text define size
            // height: widget.isActive ? 160 : 140,
            width: widget.isActive
                ? 45
                : (_isHovered ? 42 : 40), // Efeito sutil de hover
            decoration: BoxDecoration(
              color: widget.isActive
                  ? AppColors.accentGold
                  : (_isHovered
                        ? AppColors.primaryBlue.withValues(alpha: 0.9)
                        : AppColors.primaryBlue.withValues(
                            alpha: 0.7,
                          )), // Mais escuro quando inativo
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: widget.isActive ? 8 : 4,
                  offset: widget.isActive
                      ? const Offset(4, 2)
                      : const Offset(2, 2),
                ),
              ],
              border: Border.all(
                color: Colors.black.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            // Adjust padding to valid "borda grandes" (large borders)
            padding: EdgeInsets.symmetric(
              vertical: widget.isActive ? 12 : 8, // Reduced padding
              horizontal: 4,
            ),
            child: Center(
              child: RotatedBox(
                quarterTurns: 1,
                child: Text(
                  widget.tab.name.toUpperCase(),
                  softWrap: false,
                  overflow: TextOverflow.visible,
                  style: GoogleFonts.lato(
                    color: Colors.white.withValues(
                      alpha: widget.isActive ? 1.0 : 0.7,
                    ),
                    fontSize: 12,
                    fontWeight: widget.isActive
                        ? FontWeight.w900
                        : FontWeight.bold,
                    letterSpacing: 2.0,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
