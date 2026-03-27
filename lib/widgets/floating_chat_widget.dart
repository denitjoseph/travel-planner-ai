import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../utils/constants.dart';


class FloatingChatWidget extends StatefulWidget {
  const FloatingChatWidget({super.key});

  @override
  State<FloatingChatWidget> createState() => _FloatingChatWidgetState();
}

class _FloatingChatWidgetState extends State<FloatingChatWidget> with SingleTickerProviderStateMixin {
  bool _isOpen = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  final List<Map<String, String>> _messages = [
    {
      "role": "ai",
      "text":
          "Hi! 🤖 I'm your AI Travel Companion. How can I help you plan your next trip today?",
    },
  ];
  late final String _sessionId;

  // Voice Features
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  bool _isListening = false;
  bool _speechEnabled = false;
  bool _ttsEnabled = true;
  bool _sttEnabled = true;

  @override
  void initState() {
    super.initState();
    _sessionId = "floating_${DateTime.now().millisecondsSinceEpoch}";
    _initVoice();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _initVoice() async {
    _speechEnabled = await _speechToText.initialize();
    await _flutterTts.setLanguage("en-US");
    setState(() {});
  }

  void _startListening() async {
    await _speechToText.listen(
      onResult: (result) {
        setState(() {
          _controller.text = result.recognizedWords;
        });
        if (result.finalResult) {
          _stopListening();
          _sendMessage(_controller.text);
        }
      },
    );
    setState(() => _isListening = true);
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() => _isListening = false);
  }

  Future<void> _speak(String text) async {
    if (_ttsEnabled) await _flutterTts.speak(text);
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add({"role": "user", "text": text});
      _isLoading = true;
    });
    _controller.clear();
    _scrollToBottom();

    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/chat'),

        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"message": text, "session_id": _sessionId}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String aiResponse = data['response'];
        setState(() {
          _messages.add({"role": "ai", "text": aiResponse});
        });
        _speak(aiResponse); // Respect toggle inside _speak
      } else {
        setState(() {
          _messages.add({
            "role": "ai",
            "text": "Something glitched in my matrix! ⚡ Try that again?",
          });
        });
      }
    } catch (e) {
      setState(() {
        _messages.add({
          "role": "ai",
          "text": "Oops! I lost connection to the travel database. 🔌",
        });
      });
    } finally {
      setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 25,
      right: 25,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isOpen || !_animationController.isDismissed)
            ScaleTransition(
              scale: _scaleAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  width: 380,
                  height: 600,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(35),
                    border: Border.all(
                      color: const Color(0xFFD4AF37).withOpacity(0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFD4AF37).withOpacity(0.1),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(35),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Column(
                        children: [
                          // --- THEMED HEADER ---
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 15,
                            ),
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF1A1A1A), Color(0xFF000000)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              border: Border(
                                bottom: BorderSide(color: Color(0xFFD4AF37), width: 1),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Container(
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const CircleAvatar(
                                          radius: 20,
                                          backgroundColor: Colors.white,
                                          backgroundImage: AssetImage(
                                            'assets/bot_icon.png',
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              "Odyssey Intelligence",
                                              style: TextStyle(
                                                color: Color(0xFFD4AF37),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                                letterSpacing: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const Text(
                                              "AI TRAVEL CONCIERGE",
                                              style: TextStyle(
                                                color: Colors.white70,
                                                fontSize: 9,
                                                letterSpacing: 2,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        _ttsEnabled ? Icons.volume_up : Icons.volume_off,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                      onPressed: () => setState(() => _ttsEnabled = !_ttsEnabled),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.settings,
                                        color: Colors.white70,
                                        size: 18,
                                      ),
                                      onPressed: () => _showVoiceSettings(),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.close_rounded,
                                        color: Color(0xFFD4AF37),
                                        size: 24,
                                      ),
                                      onPressed: () {
                                        _animationController.reverse();
                                        Future.delayed(const Duration(milliseconds: 500), () {
                                          setState(() => _isOpen = false);
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // MESSAGES
                          Expanded(
                            child: Container(
                              color: Colors.transparent,
                              child: ListView.builder(
                                controller: _scrollController,
                                padding: const EdgeInsets.all(25),
                                itemCount: _messages.length,
                                itemBuilder: (context, index) {
                                  final msg = _messages[index];
                                  bool isUser = msg['role'] == "user";
                                  return _buildChatBubble(msg['text']!, isUser);
                                },
                              ),
                            ),
                          ),

                          if (_isLoading)
                            const Padding(
                              padding: EdgeInsets.only(bottom: 15),
                              child: Hero(
                                tag: 'ai_thinking',
                                child: Text(
                                  "REASONING IN PROGRESS... 🌌",
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFFD4AF37),
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ),
                            ),

                          // SUGGESTIONS
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            child: Row(
                              children: [
                                _buildSuggestionChip("🌬️ Weather Insights"),
                                _buildSuggestionChip("📍 Nearby Frontiers"),
                                _buildSuggestionChip("🍱 Culinary Guide"),
                                _buildSuggestionChip("🗺️ Master Plan"),
                              ],
                            ),
                          ),

                          // INPUT
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              border: Border(
                                top: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _controller,
                                    style: const TextStyle(fontSize: 14),
                                    decoration: InputDecoration(
                                      hintText: "Ask me something...",
                                      hintStyle: TextStyle(
                                        color: Colors.grey.shade400,
                                      ),
                                      filled: true,
                                      fillColor: const Color(0xFFF8FAFC),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(15),
                                        borderSide: BorderSide.none,
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 15,
                                        vertical: 10,
                                      ),
                                    ),
                                    onSubmitted: _sendMessage,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                GestureDetector(
                                  onTap: _sttEnabled && _speechEnabled
                                      ? (_isListening ? _stopListening : _startListening)
                                      : () => setState(() => _sttEnabled = !_sttEnabled),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    margin: const EdgeInsets.only(right: 8),
                                    decoration: BoxDecoration(
                                      color: _sttEnabled ? Colors.blue.shade50 : Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      _sttEnabled ? (_isListening ? Icons.mic : Icons.mic_none) : Icons.mic_off,
                                      color: _sttEnabled ? Colors.blue : Colors.grey,
                                      size: 20,
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => _sendMessage(_controller.text),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFD4AF37),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.send_rounded,
                                      color: Colors.black,
                                      size: 20,
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

          // --- THEMED FLOATING BUTTON ---
          GestureDetector(
            onTap: () {
              if (FirebaseAuth.instance.currentUser == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text("Access Denied. Please authenticate to use Odyssey Intelligence. 🔐")),
                );
                return;
              }
              setState(() {
                if (_isOpen) {
                  _animationController.reverse();
                  Future.delayed(const Duration(milliseconds: 500), () {
                    setState(() => _isOpen = false);
                  });
                } else {
                  _isOpen = true;
                  _animationController.forward();
                }
              });
            },
            child: Container(
              width: 65,
              height: 65,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFD4AF37), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFD4AF37).withOpacity(0.3),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
                image: const DecorationImage(
                  image: AssetImage('assets/bot_icon.png'),
                  fit: BoxFit.cover,
                ),
              ),
              child: _isOpen
                  ? const Icon(
                      Icons.close_rounded,
                      color: Color(0xFFD4AF37),
                      size: 30,
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(String text, bool isUser) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(isUser ? (1.0 - value) * 50 : (value - 1.0) * 50, 0),
          child: Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Row(
                mainAxisAlignment:
                    isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                children: [
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                      decoration: BoxDecoration(
                        gradient: isUser
                            ? const LinearGradient(
                                colors: [Color(0xFFD4AF37), Color(0xFFB8860B)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : LinearGradient(
                                colors: [Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.05)],
                              ),
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(25),
                          topRight: const Radius.circular(25),
                          bottomLeft: Radius.circular(isUser ? 25 : 0),
                          bottomRight: Radius.circular(isUser ? 0 : 25),
                        ),
                        border: Border.all(
                          color: isUser ? Colors.white24 : const Color(0xFFD4AF37).withOpacity(0.2),
                        ),
                      ),
                      child: Text(
                        text,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.4,
                          color: isUser ? Colors.black : Colors.white.withOpacity(0.9),
                          fontWeight: isUser ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSuggestionChip(String text) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: ActionChip(
        label: Text(
          text.toUpperCase(),
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFD4AF37), letterSpacing: 1),
        ),
        onPressed: () => _sendMessage(text),
        backgroundColor: Colors.white.withOpacity(0.05),
        side: BorderSide(color: const Color(0xFFD4AF37).withOpacity(0.3)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }

  void _showVoiceSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Voice Settings"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text("AI Voice (TTS)"),
              subtitle: const Text("Bot will read answers"),
              value: _ttsEnabled,
              onChanged: (val) {
                setState(() => _ttsEnabled = val);
                Navigator.pop(context);
                _showVoiceSettings();
              },
            ),
            SwitchListTile(
              title: const Text("Voice Input (STT)"),
              subtitle: const Text("Tap mic to speak"),
              value: _sttEnabled,
              onChanged: (val) {
                setState(() => _sttEnabled = val);
                Navigator.pop(context);
                _showVoiceSettings();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close")),
        ],
      ),
    );
  }
}
