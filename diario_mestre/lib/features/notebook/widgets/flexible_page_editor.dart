import 'package:flutter/material.dart';
import 'dart:async'; // Auto-save
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'dart:convert';
import '../models/notebook_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:diario_mestre/core/theme/colors.dart';

class FlexiblePageEditor extends StatefulWidget {
  final NotebookPage page;
  final Function(NotebookPage, {bool silent}) onSave;
  final bool showTitle;
  final bool showFormatButton;
  final Function(dynamic)? onOverflow;
  final bool shouldFocus;
  final Function(String)? onNavigate;

  const FlexiblePageEditor({
    super.key,
    required this.page,
    required this.onSave,
    this.showTitle = true,
    this.showFormatButton = true,
    this.onOverflow,
    this.shouldFocus = false,
    this.onNavigate,
  });

  @override
  State<FlexiblePageEditor> createState() => _FlexiblePageEditorState();
}

class _FlexiblePageEditorState extends State<FlexiblePageEditor> {
  late quill.QuillController _controller;
  late TextEditingController _titleController;
  late TextEditingController _acController;
  late TextEditingController _hpController;
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  bool _hasChanges = false;
  bool _isOverflowing = false;

  // Tags
  List<String> _tags = [];
  final TextEditingController _tagInputController = TextEditingController();

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
    _acController = TextEditingController(
      text: widget.page.ac?.toString() ?? '',
    ); // New
    _hpController = TextEditingController(
      text: widget.page.hp?.toString() ?? '',
    ); // New
    _tags = List.from(widget.page.tags);

    final pageContent = content ?? widget.page.content;

    try {
      final decoded = jsonDecode(pageContent);
      if (decoded is List) {
        final document = quill.Document.fromJson(decoded);
        _controller = quill.QuillController(
          document: document,
          selection: const TextSelection.collapsed(offset: 0),
        );
      } else if (decoded is Map) {
        final doc = quill.Document()
          ..insert(0, 'Conteúdo importado:\n${decoded.toString()}');
        _controller = quill.QuillController(
          document: doc,
          selection: const TextSelection.collapsed(offset: 0),
        );
      } else {
        _controller = quill.QuillController.basic();
      }
    } catch (e) {
      _controller = quill.QuillController.basic();
    }

    _controller.addListener(_onControllerChange);
    _titleController.addListener(_onTitleChange);
    _acController.addListener(_onStatChange); // New
    _hpController.addListener(_onStatChange); // New

    if (widget.shouldFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
        _controller.moveCursorToPosition(_controller.document.length - 1);
      });
    }
  }

  @override
  void didUpdateWidget(FlexiblePageEditor oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.shouldFocus && !oldWidget.shouldFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
        _controller.moveCursorToPosition(_controller.document.length - 1);
      });
    }

    if (widget.page.id != oldWidget.page.id) {
      if (_hasChanges) {
        _saveOldPage(oldWidget);
      }
      _removeSidebarOverlay();
      _initializeController();
      _hasChanges = false;
      if (mounted) setState(() {});
      return;
    }

    if (widget.page.id == oldWidget.page.id &&
        (widget.page.content != oldWidget.page.content ||
            widget.page.tags != oldWidget.page.tags) &&
        !_hasChanges) {
      _controller.removeListener(_onControllerChange);
      _titleController.removeListener(_onTitleChange);
      _acController.removeListener(_onStatChange); // New
      _hpController.removeListener(_onStatChange); // New
      _initializeController();
      if (mounted) setState(() {});
    }
  }

  Future<void> _saveOldPage(FlexiblePageEditor oldWidget) async {
    try {
      final content = jsonEncode(_controller.document.toDelta().toJson());
      final updatedPage = oldWidget.page.copyWith(
        title: _titleController.text.trim(),
        content: content,
        tags: _tags,
        ac: int.tryParse(_acController.text.trim()),
        hp: int.tryParse(_hpController.text.trim()),
        updatedAt: DateTime.now(),
      );
      await oldWidget.onSave(updatedPage, silent: true);
    } catch (e) {
      debugPrint('Error saving old page: $e');
    }
  }

  void _checkOverflow() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_scrollController.hasClients &&
          _scrollController.position.maxScrollExtent > 5.0) {
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
      final doc = _controller.document;
      final len = doc.length;
      if (len < 50) return;
      if (len <= 1) {
        widget.onOverflow?.call(null);
        return;
      }

      final text = doc.toPlainText();
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

      if (!foundSpace || splitIndex <= 0) {
        splitIndex = len - 2;
        if (splitIndex < 0) splitIndex = 0;
      }
      if (splitIndex == 0 && len > 50) splitIndex = len - 2;

      final lengthToCut = (len - 1) - splitIndex;
      final extractedText = text.substring(splitIndex, len - 1);

      _controller.replaceText(
        splitIndex,
        lengthToCut,
        '',
        TextSelection.collapsed(offset: splitIndex),
      );

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
        onPositionChanged: (newPos) => _toolbarPosition = newPos,
        onClose: _removeSidebarOverlay,
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _isToolbarOpen = true);
  }

  @override
  void dispose() {
    _autosaveTimer?.cancel();
    if (_hasChanges) _saveQuietly(silent: true);
    _removeSidebarOverlay();
    _controller.removeListener(_onControllerChange);
    _titleController.removeListener(_onTitleChange);
    _titleController.dispose();
    _scrollController.dispose();
    _tagInputController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _saveQuietly({bool silent = false}) async {
    try {
      final content = jsonEncode(_controller.document.toDelta().toJson());
      final updatedPage = widget.page.copyWith(
        title: _titleController.text.trim(),
        content: content,
        tags: _tags,
        ac: int.tryParse(_acController.text.trim()),
        hp: int.tryParse(_hpController.text.trim()),
        updatedAt: DateTime.now(),
      );
      await widget.onSave(updatedPage, silent: silent);
    } catch (e) {
      debugPrint('Error saving quietly: $e');
    }
  }

  void _onControllerChange() {
    if (!_hasChanges) {
      if (mounted) setState(() => _hasChanges = true);
    }
    _checkOverflow();
    _checkForWikiLinks();
    _autosaveTimer?.cancel();
    _autosaveTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) _saveQuietly(silent: false);
    });
  }

  void _checkForWikiLinks() {
    final sel = _controller.selection;
    if (!sel.isCollapsed) return;

    final text = _controller.document.toPlainText();
    final cursor = sel.baseOffset;

    // Check if we just typed ']]', so look back 2 chars
    if (cursor < 2) return;
    if (text.substring(cursor - 2, cursor) != ']]') return;

    // Look for opening '[['
    final startSearch = (cursor - 50) < 0 ? 0 : (cursor - 50);
    final recentText = text.substring(startSearch, cursor);
    final match = RegExp(r'\[\[(.*?)\]\]$').firstMatch(recentText);

    if (match != null) {
      final content = match.group(1);
      if (content != null && content.isNotEmpty) {
        final matchStart = startSearch + match.start;
        final matchLength = match.end - match.start;

        _controller.replaceText(
          matchStart,
          matchLength,
          content,
          TextSelection.collapsed(offset: matchStart + content.length),
        );

        _controller.formatText(
          matchStart,
          content.length,
          quill.LinkAttribute('wiki://$content'),
        );
      }
    }
  }

  void _onStatChange() {
    final newAc = int.tryParse(_acController.text.trim());
    final newHp = int.tryParse(_hpController.text.trim());
    if (newAc != widget.page.ac || newHp != widget.page.hp) {
      if (!_hasChanges) {
        if (mounted) setState(() => _hasChanges = true);
      }
    }
  }

  void _onTitleChange() {
    if (!_hasChanges) {
      if (mounted) setState(() => _hasChanges = true);
    }
  }

  void _addTag(String tag) {
    final clean = tag.trim();
    if (clean.isNotEmpty && !_tags.contains(clean)) {
      setState(() {
        _tags.add(clean);
        _hasChanges = true;
        _tagInputController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
      _hasChanges = true;
    });
  }

  Future<void> _save() async {
    if (!mounted) return;
    await _saveQuietly();
    if (mounted) {
      setState(() => _hasChanges = false);
      try {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Salvo!'),
            duration: Duration(seconds: 1),
          ),
        );
      } catch (_) {}
    }
  }

  void _removeSidebarOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) setState(() => _isToolbarOpen = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.notebookPage,
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
            Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              alignment: Alignment.center,
              child: Column(
                children: [
                  Row(
                    children: [
                      if (widget.showTitle)
                        Expanded(
                          child: TextField(
                            controller: _titleController,
                            textAlign: TextAlign.left,
                            style: GoogleFonts.libreBaskerville(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'Título da Página...',
                              border: InputBorder.none,
                              isDense: true,
                            ),
                          ),
                        ),
                      if (widget.showFormatButton)
                        IconButton(
                          icon: Icon(
                            _isToolbarOpen
                                ? Icons.auto_fix_high
                                : Icons.auto_fix_normal,
                            color: AppColors.accentGold,
                          ),
                          onPressed: _isToolbarOpen
                              ? _removeSidebarOverlay
                              : _showSidebarOverlay,
                          tooltip: 'Encantamentos (Toolbar)',
                        ),
                      if (_hasChanges)
                        IconButton(
                          icon: const Icon(
                            Icons.save,
                            color: AppColors.accentGold,
                          ),
                          tooltip: 'Salvar',
                          onPressed: _save,
                        ),
                    ],
                  ),
                  Container(
                    height: 1,
                    color: AppColors.accentGold.withValues(alpha: 0.3),
                    margin: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  Row(
                    children: [
                      const Icon(
                        Icons.label,
                        size: 16,
                        color: AppColors.textLight,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            ..._tags.map(
                              (tag) => Chip(
                                label: Text(
                                  tag,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                deleteIcon: const Icon(Icons.close, size: 12),
                                onDeleted: () => _removeTag(tag),
                                backgroundColor: AppColors.primaryBlue
                                    .withValues(alpha: 0.1),
                                visualDensity: VisualDensity.compact,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                            SizedBox(
                              width: 100,
                              child: TextField(
                                controller: _tagInputController,
                                decoration: const InputDecoration(
                                  hintText: '+Tag',
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                                style: const TextStyle(fontSize: 12),
                                onSubmitted: _addTag,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Stats Inputs
                      if (widget.showTitle &&
                          (widget.page.tabId == 'people' ||
                              widget.page.tabId == 'monsters')) ...[
                        Container(
                          width: 1,
                          height: 16,
                          color: AppColors.textLight.withValues(alpha: 0.5),
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        SizedBox(
                          width: 40,
                          child: TextField(
                            controller: _acController,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            decoration: const InputDecoration(
                              hintText: 'CA',
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            style: GoogleFonts.libreBaskerville(
                              fontSize: 12,
                              color: AppColors.textDark,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        SizedBox(
                          width: 40,
                          child: TextField(
                            controller: _hpController,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            decoration: const InputDecoration(
                              hintText: 'HP',
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            style: GoogleFonts.libreBaskerville(
                              fontSize: 12,
                              color: AppColors.textDark,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
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
                      fontSize: 16,
                      height: 1.6,
                    ),
                    child: ScrollConfiguration(
                      behavior: ScrollConfiguration.of(context).copyWith(
                        physics: const NeverScrollableScrollPhysics(),
                        scrollbars: false,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(
                          top: 20.0,
                          bottom: 100.0,
                        ),
                        child: quill.QuillEditor(
                          controller: _controller,
                          scrollController: _scrollController,
                          focusNode: _focusNode,

                          // autoFocus: false, // Default
                          // padding: EdgeInsets.zero, // Default
                          // scrollable: true, // Default
                          // onLaunchUrl: ... // Todo: Find correct param for this version
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
          setState(() => position += details.delta);
          widget.onPositionChanged(position);
        },
        child: Material(
          elevation: 12,
          borderRadius: BorderRadius.circular(12),
          color: AppColors.primaryBlue,
          child: Container(
            width: 320,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.accentGold, width: 1.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'ENCANTAMENTOS',
                      style: GoogleFonts.libreBaskerville(
                        color: AppColors.accentGold,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: AppColors.accentGold,
                        size: 18,
                      ),
                      tooltip: 'Fechar Barra',
                      onPressed: widget.onClose,
                    ),
                  ],
                ),
                const Divider(color: AppColors.accentGold),
                Theme(
                  data: ThemeData(
                    canvasColor: AppColors.primaryBlue,
                    iconTheme: const IconThemeData(color: Colors.white),
                  ),
                  child: quill.QuillSimpleToolbar(
                    controller: widget.controller,
                    config: const quill.QuillSimpleToolbarConfig(
                      showClipboardCopy: true,
                      showClipboardPaste: true,
                    ),
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
