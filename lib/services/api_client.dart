import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:http/http.dart' as http;
import '../core/constants/app_constants.dart';
import '../core/errors/app_exception.dart';

/// Thin REST client for the ExpenseFlow Node.js/MongoDB backend.
///
/// Auth is Firebase's job: every request attaches the current Firebase
/// user's ID token as a Bearer token, letting the SDK handle refresh
/// automatically (getIdToken() returns a cached token and silently
/// refreshes it in the background before it expires). This class never
/// stores a token itself. It also normalizes error responses into
/// [AppException] so the rest of the app doesn't need to know it's
/// talking to a plain HTTP API.
class ApiClient {
  static final ApiClient instance = ApiClient._internal();
  ApiClient._internal();

  final String _baseUrl = AppConstants.apiBaseUrl;

  Future<String?> _idToken({bool forceRefresh = false}) {
    final user = fb.FirebaseAuth.instance.currentUser;
    if (user == null) return Future.value(null);
    return user.getIdToken(forceRefresh);
  }

  Uri _uri(String path, [Map<String, String>? query]) =>
      Uri.parse('$_baseUrl$path').replace(queryParameters: query);

  Future<Map<String, String>> _headers({bool json = true, bool forceRefresh = false}) async {
    final t = await _idToken(forceRefresh: forceRefresh);
    return {
      if (json) 'Content-Type': 'application/json',
      if (t != null) 'Authorization': 'Bearer $t',
    };
  }

  Future<dynamic> get(String path, {Map<String, String>? query}) => _guard((refresh) async {
        final res = await http.get(_uri(path, query), headers: await _headers(forceRefresh: refresh));
        return _handle(res);
      });

  Future<dynamic> put(String path, Map<String, dynamic> body) => _guard((refresh) async {
        final res = await http.put(_uri(path), headers: await _headers(forceRefresh: refresh), body: jsonEncode(body));
        return _handle(res);
      });

  Future<dynamic> post(String path, [Map<String, dynamic>? body]) => _guard((refresh) async {
        final res = await http.post(
          _uri(path),
          headers: await _headers(forceRefresh: refresh),
          body: body == null ? null : jsonEncode(body),
        );
        return _handle(res);
      });

  Future<dynamic> patch(String path, Map<String, dynamic> body) => _guard((refresh) async {
        final res =
            await http.patch(_uri(path), headers: await _headers(forceRefresh: refresh), body: jsonEncode(body));
        return _handle(res);
      });

  Future<dynamic> delete(String path) => _guard((refresh) async {
        final res = await http.delete(_uri(path), headers: await _headers(forceRefresh: refresh));
        return _handle(res);
      });

  /// Multipart file upload (avatars / receipts). [fileBytes] + [filename]
  /// describe the file; [fields] are extra form fields if needed.
  Future<dynamic> uploadFile(
    String path, {
    required List<int> fileBytes,
    required String filename,
    Map<String, String>? fields,
  }) =>
      _guard((refresh) async {
        final request = http.MultipartRequest('POST', _uri(path));
        final t = await _idToken(forceRefresh: refresh);
        if (t != null) request.headers['Authorization'] = 'Bearer $t';
        if (fields != null) request.fields.addAll(fields);
        request.files.add(http.MultipartFile.fromBytes('file', fileBytes, filename: filename));

        final streamed = await request.send();
        final res = await http.Response.fromStream(streamed);
        return _handle(res);
      });

  /// Runs an HTTP call, retrying once with a force-refreshed ID token if
  /// the server rejects the first attempt as unauthorized (the cached
  /// token can be stale right after sign-in on some platforms). Any
  /// other failure — including a second 401 — is translated into a
  /// friendly [AppException] instead of a raw platform exception.
  Future<T> _guard<T>(Future<T> Function(bool forceRefresh) body) async {
    try {
      return await body(false);
    } on AppException catch (e) {
      if (e.code == 'unauthorized') {
        try {
          return await body(true);
        } on AppException {
          rethrow;
        } catch (_) {
          throw const AppException('Network error. Check your connection and try again.',
              code: 'network-request-failed');
        }
      }
      rethrow;
    } catch (_) {
      throw const AppException('Network error. Check your connection and try again.', code: 'network-request-failed');
    }
  }

  dynamic _handle(http.Response res) {
    final isJson = res.headers['content-type']?.contains('application/json') ?? false;
    final decoded = (res.body.isNotEmpty && isJson) ? jsonDecode(res.body) : null;

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return decoded;
    }

    final message = (decoded is Map && decoded['message'] is String)
        ? decoded['message'] as String
        : 'Something went wrong. Please try again.';

    if (res.statusCode == 401) {
      throw AppException(message, code: 'unauthorized');
    }
    throw AppException(message, code: 'http-${res.statusCode}');
  }
}
