import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../screens/about_page.dart';
import '../screens/careers_page.dart';
import '../screens/privacy_policy_page.dart';

class CustomFooter extends StatelessWidget {
  const CustomFooter({super.key});

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      throw Exception('Could not launch $url');
    }
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF1A1A1A),
        content: Text(
          "$feature section is being prepared for your next odyssey...",
          style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold),
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: Color(0xFFD4AF37), width: 0.5),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 40),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 800) {
            return Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      flex: 2,
                      child: _StaggeredReveal(
                        delayIndex: 0,
                        child: _buildBrandSection(),
                      ),
                    ),
                    Expanded(
                      child: _StaggeredReveal(
                        delayIndex: 1,
                        child: _buildColumn(context, "COMPANY", {
                          "About Us": () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AboutPage())),
                          "Careers": () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CareersPage())),
                          "Privacy Policy": () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PrivacyPolicyPage())),
                        }),
                      ),
                    ),
                    Expanded(
                      child: _StaggeredReveal(
                        delayIndex: 2,
                        child: _buildColumn(context, "CONNECT", {
                          "Twitter": () => _launchURL("https://twitter.com"),
                          "Instagram": () => _launchURL("https://instagram.com"),
                          "Facebook": () => _launchURL("https://facebook.com"),
                        }),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 60),
                const _StaggeredReveal(
                  delayIndex: 3,
                  child: Divider(color: Colors.white10),
                ),
                const SizedBox(height: 30),
                _StaggeredReveal(
                  delayIndex: 4,
                  child: Text(
                    "© 2026 ODYSSEY. ALL RIGHTS RESERVED.",
                    style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          } else {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StaggeredReveal(
                  delayIndex: 0,
                  child: _buildBrandSection(),
                ),
                const SizedBox(height: 50),
                _StaggeredReveal(
                  delayIndex: 1,
                  child: _buildColumn(context, "COMPANY", {
                    "About Us": () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AboutPage())),
                    "Careers": () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CareersPage())),
                    "Privacy Policy": () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PrivacyPolicyPage())),
                  }),
                ),
                const SizedBox(height: 40),
                _StaggeredReveal(
                  delayIndex: 2,
                  child: _buildColumn(context, "CONNECT", {
                    "Twitter": () => _launchURL("https://twitter.com"),
                    "Instagram": () => _launchURL("https://instagram.com"),
                    "Facebook": () => _launchURL("https://facebook.com"),
                  }),
                ),
                const SizedBox(height: 50),
                const _StaggeredReveal(
                  delayIndex: 3,
                  child: Divider(color: Colors.white10),
                ),
                const SizedBox(height: 30),
                Center(
                  child: _StaggeredReveal(
                    delayIndex: 4,
                    child: Text(
                      "© 2026 ODYSSEY. ALL RIGHTS RESERVED.",
                      style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildBrandSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Shimmer.fromColors(
              baseColor: const Color(0xFFD4AF37),
              highlightColor: const Color(0xFFFFF8DC),
              period: const Duration(seconds: 3),
              child: Text(
                "ODYSSEY",
                style: GoogleFonts.bodoniModa(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4.0,
                  color: const Color(0xFFD4AF37),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          "Empowering travelers with intelligent AI insights.\nPlan smarter, travel further, and stay within your\nbudget with our world-class travel assistant.",
          style: TextStyle(color: Colors.white.withOpacity(0.4), height: 1.8, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildColumn(BuildContext context, String title, Map<String, VoidCallback> links) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            color: Colors.white,
            fontSize: 12,
            letterSpacing: 3,
          ),
        ),
        const SizedBox(height: 25),
        ...links.entries.map((link) => Padding(
              padding: const EdgeInsets.only(bottom: 15),
              child: _FooterLink(title: link.key, onTap: link.value),
            )),
      ],
    );
  }
}

class _FooterLink extends StatefulWidget {
  final String title;
  final VoidCallback onTap;

  const _FooterLink({required this.title, required this.onTap});

  @override
  State<_FooterLink> createState() => _FooterLinkState();
}

class _FooterLinkState extends State<_FooterLink> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: TextStyle(
            color: _isHovered ? const Color(0xFFD4AF37) : Colors.white.withOpacity(0.5),
            fontSize: 14,
            fontWeight: _isHovered ? FontWeight.bold : FontWeight.normal,
            letterSpacing: _isHovered ? 0.5 : 0,
          ),
          child: Text(widget.title),
        ),
      ),
    );
  }
}

class _StaggeredReveal extends StatelessWidget {
  final Widget child;
  final int delayIndex;
  const _StaggeredReveal({required this.child, required this.delayIndex});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1000),
      curve: Interval(
        (0.1 * delayIndex).clamp(0.0, 1.0),
        1.0,
        curve: Curves.easeOutQuart,
      ),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
