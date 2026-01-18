import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class PreviewScreen extends StatelessWidget {
  const PreviewScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final String? path = args?['path'];
    final bool isVideo = args?['isVideo'] ?? false;
    final Position? position = args?['position'];

    if (path == null) {
      return const Scaffold(body: Center(child: Text('No media found')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Preview')),
      body: Column(
        children: [
          Expanded(
            child: isVideo
                ? Center(child: Icon(Icons.videocam, size: 120)) // placeholder
                : Image.file(File(path), fit: BoxFit.contain),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (position != null) Text('Location: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)} (±${position.accuracy}m)'),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushNamed('/report/form', arguments: {
                      'path': path,
                      'isVideo': isVideo,
                      'position': position,
                    });
                  },
                  child: const Text('Use this media'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Retake'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
