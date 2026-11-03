import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BetseidhaPriestBaptismApproval extends StatefulWidget {
  final Map<String, dynamic> baptismData;

  const BetseidhaPriestBaptismApproval({
    Key? key,
    required this.baptismData,
  }) : super(key: key);

  @override
  State<BetseidhaPriestBaptismApproval> createState() => _BetseidhaPriestBaptismApprovalState();
}

class _BetseidhaPriestBaptismApprovalState extends State<BetseidhaPriestBaptismApproval> {
  String? _approvalStatus;
  String? _disapprovalReason;
  final TextEditingController _reasonController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }
  //date format is 12-feb-2003 format
 String formatDob(String? dob) {
  if (dob == null || dob.isEmpty) return 'N/A';

  try {
    
    DateTime date = DateTime.parse(dob);
    return DateFormat('dd-MMM-yyyy').format(date); 
  } catch (e) {
    return dob; 
  }
}
  void _showDisapprovalDialog(int nBaptismRequestID) {
    _reasonController.clear();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Reject Guest Request',
          style: GoogleFonts.roboto(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Please provide a reason for rejecting this request:',
              style: GoogleFonts.roboto(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _reasonController,
              maxLines: 4,
              maxLength: 500,
              decoration: InputDecoration(
                hintText: 'Enter reason here...',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.red, width: 2),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.roboto(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final reason = _reasonController.text.trim();

              if (reason.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Please provide a reason'),
                    backgroundColor: Colors.orange,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }

              Navigator.pop(context);
              
              setState(() => _isLoading = true);
              
              try {
                await rejectRequest(reason, nBaptismRequestID);

                setState(() {
                  _approvalStatus = 'disapproved';
                  _disapprovalReason = reason;
                  _isLoading = false;
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Guest request rejected'),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } catch (e) {
                setState(() => _isLoading = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: ${e.toString()}'),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }


  Future<void> approveRequest(int nGuestID) async {
    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString('jwt');

    if (savedToken == null || savedToken.isEmpty) {
      throw Exception("Token not found. Please login again.");
    }

    final url = Uri.parse(
        "https://lv4hfxvb-7000.inc1.devtunnels.ms/churchdetails/approvalasmember/$nGuestID/");
    
    final response = await http.put(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": savedToken,
      },
      body: json.encode({
        //'jwt': savedToken,
      }),
    );

    print("Approval - Response Code: ${response.statusCode}");
    print("Approval - Response Body: ${response.body}");

    if (response.statusCode != 201) {
      throw Exception("Failed to approve request");
    }
  }

  Future<void> rejectRequest(String cReason, int nGuestID) async {
    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString('jwt');

    if (savedToken == null || savedToken.isEmpty) {
      throw Exception("Token not found. Please login again.");
    }

    final url = Uri.parse('https://lv4hfxvb-7000.inc1.devtunnels.ms/guestdetails/rejectingguestbetseidha/');

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": savedToken,
      },
      body: json.encode({
        'jwt': savedToken,
        'cReason': cReason,
        'nGuestID': nGuestID,
      }),
    );

    print("Rejection - Response Code: ${response.statusCode}");
    print("Rejection - Response Body: ${response.body}");

    if (response.statusCode != 201) {
      throw Exception("Failed to reject request");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.cyan,
        elevation: 0,
        title: Text(
          'Guest Details',
          style: GoogleFonts.roboto(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildInfoCard(),
                  const SizedBox(height: 16),
                  if (_approvalStatus != null) _buildStatusCard(),
                  if (_approvalStatus == null) ...[
                    const SizedBox(height: 10),
                    _buildActionButtons(),
                  ],
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

Widget _buildInfoCard() {
  String getGender(dynamic id) {
    if (id == 1) return "Male";
    if (id == 2) return "Female";
    return "N/A";
  }

  return Container(
    width: double.infinity,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.shade300,
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Applicant Information',
            style: GoogleFonts.roboto(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.cyan.shade700,
            ),
          ),
          const SizedBox(height: 20),
          
          // Profile Picture Section
          Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.cyan.shade700,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade400,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipOval(
                child: _buildProfileImage(),
              ),
            ),
          ),
          const SizedBox(height: 20),

          _buildInfoRow('Full Name', widget.baptismData['cMemberName'] ?? 'N/A'),
          _buildInfoRow('First Name', widget.baptismData['cFirstName'] ?? 'N/A'),
          _buildInfoRow('Last Name', widget.baptismData['cLastName'] ?? 'N/A'),
          _buildInfoRow('Gender', getGender(widget.baptismData['nGenderID'])),
          _buildInfoRow('Date of Birth', formatDob(widget.baptismData['dDoB'])),
          _buildInfoRow('Address', widget.baptismData['cAddress'] ?? 'N/A'),
        ],
      ),
    ),
  );
}
  Widget _buildStatusCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _approvalStatus == 'approved'
            ? Colors.green.shade50
            : Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _approvalStatus == 'approved' ? Colors.green : Colors.red,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            _approvalStatus == 'approved'
                ? Icons.check_circle
                : Icons.cancel,
            color: _approvalStatus == 'approved' ? Colors.green : Colors.red,
            size: 32,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _approvalStatus == 'approved'
                      ? 'Request Approved'
                      : 'Request Rejected',
                  style: GoogleFonts.roboto(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: _approvalStatus == 'approved'
                        ? Colors.green.shade700
                        : Colors.red.shade700,
                  ),
                ),
                if (_approvalStatus == 'disapproved' && _disapprovalReason != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Reason:',
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _disapprovalReason!,
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

 Widget _buildActionButtons() {
  // Check if already rejected
  final bool isAlreadyRejected = widget.baptismData['isRejected'] == 1;
  
  return Column(
    children: [
      Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : () async {
                setState(() => _isLoading = true);
                
                try {
                  await approveRequest(widget.baptismData['nGuestID']);
                  
                  setState(() {
                    _approvalStatus = 'approved';
                    _isLoading = false;
                  });
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Request approved successfully'),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } catch (e) {
                  setState(() => _isLoading = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString()}'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.check_circle_outline, size: 22),
              label: Text(
                'Approve',
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green,
                       backgroundColor: Colors.white, // explicitly set
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Colors.green, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: isAlreadyRejected
                ? ElevatedButton.icon(
                    // Already rejected - show as filled red button
                    onPressed: null, // Disabled
                    icon: const Icon(Icons.cancel, size: 22),
                    label: Text(
                      'Already Rejected',
                      style: GoogleFonts.roboto(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.red,
                      disabledForegroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                  )
                : OutlinedButton.icon(
                    // Not rejected yet - show as outlined button
                    onPressed: _isLoading ? null : () {
                      _showDisapprovalDialog(widget.baptismData['nGuestID']);
                    },
                    icon: const Icon(Icons.cancel_outlined, size: 22),
                    label: Text(
                      'Reject',
                      style: GoogleFonts.roboto(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                       backgroundColor: Colors.white, 
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Colors.red, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    ],
  );
}

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              '$label:',
              style: GoogleFonts.roboto(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: GoogleFonts.roboto(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildProfileImage() {
  String? imageUrl = widget.baptismData['cImagePath'];
  
  if (imageUrl != null && imageUrl.isNotEmpty) {
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        print('Error loading image: $error'); // For debugging
        return _defaultAvatar();
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded / 
                  loadingProgress.expectedTotalBytes!
                : null,
            color: Colors.cyan.shade700,
          ),
        );
      },
    );
  }
  
  return _defaultAvatar();
}

// Default avatar when no image is available
Widget _defaultAvatar() {
  return Container(
    color: Colors.cyan.shade100,
    child: Icon(
      Icons.person,
      size: 50,
      color: Colors.cyan.shade700,
    ),
  );
}

}

