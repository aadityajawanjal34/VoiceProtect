import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class MenuActions {
  static Future<void> deleteSelected(
      List<File> selectedRecordings, VoidCallback onDeleted) async {
    for (var file in selectedRecordings) {
      if (await file.exists()) {
        await file.delete();
      }
    }
    onDeleted();
  }

  static void shareSelected(List<File> selectedRecordings) {
    if (selectedRecordings.isEmpty) return;
    Share.shareXFiles(
      selectedRecordings.map((f) => XFile(f.path)).toList(),
      text: 'Sharing selected call recordings',
    );
  }
}
