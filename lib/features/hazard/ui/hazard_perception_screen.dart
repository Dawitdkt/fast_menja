import 'package:flutter/material.dart';

class HazardPerceptionScreen extends StatelessWidget {
  const HazardPerceptionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hazard Perception')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.videocam, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Hazard Perception Videos'),
            SizedBox(height: 8),
            Text(
              'Premium Feature',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
