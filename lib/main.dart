import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // 1. Import Firebase
import 'firebase_options.dart'; // 2. Import the generated config file
import 'screens/home_page.dart';

// 3. Convert main() to async so we can wait for Firebase
void main() async {
  // 4. Ensure Flutter bindings are initialized before Firebase
  WidgetsFlutterBinding.ensureInitialized();

  // 5. Initialize Firebase using the generated options for your platform
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const OdysseyApp());
}

class OdysseyApp extends StatelessWidget {
  const OdysseyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Odyssey - Intelligent Trip Guide',
      theme: ThemeData(
        useMaterial3:
            true, // Enable Material 3 for better looking UI components
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFD4AF37)), // Golden Seed
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Montserrat', // Modern font
      ),
      home: const HomePage(),
    );
  }
}
