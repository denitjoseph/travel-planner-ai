import 'dart:ui';
import 'package:flutter/material.dart';
import '../screens/destination_detail_page.dart';

class SplashCards extends StatelessWidget {
  const SplashCards({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> categories = [
      {
        "title": "Skydiving",
        "location": "Dubai, UAE",
        "image": "assets/splash1.png",
        "tag": "Adventure"
      },
      {
        "title": "Swiss Express",
        "location": "Alps, Switzerland",
        "image": "assets/splash2.png",
        "tag": "Luxury"
      },
      {
        "title": "City Lights",
        "location": "Tokyo, Japan",
        "image": "assets/splash3.png",
        "tag": "Culture"
      },
      {
        "title": "Skyline",
        "location": "Dubai, UAE",
        "image": "assets/splash4.png",
        "tag": "Urban"
      },
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Curated Collections",
                  style: TextStyle(
                    color: Color(0xFFD4AF37),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 15),
                const Text(
                  "Trending Experiences",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 50),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 100, vertical: 20),
            child: Row(
              children: categories.map((cat) => _SplashCard(cat: cat)).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _SplashCard extends StatefulWidget {
  final Map<String, String> cat;
  const _SplashCard({required this.cat});

  @override
  State<_SplashCard> createState() => _SplashCardState();
}

class _SplashCardState extends State<_SplashCard> with TickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _fadeController;
  late AnimationController _infiniteFloatController;
  late Animation<double> _fadeAnimation;
  
  double _tiltX = 0;
  double _tiltY = 0;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _infiniteFloatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _infiniteFloatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() {
        _isHovered = false;
        _tiltX = 0;
        _tiltY = 0;
      }),
      onHover: (event) {
        setState(() {
          _tiltY = (event.localPosition.dx / 320 - 0.5) * 0.1;
          _tiltX = (event.localPosition.dy / 450 - 0.5) * -0.1;
        });
      },
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DestinationDetailPage(destination: widget.cat),
            ),
          );
        },
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: AnimatedBuilder(
            animation: _infiniteFloatController,
            builder: (context, child) {
              double offset = 10 * _infiniteFloatController.value - 5;
              double rotation = 0.005 * _infiniteFloatController.value - 0.0025;
              
              return Transform.translate(
                offset: Offset(0, offset),
                child: Transform.rotate(
                  angle: rotation,
                  child: Transform(
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateX(_tiltX)
                      ..rotateY(_tiltY),
                    alignment: FractionalOffset.center,
                    child: child,
                  ),
                ),
              );
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.only(right: 30),
              width: 320,
              height: 450,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(_isHovered ? 0.5 : 0.2),
                    blurRadius: _isHovered ? 40 : 20,
                    offset: Offset(0, _isHovered ? 20 : 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: Stack(
                  children: [
                    // Background Image
                    AnimatedScale(
                      scale: _isHovered ? 1.15 : 1.0,
                      duration: const Duration(seconds: 2),
                      curve: Curves.easeOutCubic,
                      child: Hero(
                        tag: 'card_image_${widget.cat['title']}',
                        child: Image.asset(
                          widget.cat['image']!,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  
                  // Gradient Overlay
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

                  // Glassy Tag
                  Positioned(
                    top: 25,
                    right: 25,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          color: Colors.white.withOpacity(0.1),
                          child: Text(
                            widget.cat['tag']!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Content
                  Positioned(
                    bottom: 30,
                    left: 30,
                    right: 30,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Hero(
                          tag: 'card_location_${widget.cat['title']}',
                          child: Material(
                            color: Colors.transparent,
                            child: Text(
                              widget.cat['location']!,
                              style: const TextStyle(
                                color: Color(0xFFD4AF37),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Hero(
                          tag: 'card_title_${widget.cat['title']}',
                          child: Material(
                            color: Colors.transparent,
                            child: Text(
                              widget.cat['title']!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          height: _isHovered ? 60 : 0,
                          child: SingleChildScrollView(
                            physics: const NeverScrollableScrollPhysics(),
                            child: Column(
                              children: [
                                const SizedBox(height: 15),
                                Text(
                                  "Plan your next journey to ${widget.cat['location']} with Odyssey AI.",
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
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
    ),
  );
}
}
