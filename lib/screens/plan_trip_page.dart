import 'dart:ui' as ui;
import 'dart:async'; // Required for Timer
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart'; // Required for Pie Chart
import 'package:url_launcher/url_launcher.dart'; // Required for opening Maps
import 'package:firebase_auth/firebase_auth.dart'; // Import Auth
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore

// Ensure these widgets exist in your project structure
import '../widgets/navbar.dart';
import '../widgets/footer.dart';
import '../widgets/floating_chat_widget.dart';
import '../utils/pdf_generator.dart'; // Import PDF Generator
import 'package:shimmer/shimmer.dart';
import '../utils/constants.dart';


class PlanTripPage extends StatefulWidget {
  const PlanTripPage({super.key});

  @override
  State<PlanTripPage> createState() => _PlanTripPageState();
}

class _PlanTripPageState extends State<PlanTripPage> with TickerProviderStateMixin {
  late AnimationController _bgController;
  late AnimationController _pulsateController;
  late AnimationController _rotateController;
  // --- Form Controllers ---
  final TextEditingController _sourceController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  final TextEditingController _groupSizeController = TextEditingController(
    text: "2",
  );
  final List<String> dayOptions = List.generate(
    30,
    (index) => "${index + 1} Days",
  );

  // --- Scroll Controller for Auto-Scroll ---
  final ScrollController _mainScrollController = ScrollController();

  String? selectedDay = '3 Days';
  double _budgetStart = 5000;
  double _budgetEnd = 20000;
  String selectedStyle = "Adventure";
  final List<String> styles = ["Budget", "Family", "Luxury", "Adventure"];
  final Set<String> selectedInterests = {"Sightseeing", "Nature"};
  final List<String> interests = [
    "Sightseeing",
    "Food",
    "Nature",
    "Adventure",
    "Shopping",
    "History",
  ];

  // --- State Variables for Results ---
  bool _isLoading = false;
  Map<String, dynamic>? _planData;
  Map<String, dynamic>? _selectedDayPlan;
  String _sidePanelTab = "Budget"; // Default tab

  // Cache to store images so we don't re-fetch them constantly
  final Map<String, String> _imageCache = {};

  // --- BACKGROUND ROTATION ---
  int _bgIndex = 0;
  late Timer _bgTimer;
  final List<String> _bgImages = [
    'assets/plan_hero_bg.png',
    'assets/plan_bg_2.png',
    'assets/plan_bg_3.png',
    'assets/plan_bg_4.png',
    'assets/plan_bg_5.png',
  ];

  late AnimationController _floatController;

  // --- LOADING ANIMATION VARIABLES ---
  String _loadingMessage = "Connecting to AI...";
  final List<String> _loadingMessages = [
    "Analyzing global routes...",
    "Scouting premier locations...",
    "Curating hidden gems...",
    "Orchestrating your itinerary...",
    "Optimizing travel logistics...",
    "Perfecting the experience...",
  ];

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 40),
    )..repeat(reverse: true);

    _pulsateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _bgTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        setState(() {
          _bgIndex = (_bgIndex + 1) % _bgImages.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _sourceController.dispose();
    _destinationController.dispose();
    _groupSizeController.dispose();
    _mainScrollController.dispose();
    _bgController.dispose();
    _pulsateController.dispose();
    _rotateController.dispose();
    _floatController.dispose();
    _bgTimer.cancel();
    super.dispose();
  }

  // --- Start the Changing Text Animation ---
  void _startLoadingAnimation() {
    int index = 0;
    // Loop every 3 seconds while loading
    Future.doWhile(() async {
      if (!_isLoading) return false;
      await Future.delayed(const Duration(seconds: 3));
      if (mounted && _isLoading) {
        setState(() {
          _loadingMessage = _loadingMessages[index % _loadingMessages.length];
        });
        index++;
      }
      return _isLoading;
    });
  }

  // --- Function to handle "Cost Prediction" Click ---
  void _scrollToBudgetPanel() {
    if (_planData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please generate a trip plan first to see the budget!"),
        ),
      );
      return;
    }

    setState(() {
      _sidePanelTab = "Budget";
    });

    if (_mainScrollController.hasClients) {
      _mainScrollController.animateTo(
        600,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
      );
    }
  }

  // --- FUNCTION TO SAVE TRIP TO FIREBASE ---
  Future<void> _saveTripToFirebase(Map<String, dynamic> tripData) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Optional: Show message if not logged in, but fail gracefully
      debugPrint("User not logged in, trip not saved to Firestore.");
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('trips').add({
        'userId': user.uid,
        'userEmail': user.email,
        'source': _sourceController.text.trim().isEmpty
            ? "Unknown"
            : _sourceController.text.trim(),
        'destination': _destinationController.text.trim().isEmpty
            ? "Munnar, Kerala"
            : _destinationController.text.trim(),
        'days': selectedDay,
        'budget': "₹${_budgetStart.round()} - ₹${_budgetEnd.round()}",
        'groupSize': _groupSizeController.text,
        'tripData': tripData, // Saves the full AI response
        'createdAt': FieldValue.serverTimestamp(),
      });
      debugPrint("Trip saved to Firestore successfully!");
    } catch (e) {
      debugPrint("Error saving trip to Firestore: $e");
    }
  }

  // --- UPDATED API FUNCTION WITH TIMEOUT ---
  Future<void> _generateTripPlan() async {
    String source = _sourceController.text.trim();
    String destination = _destinationController.text.trim();

    if (destination.isEmpty) destination = "Munnar, Kerala";
    if (source.isEmpty) source = "My Location";

    setState(() {
      _isLoading = true;
      _planData = null;
      _selectedDayPlan = null;
      _sidePanelTab = "Budget";
      _loadingMessage = "Starting AI Engine..."; // Reset message
    });

    // Start the text animation
    _startLoadingAnimation();

    final Map<String, dynamic> requestData = {
      "source": source,
      "destination": destination,
      "days": selectedDay ?? "3 Days",
      "style": selectedStyle,
      "interests": selectedInterests.toList(),
      "budget": "₹${_budgetStart.round()} - ₹${_budgetEnd.round()}",
      "group_size": _groupSizeController.text,
    };

    try {
      // Note: Use http://10.0.2.2:5000 if running on Android Emulator, http://127.0.0.1:5000 for Web/iOS Simulator
      final response = await http
          .post(
        Uri.parse('${AppConstants.baseUrl}/generate_plan'),

        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestData),
      )
          .timeout(
        const Duration(seconds: 90),
        onTimeout: () {
          throw Exception(
            "The AI took too long to respond. Please try again.",
          );
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // --- SAVE TO FIREBASE HERE ---
        await _saveTripToFirebase(data);

        setState(() {
          _planData = data;
          _isLoading = false;
          // Auto-select the first day for the explorer
          if (data['itinerary'] != null && data['itinerary'].isNotEmpty) {
            _selectedDayPlan = data['itinerary'][0];
          }
        });

        // --- AUTO-SCROLL TO RESULTS ---
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_mainScrollController.hasClients) {
            _mainScrollController.animateTo(
              600,
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOut,
            );
          }
        });
      } else {
        _showError("Server Error: ${response.body}");
        setState(() => _isLoading = false);
      }
    } catch (e) {
      _showError("Request Failed: $e");
      setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  // --- Smart Map Launcher ---
  Future<void> _launchMaps(String query) async {
    // Fixed URL construction for Google Maps Search
    final Uri url = Uri.parse(
      "https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}",
    );

    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        await launchUrl(url);
      }
    } catch (e) {
      _showError("Could not open maps: $e");
    }
  }

  // --- SMART IMAGE FETCHER ---
  Future<String> _fetchRealImage(String placeName) async {
    String city = _destinationController.text.trim();
    String cacheKey = "$placeName, $city";

    if (_imageCache.containsKey(cacheKey)) {
      return _imageCache[cacheKey]!;
    }

    try {
      String searchQuery = placeName;
      final wikiUrl = Uri.parse(
        "https://en.wikipedia.org/w/api.php?action=query&generator=search&gsrsearch=${Uri.encodeComponent(searchQuery)}&gsrlimit=1&prop=pageimages&pithumbsize=600&format=json",
      );

      final response = await http.get(wikiUrl);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['query'] != null && data['query']['pages'] != null) {
          final pages = data['query']['pages'];
          final firstPageId = pages.keys.first;
          if (pages[firstPageId]['thumbnail'] != null) {
            String realImageUrl = pages[firstPageId]['thumbnail']['source'];
            String proxyUrl =
                "${AppConstants.baseUrl}/proxy_image?url=${Uri.encodeComponent(realImageUrl)}";

            _imageCache[cacheKey] = proxyUrl;
            return proxyUrl;
          }
        }
      }
    } catch (e) {
      debugPrint("Wiki Image failed, falling back to AI: $e");
    }

    String prompt = Uri.encodeComponent(
      "$placeName $city travel landmark real photography 8k",
    );
    String pollUrl =
        "https://image.pollinations.ai/prompt/$prompt?width=800&height=600&nologo=true";
    String proxyUrl =
        "${AppConstants.baseUrl}/proxy_image?url=${Uri.encodeComponent(pollUrl)}";


    _imageCache[cacheKey] = proxyUrl;
    return proxyUrl;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. CINEMATIC HERO BACKGROUND WITH ZOOM
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _bgController,
              builder: (context, child) {
                return Transform.scale(
                  scale: 1.0 + (_bgController.value * 0.15),
                  child: child,
                );
              },
              child: AnimatedSwitcher(
                duration: const Duration(seconds: 2),
                child: Image.asset(
                  _bgImages[_bgIndex],
                  key: ValueKey<int>(_bgIndex),
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
            ),
          ),

          // 2. DARK GLASS OVERLAY
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
          ),

          // 3. MAIN CONTENT
          SafeArea(
            child: SingleChildScrollView(
              controller: _mainScrollController,
              child: Column(
                children: [
                  NavBar(onScrollToBudget: _scrollToBudgetPanel),
                  
                  const SizedBox(height: 60),

                  // HERO TEXT
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        const Text(
                          "DREAM BEYOND HORIZONS",
                          style: TextStyle(
                            color: Color(0xFFD4AF37),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 6,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          "Architect Your Odyssey",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 15),
                        const Text(
                          "Our artificial intelligence distills millions of data points to craft your unique journey.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 18,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 60),

                  // --- FORM CARD WITH GLASSMORPHISM ---
                  Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 900),
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: BackdropFilter(
                          filter: ui.ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.12),
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Glassy Header
                                Container(
                                  padding: const EdgeInsets.all(35),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFD4AF37).withOpacity(0.1),
                                    border: Border(
                                      bottom: BorderSide(
                                        color: Colors.white.withOpacity(0.1),
                                      ),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "DESIGN YOUR TRIP",
                                        style: TextStyle(
                                          color: Color(0xFFD4AF37),
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 2,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        "Configure Your Journey Preferences",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(40),
                                  child: Column(
                                    children: [
                                      _buildFormFields(),
                                      const SizedBox(height: 50),

                                      // --- PREMIUM GENERATE BUTTON ---
                                      SizedBox(
                                        width: double.infinity,
                                        height: 65,
                                        child: ElevatedButton(
                                          onPressed: _isLoading ? null : _generateTripPlan,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFFD4AF37),
                                            foregroundColor: Colors.black,
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(15),
                                            ),
                                          ),
                                          child: const Text(
                                            "LAUNCH AI ENGINE",
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 2,
                                            ),
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

                  // --- RESULT SECTION ---
                  if (_isLoading) 
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 60),
                      child: _buildShimmerLoader(),
                    ),
                  if (_planData != null && !_isLoading) _buildResultSection(),

                  const SizedBox(height: 100),
                  const CustomFooter(),
                ],
              ),
            ),
          ),

          // 4. PREMIMUM AI GENERATION OVERLAY
          if (_isLoading) _buildAILoadingOverlay(),

          const FloatingChatWidget(),
        ],
      ),
    );
  }

  Widget _buildAILoadingOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.95),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Holographic Rotating AI Core
            AnimatedBuilder(
              animation: _rotateController,
              builder: (context, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer Ring
                    Transform.rotate(
                      angle: _rotateController.value * 2 * 3.14159,
                      child: Container(
                        width: 250,
                        height: 250,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFD4AF37).withOpacity(0.2),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    // Inner Rotating Segments
                    Transform.rotate(
                      angle: -_rotateController.value * 2 * 3.14159 * 2,
                      child: SizedBox(
                        width: 200,
                        height: 200,
                        child: CircularProgressIndicator(
                          value: 0.3,
                          strokeWidth: 4,
                          color: const Color(0xFFD4AF37).withOpacity(0.5),
                        ),
                      ),
                    ),
                    // Pulsating Core
                    AnimatedBuilder(
                      animation: _pulsateController,
                      builder: (context, child) {
                        return Container(
                          width: 100 + (_pulsateController.value * 20),
                          height: 100 + (_pulsateController.value * 20),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFD4AF37).withOpacity(0.1),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFD4AF37).withOpacity(0.2 * _pulsateController.value),
                                blurRadius: 40,
                                spreadRadius: 20,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.auto_awesome,
                              color: Color(0xFFD4AF37),
                              size: 40,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 60),
            // Text Animations
            const Text(
              "ODYSSEY AI ENGINE",
              style: TextStyle(
                color: Color(0xFFD4AF37),
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 20),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: Text(
                _loadingMessage,
                key: ValueKey(_loadingMessage),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w200,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            const SizedBox(height: 40),
            Container(
              width: 300,
              height: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    const Color(0xFFD4AF37).withOpacity(0.5),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            // Responsive Layout:
            // If screen is small (< 600px), stack everything.
            if (constraints.maxWidth < 600) {
              return Column(
                children: [
                  _buildTextField(
                    "From Where?",
                    "e.g. Kochi, Bangalore",
                    _sourceController,
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    "Where to?",
                    "e.g. Munnar, Wayanad",
                    _destinationController,
                  ),
                  const SizedBox(height: 20),
                  _buildDropdown("Days", dayOptions),
                  const SizedBox(height: 20),
                  _buildTextField("Group Size", "2", _groupSizeController),
                ],
              );
            }
            // If screen is wide, use Rows
            return Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        "From Where?",
                        "e.g. Kochi",
                        _sourceController,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: _buildTextField(
                        "Where to?",
                        "e.g. Munnar",
                        _destinationController,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(child: _buildDropdown("Days", dayOptions)),
                    const SizedBox(width: 20),
                    Expanded(
                      child: _buildTextField(
                        "Group Size",
                        "2",
                        _groupSizeController,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 30),
        const Text(
          "Travel Style",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70),
        ),
        const SizedBox(height: 15),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: styles.map((style) {
            bool isSelected = selectedStyle == style;
            return InkWell(
              onTap: () => setState(() => selectedStyle = style),
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFD4AF37) : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? const Color(0xFFD4AF37) : Colors.white.withOpacity(0.2),
                  ),
                ),
                child: Text(
                  style,
                  style: TextStyle(
                    color: isSelected ? Colors.black : Colors.white70,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 30),
        const Text("Interests", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70)),
        const SizedBox(height: 15),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: interests.map((interest) {
            bool isSelected = selectedInterests.contains(interest);
            return InkWell(
              onTap: () {
                setState(() {
                  isSelected ? selectedInterests.remove(interest) : selectedInterests.add(interest);
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFD4AF37) : Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? const Color(0xFFD4AF37) : Colors.white.withOpacity(0.15),
                    width: 1,
                  ),
                  boxShadow: isSelected ? [
                    BoxShadow(
                      color: const Color(0xFFD4AF37).withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ] : [],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSelected) 
                      const Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: Icon(Icons.check_circle, size: 16, color: Colors.black),
                      ),
                    Text(
                      interest,
                      style: TextStyle(
                        color: isSelected ? Colors.black : Colors.white.withOpacity(0.8),
                        fontWeight: isSelected ? FontWeight.w900 : FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 30),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Budget Range (INR)",
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70),
            ),
            Text(
              "₹${_budgetStart.round()} - ₹${_budgetEnd.round()}+",
              style: const TextStyle(
                color: Color(0xFFD4AF37),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        RangeSlider(
          values: RangeValues(_budgetStart, _budgetEnd),
          min: 1000,
          max: 100000,
          divisions: 100,
          activeColor: const Color(0xFFD4AF37),
          inactiveColor: Colors.white.withOpacity(0.1),
          onChanged: (v) => setState(() {
            _budgetStart = v.start;
            _budgetEnd = v.end;
          }),
        ),
      ],
    );
  }

  Widget _buildTextField(String label, String hint, TextEditingController c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFD4AF37), letterSpacing: 1),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: c,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFD4AF37)),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(String label, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFD4AF37), letterSpacing: 1),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedDay,
              isExpanded: true,
              dropdownColor: Colors.grey[900],
              style: const TextStyle(color: Colors.white, fontSize: 15),
              icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFFD4AF37)),
              menuMaxHeight: 300,
              items: items.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
              onChanged: (v) => setState(() => selectedDay = v),
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================================
  //      RESULT SECTION (STICKY SIDE PANEL LOGIC)
  // ==========================================================

  Widget _buildResultSection() {
    final String summary = _planData!['summary'] ?? "";
    final List itinerary = _planData!['itinerary'] ?? [];

    return Container(
      constraints: const BoxConstraints(maxWidth: 1200),
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // SUMMARY BOX (GLASSY)
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(35),
                margin: const EdgeInsets.only(bottom: 40),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Your Travel Plan Summary",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            String dest = _destinationController.text.trim();
                            if (dest.isEmpty) dest = "TravelAI Trip";
                            PdfGenerator.generateAndPrint(_planData!, dest);
                          },
                          icon: const Icon(Icons.download, size: 18),
                          label: const Text("Download PDF"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD4AF37).withOpacity(0.1),
                            foregroundColor: const Color(0xFFD4AF37),
                            elevation: 0,
                            side: BorderSide(color: const Color(0xFFD4AF37).withOpacity(0.3)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      summary,
                      style: const TextStyle(
                        fontSize: 17,
                        height: 1.6,
                        color: Colors.white70,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // SPLIT LAYOUT
          LayoutBuilder(
            builder: (context, constraints) {
              bool isDesktop = constraints.maxWidth > 900;

              if (isDesktop) {
                // --- DESKTOP LAYOUT (Sticky Side Panel Logic) ---
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // LEFT: Independent Scrollable Itinerary List
                    Expanded(
                      flex: 3,
                      child: SizedBox(
                        // This height forces the list to scroll separately from the page
                        height: 800,
                        child: ListView.builder(
                          padding: const EdgeInsets.only(right: 20, bottom: 50),
                          itemCount: itinerary.length,
                          itemBuilder: (ctx, idx) =>
                              _buildItineraryCard(itinerary[idx], idx + 1),
                        ),
                      ),
                    ),

                    // RIGHT: Static Side Panel (Stays Fixed)
                    Expanded(flex: 2, child: _buildSidePanel()),
                  ],
                );
              } else {
                // --- MOBILE LAYOUT (Classic Column) ---
                return Column(
                  children: [
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: itinerary.length,
                      itemBuilder: (ctx, idx) =>
                          _buildItineraryCard(itinerary[idx], idx + 1),
                    ),
                    const SizedBox(height: 30),
                    _buildSidePanel(),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  // --- Itinerary Card ---
  Widget _buildItineraryCard(Map<String, dynamic> item, int dayNum) {
    bool isSelected = _selectedDayPlan == item;
    String transport = item['transport'] ?? "Local transfer available";
    String? imageUrl = item['image_url'];

    return AnimatedBuilder(
      animation: _floatController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 15 * _floatController.value - 7.5),
          child: Transform.rotate(
            angle: 0.015 * _floatController.value - 0.0075,
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 25),
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFD4AF37).withOpacity(0.12) : Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFFD4AF37) : Colors.white.withOpacity(0.1),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: (isSelected ? const Color(0xFFD4AF37) : Colors.black).withOpacity(0.1),
              blurRadius: 20,
              spreadRadius: -5,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Stack(
                    children: [
                      Image.network(
                        imageUrl,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 200,
                          width: double.infinity,
                          color: Colors.white.withOpacity(0.05),
                          child: const Icon(Icons.image_not_supported, color: Colors.white24),
                        ),
                      ),
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.6),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4AF37).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.5)),
                  ),
                  child: const Text(
                    "ADVENTURE POINT",
                    style: TextStyle(
                      color: Color(0xFFD4AF37),
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Text(
                  "DAY $dayNum",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Text(
              item['title'],
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 20,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              item['description'],
              style: TextStyle(color: Colors.white.withOpacity(0.7), height: 1.6, fontSize: 15),
            ),
            const SizedBox(height: 25),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _selectedDayPlan = item;
                  _sidePanelTab = "Explorer";
                });
              },
              icon: const Icon(Icons.explore_outlined, size: 18),
              label: const Text("VIEW DETAILS"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF37).withOpacity(0.1),
                foregroundColor: const Color(0xFFD4AF37),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: const Color(0xFFD4AF37).withOpacity(0.3)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Side Panel ---
  Widget _buildSidePanel() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  _buildTabButton("BUDGET BREAKDOWN", "Budget"),
                  _buildTabButton("PLACE EXPLORER", "Explorer"),
                ],
              ),
              const Divider(height: 1, color: Colors.white12),
              Container(
                height: 550,
                padding: const EdgeInsets.all(25),
                child: _sidePanelTab == "Budget"
                    ? SingleChildScrollView(child: _buildBudgetView())
                    : _buildPlaceExplorerView(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton(String label, String value) {
    bool isActive = _sidePanelTab == value;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _sidePanelTab = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            border: isActive
                ? const Border(bottom: BorderSide(color: Color(0xFFD4AF37), width: 2))
                : null,
            color: isActive ? Colors.white.withOpacity(0.05) : Colors.transparent,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 1,
              color: isActive ? const Color(0xFFD4AF37) : Colors.white24,
            ),
          ),
        ),
      ),
    );
  }

  // --- TAB 1: Budget View ---
  Widget _buildBudgetView() {
    double total = (_budgetStart + _budgetEnd) / 2;
    double daily = total / 3;
    double hotel = daily * 0.4;

    return Column(
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            "Estimated Trip Spending",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        const SizedBox(height: 30),
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sectionsSpace: 4,
              centerSpaceRadius: 50,
              sections: [
                PieChartSectionData(
                  color: const Color(0xFFD4AF37),
                  value: 45,
                  radius: 30,
                  showTitle: false,
                ),
                PieChartSectionData(
                  color: Colors.white24,
                  value: 35,
                  radius: 25,
                  showTitle: false,
                ),
                PieChartSectionData(
                  color: Colors.white10,
                  value: 20,
                  radius: 20,
                  showTitle: false,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 30),
        _buildLegendItem(const Color(0xFFD4AF37), "Core Stays & Hotels"),
        const SizedBox(height: 10),
        _buildLegendItem(Colors.white38, "Dining & Culinary"),
        const SizedBox(height: 10),
        _buildLegendItem(Colors.white12, "Expeditions & Logistics"),
        const SizedBox(height: 40),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 30),
          decoration: BoxDecoration(
            color: const Color(0xFFD4AF37).withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.1)),
          ),
          child: Column(
            children: [
              const Text(
                "TOTAL INVESTMENT",
                style: TextStyle(
                  color: Color(0xFFD4AF37),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "₹${total.toStringAsFixed(0)}",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'BodoniModa',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "DAILY RATE",
                      style: TextStyle(fontSize: 9, color: Colors.white38, fontWeight: FontWeight.bold, letterSpacing: 1),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "₹${daily.toStringAsFixed(0)}",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "STAY EST.",
                      style: TextStyle(fontSize: 9, color: Colors.white38, fontWeight: FontWeight.bold, letterSpacing: 1),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "₹${hotel.toStringAsFixed(0)}",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      children: [
        Container(width: 12, height: 12, color: color),
        const SizedBox(width: 5),
        Text(
          text,
          style: TextStyle(color: color, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  // --- TAB 2: Place Explorer with REAL IMAGES ---
  Widget _buildPlaceExplorerView() {
    if (_selectedDayPlan == null)
      return const Center(
        child: Text("Select a day from the itinerary to view details."),
      );
    String aboutPlace = _selectedDayPlan!['about'] ??
        _selectedDayPlan!['description'] ??
        "Explore this beautiful location.";
    String placeTitle = _selectedDayPlan!['title'];
    String? backendImageUrl = _selectedDayPlan!['image_url'];
    String? locationQuery = _selectedDayPlan!['location_query'];
    String effectiveMapsQuery = locationQuery != null
        ? "$locationQuery, ${(_destinationController.text.isNotEmpty ? _destinationController.text : "Destination")}"
        : placeTitle;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            placeTitle,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  Container(
                    width: 3,
                    color: const Color(0xFFD4AF37),
                    height: double.infinity,
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Text(
                      aboutPlace,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        height: 1.6,
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),

          // --- DYNAMIC IMAGE (Using Backend URL) ---
          if (backendImageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.network(
                backendImageUrl,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 180,
                  width: double.infinity,
                  color: Colors.grey[100],
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.broken_image,
                        color: Colors.grey,
                        size: 40,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Image Load Failed\nPreviewing URL: ${backendImageUrl.length > 30 ? backendImageUrl.substring(0, 30) : backendImageUrl}...",
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            FutureBuilder<String>(
              future: _fetchRealImage(placeTitle),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Container(
                    height: 180,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Center(child: CircularProgressIndicator()),
                  );
                }
                return ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.network(
                    snapshot.data!,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                );
              },
            ),

          const SizedBox(height: 20),
          const SizedBox(height: 30),
          const Text(
            "GEOGRAPHICAL CONTEXT",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFFD4AF37),
              fontSize: 10,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 15),
          if (_selectedDayPlan!['map_url'] != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Stack(
                children: [
                  Image.network(
                    _selectedDayPlan!['map_url'],
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 200,
                      width: double.infinity,
                      color: Colors.white.withOpacity(0.05),
                      child: const Icon(Icons.map, color: Colors.white24),
                    ),
                  ),
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => _launchMaps(effectiveMapsQuery),
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const Text("LAUNCH NAVIGATION"),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFD4AF37),
                textStyle: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1, fontSize: 11),
              ),
            ),
          ),
        ],
      ),
    );
  }
  // ==========================================================
  //      SHIMMER SKELETON LOADER
  // ==========================================================

  Widget _buildShimmerLoader() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 1200),
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(top: 20),
      child: Shimmer.fromColors(
        baseColor: Colors.white.withOpacity(0.05),
        highlightColor: Colors.white.withOpacity(0.1),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: 200,
              margin: const EdgeInsets.only(bottom: 30),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    height: 500,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                const SizedBox(width: 25),
                Expanded(
                  flex: 2,
                  child: Container(
                    height: 500,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
