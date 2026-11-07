import 'package:flutter/material.dart';

void main() {
  runApp(MaterialApp(home: Scaffold(
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 8),
            const Text('hello'),
          ],
        ),
      ),
    ),
  )));
}
