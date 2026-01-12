import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:diario_mestre/core/theme/colors.dart';
import 'package:diario_mestre/core/constants/app_layout.dart';

class BookCoverView extends StatefulWidget {
  final VoidCallback onOpen;

  const BookCoverView({super.key, required this.onOpen});

  @override
  State<BookCoverView> createState() => _BookCoverViewState();
}

class _BookCoverViewState extends State<BookCoverView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: MouseRegion(
        onEnter: (_) => _controller.forward(),
        onExit: (_) => _controller.reverse(),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onOpen,
          child: AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: child,
              );
            },
            child: Container(
              // Dimensoes removidas para layout responsivo
              decoration: BoxDecoration(
                color: AppColors.notebookFrame, // Blue/Slate base
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(AppLayout.bookBorderRadius),
                  bottomRight: Radius.circular(AppLayout.bookBorderRadius),
                  topLeft: Radius.circular(4), // Spine side
                  bottomLeft: Radius.circular(4), // Spine side
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 30,
                    offset: const Offset(10, 15),
                  ),
                ],
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Color.lerp(
                      AppColors.notebookFrame,
                      Colors.black,
                      0.2,
                    )!, // Darker spine
                    AppColors.notebookFrame,
                    Color.lerp(
                      AppColors.notebookFrame,
                      Colors.black,
                      0.1,
                    )!, // Slightly dark edge
                  ],
                  stops: const [0.0, 0.15, 1.0],
                ),
              ),
              child: Stack(
                children: [
                  // Spine Indentation (Left side)
                  Positioned(
                    left: 20,
                    top: 0,
                    bottom: 0,
                    width: 2,
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.2),
                    ),
                  ),

                  // Decorative Border
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.all(AppLayout.coverPadding),
                      child: Stack(
                        children: [
                          // Sombra/Borda preta de fundo (Outline)
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.black.withValues(alpha: 0.5),
                                width: 3, // 1px maior que o dourado (2px)
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          // Borda Dourada Principal
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: AppColors.accentGold, // Goldish
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            // Inner Border (Borda interna)
                            child: Container(
                              margin: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: AppColors.accentGold,
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Corner Ornaments (Paws)
                  _buildCornerPaw(top: 40, left: 40),
                  _buildCornerPaw(top: 40, right: 40),
                  _buildCornerPaw(bottom: 40, left: 40),
                  _buildCornerPaw(bottom: 40, right: 40),

                  // Center Content
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Main Icon
                        Stack(
                          children: [
                            // Outline Preto (Simulado com sombra forte)
                            Icon(
                              Icons.pets,
                              size: AppLayout.coverIconSize,
                              color: Colors
                                  .transparent, // Transparente, só a sombra aparece
                              shadows: [
                                Shadow(
                                  offset: const Offset(1, 1),
                                  color: Colors.black.withValues(alpha: 0.8),
                                  blurRadius: 1,
                                ),
                                Shadow(
                                  offset: const Offset(-1, 1),
                                  color: Colors.black.withValues(alpha: 0.8),
                                  blurRadius: 1,
                                ),
                                Shadow(
                                  offset: const Offset(1, -1),
                                  color: Colors.black.withValues(alpha: 0.8),
                                  blurRadius: 1,
                                ),
                                Shadow(
                                  offset: const Offset(-1, -1),
                                  color: Colors.black.withValues(alpha: 0.8),
                                  blurRadius: 1,
                                ),
                              ],
                            ),
                            // Ícone Dourado
                            const Icon(
                              Icons.pets,
                              size: AppLayout.coverIconSize,
                              color: AppColors.accentGold,
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),
                        // Title
                        Text(
                          'Diário do Mestre',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.libreBaskerville(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: AppColors.accentGold,
                            letterSpacing: 1.5,
                            shadows: [
                              // Outline simples usando shadows
                              Shadow(
                                offset: const Offset(1.5, 1.5),
                                color: Colors.black.withValues(alpha: 0.6),
                                blurRadius: 0,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Tome of the Cat',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.lato(
                            fontSize: 18,
                            color: const Color(
                              0xFFD4AF37,
                            ).withValues(alpha: 0.9),
                            letterSpacing: 2.0,
                            shadows: [
                              Shadow(
                                offset: const Offset(1, 1),
                                color: Colors.black.withValues(alpha: 0.6),
                                blurRadius: 0,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCornerPaw({
    double? top,
    double? bottom,
    double? left,
    double? right,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Icon(
        Icons.pets,
        size: 24,
        color: AppColors.accentGold.withValues(alpha: 0.6),
        shadows: [
          Shadow(
            offset: const Offset(0.5, 0.5),
            blurRadius: 0,
            color: Colors.black.withValues(alpha: 0.6),
          ),
        ],
      ),
    );
  }
}
