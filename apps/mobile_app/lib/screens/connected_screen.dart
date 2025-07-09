import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import '../widgets/animated_button.dart';
import 'home_screen.dart';

class ConnectedScreen extends StatelessWidget {
  final String username;
  final String userId;

  const ConnectedScreen({super.key, required this.username, required this.userId});

  @override
  Widget build(BuildContext context) {
    final confettiController = ConfettiController(duration: const Duration(seconds: 2));
    WidgetsBinding.instance.addPostFrameCallback((_) => confettiController.play());

    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 64),
                const SizedBox(height: 16),
                const Text(
                  'Connected to Discord!',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('Username: $username'),
                Text('ID: $userId'),
                const SizedBox(height: 16),
                AnimatedButton(
                  text: 'Go to Home',
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const HomeScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 30,
              shouldLoop: false,
            ),
          ),
        ],
      ),
    );
  }
}
