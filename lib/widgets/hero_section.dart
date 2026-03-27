import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../screens/plan_trip_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/login_page.dart';

class HeroSection extends StatefulWidget {
  const HeroSection({super.key});

  @override
  State<HeroSection> createState() => _HeroSectionState();
}

class _HeroSectionState extends State<HeroSection> with TickerProviderStateMixin {
  late AnimationController _textController;
  late AnimationController _imageController;
  late AnimationController _infiniteFloatController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late AnimationController _sweepController;

  double _tiltX = 0;
  double _tiltY = 0;

  int _currentDestinationIndex = 0;
  late Timer _destinationTimer;

  final List<Map<String, String>> _destinations = [
    {
      'name': 'Amalfi Coast, Italy',
      'image': 'https://images.unsplash.com/photo-1533105079780-92b9be482077?ixlib=rb-4.0.3&auto=format&fit=crop&w=1200&q=80',
    },
    {
      'name': 'Santorini, Greece',
      'image': 'https://images.unsplash.com/photo-1570077188670-e3a8d69ac5ff?ixlib=rb-4.0.3&auto=format&fit=crop&w=1200&q=80',
    },
    {
      'name': 'Kyoto, Japan',
      'image': 'https://images.unsplash.com/photo-1493976040374-85c8e12f0c0e?ixlib=rb-4.0.3&auto=format&fit=crop&w=1200&q=80',
    },
    {
      'name': 'Swiss Alps, Switzerland',
      'image': 'https://images.unsplash.com/photo-1531219432768-9f540ce91ef3?ixlib=rb-4.0.3&auto=format&fit=crop&w=1200&q=80',
    },
    {
      'name': 'Maldives Islands',
      'image': 'https://images.unsplash.com/photo-1514282401047-d79a71a590e8?ixlib=rb-4.0.3&auto=format&fit=crop&w=1200&q=80',
    },
  ];

  @override
  void initState() {
    super.initState();
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _imageController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _infiniteFloatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOutQuart),
    );

    _textController.forward();
    _imageController.forward();

    _sweepController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _destinationTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        setState(() {
          _currentDestinationIndex = (_currentDestinationIndex + 1) % _destinations.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _destinationTimer.cancel();
    _textController.dispose();
    _imageController.dispose();
    _infiniteFloatController.dispose();
    _sweepController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isDesktop = constraints.maxWidth > 950;

        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 100 : 25,
            vertical: isDesktop ? 120 : 60,
          ),
          child: isDesktop
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 6,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: _buildTextContent(context),
                        ),
                      ),
                    ),
                    const SizedBox(width: 60),
                    Expanded(
                      flex: 5,
                      child: ScaleTransition(
                        scale: CurvedAnimation(
                          parent: _imageController,
                          curve: Curves.elasticOut,
                        ),
                        child: _buildImageCard(),
                      ),
                    ),
                  ],
                )
              : Column(
                  children: [
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: _buildTextContent(context),
                      ),
                    ),
                    const SizedBox(height: 60),
                    ScaleTransition(
                      scale: CurvedAnimation(
                        parent: _imageController,
                        curve: Curves.elasticOut,
                      ),
                      child: _buildImageCard(),
                    ),
                  ],
                ),
        );
      },
    );
  }

  // 1. LEFT SIDE: Text & Button
  Widget _buildTextContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Staggered Entrance: 1. Pill Tag
        _buildStaggeredEntrance(
          delay: 0.1,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.15),
                  Colors.white.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(50),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.auto_awesome, color: Color(0xFFD4AF37), size: 14),
                const SizedBox(width: 8),
                Text(
                  "NOW POWERED BY GPT-4O",
                  style: GoogleFonts.montserrat(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 35),
        
        // Staggered Entrance: 2. Headline
        _buildStaggeredEntrance(
          delay: 0.2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Explore the World",
                style: GoogleFonts.bodoniModa(
                  fontSize: 72,
                  fontWeight: FontWeight.w900,
                  height: 1.0,
                  color: Colors.white,
                  letterSpacing: -2,
                ),
              ),
              AnimatedBuilder(
                animation: _sweepController,
                builder: (context, child) {
                  return ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: const [
                        Color(0xFFD4AF37),
                        Color(0xFFFBEBB5),
                        Colors.white,
                        Color(0xFFFBEBB5),
                        Color(0xFFD4AF37),
                      ],
                      stops: [
                        0.0,
                        (_sweepController.value - 0.2).clamp(0.0, 1.0),
                        _sweepController.value,
                        (_sweepController.value + 0.2).clamp(0.0, 1.0),
                        1.0,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(bounds),
                    child: child,
                  );
                },
                child: Text(
                  "at Your Own Pace",
                  style: GoogleFonts.bodoniModa(
                    fontSize: 72,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                    color: Colors.white,
                    letterSpacing: -1,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.3),
                        offset: const Offset(0, 10),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 35),

        // Staggered Entrance: 3. Subtext
        _buildStaggeredEntrance(
          delay: 0.3,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.1),
                      Colors.white.withOpacity(0.02),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Text(
                  "Crafting extraordinary journeys through intelligent exploration. Every destination becomes a masterfully curated experience with Odyssey.",
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    color: Colors.white.withOpacity(0.8),
                    height: 1.6,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 50),

        // Staggered Entrance: 4. Buttons
        _buildStaggeredEntrance(
          delay: 0.4,
          child: Row(
            children: [
              _buildPrimaryButton(context),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStaggeredEntrance({required double delay, required Widget child}) {
    return AnimatedBuilder(
      animation: _textController,
      builder: (context, child) {
        final animationValue = CurvedAnimation(
          parent: _textController,
          curve: Interval(delay, delay + 0.6, curve: Curves.easeOutQuart),
        ).value;

        return Opacity(
          opacity: animationValue.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: 0.95 + (0.05 * animationValue),
            child: Transform.translate(
              offset: Offset(0, 30 * (1 - animationValue)),
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(
                  sigmaX: (1 - animationValue) * 10,
                  sigmaY: (1 - animationValue) * 10,
                ),
                child: child,
              ),
            ),
          ),
        );
      },
      child: child,
    );
  }

  Widget _buildPrimaryButton(BuildContext context) {
    return _LuxuryButton(
      onPressed: () {
        if (FirebaseAuth.instance.currentUser == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Join Odyssey to start planning!"),
              backgroundColor: Color(0xFFD4AF37),
            ),
          );
          Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginPage()));
          return;
        }
        Navigator.push(context, MaterialPageRoute(builder: (context) => const PlanTripPage()));
      },
      text: "BEGIN YOUR ODYSSEY",
    );
  }

  Widget _buildImageCard() {
    final currentDest = _destinations[_currentDestinationIndex];

    return MouseRegion(
      onHover: (event) {
        setState(() {
          _tiltY = (event.localPosition.dx / 500 - 0.5) * 0.15;
          _tiltX = (event.localPosition.dy / 500 - 0.5) * -0.15;
        });
      },
      onExit: (_) => setState(() {
        _tiltX = 0;
        _tiltY = 0;
      }),
      child: AnimatedRotation(
        turns: 0,
        duration: const Duration(milliseconds: 200),
        child: Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateX(_tiltX)
            ..rotateY(_tiltY),
          alignment: FractionalOffset.center,
          child: AnimatedBuilder(
            animation: _imageController,
            builder: (context, child) {
              double floatingOffset =
                  5 * (1 - CurvedAnimation(parent: _imageController, curve: Curves.easeInOut).value);
              return AnimatedBuilder(
                animation: _infiniteFloatController,
                builder: (context, child) {
                  double floatingOffset = 15 * _infiniteFloatController.value - 7.5;
                  double tiltRotation = 0.01 * _infiniteFloatController.value - 0.005;
                  return Transform.translate(
                    offset: Offset(0, floatingOffset),
                    child: Transform.rotate(
                      angle: tiltRotation,
                      child: child,
                    ),
                  );
                },
                child: child!,
              );
            },
            child: Container(
              height: 550,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(40),
                border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 40,
                    spreadRadius: -10,
                    offset: const Offset(0, 30),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(40),
                child: AnimatedSwitcher(
                  duration: const Duration(seconds: 1),
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(
                        scale: Tween<double>(begin: 1.1, end: 1.0).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: Stack(
                    key: ValueKey<int>(_currentDestinationIndex),
                    children: [
                      Image.network(
                        currentDest['image']!,
                        height: double.infinity,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                      // Glassy Border Gradient
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.1),
                              Colors.black.withOpacity(0.8),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 40,
                        left: 40,
                        right: 40,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              padding: const EdgeInsets.all(25),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white.withOpacity(0.2)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "FEATURED FRONTIER",
                                    style: GoogleFonts.montserrat(
                                      color: const Color(0xFFD4AF37),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 4,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    currentDest['name']!,
                                    style: GoogleFonts.bodoniModa(
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LuxuryButton extends StatefulWidget {
  final VoidCallback onPressed;
  final String text;
  const _LuxuryButton({required this.onPressed, required this.text});

  @override
  State<_LuxuryButton> createState() => _LuxuryButtonState();
}

class _LuxuryButtonState extends State<_LuxuryButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity()..scale(_isHovered ? 1.05 : 1.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFD4AF37).withOpacity(_isHovered ? 0.5 : 0.3),
              blurRadius: _isHovered ? 30 : 20,
              spreadRadius: _isHovered ? 5 : 0,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: widget.onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFD4AF37),
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 45, vertical: 25),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            elevation: 0,
          ),
          child: Shimmer.fromColors(
            baseColor: Colors.black,
            highlightColor: Colors.white.withOpacity(0.6),
            period: const Duration(seconds: 2),
            child: Text(
              widget.text,
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 3,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
