import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late ConfettiController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ConfettiController(duration: const Duration(seconds: 3));
  }

  void _onSOSPressed() {
    _controller.play();
    // Sau này mở popup chọn lý do SOS
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Nút SOS đỏ to
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 100),
              child: GestureDetector(
                onTap: _onSOSPressed,
                child: Container(
                  width: 320,
                  height: 320,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.red, blurRadius: 60, spreadRadius: 20)
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'SOS',
                      style: TextStyle(color: Colors.white, fontSize: 100, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Pháo hoa đỏ-trắng-xanh
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _controller,
              blastDirectionality: BlastDirectionality.explosive,
              colors: const [Colors.red, Colors.white, Colors.blue],
              emissionFrequency: 0.05,
              numberOfParticles: 100,
            ),
          ),

          // Tên app
          const Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: EdgeInsets.only(top: 80),
              child: Text(
                'SOS-BATTERY',
                style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}