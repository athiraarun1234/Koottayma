import 'dart:convert';
import 'dart:io';

import 'package:Koottaayma/HTTPURL/httpurl.dart';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Upload mode
enum _UploadMode { funeral, seventhDay }

// ── Models
class Church {
  final int id;
  final String name;
  Church({required this.id, required this.name});
  factory Church.fromJson(Map<String, dynamic> json) =>
      Church(id: json['nChurchID'], name: json['cChurchName']);
}

// ── Per-service data holder
class _ServiceEntry {
  Church? selectedChurch;
  DateTime? date;
  TimeOfDay? time;

  bool get isComplete =>
      selectedChurch != null && date != null && time != null;

  String get formattedDateTime {
    if (date == null || time == null) return '';
    final dt = DateTime(
        date!.year, date!.month, date!.day, time!.hour, time!.minute);
    return DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(dt);
  }
}

// ── Widget
class Obituaryimageuploading extends StatefulWidget {
  final String nFamilyMemberID;
  final String nFamilyMasterID;

  const Obituaryimageuploading({
    Key? key,
    required this.nFamilyMemberID,
    required this.nFamilyMasterID,
  }) : super(key: key);

  @override
  State<Obituaryimageuploading> createState() => _ObituaryimageuploadingState();
}

class _ObituaryimageuploadingState extends State<Obituaryimageuploading> {
  // ── Dropdown data
  List<Church> _churches = [];
  bool _isLoading = true;

  // ── Upload mode
  _UploadMode _uploadMode = _UploadMode.funeral;

  // ── Seventh Day: death notification ID
  String? _deathNotificationID;
  bool _isFetchingNotificationID = false;
  String? _notificationFetchError;

  // ── Image (Funeral only)
  String? _uploadedFileName;
  String? _uploadedFileSize;
  File? _selectedFile;
  bool _isUploading = false;
  final ImagePicker _imagePicker = ImagePicker();

  // ── index 0 = Funeral, index 1 = Seventh Day
  final List<_ServiceEntry> _services = [_ServiceEntry(), _ServiceEntry()];

  static const _serviceLabels = ['Funeral Service', 'Seventh Day Service'];
  static const _serviceIcons = [Icons.local_florist, Icons.event];
  static const _serviceCategoryIDs = [1, 2];

  

  @override
  void initState() {
    super.initState();
    _fetchDropdownData();
  }

 

  Future<void> _fetchDropdownData() async {
    try {
      final response = await http.get(Uri.parse(GuestDropdownSelection));
      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = jsonDecode(response.body);
        final churches = (decoded['ChurchDetails'] as List)
            .map((e) => Church.fromJson(e))
            .toList();
        setState(() {
          _churches = churches;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error fetching dropdown data: $e');
      setState(() => _isLoading = false);
    }
  }



  Future<void> _fetchDeathNotificationID() async {
    setState(() {
      _isFetchingNotificationID = true;
      _notificationFetchError = null;
      _deathNotificationID = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString('jwt');

      // Pass nDemiseMemberID as a query param so the API knows which record
      final uri = Uri.parse(
        'https://lv4hfxvb-7000.inc1.devtunnels.ms/notifications/getdeathnotificationid/',
      ).replace(queryParameters: {
        'nDeathNotificationID': widget.nFamilyMemberID,
      });

      final response = await http.get(
        uri,
        headers: {
          'Authorization': '$savedToken',
          'Content-Type': 'application/json',
        },
      );

      debugPrint('GET DeathNotificationID status : ${response.statusCode}');
      debugPrint('GET DeathNotificationID body   : ${response.body}');

     if (response.statusCode == 200 || response.statusCode == 201) {
  final decoded = jsonDecode(response.body);

  // ── Response is a List: [{"nDeathNotificationID":1}, ...]
  if (decoded is List && decoded.isNotEmpty) {
    final id = decoded.first['nDeathNotificationID'];
    if (id != null) {
      setState(() => _deathNotificationID = id.toString());
    } else {
      setState(() => _notificationFetchError = 'Notification ID not found.');
    }
  } else {
    setState(() => _notificationFetchError = 'No notification record found.');
  }
} else {
        setState(() => _notificationFetchError =
            'Failed to fetch notification ID (${response.statusCode})');
      }
    } catch (e) {
      debugPrint('Error fetching notification ID: $e');
      setState(() =>
          _notificationFetchError = 'Network error. Please try again.');
    } finally {
      setState(() => _isFetchingNotificationID = false);
    }
  }



  Future<void> _pickDate(int serviceIndex) async {
    final entry = _services[serviceIndex];
    final picked = await showDatePicker(
      context: context,
      initialDate: entry.date ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Colors.blue)),
        child: child!,
      ),
    );
    if (picked != null) setState(() => entry.date = picked);
  }

  Future<void> _pickTime(int serviceIndex) async {
    final entry = _services[serviceIndex];
    final picked = await showTimePicker(
      context: context,
      initialTime: entry.time ?? TimeOfDay.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Colors.blue)),
        child: child!,
      ),
    );
    if (picked != null) setState(() => entry.time = picked);
  }

 

  Future<void> _uploadFuneral() async {
    if (_selectedFile == null) {
      _showSnackBar('Please select an image', Colors.red);
      return;
    }

    final entry = _services[0];
    if (!entry.isComplete) {
      _showSnackBar('Please complete funeral service details', Colors.red);
      return;
    }

    setState(() => _isUploading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString('jwt');

      final request = http.MultipartRequest(
          'POST', Uri.parse(UploadObituaryImage));
      request.headers['Authorization'] = '$savedToken';

      request.files.add(await http.MultipartFile.fromPath(
        'cUploadedPathText',
        _selectedFile!.path,
        filename: _uploadedFileName,
      ));

      request.fields['dDemiseDate'] =
          DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(DateTime.now());
      request.fields['nDemiseMemberID'] = widget.nFamilyMemberID;
      request.fields['nFamilyMasterID'] = widget.nFamilyMasterID;
      request.fields['nServiceCategoryID'] =
          _serviceCategoryIDs[0].toString(); // 1
      request.fields['nChurchMasterID'] =
          entry.selectedChurch!.id.toString();
      request.fields['dDoFuneral'] = entry.formattedDateTime;
      request.fields['dDoService'] = ''; // filled later via Seventh Day
      request.fields['nOtherChurchID'] = ''; // filled later via Seventh Day

      debugPrint('── Funeral POST ──');
      debugPrint('nServiceCategoryID : 1');
      debugPrint('nChurchMasterID    : ${entry.selectedChurch!.id}');
      debugPrint('dDoFuneral         : ${entry.formattedDateTime}');
      debugPrint('nDemiseMemberID    : ${widget.nFamilyMemberID}');
      debugPrint('nFamilyMasterID    : ${widget.nFamilyMasterID}');

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      debugPrint('Funeral Response: $responseBody');

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSnackBar('Upload successful!', Colors.green);
        _clearSelection();
      } else if (response.statusCode == 409) {
        _showSnackBar('Please contact your church!', Colors.red);
        _clearSelection();
      } else {
        _showSnackBar(
            'Upload failed (${response.statusCode})', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Error uploading: $e', Colors.red);
      debugPrint('Funeral upload error: $e');
    } finally {
      setState(() => _isUploading = false);
    }
  }



  Future<void> _uploadSeventhDay() async {
    final entry = _services[1];

    if (_deathNotificationID == null) {
      _showSnackBar('Notification ID not loaded. Please retry.', Colors.red);
      return;
    }
    if (!entry.isComplete) {
      _showSnackBar(
          'Please complete Seventh Day service details', Colors.red);
      return;
    }

    setState(() => _isUploading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString('jwt');

      final url = Uri.parse(
        'https://lv4hfxvb-7000.inc1.devtunnels.ms/notifications/adddailyNotifications/',
      );

      final body = jsonEncode({
        'nDeathNotificationID': _deathNotificationID,
        'dDoService': entry.formattedDateTime,
        'nOtherChurchID': entry.selectedChurch!.id.toString(),
      });

      debugPrint('── Seventh Day PUT ──');
      debugPrint('URL               : $url');
      debugPrint('nDeathNotificationID : $_deathNotificationID');
      debugPrint('dDoService           : ${entry.formattedDateTime}');
      debugPrint('nOtherChurchID       : ${entry.selectedChurch!.id}');

      final response = await http.put(
        url,
        headers: {
          'Authorization': '$savedToken',
          'Content-Type': 'application/json',
        },
        body: body,
      );

      debugPrint(
          'Seventh Day Response (${response.statusCode}): ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSnackBar('Seventh Day service updated!', Colors.green);
        _clearSelection();
      } else if (response.statusCode == 409) {
        _showSnackBar('Please contact your church!', Colors.red);
        _clearSelection();
      } else {
        _showSnackBar(
            'Update failed (${response.statusCode})', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Error updating: $e', Colors.red);
      debugPrint('Seventh Day update error: $e');
    } finally {
      setState(() => _isUploading = false);
    }
  }

  

  Future<void> _onSend() async {
    if (_uploadMode == _UploadMode.funeral) {
      await _uploadFuneral();
    } else {
      await _uploadSeventhDay();
    }
  }


  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: SafeArea(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.blue),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.photo_library, color: Colors.green),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ]),
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
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  

  void _clearSelection() {
    setState(() {
      _uploadedFileName = null;
      _uploadedFileSize = null;
      _selectedFile = null;
      for (final s in _services) {
        s.selectedChurch = null;
        s.date = null;
        s.time = null;
      }
    });
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
    ));
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024)
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  bool get _canSend {
    if (_isUploading) return false;
    if (_uploadMode == _UploadMode.funeral) {
      return _selectedFile != null && _services[0].isComplete;
    } else {
      return _deathNotificationID != null && _services[1].isComplete;
    }
  }

 

  Widget _fieldLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black54)),
      );

  Widget _pickerTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isSelected = false,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding:
              const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          decoration: BoxDecoration(
            border: Border.all(
                color: isSelected ? Colors.blue : Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey[50],
          ),
          child: Row(children: [
            Icon(icon, color: Colors.blue, size: 16),
            const SizedBox(width: 6),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 12,
                      color: isSelected
                          ? Colors.black87
                          : Colors.grey[400])),
            ),
          ]),
        ),
      );



  Widget _buildModeToggle() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(children: [
        _modeTab(
          label: 'Funeral Service',
          icon: Icons.local_florist,
          isActive: _uploadMode == _UploadMode.funeral,
          onTap: () {
            if (_uploadMode == _UploadMode.funeral) return;
            setState(() {
              _uploadMode = _UploadMode.funeral;
              _clearSelection();
            });
          },
        ),
        _modeTab(
          label: 'Seventh Day',
          icon: Icons.event,
          isActive: _uploadMode == _UploadMode.seventhDay,
          onTap: () {
            if (_uploadMode == _UploadMode.seventhDay) return;
            setState(() {
              _uploadMode = _UploadMode.seventhDay;
              _clearSelection();
            });
            // Auto-fetch notification ID when tab is selected
            _fetchDeathNotificationID();
          },
        ),
      ]),
    );
  }

  Widget _modeTab({
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) =>
      Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: isActive ? Colors.blue : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon,
                    size: 15,
                    color: isActive ? Colors.white : Colors.grey[500]),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(label,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isActive
                              ? Colors.white
                              : Colors.grey[500]),
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),
        ),
      );



  Widget _buildNotificationIDStatus() {
    if (_isFetchingNotificationID) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding:
            const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue.withOpacity(0.2)),
        ),
        child: const Row(children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: Colors.blue),
          ),
          SizedBox(width: 10),
          Text('Fetching notification record…',
              style: TextStyle(fontSize: 12, color: Colors.blue)),
        ]),
      );
    }

    if (_notificationFetchError != null) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding:
            const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red.withOpacity(0.25)),
        ),
        child: Row(children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 16),
          const SizedBox(width: 8),
          Expanded(
              child: Text(_notificationFetchError!,
                  style: const TextStyle(
                      fontSize: 12, color: Colors.red))),
          TextButton(
            onPressed: _fetchDeathNotificationID,
            style:
                TextButton.styleFrom(minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
            child: const Text('Retry',
                style: TextStyle(fontSize: 12, color: Colors.red)),
          ),
        ]),
      );
    }

    // if (_deathNotificationID != null) {
    //   return Container(
    //     margin: const EdgeInsets.only(bottom: 16),
    //     padding:
    //         const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
    //     decoration: BoxDecoration(
    //       color: Colors.green.withOpacity(0.06),
    //       borderRadius: BorderRadius.circular(8),
    //       border: Border.all(color: Colors.green.withOpacity(0.3)),
    //     ),
    //     child: Row(children: [
    //       const Icon(Icons.verified, color: Colors.green, size: 16),
    //       const SizedBox(width: 8),
    //       Text(
    //         'Record found  •  ID: $_deathNotificationID',
    //         style: const TextStyle(
    //             fontSize: 12,
    //             color: Colors.green,
    //             fontWeight: FontWeight.w600),
    //       ),
    //     ]),
    //   );
    // }

    return const SizedBox.shrink();
  }



  Widget _buildServiceCard(int index) {
    final entry = _services[index];
    final label = _serviceLabels[index];
    final icon = _serviceIcons[index];

    final dateLabel = entry.date != null
        ? DateFormat('dd MMM yyyy').format(entry.date!)
        : 'Select Date';
    final timeLabel = entry.time != null
        ? entry.time!.format(context)
        : 'Select Time';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 18, color: Colors.blue),
          const SizedBox(width: 8),
          Text(label,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.blue)),
        ]),
        const SizedBox(height: 12),
        _fieldLabel('Church'),
        _isLoading
            ? const LinearProgressIndicator()
            : DropdownButtonFormField<Church>(
                value: entry.selectedChurch,
                isExpanded: true,
                hint: Text('Select Church',
                    style: TextStyle(
                        color: Colors.grey[400], fontSize: 13)),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.church,
                      color: Colors.blue, size: 20),
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: 4, horizontal: 12),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          BorderSide(color: Colors.grey[300]!)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          BorderSide(color: Colors.grey[300]!)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: Colors.blue)),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                items: _churches
                    .map((c) => DropdownMenuItem<Church>(
                          value: c,
                          child: Text(c.name,
                              style:
                                  const TextStyle(fontSize: 13)),
                        ))
                    .toList(),
                onChanged: (val) =>
                    setState(() => entry.selectedChurch = val),
              ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _fieldLabel('Date'),
                  _pickerTile(
                    icon: Icons.calendar_today,
                    label: dateLabel,
                    onTap: () => _pickDate(index),
                    isSelected: entry.date != null,
                  ),
                ]),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _fieldLabel('Time'),
                  _pickerTile(
                    icon: Icons.access_time,
                    label: timeLabel,
                    onTap: () => _pickTime(index),
                    isSelected: entry.time != null,
                  ),
                ]),
          ),
        ]),
        if (entry.isComplete) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(
                vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              border:
                  Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Row(children: [
              const Icon(Icons.check_circle,
                  color: Colors.blue, size: 16),
              const SizedBox(width: 6),
              Text(
                '${DateFormat('dd MMM yyyy').format(entry.date!)}  •  ${entry.time!.format(context)}',
                style: const TextStyle(
                    fontSize: 12,
                    color: Colors.blue,
                    fontWeight: FontWeight.w600),
              ),
            ]),
          ),
        ],
      ]),
    );
  }

 

  Widget _buildImageSection() => Column(children: [
        GestureDetector(
          onTap: _showImageSourceDialog,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32),
            decoration: BoxDecoration(
              border:
                  Border.all(color: Colors.grey[300]!, width: 2),
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[50],
            ),
            child: Column(children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                    color: Colors.blue, shape: BoxShape.circle),
                child: const Icon(Icons.image,
                    color: Colors.white, size: 32),
              ),
              const SizedBox(height: 12),
              const Text('Tap to select image',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black54)),
            ]),
          ),
        ),
        if (_selectedFile != null) ...[
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(_selectedFile!,
                width: double.infinity,
                height: 180,
                fit: BoxFit.cover),
          ),
        ],
        if (_uploadedFileName != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(children: [
              const Icon(Icons.image, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_uploadedFileName!,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      Text(_uploadedFileSize ?? '',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey[600])),
                    ]),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                color: Colors.grey[600],
                onPressed: _clearSelection,
              ),
            ]),
          ),
        ],
      ]);

  

  Widget _buildSendButton() => SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _canSend ? _onSend : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.blue.withOpacity(0.4),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
          child: _isUploading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
              : const Text('Send',
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600)),
        ),
      );

 

  @override
  Widget build(BuildContext context) {
    final isFuneral = _uploadMode == _UploadMode.funeral;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.cyan,
              Color.fromARGB(255, 202, 236, 241),
              Colors.white,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      const Text('Upload Obituary',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87)),
                      const Divider(height: 24),

                      // Mode toggle
                      _buildModeToggle(),
                      const SizedBox(height: 16),

                      // Hint banner
                      Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          color: isFuneral
                              ? Colors.orange.withOpacity(0.08)
                              : Colors.green.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: isFuneral
                                  ? Colors.orange.withOpacity(0.3)
                                  : Colors.green.withOpacity(0.3)),
                        ),
                        child: Row(children: [
                          Icon(
                            isFuneral
                                ? Icons.info_outline
                                : Icons.check_circle_outline,
                            size: 15,
                            color: isFuneral
                                ? Colors.orange
                                : Colors.green,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              isFuneral
                                  ? 'Upload obituary image with funeral details. Seventh Day can be added later.'
                                  : 'Add Seventh Day service details only. No image required.',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: isFuneral
                                      ? Colors.orange[800]
                                      : Colors.green[800]),
                            ),
                          ),
                        ]),
                      ),
                      const SizedBox(height: 16),

                      // Seventh Day: show notification ID fetch status
                      if (!isFuneral) _buildNotificationIDStatus(),

                      // Relevant service card only
                      _buildServiceCard(isFuneral ? 0 : 1),

                      // Image section — Funeral only
                      if (isFuneral) ...[
                        _buildImageSection(),
                        const SizedBox(height: 16),
                      ],

                      // Send
                      _buildSendButton(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}