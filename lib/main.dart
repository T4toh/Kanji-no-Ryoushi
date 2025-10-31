import 'package:flutter/material.dart';
import 'screens/ocr_page.dart';

void main() {
  runApp(const KanjiNoRyoushiApp());
}

class KanjiNoRyoushiApp extends StatelessWidget {
  const KanjiNoRyoushiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kanji no Ryoushi',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const OCRPage(),
    );
  }
}
