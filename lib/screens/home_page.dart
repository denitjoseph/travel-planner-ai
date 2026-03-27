import 'dart:ui';
import 'package:flutter/material.dart';
import '../widgets/navbar.dart';
import '../widgets/hero_section.dart';
import '../widgets/footer.dart';
import '../widgets/splash_cards.dart';
import '../widgets/floating_chat_widget.dart';
import '../widgets/scroll_reveal_widget.dart';
import '../widgets/mouse_glow_widget.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late AnimationController _bgController;
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0;
  double _tiltX = 0;
  double _tiltY = 0;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat(reverse: true);

    _scrollController.addListener(() {
      setState(() {
        _scrollOffset = _scrollController.offset;
      });
    });
  }

  @override
  void dispose() {
    _bgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // 1. FULL SCREEN BACKGROUND IMAGE WITH SLOW ZOOM + PARALLAX + FADE-IN
          Positioned.fill(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(seconds: 2),
              curve: Curves.easeIn,
              builder: (context, opacity, child) {
                return Opacity(
                  opacity: opacity,
                  child: AnimatedBuilder(
                    animation: _bgController,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, -_scrollOffset * 0.4), // Parallax effect
                        child: Transform.scale(
                          scale: 1.1 + (_bgController.value * 0.15), // Enhanced slow zoom
                          child: Image.asset(
                            'assets/luxury_dark_bg.png', // New High Quality Dark BG
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),

          // 2. LIVE LIGHT LEAKS (MOVING LIGHT BEAMS)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _bgController,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      transform: GradientRotation(_bgController.value * 6.28),
                      colors: [
                        Colors.white.withOpacity(0.0),
                        const Color(0xFFD4AF37).withOpacity(0.03),
                        Colors.white.withOpacity(0.0),
                      ],
                      stops: const [0.3, 0.5, 0.7],
                    ),
                  ),
                );
              },
            ),
          ),

          // 3. SOPHISTICATED LUXURY OVERLAY
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.05),
                      Colors.black.withOpacity(0.2),
                      Colors.black.withOpacity(0.5),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 4. MAIN CONTENT WITH CUSTOM SCROLL VIEW
          LayoutBuilder(
            builder: (context, constraints) {
              return MouseRegion(
                onHover: (event) {
                  setState(() {
                    _tiltY = (event.localPosition.dx / constraints.maxWidth - 0.5) * 0.05;
                    _tiltX = (event.localPosition.dy / constraints.maxHeight - 0.5) * -0.05;
                  });
                },
                onExit: (_) => setState(() {
                  _tiltX = 0;
                  _tiltY = 0;
                }),
                child: Transform(
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.0005)
                    ..rotateX(_tiltX)
                    ..rotateY(_tiltY),
                  alignment: FractionalOffset.center,
                  child: CustomScrollView(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      const SliverToBoxAdapter(child: NavBar()),
                      
                      SliverToBoxAdapter(
                        child: ScrollReveal(
                          controller: _scrollController,
                          offset: 100,
                          child: const HeroSection(),
                        ),
                      ),

                      SliverToBoxAdapter(
                        child: ScrollReveal(
                          controller: _scrollController,
                          offset: 80,
                          child: const SplashCards(),
                        ),
                      ),

                      const SliverToBoxAdapter(child: SizedBox(height: 100)),
                      
                      SliverToBoxAdapter(
                        child: ScrollReveal(
                          controller: _scrollController,
                          offset: 40,
                          child: const CustomFooter(),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
          ),

          // 5. FLOATING CHATBOT
          const FloatingChatWidget(),
        ],
      ),
    );
  }
}
