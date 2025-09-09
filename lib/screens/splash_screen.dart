import 'package:flutter/material.dart';
import 'package:songbuddy/main.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => MainScreen()));
    });

    return const Scaffold(
      body: Center(child: Text("Splash Screen")),
    );
  }
}
