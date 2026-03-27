import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shimmer/shimmer.dart';
import 'package:google_fonts/google_fonts.dart';

import '../screens/plan_trip_page.dart';
import '../screens/home_page.dart';
import '../screens/chatbot_page.dart';
import '../screens/login_page.dart';
import '../screens/signup_page.dart';
import '../screens/admin_dashboard.dart';
import '../screens/my_trips_page.dart';
import '../screens/profile_page.dart';

class NavBar extends StatefulWidget {
  final VoidCallback? onScrollToBudget;

  const NavBar({super.key, this.onScrollToBudget});

  @override
  State<NavBar> createState() => _NavBarState();
}

class _NavBarState extends State<NavBar> {
  bool _isMenuOpen = false;

  void _handleLogout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Logged out successfully")));
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDesktop = MediaQuery.of(context).size.width > 950;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          color: Colors.black.withOpacity(0.2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Scroll Progress Bar
              const _ScrollProgressBar(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // 1. LOGO
                    const AnimatedBrand(),

                  // 2. DESKTOP MENU
                  if (isDesktop)
                    Row(
                      children: [
                        _navItem(context, "Home", const HomePage()),
                        _navItem(context, "Plan Trip", const PlanTripPage()),
                        _navItem(
                          context,
                          "Cost Prediction",
                          const PlanTripPage(),
                          isCostPrediction: true,
                        ),
                        _navItem(context, "AI Guide", const ChatBotPage()),
                        StreamBuilder<User?>(
                          stream: FirebaseAuth.instance.authStateChanges(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return Row(
                                children: [
                                  const SizedBox(width: 20),
                                  AnimatedHoverButton(
                                    child: TextButton(
                                      onPressed: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const LoginPage(),
                                        ),
                                      ),
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.white,
                                      ),
                                      child: const Text(
                                        "Log In",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  AnimatedHoverButton(
                                    child: ElevatedButton(
                                      onPressed: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const SignupPage(),
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFFD4AF37),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 25,
                                          vertical: 15,
                                        ),
                                      ),
                                      child: const Text(
                                        "Sign Up",
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }

                            User? user = snapshot.data;
                            String userName = user?.displayName ?? "Traveler";
                            String userEmail = user?.email ?? "";
                            bool isAdmin = userEmail == "admin@test.com";

                            return Row(
                              children: [
                                _navItem(
                                    context, "My Trips", const MyTripsPage()),
                                if (isAdmin)
                                  _navItem(
                                    context,
                                    "Admin Panel",
                                    const AdminDashboard(),
                                  ),
                                const SizedBox(width: 20),
                                AnimatedHoverButton(
                                  child: InkWell(
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const ProfilePage(),
                                      ),
                                    ),
                                    child: Chip(
                                      avatar: const CircleAvatar(
                                        backgroundColor: Colors.white,
                                        child: Icon(
                                          Icons.person,
                                          size: 16,
                                          color: Colors.blue,
                                        ),
                                      ),
                                      label: Text("Hi, $userName"),
                                      backgroundColor: Colors.blue.shade50,
                                      side: BorderSide.none,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                AnimatedHoverButton(
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.logout,
                                      color: Colors.white70,
                                    ),
                                    tooltip: "Logout",
                                    onPressed: () => _handleLogout(context),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    )
                  else
                    AnimatedHoverButton(
                      child: IconButton(
                        icon: Icon(_isMenuOpen ? Icons.close : Icons.menu),
                        onPressed: () {
                          setState(() {
                            _isMenuOpen = !_isMenuOpen;
                          });
                        },
                      ),
                    ),
                ],
              ),
            ),

            // 3. MOBILE MENU (Collapsible)
            if (!isDesktop && _isMenuOpen)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: StreamBuilder<User?>(
                      stream: FirebaseAuth.instance.authStateChanges(),
                      builder: (context, snapshot) {
                        bool isLoggedIn = snapshot.hasData;
                        User? user = snapshot.data;
                        String userName = user?.displayName ?? "Traveler";
                        String userEmail = user?.email ?? "";
                        bool isAdmin = userEmail == "admin@test.com";

                        return Column(
                          children: [
                            _mobileNavItem(context, "Home", const HomePage()),
                            _mobileNavItem(
                              context,
                              "Plan Trip",
                              const PlanTripPage(),
                            ),
                            _mobileNavItem(
                              context,
                              "Cost Prediction",
                              const PlanTripPage(),
                              isCostPrediction: true,
                            ),
                            _mobileNavItem(
                              context,
                              "AI Guide",
                              const ChatBotPage(),
                            ),
                            if (isLoggedIn) ...[
                              _mobileNavItem(
                                context,
                                "My Trips",
                                const MyTripsPage(),
                              ),
                              if (isAdmin)
                                _mobileNavItem(
                                  context,
                                  "Admin Panel",
                                  const AdminDashboard(),
                                ),
                              _mobileNavItem(
                                context,
                                "Profile (Hi, $userName)",
                                const ProfilePage(),
                              ),
                              ListTile(
                                leading: const Icon(
                                  Icons.logout,
                                  color: Colors.redAccent,
                                ),
                                title: const Text(
                                  "Logout",
                                  style: TextStyle(
                                    color: Colors.redAccent,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                onTap: () {
                                  _isMenuOpen = false;
                                  _handleLogout(context);
                                },
                              ),
                            ] else ...[
                              const Divider(),
                              _mobileNavItem(
                                  context, "Log In", const LoginPage()),
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const SignupPage(),
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFD4AF37),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 15,
                                      ),
                                    ),
                                    child: const Text(
                                      "Sign Up",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mobileNavItem(
    BuildContext context,
    String title,
    Widget targetPage, {
    bool isCostPrediction = false,
  }) {
    return ListTile(
      title: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
      onTap: () {
        setState(() {
          _isMenuOpen = false;
        });

        // Security Check
        if ((title == "Plan Trip" ||
                title == "Cost Prediction" ||
                title == "My Trips") &&
            FirebaseAuth.instance.currentUser == null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("Please Log In!")));
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
          );
          return;
        }

        if (isCostPrediction && widget.onScrollToBudget != null) {
          widget.onScrollToBudget!();
          return;
        }

        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => targetPage),
        );
      },
    );
  }

  Widget _navItem(
    BuildContext context,
    String title,
    Widget? targetPage, {
    bool isCostPrediction = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: AnimatedHoverButton(
        child: TextButton(
          onPressed: () {
            if ((title == "Plan Trip" ||
                    title == "Cost Prediction" ||
                    title == "My Trips") &&
                FirebaseAuth.instance.currentUser == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Please Log In!"),
                  backgroundColor: Colors.redAccent,
                ),
              );
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
              return;
            }

            if (isCostPrediction && widget.onScrollToBudget != null) {
              widget.onScrollToBudget!();
              return;
            }

            if (targetPage != null) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => targetPage),
              );
            }
          },
          style: TextButton.styleFrom(foregroundColor: Colors.white70),
          child: Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

class AnimatedBrand extends StatefulWidget {
  const AnimatedBrand({super.key});
  @override
  State<AnimatedBrand> createState() => _AnimatedBrandState();
}

class _AnimatedBrandState extends State<AnimatedBrand>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 1.0, end: 1.1).animate(
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
    return InkWell(
      onTap: () => Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      ),
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, 5 * (_animation.value - 1.0)),
            child: Row(
              children: [
                Shimmer.fromColors(
                  baseColor: const Color(0xFFD4AF37),
                  highlightColor: const Color(0xFFFFF8DC),
                  period: const Duration(seconds: 3),
                  child: Text(
                    "ODYSSEY",
                    style: GoogleFonts.bodoniModa(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 12.0,
                      color: const Color(0xFFD4AF37),
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 15,
                          offset: const Offset(3, 3),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class AnimatedHoverButton extends StatefulWidget {
  final Widget child;
  const AnimatedHoverButton({super.key, required this.child});

  @override
  State<AnimatedHoverButton> createState() => _AnimatedHoverButtonState();
}

class _AnimatedHoverButtonState extends State<AnimatedHoverButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? 1.1 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutBack,
        child: widget.child,
      ),
    );
  }
}

class _ScrollProgressBar extends StatelessWidget {
  const _ScrollProgressBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 3,
      width: double.infinity,
      color: Colors.white.withOpacity(0.05),
      alignment: Alignment.centerLeft,
      child: Container(
        width: 150,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.horizontal(right: Radius.circular(5)),
          gradient: const LinearGradient(
            colors: [Color(0xFFD4AF37), Color(0xFFFFF8DC)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFD4AF37).withOpacity(0.8),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
      ),
    );
  }
}
