import 'package:flutter/material.dart';

class FeedPage extends StatelessWidget {
  const FeedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pulso Feed')),
      body: const Center(
        child: Text('Day 1 scaffold complete. Auth and feed wiring next.'),
      ),
    );
  }
}
