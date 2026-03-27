import 'dart:convert';
import 'dart:ui';
import 'dart:math' as Math;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/constants.dart';

import '../widgets/navbar.dart';

class ChatBotPage extends StatefulWidget {
  const ChatBotPage({super.key});

  @override
  State<ChatBotPage> createState() => _ChatBotPageState();
}

class _ChatBotPageState extends State<ChatBotPage> with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = [
    {
      "role": "ai",
      "text": "Hello traveler! 🌍 I'm your Odyssey companion. Where shall we explore today?",
      "type": "text",
    },
  ];
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();
  late final String _sessionId;
  late AnimationController _bgController;

  // Voice Features
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  bool _isListening = false;
  bool _speechEnabled = false;
  bool _ttsEnabled = true;
  bool _sttEnabled = true;
  
  // Mouse Tilt
  double _tiltX = 0;
  double _tiltY = 0;

  @override
  void initState() {
    super.initState();
    _sessionId = "session_${DateTime.now().millisecondsSinceEpoch}";
    _initVoice();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 40),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bgController.dispose();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _initVoice() async {
    _speechEnabled = await _speechToText.initialize();
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setPitch(1.0);
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
          _sendMessage();
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
    await _flutterTts.speak(text);
  }

  Future<void> _fetchWeather(String location) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/weather'),

        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"location": location}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _messages.add({
            "role": "ai",
            "type": "weather",
            "data": data,
            "location": location,
          });
        });
        _scrollToBottom();
      }
    } catch (_) {}
  }

  Future<void> _fetchSuggestions(String location) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/suggestions'),

        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"location": location}),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _messages.add({
            "role": "ai",
            "type": "suggestions",
            "items": data,
            "location": location,
          });
        });
        _scrollToBottom();
      }
    } catch (_) {}
  }

  Future<void> _sendMessage({String? customText}) async {
    String text = customText ?? _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({"role": "user", "text": text, "type": "text"});
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
          _messages.add({"role": "ai", "text": aiResponse, "type": "text"});
        });
        if (_ttsEnabled) _speak(aiResponse);

        if (text.toLowerCase().contains("weather")) {
          _fetchWeather(text.split(" ").last);
        } else if (text.toLowerCase().contains("suggest") ||
            text.toLowerCase().contains("near")) {
          _fetchSuggestions(text.split(" ").last);
        }
      } else {
        setState(() {
          _messages.add({
            "role": "ai",
            "text": "I'm having a bit of trouble connecting! 🛰️",
            "type": "text",
          });
        });
      }
    } catch (e) {
      setState(() {
        _messages.add({
          "role": "ai",
          "text": "Connection Failed. 🔌",
          "type": "text",
        });
      });
    } finally {
      setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // 1. Cinematic Background with Zoom
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _bgController,
              builder: (context, child) {
                return Transform.scale(
                  scale: 1.1 + (_bgController.value * 0.1),
                  child: Image.asset(
                    'assets/my_trips_premium_bg.png',
                    fit: BoxFit.cover,
                  ),
                );
              },
            ),
          ),

          // 2. Moving Luxury Gradient Layer
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _bgController,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(
                        0.7 * Math.cos(_bgController.value * 2 * Math.pi),
                        0.7 * Math.sin(_bgController.value * 2 * Math.pi),
                      ),
                      colors: [
                        const Color(0xFFD4AF37).withOpacity(0.08),
                        Colors.transparent,
                      ],
                      radius: 1.8,
                    ),
                  ),
                );
              },
            ),
          ),

          // 3. Glassy Overlay
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(
                color: Colors.black.withOpacity(0.6),
              ),
            ),
          ),

          // 3. Main Content
          Column(
            children: [
              const NavBar(),
              Expanded(
                child: Center(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 1200),
                    curve: Curves.easeOutQuart,
                    builder: (context, value, child) {
                      return Transform.translate(
                        offset: Offset(0, 50 * (1 - value)),
                        child: Opacity(
                          opacity: value,
                          child: child,
                        ),
                      );
                    },
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return MouseRegion(
                          onHover: (event) {
                            setState(() {
                              _tiltY = (event.localPosition.dx / constraints.maxWidth - 0.5) * 0.12;
                              _tiltX = (event.localPosition.dy / constraints.maxHeight - 0.5) * -0.12;
                            });
                          },
                          onExit: (_) => setState(() {
                            _tiltX = 0;
                            _tiltY = 0;
                          }),
                          child: AnimatedRotation(
                            duration: const Duration(milliseconds: 200),
                            turns: 0,
                            child: Transform(
                              transform: Matrix4.identity()
                                ..setEntry(3, 2, 0.001)
                                ..rotateX(_tiltX)
                                ..rotateY(_tiltY),
                              alignment: FractionalOffset.center,
                              child: Container(
                                constraints: const BoxConstraints(maxWidth: 950),
                                margin: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(35),
                                  border: Border.all(color: Colors.white.withOpacity(0.15)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.5),
                                      blurRadius: 50,
                                      offset: const Offset(0, 20),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(35),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                                    child: Column(
                                      children: [
                                        _buildHeader(),
                                        Expanded(
                                          child: ListView.builder(
                                            controller: _scrollController,
                                            padding: const EdgeInsets.all(30),
                                            itemCount: _messages.length,
                                            itemBuilder: (context, index) {
                                              final msg = _messages[index];
                                              return TweenAnimationBuilder<double>(
                                                key: ValueKey(index),
                                                tween: Tween(begin: 0.0, end: 1.0),
                                                duration: const Duration(milliseconds: 600),
                                                curve: Curves.easeOutBack,
                                                builder: (context, val, child) {
                                                  return Transform.translate(
                                                    offset: Offset(0, 20 * (1 - val)),
                                                    child: Opacity(opacity: val.clamp(0.0, 1.0), child: child),
                                                  );
                                                },
                                                child: msg['type'] == "weather" 
                                                    ? _buildWeatherCard(msg)
                                                    : msg['type'] == "suggestions" 
                                                        ? _buildSuggestionsCard(msg)
                                                        : _buildChatBubble(msg['text'], msg['role'] == "user"),
                                              );
                                            },
                                          ),
                                        ),
                                        if (_isLoading) _buildTypingIndicator(),
                                        _buildQuickActions(),
                                        _buildInputArea(),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }
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

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.1))),
      ),
      child: Row(
        children: [
          Container(
            height: 55,
            width: 55,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFD4AF37), width: 1.5),
              image: const DecorationImage(
                image: AssetImage('assets/bot_icon.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Odyssey Assistant",
                style: GoogleFonts.bodoniModa(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFFD4AF37),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "AI CONCIERGE • MULTIMODAL",
                    style: GoogleFonts.outfit(
                      color: const Color(0xFFD4AF37),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: Icon(
              _ttsEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
              color: _ttsEnabled ? const Color(0xFFD4AF37) : Colors.white60,
            ),
            onPressed: () => setState(() => _ttsEnabled = !_ttsEnabled),
          ),
          IconButton(
            icon: Icon(
              _sttEnabled
                  ? (_isListening ? Icons.mic_rounded : Icons.mic_none_rounded)
                  : Icons.mic_off_rounded,
              color: _isListening ? Colors.redAccent : Colors.white60,
            ),
            onPressed: _sttEnabled && _speechEnabled
                ? (_isListening ? _stopListening : _startListening)
                : () => setState(() => _sttEnabled = !_sttEnabled),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(String text, bool isUser) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 25),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFD4AF37).withOpacity(0.2),
                border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.5)),
              ),
              child: const Icon(Icons.auto_awesome_rounded, size: 16, color: Color(0xFFD4AF37)),
            ),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              decoration: BoxDecoration(
                gradient: isUser 
                    ? const LinearGradient(
                        colors: [Color(0xFFD4AF37), Color(0xFFB8860B)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.12),
                          Colors.white.withOpacity(0.05),
                        ],
                      ),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(25),
                  topRight: const Radius.circular(25),
                  bottomLeft: Radius.circular(isUser ? 25 : 0),
                  bottomRight: Radius.circular(isUser ? 0 : 25),
                ),
                border: Border.all(
                  color: isUser 
                      ? const Color(0xFFD4AF37).withOpacity(0.5) 
                      : Colors.white.withOpacity(0.15)
                ),
                boxShadow: [
                  if (isUser)
                    BoxShadow(
                      color: const Color(0xFFD4AF37).withOpacity(0.2),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                ],
              ),
              child: isUser 
                  ? Text(
                      text,
                      style: GoogleFonts.outfit(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        height: 1.5,
                        letterSpacing: 0.2,
                      ),
                    )
                  : _TypewriterText(
                      text: text,
                      style: GoogleFonts.outfit(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        height: 1.5,
                        letterSpacing: 0.2,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherCard(Map<String, dynamic> msg) {
    final data = msg['data'];
    return Padding(
      padding: const EdgeInsets.only(bottom: 25),
      child: Container(
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFD4AF37).withOpacity(0.2),
              Colors.black.withOpacity(0.3),
            ],
          ),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(
              "METEOROLOGICAL INSIGHTS: ${msg['location']}",
              style: GoogleFonts.outfit(
                color: const Color(0xFFD4AF37),
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(data['emoji'], style: const TextStyle(fontSize: 48)),
                const SizedBox(width: 20),
                Text(
                  "${data['temp']}°",
                  style: GoogleFonts.bodoniModa(
                    color: Colors.white,
                    fontSize: 54,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            Text(
              data['description'].toUpperCase(),
              style: GoogleFonts.outfit(
                color: Colors.white70,
                fontSize: 14,
                letterSpacing: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionsCard(Map<String, dynamic> msg) {
    final List<dynamic> items = msg['items'];
    return Padding(
      padding: const EdgeInsets.only(bottom: 25),
      child: Container(
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "📍 CURATED FRONTIERS NEAR ${msg['location']}",
              style: GoogleFonts.outfit(
                color: const Color(0xFFD4AF37),
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 15),
            ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on_rounded, color: Color(0xFFD4AF37), size: 16),
                  const SizedBox(width: 12),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14),
                        children: [
                          TextSpan(
                            text: "${item['name']}: ",
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          TextSpan(text: item['reason']),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 25),
        child: Row(
          children: [
            _actionChip("🌦️ WEATHER INSIGHTS", "What's the weather like in London?"),
            _actionChip("📍 NEARBY FRONTIERS", "Suggest places near Paris"),
            _actionChip("🍱 CULINARY GUIDES", "What should I eat in Tokyo?"),
          ],
        ),
      ),
    );
  }

  Widget _actionChip(String label, String query) {
    return _AnimatedHoverWrapper(
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        child: ActionChip(
          label: Text(label),
          labelStyle: GoogleFonts.outfit(
            color: const Color(0xFFD4AF37),
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
          onPressed: () => _sendMessage(customText: query),
          backgroundColor: Colors.white.withOpacity(0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: const Color(0xFFD4AF37).withOpacity(0.3)),
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: TextField(
                controller: _controller,
                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w400),
                decoration: InputDecoration(
                  hintText: "Where shall your journey take you?",
                  hintStyle: GoogleFonts.outfit(color: Colors.white.withOpacity(0.2)),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 25, vertical: 18),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(color: Color(0xFFD4AF37), width: 1.5),
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 20),
          _AnimatedHoverWrapper(
            child: Container(
              height: 56,
              width: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFD4AF37), Color(0xFFB8860B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFD4AF37).withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: IconButton(
                onPressed: _sendMessage,
                icon: const Icon(Icons.send_rounded, color: Colors.black, size: 24),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return const _InfiniteTypingDots();
  }
}

class _InfiniteTypingDots extends StatefulWidget {
  const _InfiniteTypingDots();

  @override
  State<_InfiniteTypingDots> createState() => _InfiniteTypingDotsState();
}

class _InfiniteTypingDotsState extends State<_InfiniteTypingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 45, vertical: 15),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFD4AF37).withOpacity(0.1),
            ),
            child: const Icon(Icons.auto_awesome_rounded, size: 14, color: Color(0xFFD4AF37)),
          ),
          const SizedBox(width: 15),
          Row(
            children: List.generate(3, (index) {
              return AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  double delay = index * 0.2;
                  double value = (_controller.value - delay) % 1.0;
                  double opacity = (Math.sin(value * Math.pi * 2) + 1) / 2;
                  return Container(
                    margin: const EdgeInsets.only(right: 6),
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4AF37).withOpacity(0.2 + (opacity * 0.8)),
                      shape: BoxShape.circle,
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _TypewriterText extends StatefulWidget {
  final String text;
  final TextStyle style;
  const _TypewriterText({required this.text, required this.style});

  @override
  State<_TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<_TypewriterText> {
  String _displayedText = "";
  int _currentIndex = 0;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _startTypewriting();
  }

  void _startTypewriting() {
    _timer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (_currentIndex < widget.text.length) {
        setState(() {
          _displayedText += widget.text[_currentIndex];
          _currentIndex++;
        });
      } else {
        _timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(_displayedText, style: widget.style);
  }
}

class _AnimatedHoverWrapper extends StatefulWidget {
  final Widget child;
  const _AnimatedHoverWrapper({required this.child});

  @override
  State<_AnimatedHoverWrapper> createState() => _AnimatedHoverWrapperState();
}

class _AnimatedHoverWrapperState extends State<_AnimatedHoverWrapper> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? 1.1 : 1.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutBack,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              if (_isHovered)
                BoxShadow(
                  color: const Color(0xFFD4AF37).withOpacity(0.6),
                  blurRadius: 25,
                  spreadRadius: 4,
                ),
            ],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
