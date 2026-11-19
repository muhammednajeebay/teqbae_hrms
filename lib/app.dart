import 'package:flutter/material.dart';

class RebsHrmsApp extends StatelessWidget {
  const RebsHrmsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'REBS HRMS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF006A5B)),
        useMaterial3: true,
      ),
      home: const _AppBootstrapPage(),
    );
  }
}

class _AppBootstrapPage extends StatelessWidget {
  const _AppBootstrapPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
