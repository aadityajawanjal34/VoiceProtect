import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RecordingTile extends StatelessWidget {
  final File file;
  final bool isSelected;
  final bool isPlaying;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const RecordingTile({
    super.key,
    required this.file,
    required this.isSelected,
    required this.isPlaying,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final fileName = file.path.split('/').last;
    final modifiedDate = file.lastModifiedSync();

    return ListTile(
      title: Text(fileName),
      subtitle: Text(
        'Modified: ' + DateFormat.yMMMd().add_jm().format(modifiedDate),
      ),
      trailing: Icon(
        isPlaying ? Icons.stop : Icons.play_arrow,
        color: Colors.blue,
      ),
      selected: isSelected,
      selectedTileColor: Colors.blue.shade50,
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }
}
