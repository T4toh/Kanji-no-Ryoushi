import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// 'characters' APIs are exported by Flutter's material.dart in this project

/// Widget que muestra un texto dividido en "caracteres" (grapheme clusters)
/// y permite seleccionar caracteres individuales para copiarlos.
class CharacterSelector extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Axis direction;
  final bool selectableAll; // show select all action

  const CharacterSelector({
    super.key,
    required this.text,
    this.style,
    this.direction = Axis.horizontal,
    this.selectableAll = true,
  });

  @override
  State<CharacterSelector> createState() => _CharacterSelectorState();
}

class _CharacterSelectorState extends State<CharacterSelector> {
  late final List<String> _chars;
  final Set<int> _selected = {};

  @override
  void initState() {
    super.initState();
    _chars = widget.text.characters.toList();
  }

  void _toggle(int i) {
    setState(() {
      if (_selected.contains(i)) {
        _selected.remove(i);
      } else {
        _selected.add(i);
      }
    });
  }

  void _clear() {
    setState(() => _selected.clear());
  }

  void _selectAll() {
    setState(() => _selected.addAll(List.generate(_chars.length, (i) => i)));
  }

  String get _selectedText {
    final buffer = StringBuffer();
    final indices = _selected.toList()..sort();
    for (final i in indices) {
      buffer.write(_chars[i]);
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chipPadding = const EdgeInsets.symmetric(horizontal: 6, vertical: 4);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_selected.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Seleccionados: ${_selected.length}',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                if (widget.selectableAll)
                  TextButton(
                    onPressed: _selectAll,
                    child: const Text('Seleccionar todo'),
                  ),
                TextButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _selectedText));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Texto copiado')),
                    );
                    _clear();
                  },
                  child: const Text('Copiar'),
                ),
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: _clear,
                  tooltip: 'Limpiar selección',
                ),
              ],
            ),
          ),
        Wrap(
          spacing: 2,
          runSpacing: 2,
          children: List.generate(_chars.length, (i) {
            final ch = _chars[i];
            final selected = _selected.contains(i);
            return GestureDetector(
              onTap: () => _toggle(i),
              onLongPress: () {
                Clipboard.setData(ClipboardData(text: ch));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Carácter copiado')),
                );
              },
              child: Container(
                padding: chipPadding,
                decoration: BoxDecoration(
                  color: selected
                      ? theme.colorScheme.primary.withAlpha(
                          (0.15 * 255).toInt(),
                        )
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  ch,
                  style:
                      widget.style ??
                      const TextStyle(fontSize: 18, height: 1.5),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
