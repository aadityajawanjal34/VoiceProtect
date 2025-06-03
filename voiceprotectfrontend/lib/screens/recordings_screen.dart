import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart'; // Import file_picker
import '../services/upload_service.dart';
import '../services/file_loader.dart';
import '../services/menu_actions.dart';
import '../widgets/recording_tile.dart';

class RecordingsScreen extends StatefulWidget {
  const RecordingsScreen({super.key});

  @override
  State<RecordingsScreen> createState() => _RecordingsScreenState();
}

class _RecordingsScreenState extends State<RecordingsScreen> {
  List<File> _recordings = [];
  final AudioPlayer _audioPlayer = AudioPlayer();
  List<File> _selectedRecordings = [];
  File? _currentlyPlaying;
  bool _isLoading = true;
  bool _isUploading = false;
  String? _errorMessage;
  bool _sortByName = true;
  String _searchQuery = '';

  final Color primaryColor = const Color(0xFF7B1FA2);
  final Color lightShade = const Color(0xFFE1BEE7);
  final Color midShade = const Color(0xFF8E24AA);

  @override
  void initState() {
    super.initState();
    _checkPermissionsAndLoadFiles();
  }

  Future<void> _checkPermissionsAndLoadFiles() async {
    try {
      final hasPermission = await RecordingLoader().requestPermissions();
      if (!hasPermission) {
        setState(() {
          _errorMessage = "Storage permission denied!";
          _isLoading = false;
        });
        return;
      }
      await _loadRecordings();
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to load recordings: $e";
        _isLoading = false;
      });
    }
  }

  Future<void> _loadRecordings() async {
    try {
      final audioFiles =
          await RecordingLoader().loadRecordings(sortByName: _sortByName);
      setState(() => _recordings = audioFiles);
    } catch (e) {
      setState(() {
        _errorMessage = "Error accessing recordings: $e";
      });
    }
  }

  void _playRecording(File file) async {
    try {
      if (_currentlyPlaying == file) {
        await _audioPlayer.stop();
        setState(() => _currentlyPlaying = null);
      } else {
        await _audioPlayer.stop();
        await _audioPlayer.play(DeviceFileSource(file.path));
        setState(() => _currentlyPlaying = file);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to play recording: $e")),
      );
    }
  }

  void _deleteSelected() async {
    await MenuActions.deleteSelected(_selectedRecordings, () async {
      _selectedRecordings.clear();
      await _loadRecordings();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Selected recordings deleted")),
      );
    });
  }

  void _shareSelected() {
    MenuActions.shareSelected(_selectedRecordings);
  }

  void _toggleSelection(File file) {
    setState(() {
      _selectedRecordings.contains(file)
          ? _selectedRecordings.remove(file)
          : _selectedRecordings.add(file);
    });
  }

  void _renameSelected() async {
    if (_selectedRecordings.length != 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a single file to rename")),
      );
      return;
    }

    final originalFile = _selectedRecordings.first;
    final currentName = originalFile.path.split('/').last;
    final TextEditingController controller =
        TextEditingController(text: currentName);

    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Rename Recording"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "Enter new file name"),
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text("Rename")),
        ],
      ),
    );

    if (newName != null && newName.trim().isNotEmpty) {
      String sanitizedNewName = newName.trim();

      if (!sanitizedNewName.toLowerCase().endsWith('.m4a')) {
        sanitizedNewName += '.m4a';
      }

      final dir = originalFile.parent;
      final newPath = "${dir.path}/$sanitizedNewName";

      try {
        await originalFile.rename(newPath);
        setState(() {
          _selectedRecordings.clear();
          _currentlyPlaying = null;
        });
        await _loadRecordings();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Recording renamed successfully")),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Rename failed: $e")),
        );
      }
    }
  }

  void _uploadSelected() async {
    if (_selectedRecordings.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Please select at least one recording to upload")),
      );
      return;
    }

    setState(() => _isUploading = true);

    for (File file in _selectedRecordings) {
      final response = await UploadService.uploadAudio(file);
      String name = file.path.split('/').last;

      try {
        if (response != null) {
          final decoded = response is String ? jsonDecode(response) : response;
          final result =
              decoded['final_verdict']?.toString().toUpperCase() ?? 'UNKNOWN';
          final confidence =
              decoded['confidence_score']?.toStringAsFixed(2) ?? 'N/A';

          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text("Prediction for $name"),
              content: Text(
                result == 'REAL' || result == 'DEEPFAKE'
                    ? "Result: $result"
                    : "Invalid result received.",
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("OK"),
                )
              ],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Upload failed for $name")),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error processing response for $name")),
        );
      }
    }

    setState(() {
      _selectedRecordings.clear();
      _isUploading = false;
    });
  }

  // New method to pick and upload a random audio file
  Future<void> _pickAndUploadRandomAudio() async {
    try {
      setState(() => _isUploading = true); // 🔥 Start loading

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
      );

      if (result != null) {
        File file = File(result.files.single.path!);

        final response = await UploadService.uploadAudio(file);
        String name = file.path.split('/').last;

        if (response != null) {
          final decoded = response is String ? jsonDecode(response) : response;
          final result =
              decoded['final_verdict']?.toString().toUpperCase() ?? 'UNKNOWN';
          final confidence =
              decoded['confidence_score']?.toStringAsFixed(2) ?? 'N/A';

          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text("Prediction for $name"),
              content: Text(
                result == 'REAL' || result == 'DEEPFAKE'
                    ? "Result: $result"
                    : "Invalid result received.",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("OK"),
                )
              ],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Upload failed for $name")),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No file selected")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error selecting or uploading file: $e")),
      );
    } finally {
      setState(() => _isUploading = false); // ✅ End loading
    }
  }


  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  List<File> _getFilteredRecordings() {
    if (_searchQuery.isEmpty) {
      return _recordings;
    }
    return _recordings
        .where((file) => file.path
            .split('/')
            .last
            .toLowerCase()
            .contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: const Color(0xFF010914), // Dark background
    appBar: AppBar(
      title: const Text('Call Recordings'),
      backgroundColor: const Color(0xFF010914), // Match splash theme
      foregroundColor: Colors.white, // White text/icons
      actions: [
        IconButton(
          icon: const Icon(Icons.sort_by_alpha, color: Colors.white),
          onPressed: () {
            setState(() => _sortByName = !_sortByName);
            _loadRecordings();
          },
          tooltip: _sortByName ? 'Sort by date' : 'Sort by name',
        ),
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: () {
            setState(() {
              _isLoading = true;
              _selectedRecordings.clear();
              _errorMessage = null;
            });
            _checkPermissionsAndLoadFiles();
          },
        ),
        IconButton(
          icon: const Icon(Icons.upload_file, color: Colors.white),
          onPressed: _pickAndUploadRandomAudio,
          tooltip: 'Upload a random audio file',
        ),
      ],
    ),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search, color: Colors.white70),
              hintText: 'Search recordings...',
              hintStyle: const TextStyle(color: Colors.white54),
              filled: true,
              fillColor: const Color(0xFF1A1F2C),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (query) {
              setState(() {
                _searchQuery = query;
              });
            },
          ),
        ),
        Expanded(
  child: (_isLoading || _isUploading)
      ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Colors.white),
              const SizedBox(height: 16),
              const Text(
                "Please wait, your audio is processing...",
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ],
          ),
        )
      : _errorMessage != null
          ? Center(
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.white70),
              ),
            )
          : _getFilteredRecordings().isEmpty
              ? const Center(
                  child: Text(
                    "No recordings found.",
                    style: TextStyle(color: Colors.white60),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  itemCount: _getFilteredRecordings().length,
                  itemBuilder: (context, index) {
                    final file = _getFilteredRecordings()[index];
                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                      color: _selectedRecordings.contains(file)
                          ? const Color(0xFF283046)
                          : const Color(0xFF1A1F2C),
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFF5D6D91),
                          child: Icon(Icons.audiotrack, color: Colors.white),
                        ),
                        title: Text(
                          file.path.split('/').last,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        subtitle: Text(
                          _currentlyPlaying == file ? 'Playing...' : 'Tap to play',
                          style: const TextStyle(color: Colors.white54),
                        ),
                        trailing: Icon(
                          _currentlyPlaying == file ? Icons.stop : Icons.play_arrow,
                          color: Colors.white,
                        ),
                        onTap: () => _playRecording(file),
                        onLongPress: () => _toggleSelection(file),
                      ),
                    );
                  },
                ),
        ),

      ],
    ),
    floatingActionButton: _selectedRecordings.isNotEmpty
        ? FloatingActionButton.extended(
            onPressed: _uploadSelected,
            icon: const Icon(Icons.cloud_upload),
            label: const Text("Analyze"),
            backgroundColor: const Color(0xFF102040),
            foregroundColor: Colors.white,
          )
        : null,
    bottomNavigationBar: _selectedRecordings.isNotEmpty
        ? BottomAppBar(
            color: const Color(0xFF1A1F2C),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: _deleteSelected,
                  tooltip: 'Delete selected',
                ),
                IconButton(
                  icon: const Icon(Icons.share, color: Colors.lightBlueAccent),
                  onPressed: _shareSelected,
                  tooltip: 'Share selected',
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.orangeAccent),
                  onPressed: _renameSelected,
                  tooltip: 'Rename selected',
                ),
              ],
            ),
          )
        : null,
  );
}

}
