import 'package:flutter/material.dart';

/// Minimal stub for the Dictionary page. Dictionary functionality is disabled.
class DictionaryPage extends StatelessWidget {
  const DictionaryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Diccionario (deshabilitado)')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'La funcionalidad de diccionario ha sido deshabilitada.\n\nSi quieres reactivar la importación, habilítala manualmente.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Función deshabilitada')),
                  );
                },
                icon: const Icon(Icons.download),
                label: const Text('Forzar actualización (no-op)'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
