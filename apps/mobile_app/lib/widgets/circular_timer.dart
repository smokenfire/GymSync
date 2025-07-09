import 'package:flutter/material.dart';

class CircularTimer extends StatelessWidget {
  final bool running;
  final Duration duration;
  final String activity;

  const CircularTimer({
    super.key,
    required this.running,
    required this.duration,
    required this.activity,
  });

  @override
  Widget build(BuildContext context) {
    final percent = (duration.inSeconds % 60) / 60.0;
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 160,
          height: 160,
          child: CircularProgressIndicator(
            value: percent,
            strokeWidth: 8,
            backgroundColor: Colors.grey[300],
            color: Colors.blue,
          ),
        ),
        Text(
          '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}',
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
