import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:location/location.dart';

import 'models/note_model.dart';
import 'db/db_helper.dart';

class NoteScreen extends StatefulWidget {
  const NoteScreen({super.key});

  @override
  _NoteScreenState createState() => _NoteScreenState();
}

class _NoteScreenState extends State<NoteScreen> {
  final TextEditingController _controller = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final Location _location = Location();

  List<String> _imageBase64List = [];

  /// Opens image picker and converts images to base64.
  Future<void> _pickImages() async {
    try {
      final selectedImages = await _picker.pickMultiImage(imageQuality: 80);
      if (selectedImages != null && selectedImages.isNotEmpty) {
        for (final image in selectedImages) {
          final bytes = await image.readAsBytes();
          final base64Image = base64Encode(bytes);
          _imageBase64List.add(base64Image);
        }
        setState(() {});
      }
    } catch (e) {
      _showError('Error picking images: $e');
    }
  }

  /// Shows an error message in a snackbar.
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  /// Saves the note to the database.
  Future<void> _saveNote() async {
    bool serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled && !await _location.requestService()) return;

    PermissionStatus permissionGranted = await _location.hasPermission();
    if (permissionGranted == PermissionStatus.denied &&
        await _location.requestPermission() != PermissionStatus.granted) return;

    try {
      final locData = await _location.getLocation();
      final note = Note(
        text: _controller.text,
        imageBase64List: _imageBase64List,
        dateTime: DateTime.now(),
        latitude: locData.latitude,
        longitude: locData.longitude,
      );
      await DBHelper().insertNote(note);
      Navigator.pop(context);
    } catch (e) {
      _showError('Error saving note: $e');
    }
  }

  /// Decodes a base64 image string into a widget.
  Widget _buildImage(String base64String) {
    try {
      final Uint8List bytes = base64Decode(base64String);
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.memory(
          bytes,
          width: 100,
          height: 100,
          fit: BoxFit.cover,
        ),
      );
    } catch (_) {
      return const Icon(Icons.broken_image);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Note'),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.check_mark),
            onPressed: _saveNote,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        maxLines: null,
                        expands: true,
                        decoration: const InputDecoration(
                          hintText: 'Write your note here...',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    if (_imageBase64List.isNotEmpty)
                      SizedBox(
                        height: 100,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _imageBase64List.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            return _buildImage(_imageBase64List[index]);
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton.icon(
                icon: const Icon(CupertinoIcons.photo),
                label: const Text('Attach Images'),
                onPressed: _pickImages,
              ),
            ),
          ],
        ),
      ),
    );
  }
}