// import 'dart:convert';
// import 'dart:io';
// import 'dart:typed_data';
// import 'package:MyCommunity/HTTPURL/httpurl.dart';
// import 'package:http/http.dart' as http;
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:intl/intl.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:pdf/pdf.dart';
// import 'package:pdf/widgets.dart' as pw;
// import 'package:printing/printing.dart';


// class PriestBaptismApproval extends StatefulWidget {
//   final Map<String, dynamic> baptismData;

//   const PriestBaptismApproval({
//     Key? key,
//     required this.baptismData,
//   }) : super(key: key);

//   @override
//   State<PriestBaptismApproval> createState() => _PriestBaptismApprovalState();
// }

// class _PriestBaptismApprovalState extends State<PriestBaptismApproval> {
//   String? _approvalStatus;
//   String? _disapprovalReason;
//   final TextEditingController _reasonController = TextEditingController();
//   bool _isLoading = false;
//   Uint8List? _certificatePdfBytes;

//   @override
//   void dispose() {
//     _reasonController.dispose();
//     super.dispose();
//   }

//   // ─────────────────────────────────────────────────────────────────────────
//   //  CERTIFICATE BUILDER
//   // ─────────────────────────────────────────────────────────────────────────

//   Future<Uint8List> _buildCertificatePdf(Map<String, dynamic> data) async {
//     final pdf = pw.Document();

//     const PdfColor navy     = PdfColor.fromInt(0xFF2C3E6B);
//     const PdfColor brown    = PdfColor.fromInt(0xFF7B5B3A);
//     const PdfColor textGrey = PdfColor.fromInt(0xFF555555);
//     const PdfColor blue     = PdfColor.fromInt(0xFF3366AA);

//     final loraFont       = await PdfGoogleFonts.loraRegular();
//     final loraBoldFont   = await PdfGoogleFonts.loraBold();
//     final loraItalicFont = await PdfGoogleFonts.loraItalic();

//     final bgImageData = await rootBundle.load('assets/certificateimage.jpeg');
//     final bgImage = pw.MemoryImage(bgImageData.buffer.asUint8List());

//     String val(String key, [String fallback = '']) =>
//         (data[key] ?? fallback).toString();

//     final childName = val('cName');
//     final father    = val('cFatherName');
//     final mother    = val('cMotherName');
//     final godFather = val('cGodFatherName');
//     final godMother = val('cGodMotherName');
//     final dob       = val('dDoB');
//     final baptDate  = val('dBaptismDate');
//     final parish    = val('cParishName');
//     final certNo    = val('nBaptismRequestID');

//     const double W = 841.89;
//     const double H = 595.28;

//     const double centerX      = W / 2;
//     const double nameY        = H * 0.575;
//     const double parentY      = H * 0.415;
//     const double parentLabelY = H * 0.375;
//     const double fatherX      = W * 0.295;
//     const double motherX      = W * 0.705;
//     const double godY         = H * 0.305;
//     const double godLabelY    = H * 0.267;
//     const double godFatherX   = W * 0.295;
//     const double godMotherX   = W * 0.705;
//     const double sentenceY    = H * 0.195;
//     const double labelRowY    = H * 0.118;
//     const double valueRowY    = H * 0.083;
//     const double dobX         = W * 0.270;
//     const double priestX      = W * 0.500;
//     const double churchX      = W * 0.730;

//     pdf.addPage(
//       pw.Page(
//         pageFormat: PdfPageFormat.a4.landscape,
//         margin: pw.EdgeInsets.zero,
//         build: (pw.Context ctx) {
//           return pw.Stack(
//             children: [
//               pw.Positioned.fill(
//                 child: pw.Image(bgImage, fit: pw.BoxFit.fill),
//               ),
//               pw.Positioned(
//                 left: 0, right: 0, bottom: nameY - -90,
//                 child: pw.Text(
//                   " CERTIFICATE OF BAPTISUM",
//                   textAlign: pw.TextAlign.center,
//                   style: pw.TextStyle(
//                       font: loraItalicFont, fontSize: 44, color: navy),
//                 ),
//               ),
//               pw.Positioned(
//                 left: 0, right: 0, bottom: nameY - 34,
//                 child: pw.Text(
//                   childName,
//                   textAlign: pw.TextAlign.center,
//                   style: pw.TextStyle(
//                       font: loraItalicFont, fontSize: 44, color: navy),
//                 ),
//               ),
//               pw.Positioned(
//                 left: fatherX - 120, bottom: parentY - 14,
//                 child: pw.SizedBox(
//                   width: 250,
//                   child: pw.Text(father,
//                       textAlign: pw.TextAlign.center,
//                       style: pw.TextStyle(
//                           font: loraItalicFont, fontSize: 22, color: brown)),
//                 ),
//               ),
//               pw.Positioned(
//                 left: fatherX - 50, bottom: parentLabelY - 8,
//                 child: pw.SizedBox(
//                   width: 100,
//                   child: pw.Text('Father',
//                       textAlign: pw.TextAlign.center,
//                       style: pw.TextStyle(
//                           font: loraItalicFont, fontSize: 10, color: textGrey)),
//                 ),
//               ),
//               pw.Positioned(
//                 left: motherX - 80, bottom: parentY - 14,
//                 child: pw.SizedBox(
//                   width: 160,
//                   child: pw.Text(mother,
//                       textAlign: pw.TextAlign.center,
//                       style: pw.TextStyle(
//                           font: loraItalicFont, fontSize: 22, color: brown)),
//                 ),
//               ),
//               pw.Positioned(
//                 left: motherX - 50, bottom: parentLabelY - 8,
//                 child: pw.SizedBox(
//                   width: 100,
//                   child: pw.Text('Mother',
//                       textAlign: pw.TextAlign.center,
//                       style: pw.TextStyle(
//                           font: loraItalicFont, fontSize: 10, color: textGrey)),
//                 ),
//               ),
//               pw.Positioned(
//                 left: godFatherX - 120, bottom: godY - 14,
//                 child: pw.SizedBox(
//                   width: 250,
//                   child: pw.Text(godFather,
//                       textAlign: pw.TextAlign.center,
//                       style: pw.TextStyle(
//                           font: loraItalicFont, fontSize: 18, color: brown)),
//                 ),
//               ),
//               pw.Positioned(
//                 left: godFatherX - 50, bottom: godLabelY - 8,
//                 child: pw.SizedBox(
//                   width: 100,
//                   child: pw.Text('God Father',
//                       textAlign: pw.TextAlign.center,
//                       style: pw.TextStyle(
//                           font: loraItalicFont, fontSize: 9, color: textGrey)),
//                 ),
//               ),
//               pw.Positioned(
//                 left: godMotherX - 80, bottom: godY - 14,
//                 child: pw.SizedBox(
//                   width: 160,
//                   child: pw.Text(godMother,
//                       textAlign: pw.TextAlign.center,
//                       style: pw.TextStyle(
//                           font: loraItalicFont, fontSize: 18, color: brown)),
//                 ),
//               ),
//               pw.Positioned(
//                 left: godMotherX - 50, bottom: godLabelY - 8,
//                 child: pw.SizedBox(
//                   width: 100,
//                   child: pw.Text('God Mother',
//                       textAlign: pw.TextAlign.center,
//                       style: pw.TextStyle(
//                           font: loraItalicFont, fontSize: 9, color: textGrey)),
//                 ),
//               ),
//               pw.Positioned(
//                 left: 80, right: 80, bottom: sentenceY - 8,
//                 child: pw.Text(
//                   'was received into church fellowship by water baptism on '
//                   '${DateFormat('d-MMM-yyyy').format(DateTime.parse(baptDate))}',
//                   textAlign: pw.TextAlign.center,
//                   style: pw.TextStyle(font: loraFont, fontSize: 11.5, color: navy),
//                 ),
//               ),
//               pw.Positioned(
//                 left: dobX - 60, bottom: labelRowY,
//                 child: pw.SizedBox(
//                   width: 120,
//                   child: pw.Text('DATE OF BIRTH:',
//                       textAlign: pw.TextAlign.center,
//                       style: pw.TextStyle(
//                           font: loraBoldFont,
//                           fontSize: 8,
//                           color: navy,
//                           letterSpacing: 0.8)),
//                 ),
//               ),
//               pw.Positioned(
//                 left: dobX - 60, bottom: valueRowY,
//                 child: pw.SizedBox(
//                   width: 120,
//                   child: pw.Text(
//                       DateFormat('d-MMM-yyyy').format(DateTime.parse(dob)),
//                       textAlign: pw.TextAlign.center,
//                       style: pw.TextStyle(font: loraFont, fontSize: 10, color: navy)),
//                 ),
//               ),
//               pw.Positioned(
//                 left: priestX - 70, bottom: labelRowY,
//                 child: pw.SizedBox(
//                   width: 140,
//                   child: pw.Text('PRIEST NAME',
//                       textAlign: pw.TextAlign.center,
//                       style: pw.TextStyle(
//                           font: loraBoldFont,
//                           fontSize: 8,
//                           color: navy,
//                           letterSpacing: 0.8)),
//                 ),
//               ),
//               pw.Positioned(
//                 left: priestX - 70, bottom: valueRowY,
//                 child: pw.SizedBox(
//                   width: 140,
//                   child: pw.Text('Fr. Parish Priest',
//                       textAlign: pw.TextAlign.center,
//                       style: pw.TextStyle(font: loraFont, fontSize: 10, color: blue)),
//                 ),
//               ),
//               pw.Positioned(
//                 left: churchX - 80, bottom: labelRowY,
//                 child: pw.SizedBox(
//                   width: 160,
//                   child: pw.Text('CHURCH NAME',
//                       textAlign: pw.TextAlign.center,
//                       style: pw.TextStyle(
//                           font: loraBoldFont,
//                           fontSize: 8,
//                           color: navy,
//                           letterSpacing: 0.8)),
//                 ),
//               ),
//               pw.Positioned(
//                 left: churchX - 80, bottom: valueRowY,
//                 child: pw.SizedBox(
//                   width: 160,
//                   child: pw.Text(parish,
//                       textAlign: pw.TextAlign.center,
//                       style: pw.TextStyle(font: loraFont, fontSize: 10, color: blue)),
//                 ),
//               ),
//             ],
//           );
//         },
//       ),
//     );

//     return pdf.save();
//   }

//   // ─────────────────────────────────────────────────────────────────────────
//   //  Upload certificate PDF to backend only (no external share/print)
//   // ─────────────────────────────────────────────────────────────────────────
//   Future<void> _uploadCertificateToBackend(Uint8List pdfBytes) async {
//     final prefs = await SharedPreferences.getInstance();
//     final savedToken = prefs.getString('jwt');
//     if (savedToken == null || savedToken.isEmpty) {
//       throw Exception("Token not found. Please login again.");
//     }

//     final tempDir  = await getTemporaryDirectory();
//     final fileName =
//         'Baptism_Certificate_${widget.baptismData['nBaptismRequestID']}.pdf';
//     final tempFile = File('${tempDir.path}/$fileName');
//     await tempFile.writeAsBytes(pdfBytes);

//     final uri = Uri.parse(
//         'https://79056d4q-7000.inc1.devtunnels.ms/sacraments/addbaptismcertificate/');

//     final request = http.MultipartRequest('POST', uri)
//       ..headers['Authorization'] = savedToken
//       ..fields['nBaptismRequestID'] =
//           (widget.baptismData['nBaptismRequestID'] ?? '').toString()
//       ..fields['nDioceseID'] =
//           (widget.baptismData['nDioceseID'] ?? '').toString()
//       ..fields['nParishID'] =
//           (widget.baptismData['nParishID'] ?? '').toString()
//       ..fields['nForaneID'] =
//           (widget.baptismData['nForaneID'] ?? '').toString()
//       ..fields['cApplicationCode'] =
//           (widget.baptismData['cApplicationCode'] ?? '').toString()
//       ..files.add(await http.MultipartFile.fromPath(
//         'cPdfPath',
//         tempFile.path,
//         filename: fileName,
//       ));

//     final streamedResponse = await request.send();
//     final response         = await http.Response.fromStream(streamedResponse);

//     await tempFile.delete();

//     if (response.statusCode != 200 && response.statusCode != 201) {
//       throw Exception(
//           'Upload failed (${response.statusCode}): ${response.body}');
//     }
//   }

//   // ─────────────────────────────────────────────────────────────────────────
//   //  Upload only — no external share sheet
//   // ─────────────────────────────────────────────────────────────────────────
//   Future<void> _uploadCertificate({
//     required Uint8List pdfBytes,
//     required BuildContext ctx,
//   }) async {
//     showDialog(
//       context: ctx,
//       barrierDismissible: false,
//       builder: (_) => const Center(child: CircularProgressIndicator()),
//     );

//     try {
//       await _uploadCertificateToBackend(pdfBytes);
//       if (Navigator.canPop(ctx)) Navigator.pop(ctx);
//       ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
//           content: Text('Certificate uploaded successfully'),
//           backgroundColor: Colors.green,
//           behavior: SnackBarBehavior.floating));
//     } catch (e) {
//       if (Navigator.canPop(ctx)) Navigator.pop(ctx);
//       ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
//           content: Text('Upload failed: ${e.toString()}'),
//           backgroundColor: Colors.red,
//           behavior: SnackBarBehavior.floating));
//     }
//   }

//   // ─────────────────────────────────────────────────────────────────────────
//   //  DIALOGS
//   // ─────────────────────────────────────────────────────────────────────────

//   void _showDisapprovalDialog(int nBaptismRequestID) {
//     _reasonController.clear();
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//         title: Text('Reject Baptism Request',
//             style: GoogleFonts.roboto(fontWeight: FontWeight.bold, fontSize: 18)),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text('Please provide a reason for rejecting this request:',
//                 style: GoogleFonts.roboto(fontSize: 14, color: Colors.grey.shade700)),
//             const SizedBox(height: 16),
//             TextField(
//               controller: _reasonController,
//               maxLines: 4,
//               maxLength: 500,
//               decoration: InputDecoration(
//                 hintText: 'Enter reason here...',
//                 hintStyle: TextStyle(color: Colors.grey.shade400),
//                 border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(12),
//                     borderSide: BorderSide(color: Colors.grey.shade300)),
//                 focusedBorder: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(12),
//                     borderSide: const BorderSide(color: Colors.red, width: 2)),
//                 contentPadding: const EdgeInsets.all(12),
//               ),
//             ),
//           ],
//         ),
//         actions: [
//           TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: Text('Cancel', style: GoogleFonts.roboto(color: Colors.grey))),
//           ElevatedButton(
//             onPressed: () async {
//               final reason = _reasonController.text.trim();
//               if (reason.isEmpty) {
//                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
//                     content: Text('Please provide a reason'),
//                     backgroundColor: Colors.orange,
//                     behavior: SnackBarBehavior.floating));
//                 return;
//               }
//               Navigator.pop(context);
//               setState(() => _isLoading = true);
//               try {
//                 await rejectRequest(reason, nBaptismRequestID);
//                 setState(() {
//                   _approvalStatus = 'disapproved';
//                   _disapprovalReason = reason;
//                   _isLoading = false;
//                 });
//                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
//                     content: Text('Baptism request rejected'),
//                     backgroundColor: Colors.red,
//                     behavior: SnackBarBehavior.floating));
//               } catch (e) {
//                 setState(() => _isLoading = false);
//                 ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//                     content: Text('Error: ${e.toString()}'),
//                     backgroundColor: Colors.red,
//                     behavior: SnackBarBehavior.floating));
//               }
//             },
//             style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.red,
//                 foregroundColor: Colors.white,
//                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
//             child: const Text('Submit'),
//           ),
//         ],
//       ),
//     );
//   }

//   void _showMeetingDialog(int nBaptismRequestID) {
//     final TextEditingController dateTimeController = TextEditingController();
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => StatefulBuilder(
//         builder: (context, setDialogState) => AlertDialog(
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//           title: Text('Schedule Meeting',
//               style: GoogleFonts.roboto(fontWeight: FontWeight.bold, fontSize: 18)),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                   'Please select a date and time for the meeting with the priest:',
//                   style:
//                       GoogleFonts.roboto(fontSize: 14, color: Colors.grey.shade700)),
//               const SizedBox(height: 16),
//               TextField(
//                 readOnly: true,
//                 controller: dateTimeController,
//                 decoration: InputDecoration(
//                   hintText: 'Select Date & Time',
//                   hintStyle: TextStyle(color: Colors.grey.shade400),
//                   border:
//                       OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//                   focusedBorder: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(12),
//                       borderSide: const BorderSide(color: Colors.blue, width: 2)),
//                   suffixIcon:
//                       const Icon(Icons.calendar_today, color: Colors.blue),
//                   contentPadding: const EdgeInsets.all(12),
//                 ),
//                 onTap: () async {
//                   final pickedDate = await showDatePicker(
//                     context: context,
//                     initialDate: DateTime.now(),
//                     firstDate: DateTime.now(),
//                     lastDate: DateTime(2100),
//                     builder: (ctx, child) => Theme(
//                       data: Theme.of(ctx).copyWith(
//                           colorScheme:
//                               const ColorScheme.light(primary: Colors.blue)),
//                       child: child!,
//                     ),
//                   );
//                   if (pickedDate != null) {
//                     final pickedTime = await showTimePicker(
//                       context: context,
//                       initialTime: TimeOfDay.now(),
//                       builder: (ctx, child) => Theme(
//                         data: Theme.of(ctx).copyWith(
//                             colorScheme:
//                                 const ColorScheme.light(primary: Colors.blue)),
//                         child: child!,
//                       ),
//                     );
//                     if (pickedTime != null) {
//                       setDialogState(() {
//                         final fd =
//                             '${pickedDate.day.toString().padLeft(2, '0')}-'
//                             '${pickedDate.month.toString().padLeft(2, '0')}-'
//                             '${pickedDate.year}';
//                         final ft =
//                             '${pickedTime.hour.toString().padLeft(2, '0')}:'
//                             '${pickedTime.minute.toString().padLeft(2, '0')}:00';
//                         dateTimeController.text = '$fd $ft';
//                       });
//                     }
//                   }
//                 },
//               ),
//             ],
//           ),
//           actions: [
//             TextButton(
//                 onPressed: () => Navigator.pop(context),
//                 child:
//                     Text('Cancel', style: GoogleFonts.roboto(color: Colors.grey))),
//             ElevatedButton(
//               onPressed: () async {
//                 final dateTimeStr = dateTimeController.text.trim();
//                 if (dateTimeStr.isEmpty) {
//                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
//                       content: Text('Please select a date and time'),
//                       backgroundColor: Colors.orange,
//                       behavior: SnackBarBehavior.floating));
//                   return;
//                 }
//                 Navigator.pop(context);
//                 setState(() => _isLoading = true);
//                 try {
//                   await meetingRequest(dateTimeStr, nBaptismRequestID);
//                   setState(() => _isLoading = false);
//                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
//                       content: Text('Meeting request sent successfully'),
//                       backgroundColor: Colors.green,
//                       behavior: SnackBarBehavior.floating));
//                 } catch (e) {
//                   setState(() => _isLoading = false);
//                   ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//                       content: Text('Error: ${e.toString()}'),
//                       backgroundColor: Colors.red,
//                       behavior: SnackBarBehavior.floating));
//                 }
//               },
//               style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.blue,
//                   foregroundColor: Colors.white,
//                   shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(8))),
//               child: const Text('Send'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // ─────────────────────────────────────────────────────────────────────────
//   //  API CALLS
//   // ─────────────────────────────────────────────────────────────────────────

//   Future<void> meetingRequest(String dDateTime, int nBaptismRequestID) async {
//     final prefs = await SharedPreferences.getInstance();
//     final savedToken = prefs.getString('jwt');
//     if (savedToken == null || savedToken.isEmpty) {
//       throw Exception("Token not found. Please login again.");
//     }
//     final url = Uri.parse(PriestMeetingRequest);
//     final response = await http.post(url,
//         headers: {
//           "Content-Type": "application/json",
//           "Authorization": savedToken
//         },
//         body: json.encode(
//             {'dDateTime': dDateTime, 'nBaptismRequestID': nBaptismRequestID}));
//     if (response.statusCode != 200)
//       throw Exception("Failed to send meeting request");
//   }

//   Future<void> approveRequest(int nBaptismRequestID) async {
//     final prefs = await SharedPreferences.getInstance();
//     final savedToken = prefs.getString('jwt');
//     if (savedToken == null || savedToken.isEmpty) {
//       throw Exception("Token not found. Please login again.");
//     }
//     final url = Uri.parse(
//         "https://lv4hfxvb-7000.inc1.devtunnels.ms/sacraments/priestactivating/$nBaptismRequestID/");
//     final response = await http.put(url,
//         headers: {
//           "Content-Type": "application/json",
//           "Authorization": savedToken
//         },
//         body: json.encode({'jwt': savedToken}));
//     if (response.statusCode != 201) throw Exception("Failed to approve request");
//   }

//   Future<void> rejectRequest(String cReason, int nBaptismRequestID) async {
//     final prefs = await SharedPreferences.getInstance();
//     final savedToken = prefs.getString('jwt');
//     if (savedToken == null || savedToken.isEmpty) {
//       throw Exception("Token not found. Please login again.");
//     }
//     final url = Uri.parse(PresidentRejectionAPI);
//     final response = await http.post(url,
//         headers: {
//           "Content-Type": "application/json",
//           "Authorization": savedToken
//         },
//         body: json.encode({
//           'jwt': savedToken,
//           'cReason': cReason,
//           'nBaptismRequestID': nBaptismRequestID
//         }));
//     if (response.statusCode != 200) throw Exception("Failed to reject request");
//   }

//   // ─────────────────────────────────────────────────────────────────────────
//   //  BUILD
//   // ─────────────────────────────────────────────────────────────────────────

//   String _todayFormatted() {
//     final now = DateTime.now();
//     const months = [
//       '',
//       'January', 'February', 'March', 'April', 'May', 'June',
//       'July', 'August', 'September', 'October', 'November', 'December'
//     ];
//     return '${now.day} ${months[now.month]} ${now.year}';
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey.shade100,
//       appBar: AppBar(
//         backgroundColor: Colors.cyan,
//         elevation: 0,
//         title: Text('Baptism Request Details',
//             style: GoogleFonts.roboto(
//                 color: Colors.white,
//                 fontSize: 18,
//                 fontWeight: FontWeight.w500)),
//         leading: IconButton(
//             icon: const Icon(Icons.arrow_back, color: Colors.white),
//             onPressed: () => Navigator.pop(context)),
//       ),
//       body: Stack(
//         children: [
//           SingleChildScrollView(
//             child: Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Column(
//                 children: [
//                   _buildInfoCard(),
//                   const SizedBox(height: 16),
//                   if (_approvalStatus != null) _buildStatusCard(),
//                   if (_approvalStatus == 'approved' &&
//                       _certificatePdfBytes != null)
//                     _buildCertificateCard(),
//                   if (_approvalStatus == null) ...[
//                     const SizedBox(height: 10),
//                     _buildActionButtons(),
//                   ],
//                   const SizedBox(height: 20),
//                 ],
//               ),
//             ),
//           ),
//           if (_isLoading)
//             Container(
//               color: Colors.black.withOpacity(0.3),
//               child: const Center(child: CircularProgressIndicator()),
//             ),
//         ],
//       ),
//     );
//   }

//   Widget _buildInfoCard() {
//     return Container(
//       width: double.infinity,
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//               color: Colors.grey.shade300,
//               blurRadius: 10,
//               offset: const Offset(0, 4))
//         ],
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(20.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text('Applicant Information',
//                 style: GoogleFonts.roboto(
//                     fontSize: 20,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.cyan.shade700)),
//             const SizedBox(height: 10),
//             _buildInfoRow('Baby Name',     widget.baptismData['cName']           ?? 'N/A'),
//             _buildInfoRow('Gender',        widget.baptismData['cGenderName']     ?? 'N/A'),
//             _buildInfoRow('Date of Birth', widget.baptismData['dDoB'] != null
//                 ? DateFormat('d MMM yyyy').format(DateTime.parse(widget.baptismData['dDoB']))
//                 : 'N/A'),
//             _buildInfoRow('Baptism Date',  widget.baptismData['dBaptismDate'] != null
//                 ? DateFormat('d MMM yyyy').format(DateTime.parse(widget.baptismData['dBaptismDate']))
//                 : 'N/A'),
//             const Divider(height: 10, thickness: 1),
//             _buildInfoRow('God Father',    widget.baptismData['cGodFatherName']  ?? 'N/A'),
//             _buildInfoRow('God Mother',    widget.baptismData['cGodMotherName']  ?? 'N/A'),
//             const Divider(height: 10, thickness: 1),
//             _buildInfoRow('Father',        widget.baptismData['cFatherName']     ?? 'N/A'),
//             _buildInfoRow('Mother',        widget.baptismData['cMotherName']     ?? 'N/A'),
//             const Divider(height: 10, thickness: 1),
//             _buildInfoRow('Family Unit',   widget.baptismData['cFamilyUnitName'] ?? 'N/A'),
//             _buildInfoRow('Family Number', widget.baptismData['cFamilyNo']       ?? 'N/A'),
//             const Divider(height: 10, thickness: 1),
//             _buildInfoRow('Diocese',       widget.baptismData['cDioceseName']    ?? 'N/A'),
//             _buildInfoRow('Forane',        widget.baptismData['cForaneName']     ?? 'N/A'),
//             _buildInfoRow('Parish',        widget.baptismData['cParishName']     ?? 'N/A'),
//             _buildInfoRow('Ward',          widget.baptismData['cWardName']       ?? 'N/A'),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildStatusCard() {
//     final approved = _approvalStatus == 'approved';
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: approved ? Colors.green.shade50 : Colors.red.shade50,
//         borderRadius: BorderRadius.circular(16),
//         border:
//             Border.all(color: approved ? Colors.green : Colors.red, width: 2),
//         boxShadow: [
//           BoxShadow(
//               color: Colors.grey.shade300,
//               blurRadius: 10,
//               offset: const Offset(0, 4))
//         ],
//       ),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Icon(approved ? Icons.check_circle : Icons.cancel,
//               color: approved ? Colors.green : Colors.red, size: 32),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   approved ? 'Request Approved' : 'Request Rejected',
//                   style: GoogleFonts.roboto(
//                       fontWeight: FontWeight.bold,
//                       fontSize: 18,
//                       color: approved
//                           ? Colors.green.shade700
//                           : Colors.red.shade700),
//                 ),
//                 if (!approved && _disapprovalReason != null) ...[
//                   const SizedBox(height: 8),
//                   Text('Reason:',
//                       style: GoogleFonts.roboto(
//                           fontSize: 14,
//                           fontWeight: FontWeight.w600,
//                           color: Colors.grey.shade700)),
//                   const SizedBox(height: 4),
//                   Text(_disapprovalReason!,
//                       style: GoogleFonts.roboto(
//                           fontSize: 14, color: Colors.grey.shade600)),
//                 ],
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ── Certificate card ──────────────────────────────────────────────────────
//   Widget _buildCertificateCard() {
//     return SafeArea(
//       child: Container(
//         margin: const EdgeInsets.only(top: 16),
//         width: double.infinity,
//         padding: const EdgeInsets.all(20),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(16),
//           border: Border.all(color: Colors.cyan.shade300, width: 2),
//           boxShadow: [
//             BoxShadow(
//                 color: Colors.grey.shade200,
//                 blurRadius: 10,
//                 offset: const Offset(0, 4))
//           ],
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Container(
//                   padding: const EdgeInsets.all(8),
//                   decoration: BoxDecoration(
//                     color: Colors.cyan.shade50,
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                   child: const Icon(Icons.picture_as_pdf, color: Colors.cyan, size: 28),
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: Text('Baptism Certificate Generated',
//                       style: GoogleFonts.roboto(
//                           fontSize: 15,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.cyan.shade700)),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 16),
//             Row(
//               children: [
//                 // ── Preview button ────────────────────────────────────────
//                 Expanded(
//                   child: ElevatedButton.icon(
//                     onPressed: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (_) => _CertificatePreviewPage(
//                             pdfBytes: _certificatePdfBytes!,
//                             childName: widget.baptismData['cName'] ?? 'Baptism',
//                             baptismData: widget.baptismData,
//                           ),
//                         ),
//                       );
//                     },
//                     icon: const Icon(Icons.visibility, size: 18),
//                     label: const Text('Preview'),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.cyan,
//                       foregroundColor: Colors.white,
//                       padding: const EdgeInsets.symmetric(vertical: 13),
//                       shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(10)),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 10),
//                 // ── Upload to backend only ────────────────────────────────
//                 Expanded(
//                   child: ElevatedButton.icon(
//                     onPressed: () => _uploadCertificate(
//                       pdfBytes: _certificatePdfBytes!,
//                       ctx: context,
//                     ),
//                     icon: const Icon(Icons.cloud_upload, size: 18),
//                     label: const Text('Upload'),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: const Color.fromARGB(255, 0, 119, 137),
//                       foregroundColor: Colors.white,
//                       padding: const EdgeInsets.symmetric(vertical: 13),
//                       shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(10)),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildActionButtons() {
//     return Column(
//       children: [
//         SizedBox(
//           width: double.infinity,
//           child: ElevatedButton.icon(
//             onPressed: _isLoading
//                 ? null
//                 : () => _showMeetingDialog(
//                     widget.baptismData['nBaptismRequestID']),
//             icon: const Icon(Icons.event, size: 22),
//             label: Text('Schedule Meeting',
//                 style: GoogleFonts.roboto(
//                     fontSize: 16, fontWeight: FontWeight.w600)),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.blue,
//               foregroundColor: Colors.white,
//               padding: const EdgeInsets.symmetric(vertical: 16),
//               shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12)),
//               elevation: 2,
//             ),
//           ),
//         ),
//         const SizedBox(height: 10),
//         Row(
//           children: [
//             Expanded(
//               child: ElevatedButton.icon(
//                 onPressed: _isLoading
//                     ? null
//                     : () async {
//                         setState(() => _isLoading = true);
//                         try {
//                           await approveRequest(
//                               widget.baptismData['nBaptismRequestID']);
//                           final enriched =
//                               Map<String, dynamic>.from(widget.baptismData);
//                           enriched['issueDate'] = _todayFormatted();
//                           final pdfBytes = await _buildCertificatePdf(enriched);
//                           setState(() {
//                             _approvalStatus = 'approved';
//                             _certificatePdfBytes = pdfBytes;
//                             _isLoading = false;
//                           });
//                           ScaffoldMessenger.of(context).showSnackBar(
//                               const SnackBar(
//                                   content: Text('Approved ✓  Certificate is ready!'),
//                                   backgroundColor: Colors.green,
//                                   behavior: SnackBarBehavior.floating));
//                         } catch (e) {
//                           setState(() => _isLoading = false);
//                           ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//                               content: Text('Error: ${e.toString()}'),
//                               backgroundColor: Colors.red,
//                               behavior: SnackBarBehavior.floating));
//                         }
//                       },
//                 icon: const Icon(Icons.check_circle_outline, size: 22),
//                 label: Text('Approve',
//                     style: GoogleFonts.roboto(
//                         fontSize: 16, fontWeight: FontWeight.w600)),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.green,
//                   foregroundColor: Colors.white,
//                   padding: const EdgeInsets.symmetric(vertical: 16),
//                   shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12)),
//                   elevation: 2,
//                 ),
//               ),
//             ),
//             const SizedBox(width: 12),
//             Expanded(
//               child: OutlinedButton.icon(
//                 onPressed: _isLoading
//                     ? null
//                     : () => _showDisapprovalDialog(
//                         widget.baptismData['nBaptismRequestID']),
//                 icon: const Icon(Icons.cancel_outlined, size: 22),
//                 label: Text('Reject',
//                     style: GoogleFonts.roboto(
//                         fontSize: 16, fontWeight: FontWeight.w600)),
//                 style: OutlinedButton.styleFrom(
//                   foregroundColor: Colors.red,
//                   padding: const EdgeInsets.symmetric(vertical: 16),
//                   side: const BorderSide(color: Colors.red, width: 2),
//                   shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12)),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ],
//     );
//   }

//   Widget _buildInfoRow(String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 12),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Expanded(
//             flex: 2,
//             child: Text('$label:',
//                 style: GoogleFonts.roboto(
//                     fontSize: 14,
//                     fontWeight: FontWeight.w500,
//                     color: Colors.grey.shade600)),
//           ),
//           Expanded(
//             flex: 3,
//             child: Text(value,
//                 style: GoogleFonts.roboto(
//                     fontSize: 14,
//                     fontWeight: FontWeight.w600,
//                     color: Colors.black87)),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // ─────────────────────────────────────────────────────────────────────────────
// //  Full-screen certificate preview page
// // ─────────────────────────────────────────────────────────────────────────────
// class _CertificatePreviewPage extends StatefulWidget {
//   final Uint8List pdfBytes;
//   final String childName;
//   final Map<String, dynamic> baptismData;

//   const _CertificatePreviewPage({
//     required this.pdfBytes,
//     required this.childName,
//     required this.baptismData,
//   });

//   @override
//   State<_CertificatePreviewPage> createState() =>
//       _CertificatePreviewPageState();
// }

// class _CertificatePreviewPageState extends State<_CertificatePreviewPage> {
//   // ── Upload only — no external share sheet ────────────────────────────────
//   Future<void> _uploadCertificate() async {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (_) => const Center(child: CircularProgressIndicator()),
//     );

//     try {
//       await _uploadCertificateToBackend();
//       if (Navigator.canPop(context)) Navigator.pop(context);
//       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
//           content: Text('Certificate uploaded successfully'),
//           backgroundColor: Colors.green,
//           behavior: SnackBarBehavior.floating));
//     } catch (e) {
//       if (Navigator.canPop(context)) Navigator.pop(context);
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//           content: Text('Upload failed: ${e.toString()}'),
//           backgroundColor: Colors.red,
//           behavior: SnackBarBehavior.floating));
//     }
//   }

//   Future<void> _uploadCertificateToBackend() async {
//     final prefs = await SharedPreferences.getInstance();
//     final savedToken = prefs.getString('jwt');
//     if (savedToken == null || savedToken.isEmpty) {
//       throw Exception("Token not found. Please login again.");
//     }

//     final tempDir  = await getTemporaryDirectory();
//     final fileName =
//         'Baptism_Certificate_${widget.baptismData['nBaptismRequestID']}.pdf';
//     final tempFile = File('${tempDir.path}/$fileName');
//     await tempFile.writeAsBytes(widget.pdfBytes);

//     final uri = Uri.parse(
//         'https://lv4hfxvb-7000.inc1.devtunnels.ms/sacraments/addbaptismcertificate/');

//     final request = http.MultipartRequest('POST', uri)
//       ..headers['Authorization'] = savedToken
//       ..fields['nBaptismRequestID'] =
//           (widget.baptismData['nBaptismRequestID'] ?? '').toString()
//       ..fields['nDioceseID'] =
//           (widget.baptismData['nDioceseID'] ?? '').toString()
//       ..fields['nParishID'] =
//           (widget.baptismData['nParishID'] ?? '').toString()
//       ..fields['nForaneID'] =
//           (widget.baptismData['nForaneID'] ?? '').toString()
//       ..fields['cApplicationCode'] =
//           (widget.baptismData['cApplicationCode'] ?? '').toString()
//       ..files.add(await http.MultipartFile.fromPath(
//         'cPdfPath',
//         tempFile.path,
//         filename: fileName,
//       ));

//     final streamedResponse = await request.send();
//     final response         = await http.Response.fromStream(streamedResponse);

//     await tempFile.delete();

//     if (response.statusCode != 200 && response.statusCode != 201) {
//       throw Exception(
//           'Upload failed (${response.statusCode}): ${response.body}');
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         backgroundColor: Colors.cyan,
//         title: Text('Certificate',
//             style: GoogleFonts.roboto(
//                 fontSize: 20,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.white)),
//         leading: IconButton(
//             icon: const Icon(Icons.arrow_back, color: Colors.white),
//             onPressed: () => Navigator.pop(context)),
//         actions: [
//           // ── Upload to backend only ──────────────────────────────────────
//           IconButton(
//             tooltip: 'Upload to Server',
//             icon: const Icon(Icons.cloud_upload, color: Colors.white),
//             onPressed: _uploadCertificate,
//           ),
//         ],
//       ),
//       body: PdfPreview(
//         build: (_) => widget.pdfBytes,
//         canChangeOrientation: false,
//         canChangePageFormat: false,
//         canDebug: false,
//         allowPrinting: false,
//         allowSharing: false,
//         pdfFileName: 'Baptism_Certificate_${widget.childName}.pdf',
//         initialPageFormat: PdfPageFormat.a4.landscape,
//         scrollViewDecoration: BoxDecoration(
//           gradient: LinearGradient(
//             colors: [Colors.cyan, const Color(0xFF9EDAE4), Colors.white],
//             begin: Alignment.topLeft,
//             end: Alignment.bottomCenter,
//           ),
//         ),
//       ),
//     );
//   }
// }