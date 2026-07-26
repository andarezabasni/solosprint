import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme.dart';
import '../run/run_activity.dart';
import 'share_service.dart';
import 'templates/classic_template.dart';
import 'templates/photo_template.dart';
import 'templates/map_template.dart';

class SharePage extends StatefulWidget {
  final RunActivity activity;
  const SharePage({super.key, required this.activity});

  @override
  State<SharePage> createState() => _SharePageState();
}

class _SharePageState extends State<SharePage> {
  int _selectedTemplate = 0; // 0=Classic, 1=Photo, 2=Map
  String? _photoPath;
  bool _darkMode = true;
  bool _isExporting = false;

  static const _templateNames = ['Classic', 'Photo', 'Map'];
  static const _templateIcons = [
    Icons.dashboard_outlined,
    Icons.photo_library_outlined,
    Icons.map_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Share Activity'),
        actions: [
          if (_selectedTemplate == 0)
            IconButton(
              icon: Icon(_darkMode ? Icons.light_mode : Icons.dark_mode),
              tooltip: 'Toggle dark/light',
              onPressed: () => setState(() => _darkMode = !_darkMode),
            ),
        ],
      ),
      body: Column(
        children: [
          // Template selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: List.generate(3, (i) {
                final isSelected = _selectedTemplate == i;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTemplate = i),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.accent : Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            _templateIcons[i],
                            color: isSelected ? Colors.white : Colors.black54,
                            size: 22,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _templateNames[i],
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black54,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),

          // Photo picker button (only for Photo template)
          if (_selectedTemplate == 1)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _pickPhoto,
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: Text(
                    _photoPath == null ? 'Choose Photo' : 'Change Photo',
                  ),
                ),
              ),
            ),

          const SizedBox(height: 8),

          // Preview — FittedBox ensures template renders at full 1080×1920
          // but visually scaled to fit screen. Capture will be full resolution.
          Expanded(
            child: Center(
              child: FittedBox(
                fit: BoxFit.contain,
                child: RepaintBoundary(
                  key: ShareService.previewKey,
                  child: SizedBox(
                    width: 1080,
                    height: 1920,
                    child: _buildPreview(),
                  ),
                ),
              ),
            ),
          ),

          // Action buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: _isExporting ? null : _onSave,
                      icon: const Icon(Icons.download_outlined),
                      label: const Text('Save Image'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.accent,
                        side: const BorderSide(color: AppTheme.accent),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _isExporting ? null : _onShare,
                      icon: _isExporting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.share_outlined),
                      label: Text(_isExporting ? 'Processing...' : 'Share'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    switch (_selectedTemplate) {
      case 1:
        return PhotoTemplate(activity: widget.activity, imagePath: _photoPath);
      case 2:
        return MapTemplate(activity: widget.activity);
      default:
        return ClassicTemplate(activity: widget.activity, darkMode: _darkMode);
    }
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _photoPath = picked.path);
    }
  }

  Future<Uint8List> _capture() async {
    return ShareService.captureImage();
  }

  Future<void> _onSave() async {
    setState(() => _isExporting = true);
    try {
      final bytes = await _capture();
      await ShareService.saveToGallery(bytes);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image saved to gallery!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _onShare() async {
    setState(() => _isExporting = true);
    try {
      final bytes = await _capture();
      await ShareService.shareImage(bytes);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Share failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }
}
