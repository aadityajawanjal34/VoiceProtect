import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:http_parser/http_parser.dart';

class UploadService {
  static Future<String?> uploadAudio(File audioFile) async {
    try {
      final uri = Uri.parse('https://lamb-huge-vigorously.ngrok-free.app/upload-audio');

      // Get file extension and determine MIME type
      String ext = extension(audioFile.path).toLowerCase().replaceAll('.', '');
      final mimeType = _getMimeType(ext);

      final request = http.MultipartRequest('POST', uri)
        ..files.add(await http.MultipartFile.fromPath(
          'file',
          audioFile.path,
          filename: basename(audioFile.path),
          contentType: mimeType,
        ));

      final response = await request.send();

      if (response.statusCode == 200) {
        final respStr = await response.stream.bytesToString();
        return respStr;
      } else {
        print('Upload failed with status code: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error during file upload: $e');
      return null;
    }
  }

  static MediaType _getMimeType(String ext) {
    switch (ext) {
      case 'mp3':
        return MediaType('audio', 'mpeg');
      case 'wav':
        return MediaType('audio', 'wav');
      case 'm4a':
        return MediaType('audio', 'm4a');
      default:
        return MediaType('application', 'octet-stream'); // Fallback
    }
  }
}
