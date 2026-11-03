
import 'package:Koottaayma/HTTPURL/httpurl.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

class BetseidhaMediaUploadSelector extends StatefulWidget {
  const BetseidhaMediaUploadSelector({Key? key}) : super(key: key);

  @override
  State<BetseidhaMediaUploadSelector> createState() => _BetseidhaMediaUploadSelectorState();
}

class _BetseidhaMediaUploadSelectorState extends State<BetseidhaMediaUploadSelector> {
  String? _uploadedFileName;
  String? _uploadedFileSize;
  String? _uploadedFileType;
  File? _selectedFile;
  String? _textContent;
  bool _isUploading = false;

  final ImagePicker _imagePicker = ImagePicker();
  
  // API endpoint
  final String _apiUrl = BetseidhaPriestMediaSend;

  final List<Map<String, dynamic>> _mediaTypes = [
    {
      'id': 'image',
      'label': 'Image',
      'icon': Icons.image,
      'color': Colors.blue,
    },
    {
      'id': 'voice',
      'label': 'Voice',
      'icon': Icons.mic,
      'color': Colors.red,
    },
    {
      'id': 'audio',
      'label': 'Audio',
      'icon': Icons.music_note,
      'color': Colors.purple,
    },
    {
      'id': 'video',
      'label': 'Video',
      'icon': Icons.videocam,
      'color': Colors.green,
    },
    {
      'id': 'text',
      'label': 'Text',
      'icon': Icons.description,
      'color': Colors.orange,
    },
    {
      'id': 'file',
      'label': 'File',
      'icon': Icons.attach_file,
      'color': Colors.grey,
    },
  ];

 Future<void> _uploadFile() async {
    if (_selectedFile == null && _textContent == null) {
      _showSnackBar('No file selected', Colors.red);
      return;
    }

    setState(() => _isUploading = true);

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? savedToken = prefs.getString('jwt');
      
      var request = http.MultipartRequest('POST', Uri.parse(_apiUrl));

      // Add headers to the request
      request.headers['Authorization'] = '$savedToken';
     

      // Determine the field name based on file type
      String fieldName = _getFieldName(_uploadedFileType ?? '');

      if (_selectedFile != null) {
        // Upload file
        request.files.add(
          await http.MultipartFile.fromPath(
            fieldName,
            _selectedFile!.path,
            filename: _uploadedFileName,
          ),
        );
      } else if (_textContent != null) {
        // Upload text content
        request.fields[fieldName] = _textContent!;
      }

      // Add any additional fields if needed
      // request.fields['userId'] = 'your_user_id';
     request.fields['dDate'] = DateTime.now().toIso8601String();

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSnackBar('Upload successful!', Colors.green);
        _clearSelection();
      }
       else if(response.statusCode==409){
         _showSnackBar('Please contact your church!', Colors.red);
        _clearSelection(); 
      }
       else {
        _showSnackBar('Upload failed', Colors.red);
        print('Response body: $responseBody');
      }
    } catch (e) {
      _showSnackBar('Error uploading: $e', Colors.red);
      print('Upload error: $e');
    } finally {
      setState(() => _isUploading = false);
    }
  }

  String _getFieldName(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'image':
        return 'cUploadedPathImage';
      case 'voice':
        return 'cUploadedPathVoice';
      case 'audio':
        return 'cUploadedPathAudio';
      case 'video':
        return 'cUploadedPathVideo';
      case 'text':
        return 'cUploadedPathText';
      case 'file':
        return 'cUploadedPathFile';
      default:
        return 'cUploadedPathFile';
    }
  }

  void _clearSelection() {
    setState(() {
      _uploadedFileName = null;
      _uploadedFileSize = null;
      _uploadedFileType = null;
      _selectedFile = null;
      _textContent = null;
    });
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleMediaTypeSelection(String type) {
    switch (type) {
      case 'image':
        _showImageSourceDialog();
        break;
      case 'voice':
        _showVoiceRecorder();
        break;
      case 'text':
        _showTextEditor();
        break;
      case 'audio':
        _pickAudioFile();
        break;
      case 'video':
        _pickVideoFile();
        break;
      case 'file':
        _pickAnyFile();
        break;
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.blue),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.green),
                title: const Text('Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(source: source);
      if (image != null) {
        final file = File(image.path);
        final fileSize = await file.length();
        setState(() {
          _selectedFile = file;
          _uploadedFileName = image.name;
          _uploadedFileSize = _formatFileSize(fileSize);
          _uploadedFileType = 'Image';
        });
      }
    } catch (e) {
      print('Error picking image: $e');
      _showSnackBar('Error picking image', Colors.red);
    }
  }

  void _showVoiceRecorder() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => VoiceRecorderDialog(
        onRecordingComplete: (String path, int duration) {
          final file = File(path);
          setState(() {
            _selectedFile = file;
            _uploadedFileName = 'voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
            _uploadedFileSize = '${duration}s';
            _uploadedFileType = 'Voice';
          });
        },
      ),
    );
  }

  void _showTextEditor() {
    showDialog(
      context: context,
      builder: (context) => TextEditorDialog(
        onTextComplete: (String text) {
          setState(() {
            _textContent = text;
            _uploadedFileName = 'message_${DateTime.now().millisecondsSinceEpoch}.txt';
            _uploadedFileSize = _formatFileSize(text.length);
            _uploadedFileType = 'Text';
          });
        },
      ),
    );
  }

  Future<void> _pickAudioFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
      );
      if (result != null) {
        final file = File(result.files.single.path!);
        setState(() {
          _selectedFile = file;
          _uploadedFileName = result.files.single.name;
          _uploadedFileSize = _formatFileSize(result.files.single.size);
          _uploadedFileType = 'Audio';
        });
      }
    } catch (e) {
      print('Error picking audio: $e');
      _showSnackBar('Error picking audio', Colors.red);
    }
  }

  Future<void> _pickVideoFile() async {
    try {
      final XFile? video = await _imagePicker.pickVideo(source: ImageSource.gallery);
      if (video != null) {
        final file = File(video.path);
        final fileSize = await file.length();
        setState(() {
          _selectedFile = file;
          _uploadedFileName = video.name;
          _uploadedFileSize = _formatFileSize(fileSize);
          _uploadedFileType = 'Video';
        });
      }
    } catch (e) {
      print('Error picking video: $e');
      _showSnackBar('Error picking video', Colors.red);
    }
  }

  Future<void> _pickAnyFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();
      if (result != null) {
        final file = File(result.files.single.path!);
        setState(() {
          _selectedFile = file;
          _uploadedFileName = result.files.single.name;
          _uploadedFileSize = _formatFileSize(result.files.single.size);
          _uploadedFileType = 'File';
        });
      }
    } catch (e) {
      print('Error picking file: $e');
      _showSnackBar('Error picking file', Colors.red);
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.cyan, const Color.fromARGB(255, 202, 236, 241), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            margin: const EdgeInsets.all(16),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select Media Type',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 20),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1,
                      ),
                      itemCount: _mediaTypes.length,
                      itemBuilder: (context, index) {
                        final type = _mediaTypes[index];
                        return _MediaTypeButton(
                          label: type['label'],
                          icon: type['icon'],
                          color: type['color'],
                          onTap: () => _handleMediaTypeSelection(type['id']),
                        );
                      },
                    ),
                    if (_uploadedFileName != null) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _uploadedFileName!,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black87,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$_uploadedFileType • $_uploadedFileSize',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 20),
                              color: Colors.grey[600],
                              onPressed: _clearSelection,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isUploading ? null : _uploadFile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isUploading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Send',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MediaTypeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _MediaTypeButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Voice Recorder Dialog
class VoiceRecorderDialog extends StatefulWidget {
  final Function(String path, int duration) onRecordingComplete;

  const VoiceRecorderDialog({Key? key, required this.onRecordingComplete})
      : super(key: key);

  @override
  State<VoiceRecorderDialog> createState() => _VoiceRecorderDialogState();
}

class _VoiceRecorderDialogState extends State<VoiceRecorderDialog> {
  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  int _recordDuration = 0;
  Timer? _timer;
  String? _audioPath;

  @override
  void dispose() {
    _timer?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      final status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Microphone permission denied')),
          );
        }
        return;
      }

      if (await _recorder.hasPermission()) {
        final directory = await getTemporaryDirectory();
        final path = '${directory.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
        
        await _recorder.start(const RecordConfig(), path: path);
        setState(() {
          _isRecording = true;
          _audioPath = path;
        });
        _startTimer();
      }
    } catch (e) {
      print('Error starting recording: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Recording error: $e')),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    try {
      await _recorder.stop();
      _timer?.cancel();
      setState(() => _isRecording = false);
    } catch (e) {
      print('Error stopping recording: $e');
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _recordDuration++);
    });
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Record Voice',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: _isRecording ? Colors.red : Colors.blue,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isRecording ? Icons.stop : Icons.mic,
                color: Colors.white,
                size: 50,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _formatDuration(_recordDuration),
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () {
                    if (_isRecording) _stopRecording();
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (_isRecording) {
                      await _stopRecording();
                      if (_audioPath != null) {
                        widget.onRecordingComplete(_audioPath!, _recordDuration);
                        Navigator.pop(context);
                      }
                    } else {
                      await _startRecording();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isRecording ? Colors.red : Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(_isRecording ? 'Stop' : 'Record'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Text Editor Dialog
class TextEditorDialog extends StatefulWidget {
  final Function(String text) onTextComplete;

  const TextEditorDialog({Key? key, required this.onTextComplete})
      : super(key: key);

  @override
  State<TextEditorDialog> createState() => _TextEditorDialogState();
}

class _TextEditorDialogState extends State<TextEditorDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Type Your Message',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              maxLines: 6,
              decoration: InputDecoration(
                hintText: 'Enter your text here...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    if (_controller.text.isNotEmpty) {
                      widget.onTextComplete(_controller.text);
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Done'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}                                                                                                                                  