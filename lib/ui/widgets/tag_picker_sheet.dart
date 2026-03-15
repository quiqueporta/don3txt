/// Selector visual genérico de proyectos o contextos.
///
/// Diseñado para usarse dentro de un [ModalBottomSheet]. Muestra los tags
/// disponibles como [FilterChip]s seleccionables y un campo de texto para
/// crear tags nuevos. La diferencia entre el selector de proyectos y el de
/// contextos es únicamente el [prefix] (`+` o `@`) y el [title].
///
/// El estado de selección es local al widget. Cualquier cambio se propaga
/// al padre mediante [onChanged] y el sheet se cierra automáticamente tras
/// cada acción (seleccionar o crear), siguiendo el mismo patrón que el
/// picker de prioridad.
///
/// Uso (desde el padre):
/// ```dart
/// showModalBottomSheet(
///   context: context,
///   builder: (_) => TagPickerSheet(
///     title: 'Projects',
///     prefix: '+',
///     available: notifier.allProjects,
///     selected: _selectedProjects,
///     onChanged: (projects) => setState(() => _selectedProjects = projects),
///   ),
/// );
/// ```
import 'package:flutter/material.dart';

class TagPickerSheet extends StatefulWidget {
  final String title;
  final String prefix;
  final List<String> available;
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;

  const TagPickerSheet({
    super.key,
    required this.title,
    required this.prefix,
    this.available = const [],
    this.selected = const {},
    required this.onChanged,
  });

  @override
  State<TagPickerSheet> createState() => _TagPickerSheetState();
}

class _TagPickerSheetState extends State<TagPickerSheet> {
  late Set<String> _currentSelection;
  late List<String> _currentAvailable;
  final _newItemController = TextEditingController();
  String? _errorText;

  @override
  void initState() {
    super.initState();

    _currentSelection = Set.from(widget.selected);
    _currentAvailable = List.from(widget.available);
  }

  void _toggleItem(String item, bool selected) {
    setState(() {
      if (selected) {
        _currentSelection.add(item);
      } else {
        _currentSelection.remove(item);
      }
    });

    widget.onChanged(Set.from(_currentSelection));
    Navigator.of(context).pop();
  }

  void _addNewItem() {
    var input = _newItemController.text.trim();

    // Permite que el usuario escriba "+Trabajo" o "Trabajo" indistintamente;
    // en ambos casos el resultado es el mismo tag "+Trabajo". Eliminar el
    // prefijo aquí evita que se duplique al reconstruirlo con fullName.
    if (input.startsWith(widget.prefix)) {
      input = input.substring(widget.prefix.length);
    }

    if (input.isEmpty) {
      setState(() => _errorText = 'Cannot be empty');

      return;
    }

    if (input.contains(' ')) {
      setState(() => _errorText = 'Cannot contain spaces');

      return;
    }

    if (input.length > 100) {
      setState(() => _errorText = 'Maximum 100 characters');

      return;
    }

    final fullName = '${widget.prefix}$input';

    final lowerFullName = fullName.toLowerCase();

    if (_currentAvailable.any((e) => e.toLowerCase() == lowerFullName) ||
        _currentSelection.any((e) => e.toLowerCase() == lowerFullName)) {
      setState(() => _errorText = 'Already exists');

      return;
    }

    setState(() {
      _currentAvailable.add(fullName);
      _currentSelection.add(fullName);
      _newItemController.clear();
      _errorText = null;
    });

    widget.onChanged(Set.from(_currentSelection));
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _newItemController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          if (_currentAvailable.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _currentAvailable.map((item) {
                return FilterChip(
                  label: Text(item),
                  selected: _currentSelection.contains(item),
                  onSelected: (selected) => _toggleItem(item, selected),
                );
              }).toList(),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _newItemController,
                  decoration: InputDecoration(
                    hintText: 'New ${widget.title.toLowerCase()}...',
                    errorText: _errorText,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (_) {
                    if (_errorText != null) {
                      setState(() => _errorText = null);
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: _addNewItem,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
