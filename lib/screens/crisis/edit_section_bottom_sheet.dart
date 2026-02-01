import 'package:flutter/material.dart';

/// Bottom sheet para editar secciones de listas (señales, estrategias, etc.)
class EditSectionBottomSheet extends StatefulWidget {
  final String title;
  final List<String> items;
  final bool isList;

  const EditSectionBottomSheet({
    super.key,
    required this.title,
    required this.items,
    this.isList = true,
  });

  @override
  State<EditSectionBottomSheet> createState() => _EditSectionBottomSheetState();
}

class _EditSectionBottomSheetState extends State<EditSectionBottomSheet> {
  late List<String> _items;
  final _newItemController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _items = List<String>.from(widget.items);
  }

  @override
  void dispose() {
    _newItemController.dispose();
    super.dispose();
  }

  void _addItem() {
    if (_newItemController.text.trim().isNotEmpty) {
      setState(() {
        _items.add(_newItemController.text.trim());
        _newItemController.clear();
      });
    }
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  void _reorderItems(int oldIndex, int newIndex) {
    setState(() {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final item = _items.removeAt(oldIndex);
      _items.insert(newIndex, item);
    });
  }

  void _save() {
    Navigator.pop(context, _items);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Editar ${widget.title}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Contenido
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Añadir nuevo
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _newItemController,
                          decoration: InputDecoration(
                            hintText: 'Añadir ${widget.title.toLowerCase()}...',
                            border: const OutlineInputBorder(),
                            contentPadding: EdgeInsets.zero,
                          ),
                          onSubmitted: (_) => _addItem(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _addItem,
                        icon: const Icon(Icons.add_circle, color: Color(0xFF004B49)),
                        iconSize: 40,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Lista de items
                  if (_items.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          'Sin ${widget.title.toLowerCase()} aún',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ),
                    )
                  else
                    ReorderableListView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      onReorder: _reorderItems,
                      children: _items.asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = entry.value;
                        return Card(
                          key: Key('$index'),
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: const Icon(Icons.drag_handle, color: Colors.grey),
                            title: Text(item),
                            trailing: IconButton(
                              onPressed: () => _removeItem(index),
                              icon: const Icon(Icons.delete, color: Colors.red),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          ),

          // Footer con botones
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, widget.items),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF004B49),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Guardar'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
