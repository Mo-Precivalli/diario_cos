import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:diario_mestre/features/notebook/models/notebook_page.dart';
import 'package:diario_mestre/core/theme/colors.dart';
import 'package:google_fonts/google_fonts.dart';

class FlipCard extends StatefulWidget {
  final NotebookPage page;
  final Function(NotebookPage) onSave;
  final VoidCallback onDelete;

  const FlipCard({
    super.key,
    required this.page,
    required this.onSave,
    required this.onDelete,
  });

  @override
  State<FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<FlipCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _frontRotation;
  late Animation<double> _backRotation;
  bool _isFlipped = false;

  // Edit State
  late TextEditingController _nameController;
  late TextEditingController _descController;
  bool _isEditing = false; // Only relevant for the BACK side

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _frontRotation = TweenSequence<double>([
      TweenSequenceItem<double>(
        tween: Tween(
          begin: 0.0,
          end: -pi / 2,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 50.0,
      ),
      TweenSequenceItem<double>(
        tween: ConstantTween<double>(-pi / 2),
        weight: 50.0,
      ),
    ]).animate(_controller);

    _backRotation = TweenSequence<double>([
      TweenSequenceItem<double>(
        tween: ConstantTween<double>(pi / 2),
        weight: 50.0,
      ),
      TweenSequenceItem<double>(
        tween: Tween(
          begin: pi / 2,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 50.0,
      ),
    ]).animate(_controller);

    _nameController = TextEditingController(text: widget.page.title);

    // Parse content
    String desc = '';
    try {
      final data = jsonDecode(widget.page.content);
      if (data is Map) {
        desc = data['description'] ?? '';
      }
    } catch (_) {
      // If content is not valid JSON, ignore (might be new or empty)
    }
    _descController = TextEditingController(text: desc);
  }

  @override
  void dispose() {
    _controller.dispose();
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _flipCard() {
    if (_isFlipped) {
      _controller.reverse();
    } else {
      _controller.forward();
    }
    setState(() {
      _isFlipped = !_isFlipped;
    });
  }

  Future<void> _saveChanges() async {
    // Parse existing content to keep image path
    Map<String, dynamic> data = {};
    try {
      final parsed = jsonDecode(widget.page.content);
      if (parsed is Map<String, dynamic>) data = parsed;
    } catch (_) {}

    data['description'] = _descController.text;
    // Note: Image path is saved when created/selected, but we preserve it here.

    final updatedPage = widget.page.copyWith(
      title: _nameController.text,
      content: jsonEncode(data),
      updatedAt: DateTime.now(),
    );

    widget.onSave(updatedPage);
    setState(() {
      _isEditing = false;
    });
  }

  String? _getImagePath() {
    try {
      final data = jsonDecode(widget.page.content);
      if (data is Map) {
        return data['imagePath'];
      }
    } catch (_) {}
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _isEditing ? null : _flipCard, // Block flip if editing
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Front Side
          AnimatedBuilder(
            animation: _frontRotation,
            builder: (context, child) {
              return Transform(
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateY(_frontRotation.value),
                alignment: Alignment.center,
                child: _frontRotation.value <= -pi / 2
                    ? const SizedBox.shrink() // Hide when rotated past 90
                    : _buildFront(),
              );
            },
          ),
          // Back Side
          AnimatedBuilder(
            animation: _backRotation,
            builder: (context, child) {
              return Transform(
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateY(_backRotation.value),
                alignment: Alignment.center,
                child: _backRotation.value >= pi / 2
                    ? const SizedBox.shrink() // Hide when rotated past 90
                    : _buildBack(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCardBase({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.notebookPage,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(2, 4),
          ),
        ],
        border: Border.all(color: AppColors.accentGold, width: 2),
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(14), child: child),
    );
  }

  Widget _buildFront() {
    final imagePath = _getImagePath();

    return _buildCardBase(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Image
          if (imagePath != null && File(imagePath).existsSync())
            Image.file(File(imagePath), fit: BoxFit.fill)
          else
            Container(
              color: AppColors.primaryBlue.withValues(alpha: 0.1),
              child: const Center(
                child: Icon(Icons.image, size: 48, color: AppColors.textLight),
              ),
            ),

          // Text Overlay (Only if NO image)
          if (imagePath == null || !File(imagePath).existsSync())
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.8),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Text(
                  widget.page.title,
                  style: GoogleFonts.libreBaskerville(
                    color: AppColors.accentGold,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBack() {
    return _buildCardBase(
      child: Container(
        color: AppColors.notebookPage,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: _isEditing
                      ? TextField(
                          controller: _nameController,
                          style: GoogleFonts.libreBaskerville(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          decoration: const InputDecoration(isDense: true),
                        )
                      : Text(
                          widget.page.title,
                          style: GoogleFonts.libreBaskerville(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppColors.textDark,
                          ),
                        ),
                ),
                if (!_isEditing)
                  IconButton(
                    icon: const Icon(
                      Icons.edit,
                      size: 20,
                      color: AppColors.textLight,
                    ),
                    onPressed: () {
                      setState(() {
                        _isEditing = true;
                      });
                    },
                  ),
              ],
            ),
            const Divider(color: AppColors.accentGold),

            // Description
            Expanded(
              child: _isEditing
                  ? TextField(
                      controller: _descController,
                      maxLines: null,
                      style: GoogleFonts.lato(fontSize: 14),
                      decoration: const InputDecoration(
                        hintText: 'Descrição...',
                        border: InputBorder.none,
                      ),
                    )
                  : SingleChildScrollView(
                      child: Text(
                        _descController.text.isEmpty
                            ? 'Sem descrição.'
                            : _descController.text,
                        style: GoogleFonts.lato(
                          fontSize: 14,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
            ),

            // Actions (Edit Mode)
            if (_isEditing)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: widget.onDelete,
                    tooltip: 'Excluir Carta',
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.check, color: Colors.green),
                    onPressed: _saveChanges,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
