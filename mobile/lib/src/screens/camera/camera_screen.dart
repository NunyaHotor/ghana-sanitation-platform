import 'dart:io';

import 'package:flutter/material.dart';
import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../../config/constants.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({Key? key}) : super(key: key);

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final ImagePicker _picker = ImagePicker();
  XFile? _media;
  Position? _position;
  bool _isVideo = false;
  bool _loading = false;

  Future<void> _capturePhoto() async {
    setState(() => _loading = true);
    try {
      final XFile? file = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
      if (file != null) {
        final f = File(file.path);
        final len = await f.length();
        if (len > ValidationConstraints.maxPhotoSizeBytes) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Captured photo is too large. Please reduce resolution.')));
          setState(() => _loading = false);
          return;
        }
        _media = file;
        _isVideo = false;
        await _captureLocation();
        if (mounted) {
          Navigator.of(context).pushNamed('/camera/preview', arguments: {
            'path': file.path,
            'isVideo': false,
            'position': _position,
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to capture photo: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _captureVideo() async {
    setState(() => _loading = true);
    try {
      final XFile? file = await _picker.pickVideo(source: ImageSource.camera, maxDuration: const Duration(seconds: 60));
      if (file != null) {
        final f = File(file.path);
        final len = await f.length();
        if (len > ValidationConstraints.maxVideoSizeBytes) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Captured video is too large. Try recording shorter video.')));
          setState(() => _loading = false);
          return;
        }
        _media = file;
        _isVideo = true;
        await _captureLocation();
        if (mounted) {
          Navigator.of(context).pushNamed('/camera/preview', arguments: {
            'path': file.path,
            'isVideo': true,
            'position': _position,
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to capture video: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _captureLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permissions are permanently denied.')));
        return;
      }

      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
      setState(() => _position = pos);
    } catch (e) {
      // ignore location error, allow media capture without coords
      setState(() => _position = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Capture Evidence')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: _loading ? null : _capturePhoto,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Take Photo'),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loading ? null : _captureVideo,
                icon: const Icon(Icons.videocam),
                label: const Text('Record Video (<=60s)'),
              ),
              const SizedBox(height: 24),
              if (_loading) const CircularProgressIndicator(),
              const SizedBox(height: 12),
              if (_position != null) Text('Location: ${_position!.latitude.toStringAsFixed(6)}, ${_position!.longitude.toStringAsFixed(6)} (±${_position!.accuracy}m)'),
            ],
          ),
        ),
      ),
    );
  }
}
