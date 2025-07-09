import 'package:flutter/material.dart';

class AnimatedButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool enabled;
  final bool small;

  const AnimatedButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.enabled = true,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onPressed : null,
      borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            EdgeInsets.symmetric(horizontal: small ? 16 : 32, vertical: small ? 8 : 16),
        decoration: BoxDecoration(
          color: enabled ? Colors.blue : Colors.grey,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          text,
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: small ? 14 : 18),
        ),
      ),
    );
  }
}
