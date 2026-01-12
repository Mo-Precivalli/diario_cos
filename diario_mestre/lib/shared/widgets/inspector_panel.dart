import 'package:flutter/material.dart';
import 'package:diario_mestre/features/notebook/models/notebook_page.dart';
import 'package:diario_mestre/features/notebook/widgets/flexible_page_editor.dart';
import 'package:diario_mestre/core/theme/colors.dart';

class InspectorPanel extends StatefulWidget {
  final NotebookPage? page;
  final VoidCallback onClose;
  final Function(NotebookPage) onSave;

  const InspectorPanel({
    super.key,
    required this.page,
    required this.onClose,
    required this.onSave,
  });

  @override
  State<InspectorPanel> createState() => _InspectorPanelState();
}

class _InspectorPanelState extends State<InspectorPanel>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    if (widget.page != null) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(InspectorPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.page != null && oldWidget.page == null) {
      _controller.forward();
    } else if (widget.page == null && oldWidget.page != null) {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If no page and closed, empty
    // But we need to keep the structure for animation reverse

    return SlideTransition(
      position: _offsetAnimation,
      child: Container(
        width: 450, // Fixed width panel
        height: double.infinity,
        margin: const EdgeInsets.only(left: 8),
        decoration: BoxDecoration(
          color: AppColors.background, // Or a distinct paper color
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(-5, 0),
            ),
          ],
        ),
        child: widget.page == null
            ? const SizedBox()
            : Stack(
                children: [
                  // The Content
                  Padding(
                    padding: const EdgeInsets.only(top: 40), // header space
                    child: FlexiblePageEditor(
                      page: widget.page!,
                      onSave: (p, {silent = false}) => widget.onSave(p),
                      showTitle: true,
                      showFormatButton: true,
                    ),
                  ),
                  // Grip/Header
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 40,
                    child: Container(
                      color: AppColors.primaryBlue.withValues(alpha: 0.1),
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.only(left: 16),
                      child: const Text(
                        'Ficha Rápida',
                        style: TextStyle(
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  // Close Button (Floating)
                  Positioned(
                    top: 4, // Adjusted slightly to center in 40px header
                    right: 4,
                    child: IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: AppColors.primaryBlue,
                      ), // Matches header text
                      tooltip: 'Fechar',
                      onPressed: () {
                        // debugPrint('Close button pressed');
                        _controller.reverse().then((_) => widget.onClose());
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
