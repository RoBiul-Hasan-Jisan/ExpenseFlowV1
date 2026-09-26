import 'dart:io';
import 'api_client.dart';

/// Uploads receipt images to the ExpenseFlow Node.js backend (stored on
/// disk under uploads/receipts there) instead of Firebase Storage.
/// Only used for authenticated (non-demo) users — demo mode keeps
/// receipt images as local file paths only, never uploaded.
class StorageService {
  final ApiClient _api = ApiClient.instance;

  Future<String> uploadReceipt({
    required String uid,
    required String transactionId,
    required File file,
  }) async {
    final bytes = await file.readAsBytes();
    final filename = file.path.split(Platform.pathSeparator).last;
    final data = await _api.uploadFile(
      '/api/uploads/receipt/$transactionId',
      fileBytes: bytes,
      filename: filename,
    );
    return data['receiptUrl'] as String;
  }

  Future<void> deleteReceipt({required String uid, required String transactionId}) async {
    try {
      await _api.delete('/api/uploads/receipt/$transactionId');
    } catch (_) {
      // Already deleted or never existed — safe to ignore.
    }
  }

  Future<String> uploadAvatar({required File file}) async {
    final bytes = await file.readAsBytes();
    final filename = file.path.split(Platform.pathSeparator).last;
    final data = await _api.uploadFile('/api/uploads/avatar', fileBytes: bytes, filename: filename);
    return data['avatarUrl'] as String;
  }
}
