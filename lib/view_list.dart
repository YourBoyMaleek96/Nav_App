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

    // 1) Filter selected notes
    final selectedNotes = _notes.where((n) => n.id != null && _selectedIds.contains(n.id)).toList();

    // 2) Create workbook & grab default Sheet1
    final excel = Excel.createExcel();
    final sheet = excel['Sheet1'];

    // 3) Compute how many image‑columns we need
    final maxImageCount = selectedNotes.fold<int>(
      0,
          (prev, note) => note.imagePaths.length > prev ? note.imagePaths.length : prev,
    );

    // 4) Set a fixed width only for image columns (columns 4, 5, …)
    for (var imgCol = 0; imgCol < maxImageCount; imgCol++) {
      sheet.setColumnWidth(4 + imgCol, 20);
    }

    // 5) Header row (no ID column)
    sheet.appendRow(<CellValue?>[
      TextCellValue('Text'),
      TextCellValue('DateTime'),
      TextCellValue('Latitude'),
      TextCellValue('Longitude'),
      ...List.generate(maxImageCount, (i) => TextCellValue('Image${i + 1}')),
    ]);

    // 6) Data rows
    for (var rowIndex = 0; rowIndex < selectedNotes.length; rowIndex++) {
      final note = selectedNotes[rowIndex];

      // a) Text/date/coords + placeholders for images
      sheet.appendRow(<CellValue?>[
        TextCellValue(note.text),
        DateTimeCellValue.fromDateTime(note.dateTime),
        note.latitude != null ? DoubleCellValue(note.latitude!) : null,
        note.longitude != null ? DoubleCellValue(note.longitude!) : null,
        ...List.filled(maxImageCount, null),
      ]);

      // b) Bump row height so images fit
      sheet.setRowHeight(rowIndex + 1, 80);

      // c) Embed images into their cells
      for (var imgCol = 0; imgCol < note.imagePaths.length; imgCol++) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(
            columnIndex: 4 + imgCol,
            rowIndex: rowIndex + 1, // +1 because header is row 0
          ),
        );
        cell.value = await ImageCellValue.fromFile(
          note.imagePaths[imgCol],
          width: 100,
          height: 100,
        );
      }
    }

    // 7) Save to a temporary file
    final bytes = excel.encode();
    final dir = await getTemporaryDirectory();
    final filePath = '${dir.path}/notes_export.xlsx';
    final file = File(filePath);
    await file.writeAsBytes(bytes!);

    // 8) Share via system share sheet
    try {
      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'Please find attached the exported notes.',
      );
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
          final selected = note.id != null && _selectedIds.contains(note.id);
          return _selectionMode
              ? CheckboxListTile(
            value: selected,
            title: Text(
              note.text.length > 30
                  ? note.text.substring(0, 30) + '…'
                  : note.text,
            ),
            subtitle: Text(note.dateTime.toLocal().toString()),
            onChanged: (val) => setState(() {
              if (val == true && note.id != null) {
                _selectedIds.add(note.id!);
              } else if (note.id != null) {
                _selectedIds.remove(note.id);
              }
            }),
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
