import 'package:flutter_test/flutter_test.dart';
import 'package:provider_app/services/upload_service.dart';

void main() {
  group('UploadResult', () {
    test('parses correctly from json response', () {
      final json = {
        'url': 'https://s3.amazonaws.com/avatars/user-123.jpg',
        'key': 'avatars/user-123.jpg',
        'originalName': 'avatar.jpg',
        'mimeType': 'image/jpeg',
        'size': 20480,
      };

      final result = UploadResult.fromJson(json);

      expect(result.url, 'https://s3.amazonaws.com/avatars/user-123.jpg');
      expect(result.key, 'avatars/user-123.jpg');
      expect(result.originalName, 'avatar.jpg');
      expect(result.mimeType, 'image/jpeg');
      expect(result.size, 20480);
    });

    test('handles missing or null fields gracefully', () {
      final json = <String, dynamic>{};

      final result = UploadResult.fromJson(json);

      expect(result.url, '');
      expect(result.key, '');
      expect(result.originalName, '');
      expect(result.mimeType, '');
      expect(result.size, 0);
    });
  });
}
