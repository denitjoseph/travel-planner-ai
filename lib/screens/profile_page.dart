import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:ui' as ui;
import '../widgets/navbar.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final User? user = FirebaseAuth.instance.currentUser;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;
  bool _isEditing = false;
  int _tripCount = 0;
  String _joinDate = "Unknown";
  XFile? _pickedFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (user == null) return;
    _nameController.text = user!.displayName ?? "Traveler";
    _emailController.text = user!.email ?? "";
    try {
      var userDoc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
      if (userDoc.exists && userDoc.data()!.containsKey('createdAt')) {
        Timestamp t = userDoc['createdAt'];
        setState(() {
          _joinDate = DateFormat('MMMM d, yyyy').format(t.toDate());
        });
      }
      var trips = await FirebaseFirestore.instance.collection('trips').where('userId', isEqualTo: user!.uid).get();
      setState(() {
        _tripCount = trips.docs.length;
      });
    } catch (e) {
      debugPrint("Error loading profile data: $e");
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? selected = await _picker.pickImage(source: source);
    if (selected != null) {
      setState(() {
        _pickedFile = selected;
      });
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 20),
          const Text("PROFILE PHOTOGRAPHY", style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold, letterSpacing: 2)),
          const SizedBox(height: 20),
          ListTile(
            leading: const Icon(Icons.camera_alt, color: Colors.white),
            title: const Text("Capture Live Moment", style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              _pickImage(ImageSource.camera);
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library, color: Colors.white),
            title: const Text("Select from Gallery", style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              _pickImage(ImageSource.gallery);
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Future<void> _updateProfile() async {
    if (_nameController.text.trim().isEmpty) return;

    setState(() => _isLoading = true);

    try {
      // 1. Update Firebase Auth (The Login System)
      await user!.updateDisplayName(_nameController.text.trim());

      // 2. Update Firestore (The Database)
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .update({
        'name': _nameController.text.trim(),
      });

      setState(() {
        _isEditing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Profile updated successfully!"),
            backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Error updating profile: $e"),
            backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. CINEMATIC BACKGROUND
          Positioned.fill(
            child: Image.asset(
              'assets/plan_hero_bg.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.8)),
          ),

          // 2. CONTENT
          Column(
            children: [
              const NavBar(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                  child: Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 800),
                      child: Column(
                        children: [
                          // --- LUXURY PROFILE HEADER ---
                          Stack(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0xFFD4AF37), width: 2),
                                ),
                                child: CircleAvatar(
                                  radius: 80,
                                  backgroundColor: const Color(0xFF1A1A1A),
                                  backgroundImage: _pickedFile != null
                                      ? (kIsWeb
                                          ? NetworkImage(_pickedFile!.path)
                                          : FileImage(File(_pickedFile!.path)) as ImageProvider)
                                      : (user?.photoURL != null ? NetworkImage(user!.photoURL!) : null) as ImageProvider?,
                                  child: _pickedFile == null && user?.photoURL == null
                                      ? const Icon(Icons.person, size: 80, color: Color(0xFFD4AF37))
                                      : null,
                                ),
                              ),
                              Positioned(
                                bottom: 5,
                                right: 5,
                                child: InkWell(
                                  onTap: _showImagePickerOptions,
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFD4AF37),
                                      shape: BoxShape.circle,
                                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10)],
                                    ),
                                    child: const Icon(Icons.camera_alt, color: Colors.black, size: 24),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 30),
                          Text(
                            _isEditing ? "EDIT CHRONICLE" : "YOUR ODYSSEY PROFILE",
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFD4AF37),
                              letterSpacing: 4,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "Member since $_joinDate",
                            style: TextStyle(color: Colors.white.withOpacity(0.5), letterSpacing: 1),
                          ),

                          const SizedBox(height: 40),

                          // --- STATS CARD (Luxury Glassmorphic) ---
                          ClipRRect(
                            borderRadius: BorderRadius.circular(25),
                            child: BackdropFilter(
                              filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 30),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(25),
                                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildStatItem("Trips Chartered", _tripCount.toString(), Icons.explore_outlined),
                                    _buildStatItem("Explorer Status", "Elite", Icons.workspace_premium_outlined),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 30),

                          // --- EDIT FORM (Luxury Glassmorphic) ---
                          ClipRRect(
                            borderRadius: BorderRadius.circular(25),
                            child: BackdropFilter(
                              filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Container(
                                padding: const EdgeInsets.all(40),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.03),
                                  borderRadius: BorderRadius.circular(25),
                                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLabel("FULL NAME"),
                                    TextField(
                                      controller: _nameController,
                                      enabled: _isEditing,
                                      style: const TextStyle(color: Colors.white, fontSize: 18),
                                      decoration: InputDecoration(
                                        prefixIcon: const Icon(Icons.person_outline, color: Color(0xFFD4AF37)),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(15),
                                          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(15),
                                          borderSide: const BorderSide(color: Color(0xFFD4AF37)),
                                        ),
                                        disabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(15),
                                          borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
                                        ),
                                        filled: true,
                                        fillColor: Colors.white.withOpacity(0.02),
                                      ),
                                    ),
                                    const SizedBox(height: 25),
                                    _buildLabel("SECURE EMAIL (UNMODIFIABLE)"),
                                    TextField(
                                      controller: _emailController,
                                      enabled: false,
                                      style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 16),
                                      decoration: InputDecoration(
                                        prefixIcon: Icon(Icons.email_outlined, color: Colors.white.withOpacity(0.2)),
                                        disabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(15),
                                          borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
                                        ),
                                        filled: true,
                                        fillColor: Colors.white.withOpacity(0.01),
                                      ),
                                    ),
                                    const SizedBox(height: 40),

                                    // --- ACTION BUTTONS ---
                                    if (_isEditing)
                                      Row(
                                        children: [
                                          Expanded(
                                            child: TextButton(
                                              onPressed: () => setState(() => _isEditing = false),
                                              style: TextButton.styleFrom(
                                                padding: const EdgeInsets.symmetric(vertical: 20),
                                              ),
                                              child: Text("CANCEL", style: TextStyle(color: Colors.white.withOpacity(0.5), fontWeight: FontWeight.bold, letterSpacing: 2)),
                                            ),
                                          ),
                                          const SizedBox(width: 20),
                                          Expanded(
                                            child: ElevatedButton(
                                              onPressed: _isLoading ? null : _updateProfile,
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFFD4AF37),
                                                foregroundColor: Colors.black,
                                                padding: const EdgeInsets.symmetric(vertical: 20),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                              ),
                                              child: _isLoading
                                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                                                  : const Text("SAVE CHANGES", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2)),
                                            ),
                                          ),
                                        ],
                                      )
                                    else
                                      SizedBox(
                                        width: double.infinity,
                                        child: OutlinedButton.icon(
                                          onPressed: () => setState(() => _isEditing = true),
                                          icon: const Icon(Icons.edit_note, size: 24),
                                          label: const Text("UPDATE CHRONICLE", style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold)),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: const Color(0xFFD4AF37),
                                            side: const BorderSide(color: Color(0xFFD4AF37)),
                                            padding: const EdgeInsets.symmetric(vertical: 20),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
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
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFD4AF37), fontSize: 10, letterSpacing: 2)),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFFD4AF37), size: 32),
        const SizedBox(height: 12),
        Text(value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
      ],
    );
  }
}
