import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DestinationDetailPage extends StatefulWidget {
  final Map<String, String> destination;

  const DestinationDetailPage({super.key, required this.destination});

  @override
  State<DestinationDetailPage> createState() => _DestinationDetailPageState();
}

class _DestinationDetailPageState extends State<DestinationDetailPage> with SingleTickerProviderStateMixin {
  late AnimationController _zoomController;

  @override
  void initState() {
    super.initState();
    _zoomController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 40),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _zoomController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String title = widget.destination['title']!;
    final details = _getDetails(title);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 0. GLOBAL TEXTURED BACKGROUND
          Positioned.fill(
            child: Opacity(
              opacity: 0.05,
              child: Image.asset(
                'assets/hero_bg.png',
                fit: BoxFit.cover,
              ),
            ),
          ),

          // 1. HERO BACKGROUND IMAGE
          Positioned.fill(
            child: Hero(
              tag: 'card_image_${widget.destination['title']}',
              child: AnimatedBuilder(
                animation: _zoomController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 1.0 + (_zoomController.value * 0.15),
                    child: child,
                  );
                },
                child: Image.asset(
                  widget.destination['image']!,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

          // 2. GLASSY OVERLAY
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.2),
                    Colors.black.withOpacity(0.8),
                  ],
                ),
              ),
            ),
          ),

          // 3. CONTENT
          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Back Button
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 30),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(height: 100),

                        // Title & Location
                        Hero(
                          tag: 'card_location_${widget.destination['title']}',
                          child: Material(
                            color: Colors.transparent,
                            child: Text(
                              widget.destination['location']!.toUpperCase(),
                              style: GoogleFonts.outfit(
                                color: const Color(0xFFD4AF37),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 4,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),
                        Hero(
                          tag: 'card_title_${widget.destination['title']}',
                          child: Material(
                            color: Colors.transparent,
                            child: Text(
                              title,
                              style: GoogleFonts.bodoniModa(
                                color: Colors.white,
                                fontSize: 64,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),

                        // Description
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 600),
                          child: Text(
                            details['description'],
                            style: GoogleFonts.outfit(
                              color: Colors.white70,
                              fontSize: 20,
                              height: 1.6,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ),
                        const SizedBox(height: 80),

                        // Attractions Section
                        Text(
                          "MAJOR ATTRACTIONS",
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 4,
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),

                // Grid of Attractions
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 0),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 30,
                      mainAxisSpacing: 30,
                      childAspectRatio: 2.5,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final attraction = details['attractions'][index];
                        return _buildAttractionCard(attraction);
                      },
                      childCount: details['attractions'].length,
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttractionCard(Map<String, String> attraction) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: Stack(
          children: [
            // High Quality Image (Local Asset)
            Positioned.fill(
              child: Image.asset(
                attraction['image']!,
                fit: BoxFit.cover,
              ),
            ),
            // Glassy Overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.9),
                    ],
                  ),
                ),
              ),
            ),
            // Text Content
            Padding(
              padding: const EdgeInsets.all(25.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    attraction['name']!,
                    style: GoogleFonts.outfit(
                      color: const Color(0xFFD4AF37),
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    attraction['description']!,
                    style: GoogleFonts.outfit(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                      height: 1.4,
                      fontWeight: FontWeight.w400,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _getDetails(String title) {
    final Map<String, dynamic> destinationDetails = {
      "Skydiving": {
        "description": "Experience the ultimate adrenaline rush over the iconic Palm Jumeirah in Dubai. Feel the wind as you plummet from 13,000 feet with the Arabian Gulf beneath you.",
        "attractions": [
          {
            "name": "Palm Jumeirah", 
            "description": "The world's largest man-made island, a feat of modern engineering.",
            "image": "assets/attractions/palm_jumeirah.png"
          },
          {
            "name": "Burj Khalifa", 
            "description": "The global icon of architectural excellence and human ingenuity.",
            "image": "assets/attractions/burj_khalifa.png"
          },
          {
            "name": "Dubai Marina", 
            "description": "A vibrant waterfront community known for its high-rise luxury lifestyle.",
            "image": "assets/attractions/dubai_marina.png"
          },
          {
            "name": "Dubai Mall", 
            "description": "A premier destination for world-class shopping, dining, and leisure.",
            "image": "assets/attractions/dubai_mall.png"
          }
        ]
      },
      "Swiss Express": {
        "description": "Journey through the heart of the Alps on some of the world's most scenic trains. Discover snow-capped peaks, crystal clear lakes, and charming mountain villages.",
        "attractions": [
          {
            "name": "Jungfraujoch", 
            "description": "Ascend to the highest railway station in Europe for breathtaking views.",
            "image": "assets/attractions/jungfraujoch.png"
          },
          {
            "name": "Matterhorn", 
            "description": "Stand in awe of Switzerland's most recognizable and majestic peak.",
            "image": "assets/attractions/matterhorn.png"
          },
          {
            "name": "Lake Lucerne", 
            "description": "Explore the historic heart of Switzerland by legendary steamboat.",
            "image": "assets/attractions/lake_lucerne.png"
          },
          {
            "name": "Zermatt", 
            "description": "The ultimate car-free mountain resort town at the foot of the Alps.",
            "image": "assets/attractions/zermatt.png"
          }
        ]
      },
      "City Lights": {
        "description": "Discover the vibrant energy and neon glow of Tokyo's bustling metropolises. A perfect blend of ancient tradition and cutting-edge technology.",
        "attractions": [
          {
            "name": "Shibuya Crossing", 
            "description": "Experience the organized chaos of the world's busiest intersection.",
            "image": "assets/attractions/shibuya.png"
          },
          {
            "name": "Tokyo Tower", 
            "description": "Gaze across the vast city lights from this iconic orange landmark.",
            "image": "assets/attractions/tokyo_tower.png"
          },
          {
            "name": "Senso-ji Temple", 
            "description": "Step back in time at Tokyo's oldest and most sacred Buddhist temple.",
            "image": "assets/attractions/sensoji.png"
          },
          {
            "name": "Akihabara", 
            "description": "Dive into the global hub for electronics, anime, gaming, and otaku culture.",
            "image": "assets/attractions/akihabara.png"
          }
        ]
      },
      "Skyline": {
        "description": "Marvel at the architectural wonders that define Dubai's world-famous horizon. Witness the evolution of a desert oasis into a global metropolis.",
        "attractions": [
          {
            "name": "Burj Al Arab", 
            "description": "The sail-shaped architectural masterpiece and peak of luxury.",
            "image": "assets/attractions/burj_al_arab.png"
          },
          {
            "name": "Museum of the Future", 
            "description": "Explore the world's most beautiful building and visionary technology.",
            "image": "assets/attractions/museum_future.png"
          },
          {
            "name": "The View at The Palm", 
            "description": "Get the perfect 360-degree panoramic perspective of the island.",
            "image": "assets/attractions/palm_jumeirah.png"
          },
          {
            "name": "Dubai Fountain", 
            "description": "Witness the mesmerizing dance of water, light, and music at night.",
            "image": "assets/attractions/dubai_fountain.png"
          }
        ]
      },
    };

    return destinationDetails[title] ?? {
      "description": "Discover the hidden gems of this magnificent destination.",
      "attractions": []
    };
  }
}
