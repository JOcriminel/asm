import 'package:flutter/material.dart';
import 'package:dux_front/core/widgets/dux_drawer.dart';

class TimetreeAccueilScreen extends StatelessWidget {
  const TimetreeAccueilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const DuxDrawer(),
      appBar: AppBar(title: const Text('Dux Calendar Accueil')),
      body: const Center(child: Text('Welcome to Dux Calendar')),
    );
  }
}
