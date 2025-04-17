import 'package:flutter/material.dart';
import 'package:get/get_navigation/get_navigation.dart';
import 'note.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Field App'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NoteScreen()),
                );
              },
              child: const Text('Add Note'),
            ),
            const SizedBox(height: 20),
            MyButton(text: 'View List'),
            const SizedBox(height: 20),
            MyButton(text: 'Upload'),
          ],
        ),
      ),
    );
  }
}

class MyButton extends StatelessWidget {
  const MyButton({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        print('$text pressed!');
      },
      child: Text(text),
    );
  }
}