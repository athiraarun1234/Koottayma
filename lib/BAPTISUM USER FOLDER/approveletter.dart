import 'dart:async';
import 'dart:io';

import 'package:Koottaayma/HTTPURL/httpurl.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApprovelLetterpdf extends StatefulWidget {
  const ApprovelLetterpdf({super.key});

  @override
  State<ApprovelLetterpdf> createState() => _ApprovelLetterpdfState();
}

class _ApprovelLetterpdfState extends State<ApprovelLetterpdf> {
  List<Map<String, dynamic>> _certificates = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Per-card download tracking
  Map<int, bool> _isDownloading = {};
  Map<int, double> _downloadProgress = {};

  

  @override
  void initState() {
    super.initState();
    _fetchCertificates();
  }

Future<void> _fetchCertificates() async {
  setState(() {
    _isLoading = true;
    _errorMessage = null;
  });

  final prefs = await SharedPreferences.getInstance();
  final savedToken = prefs.getString('jwt');

  if (savedToken == null || savedToken.isEmpty) {
    setState(() {
      _errorMessage = 'Session not found. Please log in again.';
      _isLoading = false;
    });
    return;
  }
  try {
    final response = await http
        .get(
          Uri.parse(ApproveLetter),
          headers: {
            'Authorization': '$savedToken',
            'Content-Type': 'application/json',
          },
        )
        .timeout(const Duration(seconds: 15));

    print('STATUS: ${response.statusCode}');
    print('BODY: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (response.body.isEmpty) {
        setState(() {
          _certificates = [];
          _isLoading = false;
        });
        return;
      }

      dynamic decoded;
      try {
        decoded = jsonDecode(response.body);
        print('DECODED TYPE: ${decoded.runtimeType}');
      } catch (e) {
        setState(() {
          _errorMessage = 'Failed to parse server response.';
          _isLoading = false;
        });
        return;
      }

      List<dynamic> data = [];

      // Parse different response structures
      if (decoded is List) {
        // If response is directly an array
        data = decoded;
      } else if (decoded is Map) {
        // Check if it's wrapped in a data property
        if (decoded.containsKey('data') && decoded['data'] is List) {
          data = decoded['data'];
        } 
        // Check if it's wrapped in a certificates property
        else if (decoded.containsKey('certificates') && decoded['certificates'] is List) {
          data = decoded['certificates'];
        }
        // Check if it's wrapped in a result property
        else if (decoded.containsKey('result') && decoded['result'] is List) {
          data = decoded['result'];
        }
        // If it's a single object wrapped in a map
        else {
          // Try to find any list value
          for (var value in decoded.values) {
            if (value is List) {
              data = value;
              break;
            }
          }
        }
      }

      print('PARSED COUNT: ${data.length}');

      if (data.isEmpty) {
        setState(() {
          _certificates = [];
          _isLoading = false;
        });
        return;
      }

      //  FIX: Properly convert to List<Map<String, dynamic>>
      setState(() {
        _certificates = data.map<Map<String, dynamic>>((e) {
          if (e is Map) {
            // Convert each map to have String keys
            return Map<String, dynamic>.from(e);
          }
          return <String, dynamic>{};
        }).toList();
        
        _isLoading = false;
      });
      
      print('CERTIFICATES LOADED: ${_certificates.length}');
    } else if (response.statusCode == 401) {
      setState(() {
        _errorMessage = 'Session expired. Please log in again.';
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMessage =
            'Server error: ${response.statusCode}. Please try again.';
        _isLoading = false;
      });
    }
  } on TimeoutException {
    setState(() {
      _errorMessage = 'Request timed out. Check your connection.';
      _isLoading = false;
    });
  } on SocketException {
    setState(() {
      _errorMessage = 'No internet connection.';
      _isLoading = false;
    });
  } catch (e) {
    print('ERROR: $e');
    setState(() {
      _errorMessage = 'Something went wrong: $e';
      _isLoading = false;
    });
  }
}

  // ── Download PDF ──
  Future<void> _downloadPdf(int certId, String pdfUrl) async {
    if (pdfUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PDF not available for this certificate.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isDownloading[certId] = true;
      _downloadProgress[certId] = 0.0;
    });

    try {
      final dir = await getApplicationDocumentsDirectory();
      final fileName = 'Baptism_Certificate_$certId.pdf';
      final savePath = '${dir.path}/$fileName';

      final dio = Dio();
      await dio.download(
        pdfUrl,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() {
              _downloadProgress[certId] = received / total;
            });
          }
        },
      );

      setState(() {
        _isDownloading[certId] = false;
        _downloadProgress[certId] = 1.0;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Download complete! Tap to open.'),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'Open',
            textColor: Colors.white,
            onPressed: () => OpenFilex.open(savePath),
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _isDownloading[certId] = false;
        _downloadProgress[certId] = 0.0;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Download failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // // ── Determine Status from cPdfPath ──
  // String _getStatus(String pdfPath) {
  //   if (pdfPath.isEmpty) return 'Not Ready';
  //   // Check if the URL is valid
  //   if (pdfPath.startsWith('http')) return 'Ready';
  //   return 'Not Ready';
  // }
  String _getStatus(String pdfPath) {
  if (pdfPath.isEmpty) return 'Not Ready';
  if (pdfPath.startsWith('http') || pdfPath.startsWith('/')) return 'Ready'; //  allow relative paths
  return 'Not Ready';
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.cyan,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Download Your Certificates',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchCertificates,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.cyan, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Loading certificates...',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 56),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 15),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _fetchCertificates,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.cyan,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_certificates.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_off_outlined, color: Colors.white, size: 56),
            SizedBox(height: 16),
            Text(
              'No certificates found.',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: ListView.separated(
        itemCount: _certificates.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          return _buildCertificateCard(_certificates[index]);
        },
      ),
    );
  }

  // ── Certificate Card ──
  Widget _buildCertificateCard(Map<String, dynamic> cert) {
   
    final int certId = cert['nBaptismCertificateID'] ?? 0;
    final String rawPath = cert['cFilePath']?.toString() ?? '';  
    final String pdfPath = rawPath.startsWith('http')
    ? rawPath
    : rawPath.isNotEmpty
        ? '$baseUrl$rawPath'  
        : '';
    final String appCode = cert['cApplicationCode']?.toString() ?? 'N/A';
    final String status = _getStatus(rawPath);

    final bool downloading = _isDownloading[certId] ?? false;
    final double progress = _downloadProgress[certId] ?? 0.0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ── Header Row ──
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.cyan.shade700.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.church,
                    color: Colors.cyan.shade700,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Baptism Certificate',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 3),
                      // Text(
                      //   'Application: $appCode',
                      //   style: TextStyle(
                      //     fontSize: 13,
                      //     color: Colors.grey.shade600,
                      //   ),
                      // ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(Icons.badge_outlined,
                              size: 12, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text(
                            'Application ID: $certId',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(status),
              ],
            ),

            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // ── Progress Bar (while downloading) ──
            if (downloading) ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Downloading...',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.cyan,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${(progress * 100).toInt()}%',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.cyan,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: Colors.cyan.shade50,
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(Colors.cyan),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ],

            // ── Footer Row ──
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.picture_as_pdf,
                          color: Colors.red.shade400, size: 16),
                      const SizedBox(width: 5),
                      Text(
                        'PDF',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red.shade400,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  pdfPath.isNotEmpty ? 'Available' : 'Pending',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
                const Spacer(),

                // ── Download Button ──
                ElevatedButton.icon(
                  onPressed: (status == 'Ready' && !downloading)
                      ? () => _downloadPdf(certId, pdfPath)
                      : null,
                  icon: downloading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.download_rounded, size: 18),
                  label: Text(
                    downloading
                        ? 'Downloading'
                        : status == 'Ready'
                            ? 'Download'
                            : 'Not Ready',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: status == 'Ready' && !downloading
                        ? Colors.cyan
                        : Colors.grey.shade300,
                    foregroundColor:
                        status == 'Ready' ? Colors.white : Colors.grey,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Status Badge ──
  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    IconData icon;

    switch (status) {
      case 'Not Ready':
        bgColor = Colors.red.shade50;
        textColor = Colors.red.shade700;
        icon = Icons.cancel_outlined;
        break;
      case 'Ready':
        bgColor = Colors.green.shade50;
        textColor = Colors.green.shade700;
        icon = Icons.check_circle_outline;
        break;
      case 'Processing':
        bgColor = Colors.blue.shade50;
        textColor = Colors.blue.shade700;
        icon = Icons.sync;
        break;
      default:
        bgColor = Colors.orange.shade50;
        textColor = Colors.orange.shade700;
        icon = Icons.hourglass_empty;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: textColor),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              fontSize: 12,
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}