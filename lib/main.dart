import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const DailyPulse());
}

class DailyPulse extends StatelessWidget {
  const DailyPulse({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ByteNews',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      home: const HomeScreen(),
    );
  }
}