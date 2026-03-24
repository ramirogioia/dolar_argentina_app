import 'package:flutter/material.dart';

/// Barra superior con brillo sutil animado para cards.
class ShimmerTopBar extends StatefulWidget {
  final Color color;
  final double height;

  const ShimmerTopBar({super.key, required this.color, this.height = 4});

  @override
  State<ShimmerTopBar> createState() => _ShimmerTopBarState();
}

class _ShimmerTopBarState extends State<ShimmerTopBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2800),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(color: widget.color),
          AnimatedBuilder(
            animation: _animation,
            builder: (context, _) {
              return Align(
                alignment: Alignment(_animation.value * 2 - 1, 0),
                child: Container(
                  width: 80,
                  height: widget.height,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.white.withOpacity(0.25),
                        Colors.white.withOpacity(0.4),
                        Colors.white.withOpacity(0.25),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
