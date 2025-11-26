import 'package:flutter/material.dart';

class LmsPage extends StatefulWidget {
  const LmsPage({super.key});

  @override
  State<LmsPage> createState() => _LmsPageState();
}

class _LmsPageState extends State<LmsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LMS'),
      ),
      body: const Center(
        child: Text('LMS'),
      ),
    );
  }
}
