import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../../config/constants.dart';
import '../../models/report.dart';
import '../../providers/report_provider.dart';
import '../../providers/sync_provider.dart';

class ReportFormScreen extends StatefulWidget {
  const ReportFormScreen({Key? key}) : super(key: key);

  @override
  State<ReportFormScreen> createState() => _ReportFormScreenState();
}

class _ReportFormScreenState extends State<ReportFormScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedCategory = ReportCategories.plasticDumping;
  final _descriptionController = TextEditingController();
  bool _anonymous = false;
  String? _mediaPath;
  bool _isVideo = false;
  Position? _position;
  bool _submitting = false;
  List<String> _selectedImages = [];
  List<String> _selectedVideos = [];
  double _uploadProgress = 0.0;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && _mediaPath == null) {
      _mediaPath = args['path'] as String?;
      _isVideo = args['isVideo'] ?? false;
      _position = args['position'] as Position?;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);

    final syncProvider = context.read<SyncProvider>();
    final reportProvider = context.read<ReportProvider>();
    final isOnline = await syncProvider.checkConnectivity();

    try {
      final capturedAt = DateTime.now().toUtc().toIso8601String();

      // combine images from gallery and camera preview
      final images = <String>[];
      if (_selectedImages.isNotEmpty) images.addAll(_selectedImages);
      if (_mediaPath != null && !_isVideo) images.add(_mediaPath!);

      // combine videos from gallery and camera preview
      final videos = <String>[];
      if (_selectedVideos.isNotEmpty) videos.addAll(_selectedVideos);
      if (_mediaPath != null && _isVideo) videos.add(_mediaPath!);

      final success = await reportProvider.submitReport(
        category: _selectedCategory!,
        latitude: _position?.latitude ?? 0.0,
        longitude: _position?.longitude ?? 0.0,
        gpsAccuracy: _position?.accuracy ?? 0.0,
        capturedAt: capturedAt,
        description: _descriptionController.text.trim(),
        anonymous: _anonymous,
        isOnline: isOnline,
        photoPaths: images.isNotEmpty ? images : null,
        videoPaths: videos.isNotEmpty ? videos : null,
        onProgress: (progress) {
          setState(() => _uploadProgress = progress);
        },
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report submitted')));
        Navigator.of(context).popUntil((route) => route.settings.name == '/home');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to submit report')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Report')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: ReportCategories.all
                      .map((c) => DropdownMenuItem(value: c, child: Text(ReportCategories.displayName(c))))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedCategory = v),
                  validator: (v) => v == null ? 'Select a category' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Description (optional)'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Checkbox(value: _anonymous, onChanged: (v) => setState(() => _anonymous = v ?? false)),
                    const SizedBox(width: 8),
                    const Text('Report anonymously'),
                  ],
                ),
                const SizedBox(height: 12),
                // Selected images from gallery or camera
                if (_selectedImages.isNotEmpty) ...[
                  SizedBox(
                    height: 120,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (context, index) {
                        final path = _selectedImages[index];
                        return Stack(
                          children: [
                            Image.file(File(path), height: 120, width: 120, fit: BoxFit.cover),
                            Positioned(
                              right: 2,
                              top: 2,
                              child: GestureDetector(
                                onTap: () => setState(() => _selectedImages.removeAt(index)),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(Icons.close, color: Colors.white, size: 18),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemCount: _selectedImages.length,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                // If a single media was provided through camera preview (legacy)
                if (_mediaPath != null && _selectedImages.isEmpty) ...[
                  _isVideo ? const Icon(Icons.videocam, size: 120) : Image.file(File(_mediaPath!), height: 240, fit: BoxFit.cover),
                  const SizedBox(height: 12),
                ],
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _pickImages,
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Add from gallery'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _pickVideos,
                      icon: const Icon(Icons.video_library),
                      label: const Text('Add Videos'),
                    ),
                    const SizedBox(width: 12),
                    if (_mediaPath == null)
                      ElevatedButton.icon(
                        onPressed: () => Navigator.of(context).pushNamed('/camera'),
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Open camera'),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                // Selected videos
                if (_selectedVideos.isNotEmpty) ...[
                  SizedBox(
                    height: 100,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _selectedVideos.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, idx) {
                        final path = _selectedVideos[idx];
                        return GestureDetector(
                          onTap: () => _previewVideo(path),
                          child: Stack(
                            children: [
                              Container(
                                width: 160,
                                height: 100,
                                color: Colors.black12,
                                child: Center(
                                  child: Icon(Icons.videocam, size: 36, color: Colors.grey[700]),
                                ),
                              ),
                              Positioned(
                                right: 2,
                                top: 2,
                                child: GestureDetector(
                                  onTap: () => setState(() => _selectedVideos.removeAt(idx)),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Icon(Icons.close, color: Colors.white, size: 18),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Text('GPS: ${_position?.latitude?.toStringAsFixed(6) ?? 'Unknown'}, ${_position?.longitude?.toStringAsFixed(6) ?? 'Unknown'}'),
                const SizedBox(height: 16),
                if (_submitting) ...[
                  LinearProgressIndicator(value: _uploadProgress),
                  const SizedBox(height: 12),
                ],
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _submit,
                    child: _submitting
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Submit Report'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickImages() async {
    try {
      final picker = ImagePicker();
      final List<XFile>? files = await picker.pickMultiImage(imageQuality: 80);
      if (files != null && files.isNotEmpty) {
        final List<String> accepted = [];
        final List<String> rejected = [];
        for (final f in files) {
          try {
            final p = f.path;
            final file = File(p);
            if (await file.exists()) {
              final len = await file.length();
              if (len <= ValidationConstraints.maxPhotoSizeBytes) {
                accepted.add(p);
              } else {
                rejected.add('${p.split(Platform.pathSeparator).last}');
              }
            }
          } catch (_) {
            rejected.add(f.name ?? 'unknown');
          }
        }

        setState(() {
          _selectedImages.addAll(accepted);
        });

        if (rejected.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Some images were too large and were skipped: ${rejected.join(", ")}')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to pick images: $e')));
    }
  }

  Future<void> _pickVideos() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.video, allowMultiple: true);
      if (result != null && result.files.isNotEmpty) {
        final List<String> accepted = [];
        final List<String> rejected = [];
        for (final file in result.files) {
          final path = file.path;
          if (path == null) continue;
          final size = file.size; // bytes
          if (size > 0 && size <= ValidationConstraints.maxVideoSizeBytes) {
            accepted.add(path);
          } else {
            rejected.add(file.name ?? path.split(Platform.pathSeparator).last);
          }
        }
        setState(() => _selectedVideos.addAll(accepted));
        if (rejected.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Some videos were too large and were skipped: ${rejected.join(", ")}')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to pick videos: $e')));
    }
  }

  Future<void> _previewVideo(String path) async {
    try {
      final controller = VideoPlayerController.file(File(path));
      await controller.initialize();
      final chewieController = ChewieController(videoPlayerController: controller, autoPlay: true, looping: false);
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (_) => Dialog(
          child: SizedBox(height: 300, width: 400, child: Chewie(controller: chewieController)),
        ),
      );
      chewieController.dispose();
      controller.dispose();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to preview video: $e')));
    }
  }
}
