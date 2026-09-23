import 'package:flutter/material.dart';

class SimplePage extends StatelessWidget {
  const SimplePage({super.key, required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(padding: const EdgeInsets.all(16), children: children),
    );
  }
}
