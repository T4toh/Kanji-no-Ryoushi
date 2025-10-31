import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/ocr_service.dart';

/// Página principal para realizar pruebas de OCR con imágenes
class OCRPage extends StatefulWidget {
  const OCRPage({super.key});

  @override
  State<OCRPage> createState() => _OCRPageState();
}

class _OCRPageState extends State<OCRPage> {
  final OCRService _ocrService = OCRService();
  final ImagePicker _imagePicker = ImagePicker();

  String _recognizedText = '';
  bool _isProcessing = false;
  File? _selectedImage;
  bool _isUsingExampleImage = true;

  @override
  void initState() {
    super.initState();
    // Cargar imagen de ejemplo al inicio
    _loadExampleImage();
  }

  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }

  /// Selecciona una imagen desde la galería
  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _isUsingExampleImage = false;
        });
        await _processSelectedImage();
      }
    } catch (e) {
      debugPrint('Error al seleccionar imagen: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al seleccionar la imagen')),
        );
      }
    }
  }

  /// Toma una foto con la cámara
  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _isUsingExampleImage = false;
        });
        await _processSelectedImage();
      }
    } catch (e) {
      debugPrint('Error al tomar foto: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Error al tomar la foto')));
      }
    }
  }

  /// Procesa la imagen seleccionada con OCR
  Future<void> _processSelectedImage() async {
    if (_selectedImage == null) return;

    setState(() {
      _isProcessing = true;
      _recognizedText = '';
    });

    try {
      final text = await _ocrService.processImageFromFile(_selectedImage!);

      setState(() {
        _recognizedText = text;
        _isProcessing = false;
      });

      debugPrint('Texto reconocido:\n$_recognizedText');
    } catch (e) {
      debugPrint('Error en OCR: $e');
      setState(() {
        _recognizedText = 'Error al procesar la imagen';
        _isProcessing = false;
      });
    }
  }

  /// Carga la imagen de ejemplo
  Future<void> _loadExampleImage() async {
    setState(() {
      _isProcessing = true;
      _recognizedText = '';
      _selectedImage = null;
      _isUsingExampleImage = true;
    });

    try {
      final text = await _ocrService.processImageFromAssets(
        'assets/images/prueba_texto.png',
      );

      setState(() {
        _recognizedText = text;
        _isProcessing = false;
      });

      debugPrint('Texto reconocido:\n$_recognizedText');
    } catch (e) {
      debugPrint('Error en OCR: $e');
      setState(() {
        _recognizedText = 'Error al procesar la imagen';
        _isProcessing = false;
      });
    }
  }

  /// Muestra un diálogo para elegir la fuente de la imagen
  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galería'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromGallery();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Cámara'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromCamera();
                },
              ),
              ListTile(
                leading: const Icon(Icons.image),
                title: const Text('Imagen de ejemplo'),
                onTap: () {
                  Navigator.pop(context);
                  _loadExampleImage();
                },
              ),
            ],
          ),
        );
      },
    );
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
            // Visualización de la imagen
            if (_selectedImage == null && !_isUsingExampleImage)
              // Estado inicial: sin imagen seleccionada
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[400]!),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate,
                        size: 64,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Selecciona una imagen',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              )
            else
              // Mostrar imagen seleccionada o de ejemplo
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _isUsingExampleImage
                    ? Image.asset(
                        'assets/images/prueba_texto.png',
                        fit: BoxFit.contain,
                        height: 200,
                      )
                    : Image.file(
                        _selectedImage!,
                        fit: BoxFit.contain,
                        height: 200,
                      ),
              ),

            const SizedBox(height: 16),

            // Botón para seleccionar imagen
            ElevatedButton.icon(
              onPressed: _isProcessing ? null : _showImageSourceDialog,
              icon: const Icon(Icons.add_a_photo),
              label: Text(
                _selectedImage == null && !_isUsingExampleImage
                    ? 'Seleccionar Imagen'
                    : 'Cambiar Imagen',
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
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
                  : _recognizedText.isEmpty
                  ? Center(
                      child: Text(
                        'El texto reconocido aparecerá aquí',
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
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
      floatingActionButton: _selectedImage != null || _isUsingExampleImage
          ? FloatingActionButton(
              onPressed: _isProcessing ? null : _processSelectedImage,
              tooltip: 'Procesar nuevamente',
              child: const Icon(Icons.refresh),
            )
          : null,
    );
  }
}
