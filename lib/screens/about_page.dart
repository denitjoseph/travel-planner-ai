import 'dart:ui';
import 'package:flutter/material.dart';
import '../widgets/navbar.dart';
import '../widgets/footer.dart';
import '../widgets/floating_chat_widget.dart';
import '../widgets/scroll_reveal_widget.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      setState(() {
        _scrollOffset = _scrollController.offset;
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Background Parallax
          Positioned.fill(
            child: Opacity(
              opacity: 0.5,
              child: Transform.translate(
                offset: Offset(0, -_scrollOffset * 0.2),
                child: Image.asset(
                  'assets/plan_hero_bg.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.8),
                    Colors.black.withOpacity(0.4),
                    Colors.black.withOpacity(0.9),
                  ],
                ),
              ),
            ),
          ),

          // 2. Main Content
          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              const SliverToBoxAdapter(child: NavBar()),

              // --- HERO SECTION ---
              SliverToBoxAdapter(
                child: ScrollReveal(
                  controller: _scrollController,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 120, horizontal: 20),
                    child: Column(
                      children: [
                        const Text(
                          "ABOUT ODYSSEY",
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFD4AF37),
                              letterSpacing: 4),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          "The Art of Intelligent Exploration",
                          style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -1),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 25),
                        Container(
                          constraints: const BoxConstraints(maxWidth: 600),
                          child: Text(
                            "Your personal AI-powered travel companion for the modern era.",
                            style: TextStyle(fontSize: 18, color: Colors.white.withOpacity(0.6), height: 1.5),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // --- MISSION SECTION ---
              SliverToBoxAdapter(
                child: ScrollReveal(
                  controller: _scrollController,
                  offset: 60,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 60),
                    alignment: Alignment.center,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 800),
                          padding: const EdgeInsets.all(40),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.03),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: Colors.white.withOpacity(0.1)),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                "Our Mission",
                                style: TextStyle(
                                    fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white),
                              ),
                              const SizedBox(height: 30),
                              Text(
                                "Odyssey was built to solve the frustration of hours spent planning trips. "
                                "We use advanced Artificial Intelligence to instantly create personalized, "
                                "day-by-day itineraries that fit your style, budget, and interests. "
                                "Explore the world smarter, not harder.",
                                style: TextStyle(
                                    fontSize: 18, height: 1.8, color: Colors.white.withOpacity(0.7)),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // --- FEATURES GRID ---
              SliverPadding(
                padding: const EdgeInsets.symmetric(vertical: 80),
                sliver: SliverToBoxAdapter(
                  child: ScrollReveal(
                    controller: _scrollController,
                    child: Wrap(
                      spacing: 30,
                      runSpacing: 30,
                      alignment: WrapAlignment.center,
                      children: [
                        _buildFeatureCard(Icons.auto_awesome, "AI Itineraries",
                            "Get complete day-by-day plans generated in seconds."),
                        _buildFeatureCard(Icons.attach_money, "Smart Budgeting",
                            "Visual breakdowns of your estimated travel costs."),
                        _buildFeatureCard(Icons.map_outlined, "Place Explorer",
                            "Discover hidden gems with integrated maps & details."),
                      ],
                    ),
                  ),
                ),
              ),

              // --- TECH STACK SECTION ---
              SliverToBoxAdapter(
                child: ScrollReveal(
                  controller: _scrollController,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFD4AF37).withOpacity(0.1),
                          Colors.transparent,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Column(
                      children: [
                        const Text("Built With Modern Tech",
                            style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: Colors.white)),
                        const SizedBox(height: 40),
                        Wrap(
                          spacing: 20,
                          runSpacing: 20,
                          alignment: WrapAlignment.center,
                          children: [
                            _buildTechBadge("Flutter Web"),
                            _buildTechBadge("Python Flask"),
                            _buildTechBadge("GPT-4o AI"),
                            _buildTechBadge("Google Maps"),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
              const SliverToBoxAdapter(child: CustomFooter()),
            ],
          ),

          // 3. Floating Chatbot
          const FloatingChatWidget(),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(IconData icon, String title, String desc) {
    return Container(
      width: 320,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: const Color(0xFFD4AF37)),
          const SizedBox(height: 25),
          Text(title,
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
          const SizedBox(height: 15),
          Text(desc,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withOpacity(0.6), height: 1.6, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildTechBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFD4AF37).withOpacity(0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3)),
      ),
      child: Text(label,
          style: const TextStyle(
              color: Color(0xFFD4AF37), fontWeight: FontWeight.bold, letterSpacing: 1, fontSize: 14)),
    );
  }
}
