import 'dart:ui';
import 'package:flutter/material.dart';
import '../widgets/navbar.dart';
import '../widgets/footer.dart';
import '../widgets/floating_chat_widget.dart';
import '../widgets/scroll_reveal_widget.dart';

class PrivacyPolicyPage extends StatefulWidget {
  const PrivacyPolicyPage({super.key});

  @override
  State<PrivacyPolicyPage> createState() => _PrivacyPolicyPageState();
}

class _PrivacyPolicyPageState extends State<PrivacyPolicyPage> {
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
              opacity: 0.4,
              child: Transform.translate(
                offset: Offset(0, -_scrollOffset * 0.15),
                child: Image.asset(
                  'assets/plan_bg_4.png', // Premium abstract/security feel
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
                    Colors.black.withOpacity(0.9),
                    Colors.black.withOpacity(0.6),
                    Colors.black,
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
                    padding: const EdgeInsets.symmetric(vertical: 100, horizontal: 20),
                    child: Column(
                      children: [
                        const Text(
                          "LEGAL & PRIVACY",
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFD4AF37),
                              letterSpacing: 4),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          "Your Trust is Our Foundation",
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
                            "Transparent, secure, and privacy-first protocols for the modern explorer.",
                            style: TextStyle(fontSize: 18, color: Colors.white.withOpacity(0.6), height: 1.5),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // --- POLICIES SECTION ---
              SliverToBoxAdapter(
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 900),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                    child: Column(
                      children: [
                        _buildPolicySection("1. Vision for Privacy", 
                          "At Odyssey, we believe that true luxury is impossible without complete privacy. We are committed to protecting the sanctity of your travel data and personal preferences."),
                        _buildPolicySection("2. Data Collection & Intelligence", 
                          "We collect data specifically to enhance your AI travel assistant's reasoning. This includes location markers, budget preferences, and preferred experiences. We never sell your data to third-party travel agencies."),
                        _buildPolicySection("3. AI Protocol Transparency", 
                          "Our GPT-powered models process your requests to generate itineraries. Your personal identifier is anonymized before reaching the reasoning layer to ensure your identity remains protected."),
                        _buildPolicySection("4. Your Digital Rights", 
                          "You maintain full ownership of your travel chronicles. At any point, you may export your data in encrypted formats or request total digital obliteration from our high-security servers."),
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

  Widget _buildPolicySection(String title, String content) {
    return ScrollReveal(
      controller: _scrollController,
      offset: 30,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            margin: const EdgeInsets.only(bottom: 0), // Adjust margin because of wrapper
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFFD4AF37), letterSpacing: 1),
                ),
                const SizedBox(height: 20),
                Text(
                  content,
                  style: TextStyle(fontSize: 16, height: 1.8, color: Colors.white.withOpacity(0.7)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
