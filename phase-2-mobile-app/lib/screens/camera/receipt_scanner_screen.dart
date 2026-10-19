import 'dart:io';
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
  bool _isProcessing = false;

  Future<void> _captureFromCamera() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      await _processImageFile(File(photo.path));
    }
  }

  Future<void> _pickFromGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      await _processImageFile(File(image.path));
    }
  }

  Future<void> _processImageFile(File file) async {
    setState(() => _isProcessing = true);
    try {
      final ocrResult = await _ocrService.processReceiptImageWithDetails(file);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ReviewReceiptScreen(transaction: ocrResult.transaction),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi nhận diện Google ML Kit: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Quét Hóa Đơn', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(
              'Google ML Kit • On-Device AI',
              style: TextStyle(fontSize: 11, color: AppColors.primary.withOpacity(0.9), fontWeight: FontWeight.w500),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.photo_library),
            onPressed: _isProcessing ? null : _pickFromGallery,
            tooltip: 'Chọn ảnh từ thư viện',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera viewfinder / Bounding box guide
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primary, width: 2.5),
                borderRadius: BorderRadius.circular(16),
                color: Colors.white.withOpacity(0.04),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 16,
                    left: 0,
                    right: 0,
                    child: Text(
                      'Căn hóa đơn vào khung',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Center(
                    child: Icon(
                      Icons.document_scanner_outlined,
                      size: 80,
                      color: Colors.white.withOpacity(0.3),
                    ),
                  ),
                ],
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
                    Text(
                      'Đang đọc hóa đơn...',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),

          // Bottom Action Bar
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.info_outline, color: Colors.white70, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Chụp rõ tổng tiền & tên hóa đơn',
                        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
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
                      icon: const Icon(Icons.flash_auto, color: Colors.white, size: 32),
                      onPressed: () {},
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
