import 'package:flutter/material.dart';

class DiscordStatusIndicator extends StatelessWidget {
  const DiscordStatusIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final bool rpcActive = true;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.discord, color: rpcActive ? Colors.green : Colors.red),
        const SizedBox(width: 8),
        Text(rpcActive ? 'Discord RPC active' : 'Discord RPC inactive'),
      ],
    );
  }
}
