// Test básico para la aplicación Kanji no Ryoushi

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kanji_no_ryoushi/main.dart';

void main() {
  testWidgets('App carga correctamente', (WidgetTester tester) async {
    // Construir la app y esperar un frame
    await tester.pumpWidget(const KanjiNoRyoushiApp());

    // Verificar que el título de la app está presente
    expect(find.text('Kanji no Ryoushi'), findsOneWidget);

    // Verificar que hay un indicador de carga inicial
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
