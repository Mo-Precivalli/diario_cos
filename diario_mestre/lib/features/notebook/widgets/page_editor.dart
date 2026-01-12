import 'package:flutter/material.dart';
import 'dart:async'; // Auto-save
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'dart:convert';
import '../models/notebook_page.dart';
import 'package:diario_mestre/providers/notebook_provider.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:diario_mestre/core/theme/colors.dart';

class PageEditor extends StatefulWidget {
  final NotebookPage page;
  final Function(NotebookPage, {bool silent}) onSave; // Updated signature
  final bool showTitle;
  final bool showFormatButton;
  final Function(dynamic)? onOverflow;
  final bool shouldFocus;

  const PageEditor({
    super.key,
    required this.page,
    required this.onSave,
    this.showTitle = true,
    this.showFormatButton = true,
    this.onOverflow,
    this.shouldFocus = false,
  });

  @override
  State<PageEditor> createState() => _PageEditorState();
}

class _PageEditorState extends State<PageEditor> {
  late quill.QuillController _controller;
  late TextEditingController _titleController;
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  bool _hasChanges = false;
  bool _isOverflowing = false;

  // Overlay Logic
  OverlayEntry? _overlayEntry;
  bool _isToolbarOpen = false;
  Offset _toolbarPosition = const Offset(400, 80);

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  void _initializeController([String? content]) {
    _titleController = TextEditingController(text: widget.page.title);
    final pageContent = content ?? widget.page.content;

    // Inicializar o Quill controller com o conteúdo da página
    try {
      final document = quill.Document.fromJson(jsonDecode(pageContent));
      _controller = quill.QuillController(
        document: document,
        selection: const TextSelection.collapsed(offset: 0),
      );
    } catch (e) {
      // Se o conteúdo for inválido, criar documento vazio
      _controller = quill.QuillController.basic();
    }

    _controller.addListener(_onControllerChange);
    _titleController.addListener(_onTitleChange);

    // Check for focus request
    if (widget.shouldFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
        // Move cursor to end
        _controller.moveCursorToPosition(_controller.document.length - 1);
      });
    }
  }

  @override
  void didUpdateWidget(PageEditor oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check if we need to force focus
    if (widget.shouldFocus && !oldWidget.shouldFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
        _controller.moveCursorToPosition(_controller.document.length - 1);
      });
    }

    // CRITICAL: Inspect if Page ID changed (Navigation occurred w/o dispose)
    if (widget.page.id != oldWidget.page.id) {
      // We are switching pages. If we have unsaved changes, SAVE THEM to the OLD page.
      if (_hasChanges) {
        _saveOldPage(oldWidget);
      }

      // Now it's safe to load the new page
      _removeSidebarOverlay(); // Close any old overlays
      _initializeController(); // Load new content
      _hasChanges = false; // Reset change flag for new page
      if (mounted) {
        setState(() {});
      }
      return;
    }

    // Refresh content if ID is same but content changed externally (e.g. sync)
    if (widget.page.id == oldWidget.page.id &&
        widget.page.content != oldWidget.page.content &&
        !_hasChanges) {
      _controller.removeListener(_onControllerChange);
      _titleController.removeListener(_onTitleChange);
      _initializeController();
      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _saveOldPage(PageEditor oldWidget) async {
    try {
      final content = jsonEncode(_controller.document.toDelta().toJson());
      final updatedPage = oldWidget.page.copyWith(
        title: _titleController.text.trim(),
        content: content,
        updatedAt: DateTime.now(),
      );
      // Use silent save to avoid crashes/rebuilds during update
      await oldWidget.onSave(updatedPage, silent: true);
    } catch (e) {
      debugPrint('Error saving old page in transition: $e');
    }
  }

  // Duplicate methods removed (moved to bottom with AutoSave)

  void _checkOverflow() {
    // We check after layout
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      // Increased tolerance to 5.0 to avoid phantom newline overflow
      if (_scrollController.hasClients &&
          _scrollController.position.maxScrollExtent > 5.0) {
        // Overflow detected
        if (!_isOverflowing) {
          _isOverflowing = true;
          _handleOverflow();
        }
      } else {
        _isOverflowing = false;
      }
    });
  }

  void _handleOverflow() {
    if (widget.onOverflow != null) {
      // Attempt to cut the last portion of text to move it to the next page
      final doc = _controller.document;
      final len = doc.length;

      // GUARD: Prevent draining the page if content is minimal (< 50 chars)
      // This implies layout issue rather than content overflow.
      if (len < 50) {
        // Stop cutting if we are nearly empty.
        return;
      }

      if (len <= 1) {
        // Empty or just newline
        widget.onOverflow?.call(null);
        return;
      }

      // Heuristic: Find the last whitespace to cut a whole word
      final text = doc.toPlainText();

      // Limit search to last 100 chars
      final limit = (len - 100) < 0 ? 0 : (len - 100);
      int splitIndex = len - 2;
      bool foundSpace = false;

      while (splitIndex > limit) {
        final char = text[splitIndex];
        if (char == ' ' || char == '\n') {
          foundSpace = true;
          break;
        }
        splitIndex--;
      }

      // If no space found in lookback, or splitIndex went to 0, force small cut
      if (!foundSpace || splitIndex <= 0) {
        splitIndex = len - 2;
        if (splitIndex < 0) splitIndex = 0;
      }

      // Safety: if len > 50 and we are cutting from 0, change to suffix cut
      if (splitIndex == 0 && len > 50) {
        splitIndex = len - 2;
      }

      // Additional Safety: If cutting leaves document empty (and it was big), deny it.
      // But above checks covers it.

      final lengthToCut = (len - 1) - splitIndex;
      final extractedText = text.substring(splitIndex, len - 1);

      // Delete from current page
      _controller.replaceText(
        splitIndex,
        lengthToCut,
        '',
        TextSelection.collapsed(
          offset: splitIndex,
        ), // Keep cursor at the end of remaining text
      );

      // Notify parent with the extracted text
      widget.onOverflow?.call(extractedText);
    }
  }

  Timer? _autosaveTimer;

  void _showSidebarOverlay() {
    if (_overlayEntry != null) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => DraggableToolbarOverlay(
        initialPosition: _toolbarPosition,
        controller: _controller,
        onPositionChanged: (newPos) {
          _toolbarPosition = newPos;
        },
        onClose: _removeSidebarOverlay,
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    setState(() {
      _isToolbarOpen = true;
    });
  }

  @override
  void dispose() {
    _autosaveTimer?.cancel();
    // Force save on dispose if changes exist
    if (_hasChanges) {
      // We cannot await here, but we can call the save method.
      // However, _save calls setState/context. We must avoid that.
      // Using a modified save method or just calling widget.onSave
      _saveQuietly(silent: true);
    }

    _removeSidebarOverlay();
    _controller.removeListener(_onControllerChange);
    _titleController.removeListener(_onTitleChange);
    // Note: Do not dispose _controller if it errors, but basic one is fine.
    // _controller.dispose();
    _titleController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // Save without UI feedback or setState checks (for dispose/auto)
  Future<void> _saveQuietly({bool silent = false}) async {
    try {
      final content = jsonEncode(_controller.document.toDelta().toJson());
      final updatedPage = widget.page.copyWith(
        title: _titleController.text.trim(),
        content: content,
        updatedAt: DateTime.now(),
      );
      await widget.onSave(updatedPage, silent: silent);
      // No setState here as might be disposed
    } catch (e) {
      debugPrint('Error saving quietly: $e');
    }
  }

  void _onControllerChange() {
    if (!_hasChanges) {
      if (mounted) {
        setState(() {
          _hasChanges = true;
        });
      }
    }
    _checkOverflow();

    // Debounced Auto-Save
    _autosaveTimer?.cancel();
    _autosaveTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) _saveQuietly(silent: false);
    });
  }

  void _onTitleChange() {
    if (!_hasChanges) {
      if (mounted) {
        setState(() {
          _hasChanges = true;
        });
      }
    }
  }

  // Explicit Save (Button)
  Future<void> _save() async {
    if (!mounted) return;

    await _saveQuietly();

    if (mounted) {
      setState(() {
        _hasChanges = false;
      });
      try {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Página salva com sucesso!'),
            duration: Duration(seconds: 1),
          ),
        );
      } catch (e) {
        // Silently fail if context is inactive
      }
    }
  }

  void _removeSidebarOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) {
      setState(() {
        _isToolbarOpen = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // Container da página inteira (Fundo Azul Escuro)
      width: double.infinity,
      height: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.notebookPage, // Marfim/Creme Paper
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(4, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Column(
          children: [
            // HEADER (Título e Botões) - Agora dentro do estilo da página
            if (widget.showTitle || widget.showFormatButton)
              Container(
                height: 60, // Altura fixa para o cabeçalho
                padding: const EdgeInsets.symmetric(horizontal: 24),
                alignment: Alignment.center,
                child: Row(
                  children: [
                    // Botão Voltar
                    if (widget.showTitle)
                      IconButton(
                        icon: const Icon(
                          Icons.pets,
                          color: AppColors.accentGold,
                        ), // Cor dourada
                        onPressed: () {
                          _removeSidebarOverlay();
                          Provider.of<NotebookProvider>(
                            context,
                            listen: false,
                          ).closeBook();
                        },
                        tooltip: 'Voltar para o Índice',
                      ),

                    // Título Centralizado Estiloso
                    Expanded(
                      child: widget.showTitle
                          ? TextField(
                              controller: _titleController,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.libreBaskerville(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppColors.accentGold,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Adventuring Notes',
                                hintStyle: TextStyle(
                                  color: AppColors.accentGold.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                                border: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                    color: AppColors.accentGold.withValues(
                                      alpha: 0.5,
                                    ),
                                    width: 1,
                                  ),
                                ),
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                    color: AppColors.accentGold.withValues(
                                      alpha: 0.2,
                                    ),
                                    width: 1,
                                  ),
                                ),
                                focusedBorder: const UnderlineInputBorder(
                                  borderSide: BorderSide(
                                    color: AppColors.accentGold,
                                    width: 1.5,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                              ),
                            )
                          : Container(), // Espaço vazio se não tiver título
                    ),

                    // Botão formatar (Encantamentos)
                    if (widget.showFormatButton)
                      IconButton(
                        icon: Icon(
                          _isToolbarOpen
                              ? Icons.auto_fix_high
                              : Icons.auto_fix_normal,
                          color: AppColors.accentGold,
                        ),
                        onPressed: () {
                          if (_isToolbarOpen) {
                            _removeSidebarOverlay();
                          } else {
                            _showSidebarOverlay();
                          }
                        },
                        tooltip: 'Formatação Mágica',
                      ),

                    // Botão salvar discreto
                    if (_hasChanges)
                      IconButton(
                        icon: const Icon(
                          Icons.save,
                          color: AppColors.accentGold,
                        ),
                        onPressed: _save,
                        tooltip: 'Salvar',
                      ),
                  ],
                ),
              ),

            // Espaçamento se tiver título (linha divisória visual feita pelo painter)
            if (widget.showTitle) const SizedBox(height: 10),

            // EDITOR (Ocupa o resto da página)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Theme(
                  data: Theme.of(context).copyWith(
                    textSelectionTheme: TextSelectionThemeData(
                      cursorColor: AppColors.accentGold,
                      selectionColor: AppColors.accentGold.withValues(
                        alpha: 0.3,
                      ),
                      selectionHandleColor: AppColors.accentGold,
                    ),
                  ),
                  child: DefaultTextStyle(
                    style: GoogleFonts.libreBaskerville(
                      color: AppColors.textDark,
                      fontSize: 18,
                      height: 1.77,
                    ),
                    child: ScrollConfiguration(
                      behavior: ScrollConfiguration.of(context).copyWith(
                        physics: const NeverScrollableScrollPhysics(),
                        scrollbars: false,
                      ),
                      child: Padding(
                        // Inner padding to force text cut-off before hitting bottom border visually
                        padding: const EdgeInsets.only(
                          top: 40.0,
                          bottom: 180.0,
                        ),
                        child: quill.QuillEditor(
                          controller: _controller,
                          scrollController: _scrollController,
                          focusNode: _focusNode,
                          // Minimal params
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DraggableToolbarOverlay extends StatefulWidget {
  final Offset initialPosition;
  final ValueChanged<Offset> onPositionChanged;
  final VoidCallback onClose;
  final quill.QuillController controller;

  const DraggableToolbarOverlay({
    super.key,
    required this.initialPosition,
    required this.onPositionChanged,
    required this.onClose,
    required this.controller,
  });

  @override
  State<DraggableToolbarOverlay> createState() =>
      _DraggableToolbarOverlayState();
}

class _DraggableToolbarOverlayState extends State<DraggableToolbarOverlay> {
  late Offset position;

  @override
  void initState() {
    super.initState();
    position = widget.initialPosition;
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: position.dx,
      top: position.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            position += details.delta;
          });
          widget.onPositionChanged(position);
        },
        child: Material(
          elevation: 12,
          borderRadius: BorderRadius.circular(12),
          color: AppColors.primaryBlue, // Fundo azul combinando com a capa
          child: Container(
            width: 320,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.accentGold, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header da Toolbar
                Container(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.drag_indicator,
                            size: 18,
                            color: AppColors.accentGold,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'ENCANTAMENTOS', // Ou "Formatação"
                            style: GoogleFonts.libreBaskerville(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: AppColors.accentGold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          size: 18,
                          color: AppColors.accentGold,
                        ),
                        onPressed: widget.onClose,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                const Divider(
                  color: AppColors.accentGold,
                  height: 1,
                  thickness: 0.5,
                ),
                const SizedBox(height: 12),
                Theme(
                  data: ThemeData(
                    canvasColor: AppColors.primaryBlue,
                    iconTheme: const IconThemeData(color: Colors.white),
                  ),
                  child: quill.QuillSimpleToolbar(
                    controller: widget.controller,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
