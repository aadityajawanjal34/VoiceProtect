import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class RecordingLoader {
  final String recordingsPath = "/storage/emulated/0/Recordings/Call/";

  Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      if (await Permission.manageExternalStorage.request().isGranted) {
        return true;
      }
      final status = await Permission.storage.request();
      return status.isGranted;
    }
    return false;
  }

  Future<List<File>> loadRecordings({bool sortByName = true}) async {
    Directory dir = Directory(recordingsPath);
    if (await dir.exists()) {
      List<FileSystemEntity> files = await dir.list().toList();
      List<File> audioFiles = files.whereType<File>().where((file) {
        final path = file.path.toLowerCase();
        return path.endsWith('.mp3') ||
            path.endsWith('.wav') ||
            path.endsWith('.m4a') ||
            path.endsWith('.aac') ||
            path.endsWith('.ogg');
      }).toList();

      if (sortByName) {
        audioFiles.sort((a, b) => a.path.compareTo(b.path));
      } else {
        audioFiles.sort((a, b) =>
            b.lastModifiedSync().compareTo(a.lastModifiedSync()));
      }

      return audioFiles;
    } else {
      throw FileSystemException("Directory not found", recordingsPath);
    }
  }
}
