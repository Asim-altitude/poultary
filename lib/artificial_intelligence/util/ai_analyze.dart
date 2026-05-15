import 'package:flutter/material.dart';

class AIWaveButton extends StatefulWidget {
  final VoidCallback onTap;

  const AIWaveButton({Key? key, required this.onTap}) : super(key: key);

  @override
  _AIWaveButtonState createState() => _AIWaveButtonState();
}

class _AIWaveButtonState extends State<AIWaveButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return GestureDetector(
          onTap: widget.onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                begin: Alignment(-1 + _controller.value * 2, 0),
                end: Alignment(1 + _controller.value * 2, 0),
                colors: [
                  Colors.blue,
                  Colors.purpleAccent,
                  Colors.deepPurple,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.purpleAccent.withOpacity(0.5),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
                BoxShadow(
                  color: Colors.blueAccent.withOpacity(0.4),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.auto_awesome, color: Colors.white),
                SizedBox(width: 10),
                Text(
                  "Analyze with AI",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}