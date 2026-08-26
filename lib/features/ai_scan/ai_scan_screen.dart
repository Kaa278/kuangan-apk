import 'dart:io';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:kuangan/features/ai_scan/ai_scan_provider.dart';
import 'package:kuangan/features/ai_scan/camera_overlay.dart';
import 'package:kuangan/features/ai_scan/scan_result_card.dart';
import 'package:kuangan/features/transactions/transaction_modal.dart';

class AiScanScreen extends ConsumerStatefulWidget {
  const AiScanScreen({super.key});

  @override
  ConsumerState<AiScanScreen> createState() => _AiScanScreenState();
}

class _AiScanScreenState extends ConsumerState<AiScanScreen> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _showReceiptPreview = false;
  bool _showFullReceiptImage = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    _cameras = await availableCameras();
    if (_cameras == null || _cameras!.isEmpty) return;

    _controller = CameraController(
      _cameras![0],
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await _controller!.initialize();
      if (mounted) {
        setState(() => _isInitialized = true);
      }
    } catch (e) {
      debugPrint('Camera error: $e');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    if (!_isInitialized || _controller!.value.isTakingPicture) return;

    try {
      final image = await _controller!.takePicture();

      setState(() => _showReceiptPreview = false);

      ref.read(aiScanProvider.notifier).setImage(File(image.path));
      _processImage();
    } catch (e) {
      debugPrint('Take photo error: $e');
    }
  }

  Future<void> _pickGallery() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() => _showReceiptPreview = false);

      ref.read(aiScanProvider.notifier).setImage(File(image.path));
      _processImage();
    }
  }

  void _processImage() {
    ref.read(aiScanProvider.notifier).process();
  }

  void _resetScan() {
    setState(() => _showReceiptPreview = false);
    ref.read(aiScanProvider.notifier).reset();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiScanProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (state.image != null)
            Positioned.fill(
              child: AnimatedScale(
                scale: state.status == AiScanStatus.success ? 1.08 : 1.0,
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOut,
                child: Image.file(
                  state.image!,
                  fit: BoxFit.cover,
                ),
              ),
            )
          else if (_isInitialized)
            Positioned.fill(child: CameraPreview(_controller!))
          else
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          if (state.image == null) const CameraOverlay(),
          _buildTopBar(context),
          if (state.status == AiScanStatus.idle && state.image == null)
            _buildBottomControls(),
          if (state.status == AiScanStatus.analyzingImage ||
              state.status == AiScanStatus.uploading)
            _buildLoadingOverlay(state.status),
          if (state.status == AiScanStatus.success && state.result != null)
            _buildResultOverlay(state.result!),
          if (state.status == AiScanStatus.error)
            _buildErrorOverlay(state.error ?? 'Gagal memproses struk'),
          if (_showFullReceiptImage && state.image != null)
            _buildFullReceiptModal(state.image!),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Positioned(
      top: 50,
      left: 20,
      right: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => context.go('/dashboard'),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black45,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white24, width: 1),
              ),
              child: const Icon(
                Icons.close_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black45,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.white24, width: 1),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.blueAccent,
                  size: 14,
                ),
                SizedBox(width: 8),
                Text(
                  'KATHLYN SCAN',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 44),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Positioned(
      bottom: 130,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionButton(Icons.photo_library_rounded, _pickGallery),
          GestureDetector(
            onTap: _takePhoto,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
              ),
              child: Container(
                margin: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  color: Colors.blueAccent,
                  size: 32,
                ),
              ),
            ),
          ),
          _buildActionButton(Icons.flash_on_rounded, () {}),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white10,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildLoadingOverlay(AiScanStatus status) {
    final message = status == AiScanStatus.analyzingImage
        ? 'Kathlyn sedang membaca teks dari gambar...'
        : 'Kathlyn sedang mengkategorikan datamu...';

    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.55),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: Colors.blueAccent,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'KATHLYN',
                style: TextStyle(
                  color: Colors.blueAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultOverlay(dynamic result) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: _showReceiptPreview ? 1.2 : 3,
              sigmaY: _showReceiptPreview ? 1.2 : 3,
            ),
            child: Container(
              color: Colors.black.withValues(
                alpha: _showReceiptPreview ? 0.25 : 0.5,
              ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 250),
            opacity: _showReceiptPreview ? 0.92 : 1,
            child: Padding(
              padding: const EdgeInsets.only(
                left: 24,
                right: 24,
                bottom: 130,
                top: 24,
              ),
              child: ScanResultCard(
                result: result,
                isViewingReceipt: _showReceiptPreview,
                onSave: () {
                  ref.read(aiScanProvider.notifier).reset();
                  context.go('/dashboard');
                  TransactionModal.show(context, scanResult: result);
                },
                onRetry: _resetScan,
                onViewReceipt: () {
                  setState(() {
                    _showFullReceiptImage = true;
                  });
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorOverlay(String message) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.9),
        padding: const EdgeInsets.all(40),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.info_outline_rounded,
                color: Colors.redAccent,
                size: 80,
              ),
              const SizedBox(height: 24),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _resetScan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('COBA LAGI'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFullReceiptModal(File image) {
    return Positioned.fill(
      child: GestureDetector(
        onTap: () => setState(() => _showFullReceiptImage = false),
        child: Container(
          color: Colors.black.withValues(alpha: 0.85),
          child: Stack(
            children: [
              // Close button
              Positioned(
                top: 50,
                left: 20,
                child: GestureDetector(
                  onTap: () => setState(() => _showFullReceiptImage = false),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: Colors.black87,
                      size: 24,
                    ),
                  ),
                ),
              ),

              // Receipt image
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(60),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(
                      image,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),

              // Hint text
              Positioned(
                bottom: 50,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Ketuk dimana saja untuk menutup',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
