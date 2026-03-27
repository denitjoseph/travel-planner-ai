import 'package:flutter/material.dart';

class ScrollReveal extends StatefulWidget {
  final Widget child;
  final ScrollController controller;
  final Duration duration;
  final double offset;

  const ScrollReveal({
    super.key,
    required this.child,
    required this.controller,
    this.duration = const Duration(milliseconds: 1000),
    this.offset = 50.0,
  });

  @override
  State<ScrollReveal> createState() => _ScrollRevealState();
}

class _ScrollRevealState extends State<ScrollReveal> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isVisible = false;
  final GlobalKey _key = GlobalKey();

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: widget.duration);
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(begin: Offset(0, widget.offset / 100), end: Offset.zero).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutQuart),
    );

    widget.controller.addListener(_checkVisibility);
    // Initial check after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkVisibility());
  }

  void _checkVisibility() {
    if (!mounted || _isVisible) return;

    final RenderObject? renderObject = _key.currentContext?.findRenderObject();
    if (renderObject is! RenderBox) return;

    final position = renderObject.localToGlobal(Offset.zero);
    final height = MediaQuery.of(context).size.height;

    if (position.dy < height * 0.9) {
      setState(() {
        _isVisible = true;
      });
      _animController.forward();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_checkVisibility);
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: _key,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: widget.child,
        ),
      ),
    );
  }
}
