import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/navbar.dart';
import '../widgets/footer.dart';
import '../utils/pdf_generator.dart';
import '../widgets/scroll_reveal_widget.dart';
import 'package:google_fonts/google_fonts.dart';


class TripResultPage extends StatefulWidget {
  final Map<String, dynamic> planData;

  const TripResultPage({super.key, required this.planData});

  @override
  State<TripResultPage> createState() => _TripResultPageState();
}

class _TripResultPageState extends State<TripResultPage> {
  bool _isSaving = false;
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

  Future<void> _saveTrip() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please login to save your trip! 🔑")),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance.collection('trips').add({
        'userId': user.uid,
        'destination':
            widget.planData['itinerary']?.first?['title']?.split(" ").last ??
                "Destination",
        'source': "My Location",
        'budget':
            widget.planData['budget_breakdown']?['total_estimated'] ?? "N/A",
        'days': "${widget.planData['itinerary']?.length ?? 0} Days",
        'tripData': widget.planData,
        'createdAt': FieldValue.serverTimestamp(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Trip saved successfully! 🎒✨")),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error saving trip: $e")));
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _shareViaWhatsApp() async {
    final destination =
        widget.planData['itinerary']?.first?['title'] ?? "my trip";
    final url =
        "https://wa.me/?text=Check out my AI-planned trip to $destination! 🌍✈️";
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  @override
  Widget build(BuildContext context) {
    final String summary =
        widget.planData['summary'] ?? "No summary available.";
    final List<dynamic> itinerary = widget.planData['itinerary'] ?? [];
    final Map<String, dynamic> budget =
        widget.planData['budget_breakdown'] ?? {};
    final List<dynamic> hotels = widget.planData['hotel_suggestions'] ?? [];

    return Scaffold(
      backgroundColor: Colors.black,
      bottomNavigationBar: _buildBottomActionBar(),
      body: Stack(
        children: [
          // 1. Background Parallax
          Positioned.fill(
            child: Opacity(
              opacity: 0.6,
              child: Transform.translate(
                offset: Offset(0, -_scrollOffset * 0.3),
                child: Image.asset(
                  'assets/plan_bg_2.png', // Using an alternative luxury bg
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Image.asset(
                    'assets/plan_hero_bg.png',
                    fit: BoxFit.cover,
                  ),
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
                    Colors.black.withOpacity(0.5),
                    Colors.black.withOpacity(0.8),
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
              const SliverToBoxAdapter(child: SizedBox(height: 60)),

              // --- 1. Page Title ---
              SliverToBoxAdapter(
                child: ScrollReveal(
                  controller: _scrollController,
                  child: Column(
                    children: [
                      const Text(
                        "YOUR ODYSSEY PLAN",
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFD4AF37),
                            letterSpacing: 4),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "Curated Adventure",
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 60)),

              // --- 2. Summary & Budget Card ---
              SliverToBoxAdapter(
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 1000),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        ScrollReveal(
                          controller: _scrollController,
                          child: _buildSummaryCard(summary),
                        ),
                        const SizedBox(height: 30),
                        if (budget.isNotEmpty)
                          ScrollReveal(
                            controller: _scrollController,
                            offset: 60,
                            child: _buildBudgetCard(budget),
                          ),
                        const SizedBox(height: 30),
                        if (hotels.isNotEmpty)
                          ScrollReveal(
                            controller: _scrollController,
                            offset: 40,
                            child: _buildHotelsCard(hotels),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 80)),

              // --- 3. Itinerary Section ---
              const SliverToBoxAdapter(
                child: Center(
                  child: Text(
                    "Chronicle of Days",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 40)),

              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final dayPlan = itinerary[index];
                      return Center(
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 1000),
                          margin: const EdgeInsets.only(bottom: 40),
                          child: ScrollReveal(
                            controller: _scrollController,
                            child: _buildItineraryCard(dayPlan),
                          ),
                        ),
                      );
                    },
                    childCount: itinerary.length,
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
              const SliverToBoxAdapter(child: CustomFooter()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _actionButton(
              Icons.save_alt,
              "Save",
              _isSaving ? null : _saveTrip,
              color: const Color(0xFF1E88E5),
            ),
            _actionButton(
              Icons.share,
              "Share",
              _shareViaWhatsApp,
              color: const Color(0xFF10B981),
            ),
            _actionButton(Icons.picture_as_pdf, "PDF", () {
              PdfGenerator.generateAndPrint(widget.planData, "Trip Plan");
            }, color: const Color(0xFF8B5CF6)),
          ],
        ),
      ),
    );
  }

  Widget _actionButton(
    IconData icon,
    String label,
    VoidCallback? onPressed, {
    Color? color,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color ?? Colors.grey[200],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String summary) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(35),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_awesome, color: Color(0xFFD4AF37), size: 28),
                  const SizedBox(width: 15),
                  Text(
                    "AI Insights & Summary",
                    style: GoogleFonts.bodoniModa(
                      fontSize: 24, 
                      fontWeight: FontWeight.w900, 
                      color: Colors.white
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 25),
              Text(
                summary,
                style: TextStyle(
                  fontSize: 17,
                  height: 1.8,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBudgetCard(Map<String, dynamic> budget) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(35),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFFD4AF37).withOpacity(0.15),
                Colors.white.withOpacity(0.02),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Estimated Budget Breakdown",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFD4AF37),
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 35),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _budgetItem("✈️ Flights", budget['flights'] ?? "N/A"),
                  _budgetItem("🏨 Hotels", budget['hotels'] ?? "N/A"),
                  _budgetItem("🍴 Food", budget['food'] ?? "N/A"),
                  _budgetItem("🎢 Activities", budget['activities'] ?? "N/A"),
                ],
              ),
              const Divider(color: Colors.white24, height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Total Estimated Cost",
                    style: TextStyle(fontSize: 18, color: Colors.white70),
                  ),
                  Text(
                    budget['total_estimated'] ?? "N/A",
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _budgetItem(String label, String amount) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Text(
          amount,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildHotelsCard(List<dynamic> hotels) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(35),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.hotel_rounded, color: Color(0xFFD4AF37), size: 28),
                  const SizedBox(width: 15),
                  Text(
                    "Recommended Stays",
                    style: GoogleFonts.bodoniModa(
                      fontSize: 24, 
                      fontWeight: FontWeight.w900, 
                      color: Colors.white
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 25),
              ...hotels
                  .map(
                    (hotel) => Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.02),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.05)),
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            hotel['name'] ?? "Unknown Hotel",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.white,
                            ),
                          ),
                          subtitle: Text(
                            hotel['description'] ?? "",
                            style: TextStyle(color: Colors.white.withOpacity(0.6), height: 1.5),
                          ),
                          trailing: Text(
                            hotel['price_per_night'] ?? "",
                            style: const TextStyle(
                              color: Color(0xFFD4AF37),
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItineraryCard(Map<String, dynamic> dayPlan) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with Image and Overlaid Badge
              Stack(
                children: [
                  if (dayPlan['image_url'] != null)
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                      child: Image.network(
                        dayPlan['image_url'],
                        height: 250,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 200,
                          color: Colors.white10,
                          child: const Icon(Icons.broken_image, size: 40, color: Colors.white24),
                        ),
                      ),
                    ),
                  // Gradient for better text visibility
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
                  // Overlaid Day Badge
                  Positioned(
                    bottom: 20,
                    left: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4AF37),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFD4AF37).withOpacity(0.3),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Text(
                        "DAY ${dayPlan['day']}",
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
    
              // Content Section
              Padding(
                padding: const EdgeInsets.all(30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dayPlan['title'] ?? "",
                      style: GoogleFonts.bodoniModa(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      dayPlan['description'] ?? "",
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.7,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 15),
    
                    // Compact Transport & Food Chips
                    Row(
                      children: [
                        if (dayPlan['transport'] != null)
                          _infoChip(
                            Icons.directions_bus_rounded,
                            dayPlan['transport'],
                          ),
                        const SizedBox(width: 8),
                        if (dayPlan['food_recommendation'] != null)
                          _infoChip(
                            Icons.restaurant_rounded,
                            dayPlan['food_recommendation'],
                          ),
                      ],
                    ),
    
                    if (dayPlan['map_url'] != null) ...[
                      const SizedBox(height: 15),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          dayPlan['map_url'],
                          height: 120, // Compact map height
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: const Color(0xFFD4AF37)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.8)),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
