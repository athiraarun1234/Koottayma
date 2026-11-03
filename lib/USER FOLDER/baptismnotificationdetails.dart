import 'dart:convert';
import 'package:Koottaayma/HTTPURL/httpurl.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BaptismNotificationDetails extends StatefulWidget {
  final Map<String, dynamic> baptismData;
 
  const BaptismNotificationDetails({
    Key? key,
   
    required this.baptismData,
  }) : super(key: key);

  @override
  State<BaptismNotificationDetails> createState() =>
      _BaptismNotificationDetailsState();
}

class _BaptismNotificationDetailsState
    extends State<BaptismNotificationDetails> {
  String? _approvalStatus;
  final TextEditingController _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

void _showDisapprovalDialog(int nBaptismRequestID) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Text(
        'Reject Baptism',
        style: GoogleFonts.roboto(
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Please provide a reason for request rejection:',
            style: GoogleFonts.roboto(fontSize: 14),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _reasonController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Enter reason here...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            final reason = _reasonController.text.trim();

            if (reason.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please provide a reason'),
                ),
              );
              return;
            }

            Navigator.pop(context);

            /// Call API here
            await rejectRequest(reason, nBaptismRequestID);

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Baptism disapproved'),
                backgroundColor: Colors.red,
              ),
            );

            setState(() {
              _approvalStatus = 'disapproved';
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
          ),
          child: const Text('Submit'),
        ),
      ],
    ),
  );
}

//Request Approval 
Future<void> approveRequest(int nBaptismRequestID) async {
 SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedToken = prefs.getString('jwt');
  final url = Uri.parse("https://lv4hfxvb-7000.inc1.devtunnels.ms/sacraments/presidentapproval/$nBaptismRequestID/");
  final response = await http.put(url,
    headers: {"Content-Type": "application/json",
     'Authorization': '$savedToken',},
      body: json.encode({ 
        'jwt': savedToken,
      }),
  );

  if (response.statusCode == 200||response.statusCode==201) {
    print("Approved Successfully");
  } else {
    print("Approval Failed: ${response.statusCode}");
    print("Response: ${response.body}");
  }
}

//Request Rejection
Future<void> rejectRequest(String cReason, int nBaptismRequestID) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? savedToken = prefs.getString('jwt');

  if (savedToken == null || savedToken.isEmpty) {
    print("Token not found. Please login again.");
    return;
  }

  final url = Uri.parse(PresidentRejectionAPI);

  final response = await http.post(
    url,
    headers: {
      "Content-Type": "application/json",
      "Authorization": "$savedToken",
    },
    body: json.encode({
      'jwt': savedToken,
      'cReason': cReason,
      'nBaptismRequestID': nBaptismRequestID,
    }),
  );

  print("Response Code: ${response.statusCode}");
  print("Response Body: ${response.body}");
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.cyan,
        elevation: 0,
        title: Text(
          'Baptism Details',
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Container(
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
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Applicant Information',
                        style: GoogleFonts.roboto(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.cyan.shade700,
                        ),
                      ),
                      const SizedBox(height: 16),
                       _buildInfoRow('Application ID', widget.baptismData['cApplicationCode'] ?? 'N/A'),
                      _buildInfoRow('Baby Name', widget.baptismData['cName'] ?? 'N/A'),
                      _buildInfoRow('Gender', widget.baptismData['cGenderName'] ?? 'N/A'),
                      _buildInfoRow('Date of Birth', widget.baptismData['dDoB'] ?? 'N/A'),
                      _buildInfoRow('Baptism Date', widget.baptismData['dBaptismDate'] ?? 'N/A'),
                      const Divider(height: 24),
                      _buildInfoRow('God Father', widget.baptismData['cGodFatherName'] ?? 'N/A'),
                      _buildInfoRow('God Mother', widget.baptismData['cGodMotherName'] ?? 'N/A'),
                      const Divider(height: 24),
                    
                      _buildInfoRow('Family Unit', widget.baptismData['cFamilyUnitName'] ?? 'N/A'),
                      _buildInfoRow('Family Number', widget.baptismData['cFamilyNo'] ?? 'N/A'),
                         const Divider(height: 24),
                      _buildInfoRow('Father', widget.baptismData['cFatherName'] ?? 'N/A'),
                      _buildInfoRow('Mother', widget.baptismData['cMotherName'] ?? 'N/A'),
                      const Divider(height: 24),
                      _buildInfoRow('Diocese', widget.baptismData['cDioceseName'] ?? 'N/A'),
                      _buildInfoRow('Forane', widget.baptismData['cForaneName'] ?? 'N/A'),
                      _buildInfoRow('Parish', widget.baptismData['cParishName'] ?? 'N/A'),
                      _buildInfoRow('Ward', widget.baptismData['cWardName'] ?? 'N/A'),
                     
                      if (_approvalStatus != null) ...[
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _approvalStatus == 'approved'
                                ? Colors.green.shade50
                                : Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _approvalStatus == 'approved'
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _approvalStatus == 'approved'
                                    ? Icons.check_circle
                                    : Icons.cancel,
                                color: _approvalStatus == 'approved'
                                    ? Colors.green
                                    : Colors.red,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _approvalStatus == 'approved'
                                          ? 'Approved'
                                          : 'Disapproved',
                                      style: GoogleFonts.roboto(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: _approvalStatus == 'approved'
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                    ),
                                    if (_approvalStatus == 'disapproved')
                                      Text(
                                        'Reason: ${_reasonController.text}',
                                        style: GoogleFonts.roboto(
                                          fontSize: 13,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (_approvalStatus == null) ...[
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                          onPressed: () async {
                          await approveRequest(widget.baptismData['nBaptismRequestID']);
                              setState(() {
                              _approvalStatus = 'approved';
                                    });
                               ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                       content: Text('Baptism approved successfully'),
                             backgroundColor: Colors.green,
                               ),
                                   );
                                  },
                        icon: const Icon(Icons.check_circle_outline),
                        label: Text(
                          'Approve',
                          style: GoogleFonts.roboto(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                  Expanded(
  child: OutlinedButton.icon(
    onPressed: () {
      _showDisapprovalDialog(widget.baptismData['nBaptismRequestID']);
    },
    icon: const Icon(Icons.cancel_outlined),
    label: Text(
      'Reject',
      style: GoogleFonts.roboto(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    ),
    style: OutlinedButton.styleFrom(
      foregroundColor: Colors.red,
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
            ],
          ),
        ),
      ),
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
                color: Colors.grey.shade700,
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
}