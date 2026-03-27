import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../widgets/navbar.dart';
import '../utils/pdf_generator.dart';
import '../widgets/scroll_reveal_widget.dart';
import '../widgets/mouse_glow_widget.dart';

class MyTripsPage extends StatefulWidget {
  const MyTripsPage({super.key});

  @override
  State<MyTripsPage> createState() => _MyTripsPageState();
}

class _MyTripsPageState extends State<MyTripsPage> with TickerProviderStateMixin {
  late AnimationController _bgController;
  late AnimationController _floatController;
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 40),
    )..repeat(reverse: true);

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _scrollController.addListener(() {
      setState(() {
        _scrollOffset = _scrollController.offset;
      });
    });
  }

  @override
  void dispose() {
    _bgController.dispose();
    _floatController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(seconds: 2),
              curve: Curves.easeIn,
              builder: (context, opacity, child) {
                return Opacity(
                  opacity: opacity,
                  child: AnimatedBuilder(
                    animation: _bgController,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, -_scrollOffset * 0.3),
                        child: Transform.scale(
                          scale: 1.1 + (_bgController.value * 0.1),
                          child: Image.asset(
                            'assets/my_trips_premium_bg.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
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
                    Colors.black.withOpacity(0.8),
                  ],
                ),
              ),
            ),
          ),

          Positioned.fill(
            child: SafeArea(
              child: MouseGlowEffect(
                child: AnimatedContainer(
                  duration: const Duration(seconds: 2),
                  curve: Curves.easeInOut,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.2),
                  ),
                  child: Column(
                    children: [
                      const NavBar(),
                      Expanded(
                        child: user == null
                            ? _buildEmptyState("Please login to view your trips.", Icons.lock_outline)
                            : StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('trips')
                                    .where('userId', isEqualTo: user.uid)
                                    .snapshots(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return const Center(
                                      child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
                                    );
                                  }

                                  if (snapshot.hasError) {
                                    return _buildEmptyState("Error: ${snapshot.error}", Icons.error_outline);
                                  }

                                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                                    return _buildEmptyState("No trips saved yet.", Icons.map_outlined);
                                  }

                                  var trips = snapshot.data!.docs;

                                  return ListView.builder(
                                    controller: _scrollController,
                                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
                                    itemCount: trips.length,
                                    itemBuilder: (context, index) {
                                      var data = trips[index].data() as Map<String, dynamic>;
                                      return ScrollReveal(
                                        controller: _scrollController,
                                        duration: Duration(milliseconds: 600 + (index * 100).clamp(0, 400)),
                                        child: _buildTripCard(context, data, trips[index].id, index),
                                      );
                                    },
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
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: const Color(0xFFD4AF37).withOpacity(0.3)),
          const SizedBox(height: 20),
          Text(
            message,
            style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 18, letterSpacing: 1),
          ),
          const SizedBox(height: 30),
          if (message.contains("No trips"))
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF37),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("BEGIN YOUR ODYSSEY", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }

  Widget _buildTripCard(BuildContext context, Map<String, dynamic> data, String docId, int index) {
    String dest = data['destination'] ?? "Unknown Destination";
    String source = data['source'] ?? "Unknown Source";
    String budget = data['budget'] ?? "N/A";
    String days = data['days'] ?? "? Days";
    Map<String, dynamic> tripData = data['tripData'] ?? {};

    String dateText = "Recent";
    if (data['createdAt'] != null && data['createdAt'] is Timestamp) {
      dateText = DateFormat('MMM d, yyyy').format((data['createdAt'] as Timestamp).toDate());
    }

    return AnimatedBuilder(
      animation: _floatController,
      builder: (context, child) {
        // Staggered float effect
        double offset = 10 * ui.lerpDouble(0, 1, (index % 3 == 0) ? _floatController.value : (1 - _floatController.value))!;
        return Transform.translate(
          offset: Offset(0, offset),
          child: child,
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 30),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.08),
                    Colors.white.withOpacity(0.02),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD4AF37).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.5)),
                            ),
                            child: const Text(
                              "ODYSSEY JOURNEY",
                              style: TextStyle(
                                color: Color(0xFFD4AF37),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "$dest Journey",
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Text(
                          days,
                          style: const TextStyle(
                            color: Color(0xFFD4AF37),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, color: Colors.white.withOpacity(0.5), size: 16),
                      const SizedBox(width: 8),
                      Text(
                        "From: $source",
                        style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
                      ),
                      const SizedBox(width: 20),
                      Icon(Icons.calendar_today_outlined, color: Colors.white.withOpacity(0.5), size: 16),
                      const SizedBox(width: 8),
                      Text(
                        "Date: $dateText",
                        style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Divider(color: Colors.white12),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "TOTAL BUDGET",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.4),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            budget,
                            style: const TextStyle(
                              color: Color(0xFFD4AF37),
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          _buildIconButton(
                            icon: Icons.delete_outline,
                            color: Colors.redAccent,
                            tooltip: "Delete Journey",
                            onTap: () async {
                              bool confirm = await _showDeleteConfirm(context);
                              if (confirm) {
                                await FirebaseFirestore.instance.collection('trips').doc(docId).delete();
                              }
                            },
                          ),
                          const SizedBox(width: 15),
                          _buildIconButton(
                            icon: Icons.picture_as_pdf_outlined,
                            color: const Color(0xFFD4AF37),
                            tooltip: "Export Experience",
                            onTap: () => PdfGenerator.generateAndPrint(tripData, dest),
                          ),
                          const SizedBox(width: 20),
                          ElevatedButton(
                            onPressed: () => _showTripDetails(context, tripData, dest),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD4AF37),
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            child: const Text("RELIVE PLAN", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
                          ),
                        ],
                      )
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton({required IconData icon, required Color color, required String tooltip, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  Future<bool> _showDeleteConfirm(BuildContext context) async {
    return await showDialog(
          context: context,
          builder: (context) => BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: AlertDialog(
              backgroundColor: const Color(0xFF1A1A1A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: const Color(0xFFD4AF37).withOpacity(0.3))),
              title: const Text("Delete Odyssey journey?", style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold)),
              content: Text("Are you sure you want to remove this journey from your chronicles?", style: TextStyle(color: Colors.white.withOpacity(0.7))),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text("RETAIN", style: TextStyle(color: Colors.white.withOpacity(0.5), letterSpacing: 1, fontWeight: FontWeight.bold)),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text("DELETE", style: TextStyle(color: Colors.redAccent, letterSpacing: 1, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ) ??
        false;
  }

  void _showTripDetails(BuildContext context, Map<String, dynamic> tripData, String title) {
    List itinerary = tripData['itinerary'] ?? [];
    String summary = tripData['summary'] ?? "No summary available.";

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            width: 800,
            height: 800,
            decoration: BoxDecoration(
              color: const Color(0xFF0F0F0F).withOpacity(0.95),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.2)),
            ),
            padding: const EdgeInsets.all(40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "JOURNEY CHRONICLE",
                            style: TextStyle(color: Color(0xFFD4AF37), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 3),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Trip to $title",
                            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white70),
                    )
                  ],
                ),
                const SizedBox(height: 30),
                Container(
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Text(
                    summary,
                    style: TextStyle(color: Colors.white.withOpacity(0.8), height: 1.6, fontSize: 16),
                  ),
                ),
                const SizedBox(height: 30),
                Expanded(
                  child: ListView.separated(
                    itemCount: itinerary.length,
                    separatorBuilder: (ctx, i) => const SizedBox(height: 20),
                    itemBuilder: (context, index) {
                      var day = itinerary[index];
                      return Container(
                        padding: const EdgeInsets.all(25),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.03),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.05)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFD4AF37).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3)),
                                  ),
                                  child: Text(
                                    "DAY ${day['day']}",
                                    style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFD4AF37), fontSize: 14),
                                  ),
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: Text(
                                    day['title'] ?? "",
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              day['description'] ?? "",
                              style: TextStyle(color: Colors.white.withOpacity(0.6), height: 1.5),
                            ),
                          ],
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
    );
  }
}
