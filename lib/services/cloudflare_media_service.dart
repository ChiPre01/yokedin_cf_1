import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

/// Handles authenticated media uploads, downloads and deletions
/// through the Yokedin Cloudflare Worker.
class CloudflareMediaService {
  CloudflareMediaService._();

  static final CloudflareMediaService instance =
      CloudflareMediaService._();

  static const String baseUrl =
      'https://yokedin-media-api.ogaizi70.workers.dev';

  static const int maxFileSize = 25 * 1024 * 1024;

  static const Duration requestTimeout = Duration(seconds: 60);

  /// Gets a Firebase ID token for the currently signed-in user.
  Future<String> _getAuthToken() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw CloudflareMediaException(
        'You must sign in before accessing media.',
      );
    }

    final token = await user.getIdToken();

    if (token == null || token.isEmpty) {
      throw CloudflareMediaException(
        'Unable to obtain your authentication token. '
        'Please sign in again.',
      );
    }

    return token;
  }

  /// Determines the MIME type from the selected file extension.
  String _getContentType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();

    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';

      case 'png':
        return 'image/png';

      case 'webp':
        return 'image/webp';

      case 'gif':
        return 'image/gif';

      case 'mp4':
        return 'video/mp4';

      case 'webm':
        return 'video/webm';

      case 'mp3':
        return 'audio/mpeg';

      case 'm4a':
        return 'audio/mp4';

      case 'wav':
        return 'audio/wav';

      case 'ogg':
        return 'audio/ogg';

      case 'pdf':
        return 'application/pdf';

      default:
        throw CloudflareMediaException(
          'Unsupported file extension: .$extension',
        );
    }
  }

  /// Uploads an image, video, audio file or PDF to Cloudflare R2.
  ///
  /// Returns the URL and storage key supplied by the Worker.
  ///
  /// Example:
  /// final result = await CloudflareMediaService.instance.uploadFile(file);
  /// final url = result['url'];
  /// final key = result['key'];
  Future<Map<String, dynamic>> uploadFile(XFile file) async {
    final bytes = await file.readAsBytes();

    if (bytes.isEmpty) {
      throw CloudflareMediaException(
        'The selected file is empty.',
      );
    }

    if (bytes.length > maxFileSize) {
      throw CloudflareMediaException(
        'The file exceeds the 25 MB upload limit.',
      );
    }

    final contentType = _getContentType(file.name);
    final token = await _getAuthToken();

    final uri = Uri.parse('$baseUrl/upload');

    final request = http.Request('POST', uri);

    request.headers.addAll({
      'Authorization': 'Bearer $token',
      'Content-Type': contentType,
      'X-File-Name': Uri.encodeComponent(file.name),
    });

    request.bodyBytes = bytes;

    final streamedResponse = await request.send().timeout(
      requestTimeout,
    );

    final response = await http.Response.fromStream(
      streamedResponse,
    ).timeout(requestTimeout);

    final Map<String, dynamic> data;

    try {
      final decoded = jsonDecode(response.body);

      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Unexpected response format.');
      }

      data = decoded;
    } catch (_) {
      throw CloudflareMediaException(
        'The media server returned an invalid response '
        '(HTTP ${response.statusCode}).',
      );
    }

    if (response.statusCode != 201 || data['success'] != true) {
      throw CloudflareMediaException(
        data['error']?.toString() ??
            'Upload failed (HTTP ${response.statusCode}).',
      );
    }

    if (data['url'] is! String || data['key'] is! String) {
      throw CloudflareMediaException(
        'The server response is missing the media URL or key.',
      );
    }

    return data;
  }

  /// Downloads media through the Worker with Firebase authentication.
  ///
  /// Use the returned bytes with Image.memory for images.
  Future<Uint8List> downloadMedia(String mediaUrl) async {
    final token = await _getAuthToken();

    final uri = Uri.parse(mediaUrl);
    final baseUri = Uri.parse(baseUrl);

    if (uri.scheme != 'https' ||
        uri.host != baseUri.host ||
        uri.port != baseUri.port) {
      throw CloudflareMediaException(
        'The media URL is not from the configured media server.',
      );
    }

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
      },
    ).timeout(requestTimeout);

    if (response.statusCode != 200) {
      throw CloudflareMediaException(
        'Unable to download media '
        '(HTTP ${response.statusCode}).',
      );
    }

    return response.bodyBytes;
  }

  /// Deletes an uploaded file.
  ///
  /// Only files owned by the signed-in user can be deleted
  /// by the current Worker implementation.
  Future<void> deleteMedia(String mediaKey) async {
    final token = await _getAuthToken();

    final key = mediaKey.trim();

    if (key.isEmpty ||
        key.startsWith('/') ||
        key.contains('..') ||
        key.contains('\\')) {
      throw CloudflareMediaException(
        'Invalid media storage key.',
      );
    }

    final uri = Uri.parse('$baseUrl/media/$key');

    final response = await http.delete(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
      },
    ).timeout(requestTimeout);

    if (response.statusCode != 200) {
      String message = 'Media deletion failed '
          '(HTTP ${response.statusCode}).';

      try {
        final data = jsonDecode(response.body);

        if (data is Map && data['error'] != null) {
          message = data['error'].toString();
        }
      } catch (_) {
        // Keep the default error message.
      }

      throw CloudflareMediaException(message);
    }
  }
}

/// A readable error type for Cloudflare media operations.
class CloudflareMediaException implements Exception {
  final String message;

  CloudflareMediaException(this.message);

  @override
  String toString() => message;
}
