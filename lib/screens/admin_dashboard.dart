import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> with TickerProviderStateMixin {
  String _selectedView = "Overview";
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  late AnimationController _mainAnimationController;
  late Animation<double> _fadeAnimation;
  int _hoveredSectionIndex = -1;

  @override
  void initState() {
    super.initState();
    _mainAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mainAnimationController, curve: Curves.easeIn),
    );
    _mainAnimationController.forward();
  }

  @override
  void dispose() {
    _mainAnimationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Helper to switch views and clear search
  void _switchView(String viewName) {
    setState(() {
      _selectedView = viewName;
      _searchQuery = "";
      _searchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. UNIQUE 8K BACKGROUND
          Positioned.fill(
            child: Image.asset(
              'assets/admin_bg.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.4), // Dark overlay for readability
            ),
          ),

          Row(
            children: [
              // --- 1. LUXURY SIDEBAR ---
              _buildModernSidebar(),

              // --- 2. MAIN CONTENT AREA ---
              Expanded(
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: Container(
                      color: Colors.white.withOpacity(0.05),
                      padding: const EdgeInsets.all(40.0),
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: _buildMainContent(),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModernSidebar() {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        border: Border(right: BorderSide(color: Colors.white.withOpacity(0.1))),
      ),
      child: Column(
        children: [
          const SizedBox(height: 60),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [const Color(0xFFD4AF37), const Color(0xFFD4AF37).withOpacity(0.5)],
              ),
              boxShadow: [
                BoxShadow(color: const Color(0xFFD4AF37).withOpacity(0.3), blurRadius: 20)
              ],
            ),
            child: const Icon(Icons.shield_rounded, size: 50, color: Colors.black),
          ),
          const SizedBox(height: 20),
          Text(
            "ODYSSEY",
            style: GoogleFonts.outfit(
              color: const Color(0xFFD4AF37),
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: 4,
            ),
          ),
          Text(
            "ADMIN PANEL",
            style: GoogleFonts.inter(
              color: Colors.white38,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 60),
          _buildMenuItem("Overview", Icons.grid_view_rounded),
          _buildMenuItem("Users", Icons.group_rounded),
          _buildMenuItem("Trips", Icons.explore_rounded),
          const Spacer(),
          _buildExitButton(),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildExitButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        leading: const Icon(Icons.power_settings_new_rounded, color: Colors.redAccent),
        title: Text("EXIT", style: GoogleFonts.inter(color: Colors.redAccent, fontWeight: FontWeight.bold, letterSpacing: 1)),
        onTap: () => Navigator.pop(context),
        hoverColor: Colors.redAccent.withOpacity(0.1),
      ),
    );
  }

  // Logic to choose which section to show
  Widget _buildMainContent() {
    if (_selectedView == "Overview") return _buildOverviewSection();
    if (_selectedView == "Users") return _buildUsersSection();
    if (_selectedView == "Trips") return _buildTripsSection();
    return _buildOverviewSection();
  }

  Widget _buildMenuItem(String title, IconData icon) {
    bool isSelected = _selectedView == title;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: isSelected
              ? LinearGradient(
                  colors: [const Color(0xFFD4AF37).withOpacity(0.2), Colors.transparent],
                )
              : null,
          border: isSelected ? Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3)) : null,
        ),
        child: ListTile(
          leading: Icon(icon, color: isSelected ? const Color(0xFFD4AF37) : Colors.white38),
          title: Text(
            title.toUpperCase(),
            style: GoogleFonts.inter(
              color: isSelected ? Colors.white : Colors.white38,
              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w500,
              fontSize: 13,
              letterSpacing: 1.5,
            ),
          ),
          onTap: () => _switchView(title),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
      ),
    );
  }

  // ==================================================
  //          VIEW 1: OVERVIEW (With Charts)
  // ==================================================
  Widget _buildOverviewSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "DASHBOARD OVERVIEW",
          style: GoogleFonts.outfit(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 40),

        // 1. STATS CARDS
        Row(
          children: [
            Expanded(
                child: _buildLiveStatCard(
                    "users", "TOTAL USERS", Icons.people_alt_rounded, const Color(0xFF1E88E5))),
            const SizedBox(width: 25),
            Expanded(
                child: _buildLiveStatCard(
                    "trips", "TRIPS GENERATED", Icons.auto_awesome_rounded, const Color(0xFFD4AF37))),
            const SizedBox(width: 25),
            Expanded(
                child: _buildStatCard("SYSTEM STATUS", "ACTIVE",
                    Icons.verified_user_rounded, Colors.green)),
          ],
        ),

        const SizedBox(height: 40),

        // 2. ANALYTICS CHART & RECENT ACTIVITY
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- CHART SECTION ---
              Expanded(
                flex: 4,
                child: _buildGlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("ACTIVITY TRENDS",
                              style: GoogleFonts.inter(
                                  fontSize: 14, fontWeight: FontWeight.w900, color: const Color(0xFFD4AF37), letterSpacing: 1.5)),
                          const Icon(Icons.show_chart_rounded, color: Colors.white24),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text("TRIPS GENERATED (LAST 7 DAYS)", style: GoogleFonts.inter(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                      const SizedBox(height: 30),
                      Expanded(
                        child: StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('trips')
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)));
                            var trips = snapshot.data!.docs;
                            if (trips.isEmpty) return const Center(child: Text("NO DATA", style: TextStyle(color: Colors.white24)));

                            // 1. Process data for Line Chart (Trips over last 7 days)
                            Map<DateTime, int> activityData = {};
                            DateTime now = DateTime.now();
                            for (int i = 0; i < 7; i++) {
                              DateTime date = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
                              activityData[date] = 0;
                            }

                            for (var trip in trips) {
                              var data = trip.data() as Map<String, dynamic>;
                              if (data['createdAt'] != null) {
                                Timestamp t = data['createdAt'];
                                DateTime tripDate = DateTime(t.toDate().year, t.toDate().month, t.toDate().day);
                                if (activityData.containsKey(tripDate)) {
                                  activityData[tripDate] = activityData[tripDate]! + 1;
                                }
                              }
                            }

                            List<FlSpot> spots = [];
                            var sortedKeys = activityData.keys.toList()..sort();
                            for (int i = 0; i < sortedKeys.length; i++) {
                              spots.add(FlSpot(i.toDouble(), activityData[sortedKeys[i]]!.toDouble()));
                            }

                            return LineChart(
                              LineChartData(
                                gridData: FlGridData(
                                  show: true,
                                  drawVerticalLine: false,
                                  getDrawingHorizontalLine: (value) => FlLine(color: Colors.white.withOpacity(0.05), strokeWidth: 1),
                                ),
                                titlesData: FlTitlesData(
                                  show: true,
                                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (value, meta) {
                                        if (value.toInt() < 0 || value.toInt() >= sortedKeys.length) return const Text("");
                                        return Text(
                                          DateFormat('MMM d').format(sortedKeys[value.toInt()]),
                                          style: const TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold),
                                        );
                                      },
                                    ),
                                  ),
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (value, meta) => Text(value.toInt().toString(), style: const TextStyle(color: Colors.white24, fontSize: 10)),
                                    ),
                                  ),
                                ),
                                borderData: FlBorderData(show: false),
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: spots,
                                    isCurved: true,
                                    color: const Color(0xFFD4AF37),
                                    barWidth: 4,
                                    isStrokeCapRound: true,
                                    dotData: FlDotData(
                                      show: true,
                                      getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                                        radius: 4,
                                        color: Colors.black,
                                        strokeWidth: 2,
                                        strokeColor: const Color(0xFFD4AF37),
                                      ),
                                    ),
                                    belowBarData: BarAreaData(
                                      show: true,
                                      gradient: LinearGradient(
                                        colors: [const Color(0xFFD4AF37).withOpacity(0.3), Colors.transparent],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              duration: const Duration(milliseconds: 1000),
                              curve: Curves.easeInOutCubic,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 30),

              // --- RECENT TRIPS LIST ---
              Expanded(
                flex: 6,
                child: _buildGlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("RECENT REQUESTS",
                              style: GoogleFonts.inter(
                                  fontSize: 14, fontWeight: FontWeight.w900, color: const Color(0xFFD4AF37), letterSpacing: 1.5)),
                          const Icon(Icons.history_rounded, color: Colors.white24),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('trips')
                              .orderBy('createdAt', descending: true)
                              .limit(10)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)));
                            if (snapshot.data!.docs.isEmpty) return const Center(child: Text("NO RECENT ACTIVITY", style: TextStyle(color: Colors.white24)));

                            return ListView.builder(
                              itemCount: snapshot.data!.docs.length,
                              itemBuilder: (context, index) {
                                var trip = snapshot.data!.docs[index];
                                var data = trip.data() as Map<String, dynamic>;
                                return _buildLuxuryListTile(data);
                              },
                            );
                          },
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
    );
  }


  Widget _buildLuxuryListTile(Map<String, dynamic> data) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFD4AF37).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.airplane_ticket_rounded, color: Color(0xFFD4AF37)),
          ),
          title: Text(
            (data['destination'] ?? "Unknown").toUpperCase(),
            style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1),
          ),
          subtitle: Text(
            data['userEmail'] ?? "Anonymous",
            style: GoogleFonts.inter(color: Colors.white38, fontSize: 11),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                data['days'] ?? "",
                style: GoogleFonts.inter(color: const Color(0xFFD4AF37), fontWeight: FontWeight.w900, fontSize: 12),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Colors.white24),
            ],
          ),
          onTap: () => _showTripDetails(context, data['tripData'] ?? {}, data['destination'] ?? "Trip"),
        ),
      ),
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 40, offset: const Offset(0, 10))
        ],
      ),
      child: child,
    );
  }

  // ==================================================
  //          VIEW 2: USERS MANAGER
  // ==================================================
  Widget _buildUsersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("MANAGE USERS", style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5)),
        const SizedBox(height: 25),
        _buildSearchBar("Search Users by Name or Email..."),
        const SizedBox(height: 25),
        Expanded(
          child: _buildGlassCard(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting)
                  return const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)));
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
                  return const Center(child: Text("NO USERS FOUND", style: TextStyle(color: Colors.white24)));

                var filteredDocs = snapshot.data!.docs.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  String name = (data['name'] ?? "").toLowerCase();
                  String email = (data['email'] ?? "").toLowerCase();
                  return name.contains(_searchQuery) ||
                      email.contains(_searchQuery);
                }).toList();

                if (filteredDocs.isEmpty)
                  return const Center(child: Text("NO MATCHES FOUND", style: TextStyle(color: Colors.white24)));

                return ListView.builder(
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    var userDoc = filteredDocs[index];
                    var data = userDoc.data() as Map<String, dynamic>;
                    return _buildLuxuryUserTile(userDoc.id, data);
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLuxuryUserTile(String docId, Map<String, dynamic> data) {
    String name = data['name'] ?? "Unknown";
    String email = data['email'] ?? "No Email";
    String role = data['role'] ?? "user";
    bool isAdmin = role == 'admin';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (isAdmin ? Colors.redAccent : const Color(0xFFD4AF37)).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(isAdmin ? Icons.admin_panel_settings_rounded : Icons.person_rounded, 
                  color: isAdmin ? Colors.redAccent : const Color(0xFFD4AF37), size: 20),
          ),
          title: Text(name.toUpperCase(), style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1)),
          subtitle: Text(email, style: GoogleFonts.inter(color: Colors.white38, fontSize: 11)),
          trailing: !isAdmin ? IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.white24, size: 20),
            onPressed: () => _confirmDeleteUser(context, docId, email),
            hoverColor: Colors.redAccent.withOpacity(0.1),
          ) : Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.redAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(5),
            ),
            child: const Text("ADMIN", style: TextStyle(color: Colors.redAccent, fontSize: 9, fontWeight: FontWeight.bold)),
          ),
          onTap: () => _showUserDetails(context, data),
        ),
      ),
    );
  }

  // ==================================================
  //          VIEW 3: TRIPS MANAGER
  // ==================================================
  Widget _buildTripsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("MANAGE TRIPS", style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5)),
        const SizedBox(height: 25),
        _buildSearchBar("Search Trips by Destination or User..."),
        const SizedBox(height: 25),
        Expanded(
          child: _buildGlassCard(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('trips')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting)
                  return const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)));
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
                  return const Center(child: Text("NO TRIPS FOUND", style: TextStyle(color: Colors.white24)));

                var filteredDocs = snapshot.data!.docs.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  String dest = (data['destination'] ?? "").toLowerCase();
                  String email = (data['userEmail'] ?? "").toLowerCase();
                  return dest.contains(_searchQuery) ||
                      email.contains(_searchQuery);
                }).toList();

                if (filteredDocs.isEmpty)
                  return const Center(child: Text("NO MATCHES FOUND", style: TextStyle(color: Colors.white24)));

                return ListView.builder(
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    var trip = filteredDocs[index];
                    var data = trip.data() as Map<String, dynamic>;
                    return _buildLuxuryTripTile(trip.id, data);
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLuxuryTripTile(String docId, Map<String, dynamic> data) {
    String dest = data['destination'] ?? "Unknown";
    String email = data['userEmail'] ?? "Anonymous";
    String days = data['days'] ?? "? Days";
    String dateText = "Unknown Date";
    if (data['createdAt'] != null) {
      Timestamp t = data['createdAt'];
      dateText = DateFormat('MMM d, h:mm a').format(t.toDate());
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.orangeAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.location_on_rounded, color: Colors.orangeAccent, size: 20),
          ),
          title: Text(dest.toUpperCase(), style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1)),
          subtitle: Text("$email • $dateText", style: GoogleFonts.inter(color: Colors.white38, fontSize: 11)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(days, style: GoogleFonts.inter(color: const Color(0xFFD4AF37), fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(width: 15),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.white24, size: 20),
                onPressed: () {
                  FirebaseFirestore.instance.collection('trips').doc(docId).delete();
                },
                hoverColor: Colors.redAccent.withOpacity(0.1),
              ),
            ],
          ),
          onTap: () => _showTripDetails(context, data['tripData'] ?? {}, dest),
        ),
      ),
    );
  }

  // --- REUSABLE SEARCH BAR ---
  Widget _buildSearchBar(String hint) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint.toUpperCase(),
          hintStyle: GoogleFonts.inter(color: Colors.white24, fontSize: 11, letterSpacing: 1, fontWeight: FontWeight.bold),
          prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFFD4AF37), size: 18),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 20),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value.toLowerCase();
          });
        },
      ),
    );
  }

  // --- POPUP: TRIP DETAILS ---
  void _showTripDetails(
      BuildContext context, Map<String, dynamic> tripData, String title) {
    List itinerary = tripData['itinerary'] ?? [];
    String summary = tripData['summary'] ?? "No summary available.";

    showDialog(
      context: context,
      builder: (context) => Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              width: 500,
              height: 650,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
                boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 40)],
              ),
              padding: const EdgeInsets.all(35),
              child: Material(
                color: Colors.transparent,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            "TRIP TO ${title.toUpperCase()}",
                            style: GoogleFonts.outfit(color: const Color(0xFFD4AF37), fontSize: 22, fontWeight: FontWeight.w900),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Colors.white24),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text(
                        summary,
                        style: GoogleFonts.inter(color: Colors.white70, fontSize: 13, height: 1.5),
                      ),
                    ),
                    const SizedBox(height: 30),
                    Text(
                      "ITINERARY",
                      style: GoogleFonts.inter(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 2),
                    ),
                    const SizedBox(height: 15),
                    Expanded(
                      child: ListView.builder(
                        itemCount: itinerary.length,
                        itemBuilder: (context, index) {
                          var day = itinerary[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.02),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: const BoxDecoration(color: Color(0xFFD4AF37), shape: BoxShape.circle),
                                  child: Text("${day['day']}", style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                                ),
                                title: Text(day['title'] ?? "", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                subtitle: Text(day['description'] ?? "", style: GoogleFonts.inter(color: Colors.white38, fontSize: 12)),
                              ),
                            ),
                          );
                        },
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

  // --- POPUP: USER DETAILS ---
  void _showUserDetails(BuildContext context, Map<String, dynamic> data) {
    String name = data['name'] ?? "Unknown";
    String email = data['email'] ?? "No Email";
    String uid = data['uid'] ?? "Unknown UID";
    String dateText = "Unknown";

    if (data['createdAt'] != null) {
      Timestamp t = data['createdAt'];
      dateText = DateFormat('MMMM d, yyyy').format(t.toDate());
    }

    showDialog(
      context: context,
      builder: (ctx) => Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              width: 400,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              padding: const EdgeInsets.all(35),
              child: Material(
                color: Colors.transparent,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: const Color(0xFFD4AF37).withOpacity(0.1), shape: BoxShape.circle),
                      child: const Icon(Icons.person_outline_rounded, color: Color(0xFFD4AF37), size: 40),
                    ),
                    const SizedBox(height: 20),
                    Text(name.toUpperCase(), style: GoogleFonts.outfit(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 1)),
                    Text("USER PROFILE", style: GoogleFonts.inter(color: const Color(0xFFD4AF37), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2)),
                    const SizedBox(height: 30),
                    _luxuryDetailRow("EMAIL ADDRESS", email),
                    _luxuryDetailRow("UNIQUE IDENTIFIER", uid),
                    _luxuryDetailRow("REGISTRATION DATE", dateText),
                    _luxuryDetailRow("ACCOUNT ROLE", (data['role'] ?? 'user').toUpperCase()),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          backgroundColor: Colors.white.withOpacity(0.05),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                        onPressed: () => Navigator.pop(ctx),
                        child: Text("DISMISS", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
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

  Widget _luxuryDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.inter(color: Colors.white24, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const SizedBox(height: 5),
          SelectableText(value, style: GoogleFonts.inter(color: Colors.white, fontSize: 14)),
          const Divider(color: Colors.white10),
        ],
      ),
    );
  }



  void _confirmDeleteUser(BuildContext context, String docId, String email) {
    showDialog(
      context: context,
      builder: (ctx) => Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              width: 350,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.9),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.redAccent.withOpacity(0.2)),
              ),
              padding: const EdgeInsets.all(35),
              child: Material(
                color: Colors.transparent,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 50),
                    const SizedBox(height: 20),
                    Text("TERMINATE DATA", style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 15),
                    Text(
                      "Are you sure you want to permanently remove data for $email?\nThis action is irreversible.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(color: Colors.white70, fontSize: 13, height: 1.5),
                    ),
                    const SizedBox(height: 30),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: Text("CANCEL", style: GoogleFonts.inter(color: Colors.white38, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 15),
                            ),
                            onPressed: () async {
                              await FirebaseFirestore.instance.collection('users').doc(docId).delete();
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(backgroundColor: Colors.redAccent, content: Text("User data successfully purged.")),
                              );
                            },
                            child: Text("PURGE", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
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

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 20)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(title,
                style: GoogleFonts.inter(
                    color: Colors.white38, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1.5)),
            Icon(icon, color: color.withOpacity(0.8), size: 28)
          ]),
          const SizedBox(height: 15),
          Text(value,
              style: GoogleFonts.outfit(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildLiveStatCard(
      String collection, String title, IconData icon, Color color) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection(collection).snapshots(),
      builder: (context, snapshot) {
        String count =
            snapshot.hasData ? snapshot.data!.docs.length.toString() : "...";
        return _buildStatCard(title, count, icon, color);
      },
    );
  }
}
