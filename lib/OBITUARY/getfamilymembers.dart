import 'dart:convert';

import 'package:Koottaayma/HTTPURL/httpurl.dart';
import 'package:Koottaayma/OBITUARY/imageuploading.dart';
import 'package:Koottaayma/SQFLITEVERSION1/PhoneNumberField.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';


class FamilyMember {
  final String cName;
  final String nFamilyMemberID;
  final  String nFamilyMasterID;
  
  FamilyMember({required this.cName,
  required this.nFamilyMemberID,
  required this.nFamilyMasterID
  });

  factory FamilyMember.fromJson(Map<String, dynamic> json) {
    return FamilyMember(
      cName: json['cName'] ?? '',
      nFamilyMemberID: json['nFamilyMemberID']?.toString() ?? '',
      nFamilyMasterID: json['nFamilyMasterID']?.toString() ?? '',
   );
  }
 
}

class ObituaryMemberDetails extends StatefulWidget {
  const ObituaryMemberDetails({super.key});

  @override
  State<ObituaryMemberDetails> createState() => _ObituaryMemberDetailsState();
}

class _ObituaryMemberDetailsState extends State<ObituaryMemberDetails> {
  int? languageId;
  bool _isLoading = false;
  bool _isLoadingFromBackend = false;
  String? _errorMessage;
  String? _savedToken;
  String _phoneNumber = '';

  // ── Typed list using FamilyMember model
 late List<FamilyMember> _applicationList;


  @override
  void initState() {
    super.initState();
     _applicationList = [];
    _loadTokenAndFetch();
  }

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

Future<void> _fetchData() async {
  setState(() {
    _isLoading = true;
    _isLoadingFromBackend = true;
    _errorMessage = null;
  });

  try {
    final uri = Uri.parse( GetFamilyMembersOnly);

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': '$_savedToken',
      },
      body: jsonEncode({
        'nPhoneNo': _phoneNumber, 
      }),
    );

    print('Status: ${response.statusCode}');
    print('Body: ${response.body}');

    if (response.statusCode == 200||response.statusCode == 201) {
      final List<dynamic> jsonList = jsonDecode(response.body);

      setState(() {
        _applicationList = jsonList
            .map((item) => FamilyMember.fromJson(item as Map<String, dynamic>))
            .toList();
      });

      print('Loaded ${_applicationList.length} family members');
  
    }
     else if (response.statusCode == 401 ||
               response.statusCode == 403 ||
               response.statusCode == 417) {
      // Redirect to PhoneNumber page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PhoneNumber(
            languageId: languageId ?? 0,
            phoneNumber: 0,
            nUserTypeID: 0,
          ),
        ),
      );
    }
     else {
      setState(() {
        _errorMessage = 'Server error: ${response.statusCode}';
      });
    }
  } catch (e) {
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
          'Family Members',
          style: GoogleFonts.roboto(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
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
              'Family Members',
              style: GoogleFonts.roboto(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.cyan));
    }

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
                  color: Colors.red),
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

    if (_applicationList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inbox, color: Colors.grey, size: 48),
            const SizedBox(height: 12),
            Text(
              'No family members found.',
              style: GoogleFonts.roboto(fontSize: 15, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _applicationList.length,
      itemBuilder: (context, index) {
        final member = _applicationList[index];
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
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Obituaryimageuploading(
                   nFamilyMemberID:member.nFamilyMemberID,
                   nFamilyMasterID:member.nFamilyMasterID, 
                  ),
                ),
              );
            },
            // ── Display cName instead of cApplicationCode
            child: Text(
              member.cName,
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
