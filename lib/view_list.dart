import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart'; // For mobile
import 'dart:io' show File; // For Excel export only

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

  Future<void> _deleteNote(int? id) async {
    if (id == null) return;
    await DBHelper().deleteNote(id);
    _loadNotes();
  }

  void _toggleSelectionMode() {
    setState(() {
      _selectionMode = !_selectionMode;
      if (!_selectionMode) _selectedIds.clear();
    });
  }

  /// Converts a base64 image to a widget.
  Widget _buildImageFromBase64(String base64Str) {
    try {
      final Uint8List bytes = base64Decode(base64Str);
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.memory(
          bytes,
          width: 50,
          height: 50,
          fit: BoxFit.cover,
        ),
      );
    } catch (_) {
      return const Icon(CupertinoIcons.photo);
    }
  }

  Future<void> _exportSelected() async {
    if (_selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No notes selected for export')),
      );
      return;
    }

    final selectedNotes = _notes.where((n) => n.id != null && _selectedIds.contains(n.id)).toList();
    final excel = Excel.createExcel();
    final sheet = excel['Sheet1'];

    final maxImageCount = selectedNotes.fold<int>(
      0,
          (prev, note) => note.imageBase64List.length > prev ? note.imageBase64List.length : prev,
    );

    for (var imgCol = 0; imgCol < maxImageCount; imgCol++) {
      sheet.setColumnWidth(4 + imgCol, 20);
    }

    sheet.appendRow(<CellValue?>[
      TextCellValue('Text'),
      TextCellValue('DateTime'),
      TextCellValue('Latitude'),
      TextCellValue('Longitude'),
      ...List.generate(maxImageCount, (i) => TextCellValue('Image${i + 1}')),
    ]);

    for (var rowIndex = 0; rowIndex < selectedNotes.length; rowIndex++) {
      final note = selectedNotes[rowIndex];
      sheet.appendRow(<CellValue?>[
        TextCellValue(note.text),
        DateTimeCellValue.fromDateTime(note.dateTime),
        note.latitude != null ? DoubleCellValue(note.latitude!) : null,
        note.longitude != null ? DoubleCellValue(note.longitude!) : null,
        ...List.generate(maxImageCount, (i) {
          if (i < note.imageBase64List.length) {
            return TextCellValue('[Image]');
          }
          return null;
        }),
      ]);
    }

    final bytes = excel.encode();
    final dir = await getTemporaryDirectory();
    final filePath = '${dir.path}/notes_export.xlsx';
    final file = File(filePath);
    await file.writeAsBytes(bytes!);

    try {
      await Share.shareXFiles([XFile(filePath)], text: 'Please find attached the exported notes.');
      setState(() {
        _selectionMode = false;
        _selectedIds.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to share file: $e')));
    }
  }

  String formatDateTime(DateTime dateTime) {
    return DateFormat('yyyy-MM-dd hh:mm a').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Notes'),
        actions: [
          IconButton(
            icon: Icon(_selectionMode ? CupertinoIcons.xmark : CupertinoIcons.check_mark_circled),
            onPressed: _toggleSelectionMode,
          ),
          if (_selectionMode)
            IconButton(
              icon: const Icon(CupertinoIcons.share),
              onPressed: _exportSelected,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CupertinoActivityIndicator())
          : _notes.isEmpty
          ? const Center(child: Text('No notes yet'))
          : SingleChildScrollView(
        child: ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _notes.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final note = _notes[index];
            final selected = note.id != null && _selectedIds.contains(note.id);
            return _selectionMode
                ? CheckboxListTile(
              value: selected,
              title: Text(note.text.length > 30 ? '${note.text.substring(0, 30)}…' : note.text),
              subtitle: Text(formatDateTime(note.dateTime)),
              onChanged: (val) => setState(() {
                if (val == true && note.id != null) {
                  _selectedIds.add(note.id!);
                } else if (note.id != null) {
                  _selectedIds.remove(note.id);
                }
              }),
            )
                : Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListTile(
                leading: note.imageBase64List.isNotEmpty
                    ? _buildImageFromBase64(note.imageBase64List.first)
                    : const Icon(CupertinoIcons.doc_text),
                title: Text(note.text.length > 30 ? '${note.text.substring(0, 30)}…' : note.text),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formatDateTime(note.dateTime),
                      style: const TextStyle(color: Colors.grey),
                    ),
                    Text(
                      'Lat: ${note.latitude?.toStringAsFixed(4)}  Lng: ${note.longitude?.toStringAsFixed(4)}',
                    ),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(CupertinoIcons.delete, color: Colors.redAccent),
                  onPressed: () => _deleteNote(note.id),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}