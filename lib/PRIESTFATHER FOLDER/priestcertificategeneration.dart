import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:Koottaayma/HTTPURL/httpurl.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';



class PriestCertificateGenerating extends StatefulWidget {
  final Map<String, dynamic>? initialData;

  const PriestCertificateGenerating({
    Key? key,
    this.initialData,
  }) : super(key: key);

  @override
  State<PriestCertificateGenerating> createState() =>
      _PriestCertificateGeneratingState();
}

class _PriestCertificateGeneratingState
    extends State<PriestCertificateGenerating> {
  bool _isFetching = true;
  String? _fetchError;

  //  FIX: Store the FULL list instead of a single map
  List<Map<String, dynamic>> _baptismList = [];

  // Per-record state: generated PDF bytes and UI flags
  final Map<int, Uint8List?> _pdfBytesMap = {};
  final Map<int, bool> _generatingMap = {};
  final Map<int, bool> _showDetailsMap = {};
  final Map<int, GlobalKey> _cardKeys = {};
Uint8List? _certificatePdfBytes;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null && widget.initialData!.isNotEmpty) {
      _baptismList = [widget.initialData!];
      _isFetching = false;
    } else {
      _fetchBaptismDetails();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // ── 1. GET: Fetch baptism request details 
  Future<void> _fetchBaptismDetails() async {
    setState(() {
      _isFetching = true;
      _fetchError = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString('jwt');

      final uri = Uri.parse(BaptisumAllRequestGetPriest);

      final response = await http
          .get(
            uri,
            headers: {
              'Content-Type': 'application/json',
              if (savedToken != null) 'Authorization': ' $savedToken',
            },
          )
          .timeout(const Duration(seconds: 15));

      debugPrint('GET baptism [${response.statusCode}]: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = jsonDecode(response.body);

        // FIX: Parse as a full list; wrap single map in a list
        final List<Map<String, dynamic>> list;
        if (decoded is List) {
          list = decoded.cast<Map<String, dynamic>>();
        } else {
          list = [decoded as Map<String, dynamic>];
        }

        setState(() {
          _baptismList = list;
          _isFetching = false;
        });
      } else {
        throw Exception('Server returned ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isFetching = false;
        _fetchError = 'Failed to load details: ${e.toString()}';
      });
    }
  }

  // ── 2. Generate certificate PDF for a specific record 
  Future<void> _generateCertificate(int index) async {
    final data = _baptismList[index];

    setState(() => _generatingMap[index] = true);

    try {
      final bytes = await _buildCertificatePdf(data);
      setState(() {
        _pdfBytesMap[index] = bytes;
        _generatingMap[index] = false;
      });
      _showSnack('Certificate generated for ${data['cName']}!');
    } catch (e) {
      setState(() => _generatingMap[index] = false);
      _showSnack('Error generating certificate: $e', isError: true);
    }
  }

 //  Upload certificate PDF to backend only (no external share/print)
  
  Future<void> _uploadCertificateToBackend(Uint8List pdfBytes,String baptismRequestID) async {
    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString('jwt');
    if (savedToken == null || savedToken.isEmpty) {
      throw Exception("Token not found. Please login again.");
    }

    final tempDir  = await getTemporaryDirectory();
      final fileName = 'Baptism_Certificate_$baptismRequestID.pdf';
  // ...
 
    final tempFile = File('${tempDir.path}/$fileName');
    await tempFile.writeAsBytes(pdfBytes);

    final uri = Uri.parse(ApproveLetter);

    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = savedToken
      ..fields['nBaptismRequestID'] = baptismRequestID
     // ..fields['nDioceseID'] =
       //   (widget.baptismData['nDioceseID'] ?? '').toString()
    //  ..fields['nParishID'] =
      //    (widget.baptismData['nParishID'] ?? '').toString()
     // ..fields['nForaneID'] =
      //    (widget.baptismData['nForaneID'] ?? '').toString()
     // ..fields['cApplicationCode'] =
        //  (widget.baptismData['cApplicationCode'] ?? '').toString()
     // ..fields['nFileCategoryID'] = '1'   
      ..files.add(await http.MultipartFile.fromPath(
        'cFilePath',
        tempFile.path,
        filename: fileName,
      ));
            // PRINT HEADERS
         print("Headers:");
             request.headers.forEach((key, value) {
              print("$key : $value");
                  });

                // PRINT POST FIELDS
               print("POST Fields:");
              request.fields.forEach((key, value) {
                 print("$key : $value");
                                  });
                                  // PRINT FILE DETAILS
                 print("Files:");
                for (var file in request.files) {
                 print("Field: ${file.field}");
                    print("Filename: ${file.filename}");
                         }

    final streamedResponse = await request.send();
    final response         = await http.Response.fromStream(streamedResponse);

    await tempFile.delete();

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
          'Upload failed (${response.statusCode}): ${response.body}');
    }
  }

  
  //  Upload only — no external share sheet
  
 Future<void> _uploadCertificate({
  required Uint8List pdfBytes,
  required BuildContext ctx,
  required String baptismRequestID,
  required int index,  // ← ADD THIS
}) async {
  showDialog(
    context: ctx,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );

  try {
    await _uploadCertificateToBackend(pdfBytes, baptismRequestID);
    if (Navigator.canPop(ctx)) Navigator.pop(ctx);

    //  Remove the sent record from the list
    setState(() {
      _baptismList.removeAt(index);
      _pdfBytesMap.remove(index);
      _generatingMap.remove(index);
      _showDetailsMap.remove(index);
      _cardKeys.remove(index);
    });

    ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
        content: Text('Certificate uploaded successfully'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating));
  } catch (e) {
    if (Navigator.canPop(ctx)) Navigator.pop(ctx);
    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
        content: Text('Upload failed: ${e.toString()}'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating));
  }
}

  // ── 3. Preview certificate 
  void _previewCertificate(int index) {
    final bytes = _pdfBytesMap[index];
    if (bytes == null) {
      _showSnack('Please generate the certificate first.', isError: true);
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _CertificatePreviewPage(
          pdfBytes: bytes,
          childName: _baptismList[index]['cName'] ?? 'Baptism',
        ),
      ),
    );
  }

  // ── Snack-bar helper 
  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red.shade700 : Colors.teal.shade600,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _toggleDetails(int index) {
    setState(() {
      _showDetailsMap[index] = !(_showDetailsMap[index] ?? false);
    });

    if (_showDetailsMap[index] == true) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final key = _cardKeys[index];
        if (key != null) {
          final ctx = key.currentContext;
          if (ctx != null) {
            Scrollable.ensureVisible(ctx,
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut);
          }
        }
      });
    }
  }

  // ── PDF builder 
  Future<Uint8List> _buildCertificatePdf(Map<String, dynamic> data) async {
    final pdf = pw.Document();

    const PdfColor navy     = PdfColor.fromInt(0xFF2C3E6B);
    const PdfColor brown    = PdfColor.fromInt(0xFF7B5B3A);
    const PdfColor textGrey = PdfColor.fromInt(0xFF555555);
    const PdfColor blue     = PdfColor.fromInt(0xFF3366AA);

    final loraFont       = await PdfGoogleFonts.loraRegular();
    final loraBoldFont   = await PdfGoogleFonts.loraBold();
    final loraItalicFont = await PdfGoogleFonts.loraItalic();

    final bgImageData = await rootBundle.load('assets/certificateimage.jpeg');
    final bgImage = pw.MemoryImage(bgImageData.buffer.asUint8List());

    String val(String key, [String fallback = '']) =>
        (data[key] ?? fallback).toString();

    final childName = val('cName');
    final father    = val('cFatherName');
    final mother    = val('cMotherName');
    final godFather = val('cGodFatherName');
    final godMother = val('cGodMotherName');
    final dob       = val('dDoB');
    final baptDate  = val('dBaptismDate');
    final parish    = val('cParishName');

    const double W = 841.89;
    const double H = 950.00;

    const double fatherX      = W * 0.295;
    const double motherX      = W * 0.705;
    const double parentY      = H * 0.415;
    const double parentLabelY = H * 0.375;
    const double godY         = H * 0.305;
    const double godLabelY    = H * 0.267;
    const double godFatherX   = W * 0.295;
    const double godMotherX   = W * 0.705;
    const double sentenceY    = H * 0.195;
    const double labelRowY    = H * 0.118;
    const double valueRowY    = H * 0.083;
    const double dobX         = W * 0.270;
    const double priestX      = W * 0.500;
    const double churchX      = W * 0.730;
    const double nameY        = H * 0.575;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(W, H),
        margin: pw.EdgeInsets.zero,
        build: (pw.Context ctx) {
          return pw.Stack(
            children: [
              pw.Positioned.fill(
                child: pw.Image(bgImage, fit: pw.BoxFit.fill),
              ),
              pw.Positioned(
                left: 0, right: 0, bottom: nameY + 90,
                child: pw.Text('BAPTISM CERTIFICATE',
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                        font: loraItalicFont, fontSize: 44, color: navy)),
              ),
              pw.Positioned(
                left: 0, right: 0, bottom: nameY - 34,
                child: pw.Text(childName,
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                        font: loraItalicFont, fontSize: 44, color: navy)),
              ),
              pw.Positioned(
                left: fatherX - 120, bottom: parentY - 14,
                child: pw.SizedBox(
                  width: 250,
                  child: pw.Text(father,
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                          font: loraItalicFont, fontSize: 22, color: brown)),
                ),
              ),
              pw.Positioned(
                left: fatherX - 50, bottom: parentLabelY - 8,
                child: pw.SizedBox(
                  width: 100,
                  child: pw.Text('Father',
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                          font: loraItalicFont, fontSize: 10, color: textGrey)),
                ),
              ),
              pw.Positioned(
                left: motherX - 80, bottom: parentY - 14,
                child: pw.SizedBox(
                  width: 160,
                  child: pw.Text(mother,
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                          font: loraItalicFont, fontSize: 22, color: brown)),
                ),
              ),
              pw.Positioned(
                left: motherX - 50, bottom: parentLabelY - 8,
                child: pw.SizedBox(
                  width: 100,
                  child: pw.Text('Mother',
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                          font: loraItalicFont, fontSize: 10, color: textGrey)),
                ),
              ),
              pw.Positioned(
                left: godFatherX - 120, bottom: godY - 14,
                child: pw.SizedBox(
                  width: 250,
                  child: pw.Text(godFather,
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                          font: loraItalicFont, fontSize: 18, color: brown)),
                ),
              ),
              pw.Positioned(
                left: godFatherX - 50, bottom: godLabelY - 8,
                child: pw.SizedBox(
                  width: 100,
                  child: pw.Text('God Father',
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                          font: loraItalicFont, fontSize: 9, color: textGrey)),
                ),
              ),
              pw.Positioned(
                left: godMotherX - 80, bottom: godY - 14,
                child: pw.SizedBox(
                  width: 160,
                  child: pw.Text(godMother,
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                          font: loraItalicFont, fontSize: 18, color: brown)),
                ),
              ),
              pw.Positioned(
                left: godMotherX - 50, bottom: godLabelY - 8,
                child: pw.SizedBox(
                  width: 100,
                  child: pw.Text('God Mother',
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                          font: loraItalicFont, fontSize: 9, color: textGrey)),
                ),
              ),
              pw.Positioned(
                left: 80, right: 80, bottom: sentenceY - 8,
                child: pw.Text(
                 'was received into church fellowship by water baptism on March 5, 2026.'
                  '${DateFormat('d-MMM-yyyy').format(DateTime.parse(baptDate))}.',
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                      font: loraFont, fontSize: 11.5, color: navy),
                ),
              ),
              pw.Positioned(
                left: dobX - 60, bottom: labelRowY,
                child: pw.SizedBox(
                  width: 120,
                  child: pw.Text('DATE OF BIRTH:',
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                          font: loraBoldFont,
                          fontSize: 8,
                          color: navy,
                          letterSpacing: 0.8)),
                ),
              ),
              pw.Positioned(
                left: dobX - 60, bottom: valueRowY,
                child: pw.SizedBox(
                  width: 120,
                  child: pw.Text(
                      DateFormat('d-MMM-yyyy').format(DateTime.parse(dob)),
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                          font: loraFont, fontSize: 10, color: navy)),
                ),
              ),
              pw.Positioned(
                left: priestX - 70, bottom: labelRowY,
                child: pw.SizedBox(
                  width: 140,
                  child: pw.Text('PRIEST NAME',
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                          font: loraBoldFont,
                          fontSize: 8,
                          color: navy,
                          letterSpacing: 0.8)),
                ),
              ),
              pw.Positioned(
                left: priestX - 70, bottom: valueRowY,
                child: pw.SizedBox(
                  width: 140,
                  child: pw.Text('Fr. Parish Priest',
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                          font: loraFont, fontSize: 10, color: blue)),
                ),
              ),
              pw.Positioned(
                left: churchX - 80, bottom: labelRowY,
                child: pw.SizedBox(
                  width: 160,
                  child: pw.Text('CHURCH NAME',
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                          font: loraBoldFont,
                          fontSize: 8,
                          color: navy,
                          letterSpacing: 0.8)),
                ),
              ),
              pw.Positioned(
                left: churchX - 80, bottom: valueRowY,
                child: pw.SizedBox(
                  width: 160,
                  child: pw.Text(parish,
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                          font: loraFont, fontSize: 10, color: blue)),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  // ── BUILD ─
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.cyan,
        automaticallyImplyLeading: false,
        elevation: 0,
        title: Center(
          child: Text(
            'Certificates',
            style: GoogleFonts.roboto(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500),
          ),
        ),
       
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _isFetching ? null : _fetchBaptismDetails,
          ),
        ],
      ),
      body: _isFetching
          ? const Center(child: CircularProgressIndicator())
          : _fetchError != null
              ? _buildErrorState()
              : _baptismList.isEmpty
                  ? Center(
                      child: Text('No baptism requests found.',
                          style: GoogleFonts.roboto(
                              fontSize: 14, color: Colors.grey.shade600)),
                    )
                  : SingleChildScrollView(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // ✅ FIX: Render ALL records, one card per item
                          ...List.generate(_baptismList.length, (i) {
                            _cardKeys.putIfAbsent(i, () => GlobalKey());
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 20),
                              child: _buildRecordSection(i),
                            );
                          }),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
    );
  }

  // ── One full section per baptism record 
  Widget _buildRecordSection(int index) {
    final data = _baptismList[index];
    final isGenerating = _generatingMap[index] ?? false;
    final pdfBytes = _pdfBytesMap[index];
    final showDetails = _showDetailsMap[index] ?? false;

    return Column(
      children: [
        _buildSummaryCard(index, data, isGenerating),
        const SizedBox(height: 12),
        _buildActionButtons(index, isGenerating, pdfBytes),
        if (showDetails) ...[
          const SizedBox(height: 12),
          _buildInfoCard(index, data),
        ],
        if (pdfBytes != null) ...[
          const SizedBox(height: 12),
          _buildCertificateCard(index, data, pdfBytes),
        ],
      ],
    );
  }

  // ── Error state
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 60, color: Colors.red.shade400),
            const SizedBox(height: 16),
            Text(
              _fetchError!,
              textAlign: TextAlign.center,
              style: GoogleFonts.roboto(
                  fontSize: 14, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _fetchBaptismDetails,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyan,
                  foregroundColor: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  // ── Summary card 
  Widget _buildSummaryCard(
      int index, Map<String, dynamic> data, bool isGenerating) {
    final showDetails = _showDetailsMap[index] ?? false;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.cyan.withOpacity(0.1),
            Colors.blue.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.cyan.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child:
                    Icon(Icons.child_care, color: Colors.cyan[700], size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            data['cName'] ?? 'N/A',
                            style: GoogleFonts.roboto(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87),
                          ),
                        ),
                        Text(
                          data['cApplicationCode'] ?? '',
                          style: GoogleFonts.roboto(
                              fontSize: 12,
                              color: Colors.cyan[700],
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Father: ${data['cFatherName'] ?? 'N/A'}',
                      style: GoogleFonts.roboto(
                          fontSize: 12, color: Colors.grey.shade700),
                    ),
                    Text(
                      'Mother: ${data['cMotherName'] ?? 'N/A'}',
                      style: GoogleFonts.roboto(
                          fontSize: 12, color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.cyan[700],
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.cyan.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.calendar_today,
                        size: 12, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      data['dBaptismDate'] != null ? DateFormat('d MMM yyyy').format(DateTime.parse(data['dDoB']))  :  'N/A',
                      style: GoogleFonts.roboto(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => _toggleDetails(index),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.cyan[700],
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.cyan.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    showDetails ? 'Hide Details' : 'View Details',
                    style: GoogleFonts.roboto(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Full info card 
  Widget _buildInfoCard(int index, Map<String, dynamic> data) {
    return Container(
      key: _cardKeys[index],
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.shade300,
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Applicant Information',
              style: GoogleFonts.roboto(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.cyan.shade700),
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Baby Name',        data['cName']            ?? 'N/A'),
            _buildInfoRow('Gender',           data['cGenderName']      ?? 'N/A'),
            _buildInfoRow( 'Date of Birth', data['dDoB'] != null? DateFormat('d MMM yyyy').format(DateTime.parse(data['dDoB']))  : 'N/A',),
            _buildInfoRow('Baptism Date',     data['dBaptismDate'] !=null ? DateFormat('d MMM yyyy').format(DateTime.parse(data['dBaptismDate'])) :     'N/A'),
            const Divider(height: 20, thickness: 1),
            _buildInfoRow('God Father',       data['cGodFatherName']   ?? 'N/A'),
            _buildInfoRow('God Mother',       data['cGodMotherName']   ?? 'N/A'),
            const Divider(height: 20, thickness: 1),
            _buildInfoRow('Father',           data['cFatherName']      ?? 'N/A'),
            _buildInfoRow('Mother',           data['cMotherName']      ?? 'N/A'),
            const Divider(height: 20, thickness: 1),
            _buildInfoRow('Family Unit',      data['cFamilyUnitName']  ?? 'N/A'),
            _buildInfoRow('Family Number',    data['cFamilyNo']        ?? 'N/A'),
            const Divider(height: 20, thickness: 1),
            _buildInfoRow('Diocese',          data['cDioceseName']     ?? 'N/A'),
            _buildInfoRow('Forane',           data['cForaneName']      ?? 'N/A'),
            _buildInfoRow('Parish',           data['cParishName']      ?? 'N/A'),
            _buildInfoRow('Ward',             data['cWardName']        ?? 'N/A'),
            _buildInfoRow('Application Code', data['cApplicationCode'] ?? 'N/A'),
          ],
        ),
      ),
    );
  }

  // ── Action buttons 
  Widget _buildActionButtons(
      int index, bool isGenerating, Uint8List? pdfBytes) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: isGenerating ? null : () => _generateCertificate(index),
            icon: isGenerating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.picture_as_pdf, size: 20),
            label: Text(
              isGenerating
                  ? 'Generating…'
                  : pdfBytes == null
                      ? 'Generate Certificate'
                      : 'Regenerate Certificate',
              style: GoogleFonts.roboto(
                  fontSize: 15, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.cyan.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: (pdfBytes == null || isGenerating)
                ? null
                : () => _previewCertificate(index),
            icon: const Icon(Icons.visibility, size: 18),
            label: Text('Preview',
                style: GoogleFonts.roboto(fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.shade300,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  // ── Certificate ready card 
  Widget _buildCertificateCard(
      int index, Map<String, dynamic> data, Uint8List pdfBytes) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.cyan.shade300, width: 2),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.teal, size: 24),
              const SizedBox(width: 8),
              Text(
                'Certificate Ready',
                style: GoogleFonts.roboto(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal.shade700),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'The baptism certificate for ${data['cName'] ?? 'the applicant'} '
            'has been generated.',
            style:
                GoogleFonts.roboto(fontSize: 13, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
        onPressed: () => _uploadCertificate(
  pdfBytes: pdfBytes,
  ctx: context,
  baptismRequestID: (data['nBaptismRequestID'] ?? '').toString(),
  index: index,  // ← ADD THIS
),

              //  async {
              //   await Printing.sharePdf(
              //     bytes: pdfBytes,
              //     filename:
              //         'Baptism_Certificate_${data['cName'] ?? 'Certificate'}.pdf',
              //   );
              // },
             // icon: const Icon(Icons.share, size: 18),
              label: Text('Send',
                  style: GoogleFonts.roboto(fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.cyan.shade700,
                side: BorderSide(color: Colors.cyan.shade400),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Info row helper 
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              '$label:',
              style: GoogleFonts.roboto(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: GoogleFonts.roboto(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Certificate preview page 
class _CertificatePreviewPage extends StatelessWidget {
  final Uint8List pdfBytes;
  final String childName;

  const _CertificatePreviewPage({
    required this.pdfBytes,
    required this.childName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.cyan,
        title: Text(
          'Certificate – $childName',
          style: GoogleFonts.roboto(color: Colors.white, fontSize: 16),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            tooltip: 'Share / Print',
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () async {
              await Printing.sharePdf(
                bytes: pdfBytes,
                filename: 'Baptism_Certificate_$childName.pdf',
              );
            },
          ),
        ],
      ),
      body: PdfPreview(
        build: (_) => pdfBytes,
      canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
        allowPrinting: false,
        allowSharing: false,
        pdfFileName: 'Baptism_Certificate_${childName}.pdf',
        initialPageFormat: PdfPageFormat.a4.landscape,
        scrollViewDecoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.cyan, const Color(0xFF9EDAE4), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomCenter,
          ),
        ),
      ),
    );
  }
}