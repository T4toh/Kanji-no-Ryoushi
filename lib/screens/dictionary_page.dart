import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/dictionary_entry.dart';
import '../services/jitendex_service.dart';

/// Página del diccionario Jitendex - busca palabras japonesas
class DictionaryPage extends StatefulWidget {
  final String? initialSearchText; // Texto inicial para buscar

  const DictionaryPage({super.key, this.initialSearchText});

  @override
  State<DictionaryPage> createState() => _DictionaryPageState();
}

class _DictionaryPageState extends State<DictionaryPage> {
  final TextEditingController _searchController = TextEditingController();
  JitendexService? _jitendexService;
  List<DictionaryEntry> _results = [];
  bool _isLoading = false;
  bool _isInitialized = false;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String? _errorMessage;
  bool _pendingSearch = false; // Marca si hay una búsqueda pendiente

  /// Método público para buscar texto desde fuera (ej: desde OCR page)
  void searchText(String text) {
    _searchController.text = text;
    _search();
  }

  @override
  void initState() {
    super.initState();
    _initService();
    // Si hay texto inicial, establecerlo y marcar búsqueda pendiente
    if (widget.initialSearchText != null) {
      _searchController.text = widget.initialSearchText!;
      _pendingSearch = true; // Marcar que hay que buscar cuando esté listo
    }
    // Listener para actualizar UI cuando cambia el texto
    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void didUpdateWidget(DictionaryPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si llega un nuevo texto inicial, buscar
    if (widget.initialSearchText != null &&
        widget.initialSearchText != oldWidget.initialSearchText) {
      _searchController.text = widget.initialSearchText!;
      // Buscar inmediatamente si el servicio está listo
      if (_isInitialized && _jitendexService != null) {
        _search();
      } else {
        // Si no está listo, marcar que debe buscar cuando esté listo
        _pendingSearch = true;
      }
    }
  }

  Future<void> _initService() async {
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    try {
      final service = await JitendexService.create(
        onDownloadProgress: (progress) {
          setState(() {
            _downloadProgress = progress;
          });
        },
      );
      final available = await service.isAvailable();

      setState(() {
        _jitendexService = service;
        _isInitialized = true;
        _isDownloading = false;
        if (!available) {
          _errorMessage = 'Base de datos no disponible';
        }
      });

      // Si hay una búsqueda pendiente, ejecutarla ahora
      if (_pendingSearch && _searchController.text.isNotEmpty) {
        _pendingSearch = false;
        _search();
      }
    } catch (e) {
      setState(() {
        _isInitialized = true;
        _isDownloading = false;
        _errorMessage = 'Error al inicializar: $e';
      });
    }
  }

  Future<void> _search() async {
    final query = _searchController.text.trim();
    if (query.isEmpty || _jitendexService == null) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await _jitendexService!.search(query);
      setState(() {
        _results = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error en la búsqueda: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _jitendexService?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Diccionario Jitendex'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: Column(
          children: [
            // Barra de búsqueda
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar palabra o lectura (ej: 食べる, たべる)',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Botón de pegar
                      IconButton(
                        icon: const Icon(Icons.paste),
                        tooltip: 'Pegar',
                        onPressed: () async {
                          final clipboardData = await Clipboard.getData(
                            'text/plain',
                          );
                          if (clipboardData?.text != null) {
                            _searchController.text = clipboardData!.text!;
                            setState(() {});
                          }
                        },
                      ),
                      // Botón de limpiar (solo si hay texto)
                      if (_searchController.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _results = [];
                            });
                          },
                        ),
                    ],
                  ),
                  border: const OutlineInputBorder(),
                ),
                onSubmitted: (_) => _search(),
                enabled: _isInitialized && _errorMessage == null,
              ),
            ),

            // Botón de búsqueda
            if (_isInitialized && _errorMessage == null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _search,
                    icon: const Icon(Icons.search),
                    label: const Text('Buscar'),
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Contenido principal
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    // Pantalla de carga inicial / descarga
    if (!_isInitialized) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 24),
              Text(
                _isDownloading
                    ? 'Descargando diccionario...'
                    : 'Inicializando diccionario...',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (_isDownloading && _downloadProgress > 0) ...[
                const SizedBox(height: 16),
                LinearProgressIndicator(value: _downloadProgress),
                const SizedBox(height: 8),
                Text(
                  '${(_downloadProgress * 100).toStringAsFixed(0)}% completado',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  '~112 MB - Primera descarga',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ],
          ),
        ),
      );
    }

    // Error de inicialización
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            ],
          ),
        ),
      );
    }

    // Búsqueda en progreso
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Sin resultados
    if (_results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            _searchController.text.isEmpty
                ? 'Ingresa una palabra para buscar'
                : 'No se encontraron resultados para "${_searchController.text}"',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
        ),
      );
    }

    // Resultados
    return ListView.builder(
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final entry = _results[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Encabezado con término y popularidad
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Término (headword)
                          Text(
                            entry.headword,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Lectura
                          if (entry.readings.isNotEmpty)
                            Text(
                              entry.readings.join('、'),
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[700],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Indicador de frecuencia
                    if (entry.popularity != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (entry.frequencyIcon.isNotEmpty)
                            Text(
                              entry.frequencyIcon,
                              style: const TextStyle(fontSize: 16),
                            ),
                          const SizedBox(height: 2),
                          Text(
                            entry.frequencyLabel,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),

                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),

                // Definiciones
                ...entry.meanings.asMap().entries.map((e) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${e.key + 1}. ',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            e.value,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}
