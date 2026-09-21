import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

/// Firebase Storage wrapper for receipt images.
/// Only used for authenticated (non-demo) users — demo mode keeps
/// receipt images as local file paths only, never uploaded.
class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadReceipt({
    required String uid,
    required String transactionId,
    required File file,
  }) async {
    final ref = _storage.ref('receipts/$uid/$transactionId.jpg');
    await ref.putFile(file);
    return ref.getDownloadURL();
  }

  Future<void> deleteReceipt({required String uid, required String transactionId}) async {
    final ref = _storage.ref('receipts/$uid/$transactionId.jpg');
    try {
      await ref.delete();
    } catch (_) {
      // Already deleted or never existed — safe to ignore.
    }
  }
}
