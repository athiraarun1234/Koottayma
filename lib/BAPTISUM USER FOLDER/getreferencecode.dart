import 'dart:convert';
import 'package:Koottaayma/BAPTISUM%20USER%20FOLDER/documentuploading.dart';
import 'package:Koottaayma/HTTPURL/httpurl.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart'; 

// Model 

class Documentaionmodel {
  String cApplicationCode;
  String nFamilyMasterID;
  String nApplicationType;
  String nBaptismRequestID;

  Documentaionmodel({
    required this.cApplicationCode,
    required this.nFamilyMasterID,
    required this.nApplicationType,
    required this.nBaptismRequestID,
    });

  factory Documentaionmodel.fromJson(Map<String, dynamic> json) {
  return Documentaionmodel(
    cApplicationCode: json['cApplicationCode']?.toString() ?? '',
    nFamilyMasterID: json['nFamilyMasterID']?.toString() ?? '',
    nApplicationType: json['nApplicationType']?.toString() ?? '',
    nBaptismRequestID:json['nBaptismRequestID']?.toString() ?? '',
  );
}
  Map<String, dynamic> toJson() {
    return {'cApplicationCode': cApplicationCode};
  }
}

//  API Service 

class DocumentationService {


  static Future<List<Documentaionmodel>> fetchApplicationCodes({
    required String phoneNumber,
    String? savedToken,
  }) async {
    try {
      final response = await http.post(
        Uri.parse( BaptisumReferenceCode),
        headers: {
          'Content-Type': 'application/json',
          if (savedToken != null) 'Authorization': '$savedToken',
        },
        body: jsonEncode({
          'nPhoneNo': phoneNumber,
        }),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Connection timeout. Please try again.');
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        var responseData = jsonDecode(response.body);
        List<dynamic> requests = [];

        if (responseData is List) {
          requests = responseData;
        } else if (responseData is Map) {
          requests = responseData['data'] ?? [responseData];
        }

        return requests
            .map((item) =>
                Documentaionmodel.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } on http.ClientException catch (e) {
      print('Network error: $e');
      throw Exception('Network error. Check your connection.');
    } catch (e) {
      print('Error fetching data: $e');
      throw Exception('Failed to load data: ${e.toString()}');
    }
  }
}


class DocumentaionUploading extends StatefulWidget {
  const DocumentaionUploading({super.key});

  @override
  State<DocumentaionUploading> createState() => _DocumentaionUploadingState();
}

class _DocumentaionUploadingState extends State<DocumentaionUploading> {
  List<Documentaionmodel> _applicationList = [];
  bool _isLoading = false;
  bool _isLoadingFromBackend = false;
  String? _errorMessage;
  String? _savedToken;
  String _phoneNumber = '';

  @override
  void initState() {
    super.initState();
    _loadTokenAndFetch();
  }

  // ── Load token from SharedPreferences then fetch
  Future<void> _loadTokenAndFetch() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _savedToken = prefs.getString('jwt');     
      _phoneNumber = prefs.getString('userPhone') ?? ''; 
      print('Token: $_savedToken');
      print('Phone: $_phoneNumber');
    } catch (e) {
      print('Error loading prefs: $e');
    }

    await _fetchData();
  }

  // ── Fetch from API 
  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _isLoadingFromBackend = true;
      _errorMessage = null;
    });

    try {
      final data = await DocumentationService.fetchApplicationCodes(
        phoneNumber: _phoneNumber,
        savedToken: _savedToken,
      );

      setState(() {
        _applicationList = data;
      });

      print('Loaded ${_applicationList.length} application codes');
    } on Exception catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
      print('Fetch error: $e');
    } finally {
      setState(() {
        _isLoading = false;
        _isLoadingFromBackend = false;
      });
    }
  }

  // ─── Build 
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
          'Documentation Uploading',
          style: GoogleFonts.roboto(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          // Show loading spinner in AppBar while backend is loading
          if (_isLoadingFromBackend)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _fetchData,
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Application Codes',
              style: GoogleFonts.roboto(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            // ── States 
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    // Loading state
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.cyan),
      );
    }

    // Error state
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 12),
            Text(
              'Something went wrong',
              style: GoogleFonts.roboto(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: GoogleFonts.roboto(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _fetchData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan),
            ),
          ],
        ),
      );
    }

    // Empty state
    if (_applicationList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inbox, color: Colors.grey, size: 48),
            const SizedBox(height: 12),
            Text(
              'No application codes found.',
              style: GoogleFonts.roboto(fontSize: 15, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // Success state — list of buttons
    return ListView.builder(
      itemCount: _applicationList.length,
      itemBuilder: (context, index) {
        final doc = _applicationList[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.cyan,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 3,
            ),
            onPressed: () {
              Navigator.push(context,MaterialPageRoute(builder: (context) =>UserMediaUploadFiles(
                cApplicationCode: doc.cApplicationCode,
                 nFamilyMasterID: doc.nFamilyMasterID,
                  nApplicationType: doc.nApplicationType,
                  nBaptismRequestID:doc.nBaptismRequestID) ,));
            },
            child: Text(
              doc.cApplicationCode,
              style: GoogleFonts.roboto(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      },
    );
  }
}