import 'package:flutter/material.dart';
import '../theme/colors.dart';

class PageCornerButton extends StatefulWidget {
  final bool isLeft;
  final VoidCallback onTap;
  final bool visible;

  const PageCornerButton({
    super.key,
    required this.isLeft,
    required this.onTap,
    required this.visible,
  });

  @override
  State<PageCornerButton> createState() => _PageCornerButtonState();
}

class _PageCornerButtonState extends State<PageCornerButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _curlAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _curlAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.visible) return const SizedBox.shrink();

    return MouseRegion(
      onEnter: (_) => _controller.forward(),
      onExit: (_) => _controller.reverse(),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _curlAnimation,
          builder: (context, child) {
            return CustomPaint(
              painter: _PageCornerPainter(
                isLeft: widget.isLeft,
                curlProgress: _curlAnimation.value,
                color: AppColors.notebookPage,
                curlColor: Colors.white.withOpacity(
                  0.9,
                ), // Cor da parte de trás da folha
              ),
              size: const Size(60, 60), // Tamanho da área clicável
              child: Container(
                width: 60,
                height: 60,
                alignment: widget.isLeft
                    ? Alignment.bottomLeft
                    : Alignment.bottomRight,
                padding: const EdgeInsets.all(12),
                // Exibe a seta apenas se o curl estiver baixo (opcional, ou sempre)
                child: Opacity(
                  opacity: 1.0 - _curlAnimation.value,
                  child: Icon(
                    widget.isLeft
                        ? Icons.keyboard_arrow_left
                        : Icons.keyboard_arrow_right,
                    color: AppColors.textLight.withOpacity(0.5),
                    size: 24,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PageCornerPainter extends CustomPainter {
  final bool isLeft;
  final double curlProgress;
  final Color color;
  final Color curlColor;

  _PageCornerPainter({
    required this.isLeft,
    required this.curlProgress,
    required this.color,
    required this.curlColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (curlProgress == 0) return;

    final paint = Paint()
      ..color = curlColor
      ..style = PaintingStyle.fill;

    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.2 * curlProgress)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    double curlSize = size.width * curlProgress;

    // Lógica para desenhar o triângulo dobrado
    // Se isLeft: Canto Inferior Esquerdo (Bottom Left)
    // Se !isLeft: Canto Inferior Direito (Bottom Right)

    Path curlPath = Path();

    if (isLeft) {
      // Canto Inferior Esquerdo
      // Começa no canto inferior esquerdo (0, height)
      // Vai para cima (0, height - curlSize)
      // Vai para direita (curlSize, height)
      // Fecha

      // Ajuste para parecer "dobrado":
      // O triângulo "buraco" (onde a folha saiu) ficaria transparente se fosse recortado,
      // mas aqui estamos desenhando a "aba" por cima.

      // Desenhando a aba dobrada (Back face of the page)
      curlPath.moveTo(0, size.height - curlSize);
      curlPath.lineTo(
        curlSize,
        size.height - curlSize,
      ); // Ponto de dobra superior
      curlPath.lineTo(curlSize, size.height);
      curlPath.close();

      // Sombra embaixo da dobra
      canvas.drawPath(curlPath, shadowPaint);
      canvas.drawPath(curlPath, paint);

      // Linha de dobra (opcional)
      final borderPaint = Paint()
        ..color = Colors.black12
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      canvas.drawPath(curlPath, borderPaint);
    } else {
      // Canto Inferior Direito
      // (width, height - curlSize)
      // (width - curlSize, height - curlSize)
      // (width - curlSize, height)

      curlPath.moveTo(size.width, size.height - curlSize);
      curlPath.lineTo(size.width - curlSize, size.height - curlSize);
      curlPath.lineTo(size.width - curlSize, size.height);
      curlPath.close();

      canvas.drawPath(curlPath, shadowPaint);
      canvas.drawPath(curlPath, paint);

      final borderPaint = Paint()
        ..color = Colors.black12
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      canvas.drawPath(curlPath, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _PageCornerPainter oldDelegate) {
    return oldDelegate.curlProgress != curlProgress ||
        oldDelegate.isLeft != isLeft;
  }
}
