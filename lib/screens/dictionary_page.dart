import 'package:flutter/material.dart';

import '../models/dictionary_entry.dart';
import '../services/jitendex_service.dart';

/// Página del diccionario Jitendex - busca palabras japonesas
class DictionaryPage extends StatefulWidget {
  const DictionaryPage({super.key});

  @override
  State<DictionaryPage> createState() => _DictionaryPageState();
}

class _DictionaryPageState extends State<DictionaryPage> {
  final TextEditingController _searchController = TextEditingController();
  JitendexService? _jitendexService;
  List<DictionaryEntry> _results = [];
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initService();
  }

  Future<void> _initService() async {
    try {
      final service = await JitendexService.create();
      final available = await service.isAvailable();

      setState(() {
        _jitendexService = service;
        _isInitialized = true;
        if (!available) {
          _errorMessage = 'Base de datos no disponible';
        }
      });
    } catch (e) {
      setState(() {
        _isInitialized = true;
        _errorMessage = 'Error al inicializar: $e';
      });
      print('Error inicializando JitendexService: $e');
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
      print('Error en búsqueda: $e');
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Diccionario Jitendex'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar palabra o lectura (ej: 食べる, たべる)',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _results = [];
                          });
                        },
                      )
                    : null,
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
    );
  }

  Widget _buildContent() {
    // Pantalla de carga inicial
    if (!_isInitialized) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Inicializando diccionario...'),
          ],
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
