import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class NoteScreen extends StatefulWidget {
  const NoteScreen({super.key});
  @override
  _NoteScreenState createState() => _NoteScreenState();
}

class _NoteScreenState extends State<NoteScreen> {
  final TextEditingController _controller = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  List<XFile> _images = [];

  Future<void> _pickImages() async {
    final List<XFile>? selectedImages = await _picker.pickMultiImage();
    if (selectedImages != null && selectedImages.isNotEmpty) {
      setState(() {
        _images.addAll(selectedImages);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Note'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              // TODO: Persist note content and images
              print('Note content: ${_controller.text}');
              print('Attached images: ${_images.length}');
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Container holding text input and image previews
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        textAlignVertical: TextAlignVertical.top,
                        maxLines: null,
                        expands: true,
                        decoration: const InputDecoration(
                          hintText: 'Write your note here...',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(8),
                          alignLabelWithHint: true,
                        ),
                      ),
                    ),
                    if (_images.isNotEmpty)
                      SizedBox(
                        height: 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _images.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Image.file(
                                File(_images[index].path),
                                width: 100,
                                fit: BoxFit.cover,
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _pickImages,
                  icon: const Icon(Icons.attach_file),
                  label: const Text('Attach Images'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}