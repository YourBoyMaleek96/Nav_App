import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:excel/excel.dart';
import 'package:share_plus/share_plus.dart';
import 'models/note_model.dart';
import 'db/db_helper.dart';

class ViewListScreen extends StatefulWidget {
  const ViewListScreen({super.key});
  @override
  _ViewListScreenState createState() => _ViewListScreenState();
}

class _ViewListScreenState extends State<ViewListScreen> {
  List<Note> _notes = [];
  bool _loading = true;
  bool _selectionMode = false;
  final Set<int> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    final notes = await DBHelper().getNotes();
    setState(() {
      _notes = notes;
      _loading = false;
    });
  }

  void _toggleSelectionMode() {
    setState(() {
      _selectionMode = !_selectionMode;
      if (!_selectionMode) _selectedIds.clear();
    });
  }

  Future<void> _exportSelected() async {
    if (_selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No notes selected for export')),
      );
      return;
    }
    // Create Excel
    final excel = Excel.createExcel();
    final sheet = excel['Notes'];
    sheet.appendRow([
      'ID', 'Text', 'DateTime', 'Latitude', 'Longitude', 'ImagePaths'
    ]);
    for (final note in _notes.where((n) => _selectedIds.contains(n.id))) {
      sheet.appendRow([
        note.id,
        note.text,
        note.dateTime.toIso8601String(),
        note.latitude,
        note.longitude,
        note.imagePaths.join(';')
      ]);
    }
    final bytes = excel.encode();
    final dir = await getTemporaryDirectory();
    final filePath = '${dir.path}/notes_export.xlsx';
    final file = File(filePath);
    await file.writeAsBytes(bytes!);

    // Share via system share sheet
    try {
      await Share.shareXFiles([
        XFile(filePath)
      ], text: 'Please find attached the exported notes.');
      setState(() {
        _selectionMode = false;
        _selectedIds.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to share file: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Notes'),
        actions: [
          IconButton(
            icon: Icon(_selectionMode ? Icons.close : Icons.check_box),
            onPressed: _toggleSelectionMode,
          ),
          if (_selectionMode)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _exportSelected,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _notes.isEmpty
          ? const Center(child: Text('No notes yet'))
          : ListView.builder(
        itemCount: _notes.length,
        itemBuilder: (context, index) {
          final note = _notes[index];
          final selected = _selectedIds.contains(note.id);
          return _selectionMode
              ? CheckboxListTile(
            value: selected,
            title: Text(
              note.text.length > 30
                  ? note.text.substring(0, 30) + '…'
                  : note.text,
            ),
            subtitle: Text(
              note.dateTime.toLocal().toString(),
            ),
            onChanged: (val) {
              setState(() {
                if (val == true) _selectedIds.add(note.id!);
                else _selectedIds.remove(note.id);
              });
            },
          )
              : ListTile(
            leading: note.imagePaths.isNotEmpty
                ? Image.file(
              File(note.imagePaths.first),
              width: 50,
              height: 50,
              fit: BoxFit.cover,
            )
                : const Icon(Icons.note),
            title: Text(
              note.text.length > 30
                  ? note.text.substring(0, 30) + '…'
                  : note.text,
            ),
            subtitle: Text(
              'Lat: ${note.latitude?.toStringAsFixed(4)} '
                  'Lng: ${note.longitude?.toStringAsFixed(4)}',
            ),
          );
        },
      ),
    );
  }
}