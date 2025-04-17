import 'dart:io';
import 'package:flutter/material.dart';
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

  Future<void> _deleteNote(int id, int index) async {
    await DBHelper().deleteNote(id);
    setState(() {
      _notes.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Note deleted')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Saved Notes')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _notes.isEmpty
          ? const Center(child: Text('No notes yet'))
          : ListView.builder(
        itemCount: _notes.length,
        itemBuilder: (context, index) {
          final note = _notes[index];
          return ListTile(
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
              '${note.dateTime.toLocal()}\nLat: ${note.latitude?.toStringAsFixed(4)} Lng: ${note.longitude?.toStringAsFixed(4)}',
            ),
            isThreeLine: true,
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _deleteNote(note.id!, index),
            ),
          );
        },
      ),
    );
  }
}