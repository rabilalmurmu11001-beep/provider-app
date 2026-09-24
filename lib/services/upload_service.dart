import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../network.dart';

final uploadServiceProvider = Provider<UploadService>((ref) {
  final dio = ref.watch(dioProvider);
  return UploadService(dio);
});

class UploadResult {
  final String url;
  final String key;
  final String originalName;
  final String mimeType;
  final int size;

  UploadResult({
    required this.url,
    required this.key,
    required this.originalName,
    required this.mimeType,
    required this.size,
  });

  factory UploadResult.fromJson(Map<String, dynamic> json) {
    return UploadResult(
      url: json['url']?.toString() ?? '',
      key: json['key']?.toString() ?? '',
      originalName: json['originalName']?.toString() ?? '',
      mimeType: json['mimeType']?.toString() ?? '',
      size: (json['size'] as num?)?.toInt() ?? 0,
    );
  }
}

class UploadService {
  final Dio _dio;

  UploadService(this._dio);

  /// Upload an image/file to AWS S3 via the backend /upload endpoint
  Future<UploadResult> uploadFile({
    required XFile file,
    String folder = 'avatars',
  }) async {
    try {
      final fileName = file.name.isNotEmpty
          ? file.name
          : file.path.split('/').last;

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: fileName,
        ),
        'folder': folder,
      });

      final response = await _dio.post(
        '/upload',
        data: formData,
      );

      if (response.data is Map<String, dynamic>) {
        final data = response.data['data'];
        if (data is Map<String, dynamic>) {
          return UploadResult.fromJson(data);
        }
      }
      throw Exception('Unexpected server response format during file upload.');
    } catch (err) {
      rethrow;
    }
  }
}
