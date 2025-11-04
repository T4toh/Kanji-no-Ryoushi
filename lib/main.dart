import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'screens/ocr_page.dart';
import 'screens/dictionary_page.dart';
import 'services/screen_capture_service.dart';

// GlobalKey para acceder al OCRPage desde callbacks globales
final GlobalKey<OCRPageState> ocrPageKey = GlobalKey<OCRPageState>();

void main() {
  // Inicializar Flutter binding PRIMERO
  WidgetsFlutterBinding.ensureInitialized();

  // Ahora sí podemos inicializar el servicio de captura de pantalla
  ScreenCaptureService.initialize();

  // Configurar callbacks GLOBALMENTE (antes de que OCRPage se monte)
  ScreenCaptureService.onCaptureComplete = _globalHandleCapturedImage;
  ScreenCaptureService.onCaptureCancelled = _globalHandleCaptureCancelled;
  ScreenCaptureService.onMediaProjectionGranted =
      _globalHandleMediaProjectionGranted;
  ScreenCaptureService.onPermissionExpired = _globalHandlePermissionExpired;

  runApp(const KanjiNoRyoushiApp());
}

// Callbacks globales que redirigen a OCRPage
void _globalHandleCapturedImage(Uint8List imageBytes) {
  ocrPageKey.currentState?.handleCapturedImage(imageBytes);
}

void _globalHandleCaptureCancelled() {
  ocrPageKey.currentState?.handleCaptureCancelled();
}

void _globalHandleMediaProjectionGranted() {
  ocrPageKey.currentState?.handleMediaProjectionGranted();
}

void _globalHandlePermissionExpired() {
  ocrPageKey.currentState?.handlePermissionExpired();
}

class KanjiNoRyoushiApp extends StatelessWidget {
  const KanjiNoRyoushiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '漢字の漁師 🎣 🗾',
      debugShowCheckedModeBanner: false,

      // Tema claro
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigoAccent,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
        cardTheme: const CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 2,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),

      // Tema oscuro
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigoAccent,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
        cardTheme: const CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 2,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),

      // Usar el tema del sistema
      themeMode: ThemeMode.system,

      home: const _HomeShell(),
    );
  }
}

class _HomeShell extends StatefulWidget {
  const _HomeShell();

  @override
  State<_HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<_HomeShell> {
  int _idx = 0;
  String? _dictionarySearchText;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      OCRPage(key: ocrPageKey, onSearchInDictionary: _searchInDictionary),
      DictionaryPage(initialSearchText: _dictionarySearchText),
    ];
  }

  void _searchInDictionary(String text) {
    setState(() {
      _dictionarySearchText = text;
      // Solo cambiar de tab en móvil (tablet lo muestra lado a lado)
      final isTablet = MediaQuery.of(context).size.width >= 600;
      if (!isTablet) {
        _idx = 1; // Cambiar a pestaña de diccionario
      }
      // Recrear la página del diccionario con el nuevo texto
      _pages[1] = DictionaryPage(
        key: ValueKey(text + DateTime.now().toString()),
        initialSearchText: text,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;

    if (isTablet) {
      // Vista de tablet: mostrar OCR y diccionario lado a lado
      return Scaffold(
        body: Row(
          children: [
            // Panel izquierdo: OCR (60% en tablets normales, 50% en tablets grandes)
            Expanded(flex: screenWidth >= 900 ? 1 : 3, child: _pages[0]),
            // Divisor vertical
            VerticalDivider(
              width: 1,
              thickness: 1,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            // Panel derecho: Diccionario (40% en tablets normales, 50% en tablets grandes)
            Expanded(flex: screenWidth >= 900 ? 1 : 2, child: _pages[1]),
          ],
        ),
      );
    } else {
      // Vista móvil: tabs como antes
      return Scaffold(
        body: IndexedStack(index: _idx, children: _pages),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _idx,
          onTap: (i) => setState(() => _idx = i),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.photo_camera),
              label: 'OCR',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.book),
              label: 'Diccionario',
            ),
          ],
        ),
      );
    }
  }
}
