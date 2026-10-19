import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../extractor/dart_receipt_extractor.dart';
import '../models/transaction_model.dart';

/// Kết quả chi tiết từ mô hình Google ML Kit Text Recognition
class MLKitOcrResult {
  final TransactionModel transaction;
  final String rawText;
  final int totalBlocks;
  final int totalLines;
  final int executionTimeMs;
  final List<String> detectedLines;

  MLKitOcrResult({
    required this.transaction,
    required this.rawText,
    required this.totalBlocks,
    required this.totalLines,
    required this.executionTimeMs,
    required this.detectedLines,
  });
}

class MLKitOcrService {
  /// Khởi tạo Google ML Kit Text Recognizer với Latin script (tương thích toàn diện tiếng Việt)
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  /// Nhận diện văn bản trực tiếp on-device từ file ảnh chụp với Google ML Kit
  Future<TransactionModel> processReceiptImage(File imageFile) async {
    final result = await processReceiptImageWithDetails(imageFile);
    return result.transaction;
  }

  /// Nhận diện văn bản chi tiết kèm số block, dòng và thời gian thực thi (ms)
  Future<MLKitOcrResult> processReceiptImageWithDetails(File imageFile) async {
    final stopwatch = Stopwatch()..start();

    // 1. Tạo InputImage từ file ảnh chụp
    final inputImage = InputImage.fromFile(imageFile);

    // 2. Gọi Google ML Kit on-device model xử lý ảnh
    final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
    stopwatch.stop();

    final rawText = recognizedText.text;
    final List<String> detectedLines = [];

    // Duyệt qua các Blocks và Lines để trích xuất text có thứ tự
    for (final TextBlock block in recognizedText.blocks) {
      for (final TextLine line in block.lines) {
        if (line.text.trim().isNotEmpty) {
          detectedLines.add(line.text.trim());
        }
      }
    }

    // 3. Bóc tách dữ liệu thông minh qua Bộ trích xuất hóa đơn tiếng Việt
    final transaction = DartReceiptExtractor.parseAll(rawText);

    final finalTx = TransactionModel(
      id: transaction.id,
      userId: transaction.userId,
      merchantName: transaction.merchantName,
      amount: transaction.amount,
      type: transaction.type,
      transactionDate: transaction.transactionDate,
      transactionTime: transaction.transactionTime,
      groupId: transaction.groupId,
      category: transaction.category,
      receiptImagePath: imageFile.path,
      rawOcrText: rawText,
      notes: transaction.notes,
      lineItems: transaction.lineItems,
    );

    return MLKitOcrResult(
      transaction: finalTx,
      rawText: rawText,
      totalBlocks: recognizedText.blocks.length,
      totalLines: detectedLines.length,
      executionTimeMs: stopwatch.elapsedMilliseconds,
      detectedLines: detectedLines,
    );
  }

  /// Xử lý văn bản thô trực tiếp
  TransactionModel processMockReceipt(String rawText, {String? mockPath}) {
    final transaction = DartReceiptExtractor.parseAll(rawText);
    return TransactionModel(
      userId: 1,
      merchantName: transaction.merchantName,
      amount: transaction.amount,
      transactionDate: transaction.transactionDate,
      category: transaction.category,
      receiptImagePath: mockPath,
      rawOcrText: rawText,
      lineItems: transaction.lineItems,
    );
  }

  void dispose() {
    _textRecognizer.close();
  }
}

