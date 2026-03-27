import 'dart:ui';
import 'package:flutter/material.dart';
import '../widgets/navbar.dart';
import '../widgets/footer.dart';
import '../widgets/floating_chat_widget.dart';
import '../widgets/scroll_reveal_widget.dart';

class CareersPage extends StatefulWidget {
  const CareersPage({super.key});

  @override
  State<CareersPage> createState() => _CareersPageState();
}

class _CareersPageState extends State<CareersPage> {
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
                  'assets/splash4.png', // Premium cityscape for careers
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
                          "JOIN THE ODYSSEY",
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFD4AF37),
                              letterSpacing: 4),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          "Shape the Future of Travel",
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
                            "We are looking for visionaries, creators, and explorers to help us redefine how the world journeys.",
                            style: TextStyle(fontSize: 18, color: Colors.white.withOpacity(0.6), height: 1.5),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // --- VALUES SECTION ---
              SliverToBoxAdapter(
                child: ScrollReveal(
                  controller: _scrollController,
                  offset: 60,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 60),
                    alignment: Alignment.center,
                    child: Wrap(
                      spacing: 30,
                      runSpacing: 30,
                      alignment: WrapAlignment.center,
                      children: [
                        _buildValueCard(Icons.flare, "Innovation", "Pushing the boundaries of what AI can achieve in spatial intelligence."),
                        _buildValueCard(Icons.public, "Global Reach", "Building tools that connect cultures and simplify global exploration."),
                        _buildValueCard(Icons.diamond_outlined, "Excellence", "A commitment to luxury, precision, and world-class design."),
                      ],
                    ),
                  ),
                ),
              ),

              // --- OPEN ROLES SECTION ---
              SliverToBoxAdapter(
                child: ScrollReveal(
                  controller: _scrollController,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 20),
                    child: Column(
                      children: [
                        const Text(
                          "CURATED OPPORTUNITIES",
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFD4AF37),
                              letterSpacing: 4),
                        ),
                        const SizedBox(height: 40),
                        _buildRoleItem("Principal AI Architect", "Remote / Zurich", "Lead the development of our next-gen travel reasoning engine."),
                        _buildRoleItem("Senior Product Designer", "Remote / London", "Craft the premium visual language of the Odyssey ecosystem."),
                        _buildRoleItem("Global Strategy Lead", "New York / Dubai", "Expand Odyssey's reaches into new global frontier markets."),
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

  Widget _buildValueCard(IconData icon, String title, String desc) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            children: [
              Icon(icon, size: 40, color: const Color(0xFFD4AF37)),
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
        ),
      ),
    );
  }

  Widget _buildRoleItem(String title, String location, String desc) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 800),
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 8),
                Text(location, style: const TextStyle(fontSize: 14, color: Color(0xFFD4AF37), fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Text(desc, style: TextStyle(color: Colors.white.withOpacity(0.5))),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4AF37).withOpacity(0.1),
              foregroundColor: const Color(0xFFD4AF37),
              side: const BorderSide(color: Color(0xFFD4AF37), width: 0.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text("APPLY"),
          ),
        ],
      ),
    );
  }
}
