import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:gal/gal.dart';

class ShareService {
  static final GlobalKey previewKey = GlobalKey();

  /// Render the preview widget to PNG bytes.
  static Future<Uint8List> captureImage() async {
    final boundary = previewKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) throw Exception('Preview not ready');

    final image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) throw Exception('Failed to render image');

    return byteData.buffer.asUint8List();
  }

  /// Save PNG to a temp file and return the path.
  static Future<File> saveToFile(Uint8List bytes) async {
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/solosprint_share.png');
    await file.writeAsBytes(bytes);
    return file;
  }

  /// Save image to device gallery.
  static Future<void> saveToGallery(Uint8List bytes) async {
    await Gal.putImageBytes(bytes);
  }

  /// Share image via Android Share Sheet.
  static Future<void> shareImage(Uint8List bytes) async {
    final file = await saveToFile(bytes);
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'My run with SoloSprint',
    );
  }

  /// Format duration for display.
  static String formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) return '${h}h ${m}m';
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }

  /// Format pace.
  static String formatPace(double pace) {
    if (pace <= 0) return '--';
    final min = pace.floor();
    final sec = ((pace - min) * 60).round();
    return '$min:${sec.toString().padLeft(2, '0')}';
  }

  /// Format date.
  static String formatDate(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}
