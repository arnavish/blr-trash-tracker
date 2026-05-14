import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/trash_provider.dart';
import 'screens/home.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => TrashProvider(),
      child: const TrashSpotterApp(),
    ),
  );
}

class TrashSpotterApp extends StatelessWidget {
  const TrashSpotterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trash Tracker - Bengaluru',
      theme: ThemeData(primarySwatch: Colors.green),
      home: const HomeScreen(),
    );
  }
}
