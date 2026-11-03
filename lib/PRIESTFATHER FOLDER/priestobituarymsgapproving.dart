
import 'package:Koottaayma/HTTPURL/formatdate.dart';
import 'package:Koottaayma/HTTPURL/httpurl.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
//athira 
class FamilyMember {
  int? nFamilyMemberID;
  String? cFullName;

  FamilyMember({this.nFamilyMemberID, this.cFullName});

 FamilyMember.fromJson(Map<String, dynamic> json) {
  nFamilyMemberID = json['nFamilyMemberID'] is int
      ? json['nFamilyMemberID']
      : int.tryParse(json['nFamilyMemberID'].toString());
  cFullName = json['cFullName']?.toString();
}
}

class DeathNotification {
  int? nDeathNotificationID;
  String? cFullName;
  String? dDoB;
  String? cUploadedFile;
  String? dDate;
  String? cServiceCategoryID;
  String? cChurchName;
  String? dChurchDate;
  List<FamilyMember>? familyMembers;

  DeathNotification({
    this.nDeathNotificationID,
    this.cFullName,
    this.dDoB,
    this.cUploadedFile,
    this.dDate,
    this.cServiceCategoryID,
    this.cChurchName,
    this.dChurchDate,
    this.familyMembers,
  });

DeathNotification.fromJson(Map<String, dynamic> json) {
  nDeathNotificationID = json['nDeathNotificationID'] is int
      ? json['nDeathNotificationID']
      : int.tryParse(json['nDeathNotificationID'].toString());
  cFullName        = json['cFullName']?.toString();
  dDoB             = json['dDoB']?.toString();
  cUploadedFile    = json['cUploadedFile']?.toString();
  dDate            = json['dDate']?.toString();
  cServiceCategoryID = json['cServiceCategoryID']?.toString();
  cChurchName      = json['cChurchName']?.toString();
  dChurchDate      = json['dChurchDate']?.toString();
  if (json['familyMembers'] != null) {
    familyMembers = (json['familyMembers'] as List)
        .map((e) => FamilyMember.fromJson(e))
        .toList();
  }
}

  /// Calculate age from dDoB to dDate (or today if dDate is null)
  int? get age {
    if (dDoB == null) return null;
    try {
      final birth = DateTime.parse(dDoB!);
      final death = dDate != null ? DateTime.parse(dDate!) : DateTime.now();
      int years = death.year - birth.year;
      if (death.month < birth.month ||
          (death.month == birth.month && death.day < birth.day)) {
        years--;
      }
      return years;
    } catch (_) {
      return null;
    }
  }

  String get fullImageUrl {
    if (cUploadedFile == null || cUploadedFile!.isEmpty) return '';
    if (cUploadedFile!.startsWith('http')) return cUploadedFile!;
    return 'https://lv4hfxvb-7000.inc1.devtunnels.ms/$cUploadedFile';
  }
}

class MembersObituarymessagesPriestApprovingPage extends StatefulWidget {
  const MembersObituarymessagesPriestApprovingPage({super.key});

  @override
  State<MembersObituarymessagesPriestApprovingPage> createState() =>
      _MembersObituarymessagesPriestApprovingPageState();
}

class _MembersObituarymessagesPriestApprovingPageState
    extends State<MembersObituarymessagesPriestApprovingPage> {
  List<DeathNotification> messages = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchMessages();
  }

  Future<void> fetchMessages() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? savedToken = prefs.getString('jwt');

      setState(() {
        isLoading = true;
        errorMessage = null;
      });
      final response = await http.get(
        Uri.parse(PriestApprovingObituaryMessages),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': '$savedToken',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final List<dynamic> jsonData = json.decode(response.body);
        setState(() {
          messages =
              jsonData.map((e) => DeathNotification.fromJson(e)).toList();
          isLoading = false;
        });
      } else { 
        debugPrint('API Response: ${response.body}');
        setState(() {
          errorMessage =
              'Failed to load messages. Status: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e';
        isLoading = false;
      });
    }
  }

  Future<void> approveRequest(int nDeathNotificationID) async {
    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString('jwt');

    if (savedToken == null || savedToken.isEmpty) {
      throw Exception("Token not found. Please login again.");
    }

    final url = Uri.parse(
        "https://lv4hfxvb-7000.inc1.devtunnels.ms/notifications/approvingmembernotifications/$nDeathNotificationID/");

    final response = await http.put(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": savedToken,
      },
      body: json.encode({}),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception("Failed to approve request");
    }
  }

  void _onMessageUpdated() {
    fetchMessages();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.cyan,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
        // 'Obituary Approvals',
            'Recent Messages',
          style: GoogleFonts.roboto(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.cyan, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white))
            : errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 60, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(errorMessage!,
                            style: GoogleFonts.roboto(
                                fontSize: 16, color: Colors.red),
                            textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: fetchMessages,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : messages.isEmpty
                    ? Center(
                        child: Text(
                          'No obituary notifications available',
                          style: GoogleFonts.roboto(
                              fontSize: 18, color: Colors.white),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          return DeathNotificationCard(
                            notification: messages[index],
                            onApprove: approveRequest,
                          //  onReject: rejectRequest,
                            onMessageUpdated: _onMessageUpdated,
                          );
                        },
                      ),
      ),
    );
  }
}


// DeathNotificationCard

class DeathNotificationCard extends StatefulWidget {
  final DeathNotification notification;
  final Future<void> Function(int) onApprove;
 // final Future<void> Function(String, int) onReject;
  final VoidCallback onMessageUpdated;

  const DeathNotificationCard({
    super.key,
    required this.notification,
    required this.onApprove,
   // required this.onReject,
    required this.onMessageUpdated,
  });

  @override
  State<DeathNotificationCard> createState() => _DeathNotificationCardState();
}

class _DeathNotificationCardState extends State<DeathNotificationCard> {
  String? _approvalStatus;
  String? _disapprovalReason;
  final TextEditingController _reasonController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }
String _formatChurchDateTime(String? raw) {
  if (raw == null || raw.isEmpty) return '';
  try {
    final dt = DateTime.parse(raw);
    final datePart = DateFormat('dd MMM yyyy').format(dt);
    final timePart = DateFormat('h:mm a').format(dt);
    return '$datePart  •  $timePart';
  } catch (_) {
    return raw;
  }
}
 
  @override
  Widget build(BuildContext context) {
    final n = widget.notification;
    final ageStr = n.age != null ? ' (${n.age} yrs)' : '';

    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Deceased banner 
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade800,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.church, color: Colors.white70, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'OBITUARY NOTICE',
                    style: GoogleFonts.roboto(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                      letterSpacing: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // ── Photo + Name / Dates 
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Photo
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: n.fullImageUrl.isNotEmpty
                      ? Image.network(
                          n.fullImageUrl,
                          width: 100,
                          height: 120,
                          fit: BoxFit.cover,
                          loadingBuilder: (ctx, child, progress) {
                            if (progress == null) return child;
                            return Container(
                              width: 100,
                              height: 120,
                              color: Colors.grey.shade200,
                              child: const Center(
                                  child: CircularProgressIndicator()),
                            );
                          },
                          errorBuilder: (ctx, _, __) => Container(
                            width: 100,
                            height: 120,
                            color: Colors.grey.shade300,
                            child: const Icon(Icons.person,
                                size: 50, color: Colors.grey),
                          ),
                        )
                      : Container(
                          width: 100,
                          height: 120,
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.person,
                              size: 50, color: Colors.grey),
                        ),
                ),

                const SizedBox(width: 14),

                // Name & dates
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Deceased name + age
                      Text(
                        '${n.cFullName ?? 'Unknown'}$ageStr',
                        style: GoogleFonts.roboto(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Date of Birth
                      if (n.dDoB != null) ...[
                        _infoRow(
                          Icons.cake_outlined,
                          'Born',
                          DateFormatter.formatDate(n.dDoB),
                          Colors.blueGrey,
                        ),
                        const SizedBox(height: 4),
                      ],

                      // Date of Death
                      if (n.dDate != null)
                        _infoRow(
                          Icons.favorite_border,
                          'Passed',
                          DateFormatter.formatDate(n.dDate),
                          Colors.red.shade400,
                        ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            //service caagory 
            // ── Service / Church Details ──
if (n.cServiceCategoryID != null ||
    n.cChurchName != null ||
    n.dChurchDate != null) ...[
  Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [Colors.cyan.shade50, Colors.white],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.cyan.shade100, width: 1.2),
      boxShadow: [
        BoxShadow(
          color: Colors.cyan.shade50,
          blurRadius: 6,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.cyan.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.church, size: 16, color: Colors.cyan.shade700),
            ),
            const SizedBox(width: 8),
            Text(
              'Service Details',
              style: GoogleFonts.roboto(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.cyan.shade700,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

     if (n.cServiceCategoryID != null)
              _serviceDetailRow(
               icon: Icons.category_outlined,
               label: 'Service',
               value: _getServiceCategoryLabel(n.cServiceCategoryID),
               iconColor: Colors.deepPurple.shade300,
  ),

        if (n.cServiceCategoryID != null && n.cChurchName != null)
          const SizedBox(height: 10),

        if (n.cChurchName != null)
          _serviceDetailRow(
            icon: Icons.location_on_outlined,
            label: 'Church',
            value: n.cChurchName!,
            iconColor: Colors.orange.shade400,
          ),

        if (n.cChurchName != null && n.dChurchDate != null)
          const SizedBox(height: 10),

       if (n.dChurchDate != null)
  _serviceDetailRow(
    icon: Icons.calendar_today_outlined,
    label: 'Date & Time',
    value: _formatChurchDateTime(n.dChurchDate),   
    iconColor: Colors.teal.shade400,)
      ],
    ),
  ),
  const SizedBox(height: 14),
],


            // ── Family Members 
            if (n.familyMembers != null && n.familyMembers!.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(Icons.people_outline,
                      size: 18, color: Colors.cyan),
                  const SizedBox(width: 6),
                  Text(
                    'Family Members (${n.familyMembers!.length})',
                    style: GoogleFonts.roboto(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.cyan.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: n.familyMembers!
                    .map((fm) => _familyChip(fm.cFullName ?? ''))
                    .toList(),
              ),
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 12),
            ],

            // ── Approve / Reject 
            if (_approvalStatus != null)
              _buildStatusCard()
            else
              _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
     //   Icon(icon, size: 15, color: color),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: GoogleFonts.roboto(
              fontSize: 13, color: Colors.grey.shade600),
        ),
        Flexible(
          child: Text(
            value,
            style: GoogleFonts.roboto(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87),
          ),
        ),
      ],
    );
  }
  
Widget _serviceDetailRow({
  required IconData icon,
  required String label,
  required String value,
  required Color iconColor,
}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 14, color: iconColor),
      ),
      const SizedBox(width: 10),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.roboto(
              fontSize: 11,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.roboto(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    ],
  );
}
  Widget _familyChip(String name) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.cyan.shade50,
        border: Border.all(color: Colors.cyan.shade200),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.person_outline, size: 14, color: Colors.cyan.shade600),
          const SizedBox(width: 4),
          Text(
            name,
            style: GoogleFonts.roboto(
              fontSize: 13,
              color: Colors.cyan.shade800,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
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
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            _approvalStatus == 'approved' ? Icons.check_circle : Icons.cancel,
            color:
                _approvalStatus == 'approved' ? Colors.green : Colors.red,
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
              
              ],
            ),
          ),
        ],
      ),
    );
  }

 Widget _buildActionButtons() {
  return Row(
    children: [
      Expanded(
        child: ElevatedButton.icon(
          onPressed: _isLoading
              ? null
              : () async {
                  if (widget.notification.nDeathNotificationID == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Invalid notification ID. Cannot approve.'),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }

                  setState(() => _isLoading = true);
                  try {
                    await widget.onApprove(
                        widget.notification.nDeathNotificationID!);
                    if (mounted) {
                      setState(() {
                        _approvalStatus = 'approved';
                        _isLoading = false;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Request approved successfully'),
                          backgroundColor: Colors.green,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      widget.onMessageUpdated();
                    }
                  } catch (e) {
                    if (mounted) {
                      setState(() => _isLoading = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: ${e.toString()}'),
                          backgroundColor: Colors.red,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                },
          icon: _isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.check_circle_outline, size: 22),
          label: Text('Approve',
              style: GoogleFonts.roboto(
                  fontSize: 16, fontWeight: FontWeight.w600)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            elevation: 2,
          ),
        ),
      ),
      const SizedBox(width: 12),
    ],
  );
}

 String _getServiceCategoryLabel(String? id) {
  switch (id) {
    case '1': return 'Funeral';
    case '2': return 'Seventh Day';
   
    default:  return id ?? 'Unknown';
  }
}
}