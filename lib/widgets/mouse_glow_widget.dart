import 'package:flutter/material.dart';

class MouseGlowEffect extends StatefulWidget {
  final Widget child;
  const MouseGlowEffect({super.key, required this.child});

  @override
  State<MouseGlowEffect> createState() => _MouseGlowEffectState();
}

class _MouseGlowEffectState extends State<MouseGlowEffect> with SingleTickerProviderStateMixin {
  Offset _mousePos = Offset.zero;
  late AnimationController _breathingController;
  late Animation<double> _edgeOpacity;

  @override
  void initState() {
    super.initState();
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    
    _edgeOpacity = Tween<double>(begin: 0.1, end: 0.4).animate(
      CurvedAnimation(parent: _breathingController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _breathingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: (event) {
        setState(() {
          _mousePos = event.localPosition;
        });
      },
      child: Stack(
        children: [
          // The actual content
          widget.child,

          // Mouse Glow Layer
          IgnorePointer(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 50),
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(
                    (_mousePos.dx / MediaQuery.of(context).size.width) * 2 - 1,
                    (_mousePos.dy / MediaQuery.of(context).size.height) * 2 - 1,
                  ),
                  radius: 0.5,
                  colors: [
                    const Color(0xFFD4AF37).withOpacity(0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Glow Edges
          IgnorePointer(
            child: AnimatedBuilder(
              animation: _edgeOpacity,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color(0xFFD4AF37).withOpacity(_edgeOpacity.value),
                      width: 2.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFD4AF37).withOpacity(_edgeOpacity.value * 0.5),
                        blurRadius: 60,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
