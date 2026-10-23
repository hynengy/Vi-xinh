import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../services/mlkit_ocr_service.dart';
import '../review/review_receipt_screen.dart';

class ReceiptScannerScreen extends StatefulWidget {
  const ReceiptScannerScreen({Key? key}) : super(key: key);

  @override
  State<ReceiptScannerScreen> createState() => _ReceiptScannerScreenState();
}

class _ReceiptScannerScreenState extends State<ReceiptScannerScreen> {
  final ImagePicker _picker = ImagePicker();
  final MLKitOcrService _ocrService = MLKitOcrService();
  CameraController? _camera;
  bool _isProcessing = false;
  bool _flashOn = false;
  String? _cameraError;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _cameraError = 'Không tìm thấy camera');
        return;
      }
      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        back,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() => _camera = controller);
    } catch (e) {
      if (mounted) setState(() => _cameraError = 'Không mở được camera. Dùng thư viện ảnh.');
    }
  }

  Future<void> _toggleFlash() async {
    if (_camera == null || !_camera!.value.isInitialized) return;
    _flashOn = !_flashOn;
    await _camera!.setFlashMode(_flashOn ? FlashMode.torch : FlashMode.off);
    setState(() {});
  }

  Future<void> _captureFromCamera() async {
    if (_camera != null && _camera!.value.isInitialized) {
      try {
        final shot = await _camera!.takePicture();
        await _processImageFile(File(shot.path));
        return;
      } catch (_) {}
    }
    final photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo != null) await _processImageFile(File(photo.path));
  }

  Future<void> _pickFromGallery() async {
    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) await _processImageFile(File(image.path));
  }

  Future<void> _processImageFile(File file) async {
    setState(() => _isProcessing = true);
    try {
      final ocrResult = await _ocrService.processReceiptImageWithDetails(file);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ReviewReceiptScreen(
            transaction: ocrResult.transaction,
            ocrLines: ocrResult.totalLines,
            ocrMs: ocrResult.executionTimeMs,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không nhận diện được hóa đơn: $e'), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  void dispose() {
    _camera?.dispose();
    _ocrService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ready = _camera != null && _camera!.value.isInitialized;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quét Hóa Đơn', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('Google ML Kit • On-Device', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.photo_library),
            onPressed: _isProcessing ? null : _pickFromGallery,
          ),
        ],
      ),
      body: Stack(
        children: [
          if (ready)
            Positioned.fill(child: CameraPreview(_camera!))
          else
            Center(
              child: Text(
                _cameraError ?? 'Đang mở camera...',
                style: const TextStyle(color: Colors.white70),
              ),
            ),
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 28, vertical: 80),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primary, width: 2.5),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppColors.primary),
                    SizedBox(height: 16),
                    Text('Đang đọc hóa đơn...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Column(
              children: [
                const Text('Căn hóa đơn vào khung, chụp rõ tổng tiền', style: TextStyle(color: Colors.white, fontSize: 12)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.photo_library, color: Colors.white, size: 32),
                      onPressed: _isProcessing ? null : _pickFromGallery,
                    ),
                    GestureDetector(
                      onTap: _isProcessing ? null : _captureFromCamera,
                      child: Container(
                        height: 74,
                        width: 74,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          gradient: AppColors.primaryGradient,
                        ),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 36),
                      ),
                    ),
                    IconButton(
                      icon: Icon(_flashOn ? Icons.flash_on : Icons.flash_off, color: Colors.white, size: 32),
                      onPressed: _toggleFlash,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
