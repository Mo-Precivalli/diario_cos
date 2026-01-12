import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:diario_mestre/providers/book_navigation_provider.dart';
import 'package:diario_mestre/providers/notification_provider.dart';
import 'package:diario_mestre/providers/library_provider.dart';
import '../widgets/book_cover.dart'; // Import da capa
import 'package:diario_mestre/features/notebook/screens/notebook_view.dart';
import 'package:diario_mestre/core/theme/colors.dart';

import 'dart:math';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  // bool _isBookOpen = false; // Moved to Provider

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    // Inicializar o provider após o primeiro frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<LibraryProvider>(context, listen: false).initialize();
      // Sync initial state if needed, or listener
      final nav = Provider.of<BookNavigationProvider>(context, listen: false);
      nav.addListener(_onBookStateChanged);

      final notif = Provider.of<NotificationProvider>(context, listen: false);
      notif.addListener(_onNotification);
    });
  }

  @override
  void dispose() {
    // Remove listener if we had a reference, but context might be unsafe.
    // Usually fine for singleton providers or we rely on cleaning up structure.
    // Ideally we'd keep a reference to 'nav' to remove listener.
    _controller.dispose();
    super.dispose();
  }

  void _onBookStateChanged() {
    if (!mounted) return;
    final isOpen = Provider.of<BookNavigationProvider>(
      context,
      listen: false,
    ).isBookOpen;
    if (isOpen &&
        _controller.status != AnimationStatus.completed &&
        _controller.status != AnimationStatus.forward) {
      _controller.forward();
    } else if (!isOpen &&
        _controller.status != AnimationStatus.dismissed &&
        _controller.status != AnimationStatus.reverse) {
      _controller.reverse();
    }
  }

  void _onNotification() {
    if (!mounted) return;
    final provider = Provider.of<NotificationProvider>(context, listen: false);
    final msg = provider.latestMessage;
    if (msg != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            msg.message,
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: msg.isError ? Colors.redAccent : Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      provider.clear();
    }
  }

  void _openBook() {
    Provider.of<BookNavigationProvider>(context, listen: false).openBook();
  }

  void _closeBook() {
    Provider.of<BookNavigationProvider>(context, listen: false).closeBook();
  }

  @override
  Widget build(BuildContext context) {
    // Controller is driven by AnimatedBuilder below.

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.menu_book, color: AppColors.accentGold, size: 28),
            const SizedBox(width: 12),
            Text(
              'Diário do Mestre',
              style: GoogleFonts.libreBaskerville(
                color: AppColors.accentGold,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.background.withValues(
          alpha: 0.8,
        ), // AppBar combina com a mesa
        elevation: 0,
        actions: [
          // Watch provider for UI updates
          Consumer<BookNavigationProvider>(
            builder: (context, nav, child) {
              if (!nav.isBookOpen) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.close, color: AppColors.accentGold),
                onPressed: _closeBook,
                tooltip: 'Fechar Livro',
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.search, color: AppColors.accentGold),
            onPressed: () {},
            tooltip: 'Buscar',
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: AppColors.accentGold),
            onPressed: () {},
            tooltip: 'Configurações',
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Calcula o tamanho base do livro de acordo com a tela
          // Queremos que o livro fechado seja metade do aberto.
          final bookHeight = constraints.maxHeight * 0.85;
          final bookWidthOpen =
              constraints.maxWidth * 0.9; // Largura total aberto
          final bookWidthClosed = bookWidthOpen / 2;

          return Stack(
            children: [
              // Padrão de fundo (Patinhas)
              Positioned.fill(
                child: Opacity(
                  opacity: 0.05,
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 8,
                        ),
                    itemBuilder: (context, index) =>
                        const Icon(Icons.pets, size: 40, color: Colors.white),
                  ),
                ),
              ),

              // Conteúdo Principal (Capa ou Livro Aberto)
              Positioned.fill(
                child: Center(
                  child: SizedBox(
                    width: bookWidthOpen,
                    height: bookHeight,
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        // Apply Curve here
                        final double animValue = Curves.easeInOutCubicEmphasized
                            .transform(_controller.value);

                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            // --- METADE DIREITA (Base) ---
                            // Página Direita do Livro
                            Positioned(
                              right: 0,
                              width: bookWidthClosed,
                              height: bookHeight,
                              child: ClipRect(
                                child: Stack(
                                  children: [
                                    Positioned(
                                      right: 0,
                                      width: bookWidthOpen, // Largura total
                                      height: bookHeight,
                                      child: const NotebookView(),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // --- METADE ESQUERDA / CAPA (Móvel) ---
                            // Página Esquerda do Livro (Verso da Capa)
                            Positioned(
                              right: 0,
                              width: bookWidthClosed,
                              height: bookHeight,
                              child: Transform(
                                transform: Matrix4.identity()
                                  ..setEntry(
                                    3,
                                    2,
                                    -0.0005,
                                  ) // Perspectiva Negativa (2000px)
                                  ..rotateY(
                                    -(animValue * pi),
                                  ), // -180 graus (pi)
                                alignment:
                                    Alignment.centerLeft, // Pivô na lombada
                                child: (animValue * pi) < (pi / 2)
                                    ? BookCoverView(onOpen: _openBook)
                                    : Transform(
                                        alignment: Alignment.center,
                                        transform: Matrix4.identity()
                                          ..rotateY(
                                            -pi,
                                          ), // Desvira para conteúdo
                                        child: ClipRect(
                                          child: Stack(
                                            children: [
                                              Positioned(
                                                left: 0,
                                                width:
                                                    bookWidthOpen, // Largura total
                                                height: bookHeight,
                                                child: const NotebookView(),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
