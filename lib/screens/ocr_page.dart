import 'package:flutter/material.dart';
import '../services/ocr_service.dart';

/// Página principal para realizar pruebas de OCR con imágenes
class OCRPage extends StatefulWidget {
  const OCRPage({super.key});

  @override
  State<OCRPage> createState() => _OCRPageState();
}

class _OCRPageState extends State<OCRPage> {
  final OCRService _ocrService = OCRService();
  String _recognizedText = '';
  bool _isProcessing = true;

  @override
  void initState() {
    super.initState();
    _processTestImage();
  }

  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }

  Future<void> _processTestImage() async {
    setState(() {
      _isProcessing = true;
      _recognizedText = '';
    });

    try {
      final text = await _ocrService.processImageFromAssets(
        'assets/images/prueba_texto.png',
      );

      setState(() {
        _recognizedText = text;
        _isProcessing = false;
      });

      // Log para depuración
      debugPrint('Texto reconocido:\n$_recognizedText');
    } catch (e) {
      debugPrint('Error en OCR: $e');
      setState(() {
        _recognizedText = 'Error al procesar la imagen';
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kanji no Ryoushi'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Imagen de prueba
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/images/prueba_texto.png',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 20),

            // Indicador de carga o resultado
            Expanded(
              child: _isProcessing
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Procesando imagen...'),
                        ],
                      ),
                    )
                  : Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: SingleChildScrollView(
                          child: SelectableText(
                            _recognizedText,
                            style: const TextStyle(fontSize: 18, height: 1.5),
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isProcessing ? null : _processTestImage,
        tooltip: 'Procesar nuevamente',
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
