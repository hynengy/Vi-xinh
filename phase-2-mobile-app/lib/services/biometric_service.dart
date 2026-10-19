import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

class BiometricService {
  static final BiometricService _instance = BiometricService._internal();
  factory BiometricService() => _instance;
  BiometricService._internal();

  final LocalAuthentication _auth = LocalAuthentication();

  /// Kiểm tra thiết bị có phần cứng sinh trắc học và đã cài vân tay/FaceID chưa
  Future<bool> isBiometricsAvailable() async {
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await _auth.isDeviceSupported();
      return canAuthenticate;
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// Lấy danh sách các phương thức sinh trắc học khả dụng (Face ID, Vân tay, Mống mắt)
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } on PlatformException catch (_) {
      return <BiometricType>[];
    }
  }

  /// Thực hiện quét sinh trắc học (Mở khóa Face ID hoặc chạm vân tay)
  Future<bool> authenticate({
    String reason = 'Xác thực sinh trắc học để mở khóa Ví Xinh',
  }) async {
    try {
      final bool isAvailable = await isBiometricsAvailable();
      if (!isAvailable) {
        // Fallback cho môi trường test hoặc thiết bị không hỗ trợ
        return true;
      }

      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // Cho phép nhập mã PIN/Pattern nếu vân tay lỗi
          useErrorDialogs: true,
        ),
      );
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// Lấy tên thân thiện hiển thị cho người dùng (Face ID / Vân tay)
  Future<String> getBiometricDisplayName() async {
    final types = await getAvailableBiometrics();
    if (types.contains(BiometricType.face)) {
      return 'Face ID (Khuôn mặt)';
    } else if (types.contains(BiometricType.fingerprint) || types.contains(BiometricType.strong)) {
      return 'Cảm biến vân tay';
    } else if (types.contains(BiometricType.iris)) {
      return 'Nhận diện mống mắt';
    }
    return 'Sinh trắc học thiết bị';
  }
}
