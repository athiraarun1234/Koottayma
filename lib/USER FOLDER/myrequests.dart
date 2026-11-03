import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:Koottaayma/HTTPURL/httpurl.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Baptisumgetdetails extends StatefulWidget {
  final Map<String, dynamic> baptismData;
  final Map<String, dynamic> dailyRequest;
  const Baptisumgetdetails({Key? key, required this.baptismData, required this.dailyRequest}) : super(key: key);

  @override
  State<Baptisumgetdetails> createState() => _BaptisumgetdetailsState();
}

class _BaptisumgetdetailsState extends State<Baptisumgetdetails> {
  bool isLoading = true;
  String errorMessage = '';
  List<dynamic> baptismRequests = [];
  List<dynamic> dailyRequests = [];
  bool isLoadingFromBackend = false;
  
  @override
  void initState() {
    super.initState();
    fetchAllRequests();
  }

  Future<void> fetchAllRequests() async {
  await fetchBaptismDetails(); //  single call handles everything
}

  
  Future<void> fetchBaptismDetails() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? phoneNumber = prefs.getString('userPhone');
      String? savedToken = prefs.getString('jwt');
      
      if (phoneNumber == null) {
        setState(() {
          isLoading = false;
          errorMessage = 'Phone number not found. Please login again.';
        });
        return;
      }
      
      if (savedToken == null) {
        setState(() {
          isLoading = false;
          errorMessage = 'Authentication token not found. Please login again.';
        });
        return;
      }
      
      await _fetchFromBackend(phoneNumber, savedToken);
    } catch (e) {
      print('Error in fetchBaptismDetails: $e');
      setState(() {
        isLoading = false;
        errorMessage = 'Error: ${e.toString()}';
      });
    }
  }

Future<void> _fetchFromBackend(String phoneNumber, String? savedToken) async {
  setState(() {
    isLoadingFromBackend = true;
  });

  try {
    var response = await http.post(
      Uri.parse(GetBaptisumRequestData),
      headers: {
        'Content-Type': 'application/json',
        if (savedToken != null) 'Authorization': '$savedToken',
      },
      body: jsonEncode({
        'nPhoneNo': phoneNumber,
      }),
    ).timeout(
      const Duration(seconds: 15),
      onTimeout: () => throw Exception('Connection timeout'),
    );

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      var responseData = jsonDecode(response.body);

      List<dynamic> allData = responseData is List ? responseData : [responseData];

      //  Split into baptism and daily requests based on key presence
      List<dynamic> baptism = allData
          .where((item) => item.containsKey('nBaptismRequestID'))
          .toList();

      List<dynamic> daily = allData
          .where((item) => item.containsKey('nMemberRequestID'))
          .toList();

      setState(() {
        baptismRequests = baptism;
        dailyRequests = daily;
        isLoading = false;
        isLoadingFromBackend = false;
      });

      print('Baptism: ${baptismRequests.length}, Daily: ${dailyRequests.length}');
    } else {
      throw Exception('Server error: ${response.statusCode}');
    }
  } on http.ClientException catch (e) {
    setState(() {
      isLoading = false;
      isLoadingFromBackend = false;
      errorMessage = 'Network error. Check your connection.';
    });
    print('Network error: $e');
  } catch (e) {
    setState(() {
      isLoading = false;
      isLoadingFromBackend = false;
      errorMessage = 'Failed to load data: ${e.toString()}';
    });
    print('Error: $e');
  }
}

  String _getValue(Map<String, dynamic> data, String key) {
    var value = data[key];
    if (value == null || value.toString().isEmpty) return 'N/A';
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.cyan,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'My Requests',
          style: GoogleFonts.roboto(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.cyan),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading requests...',
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            )
          : errorMessage.isNotEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.error_outline,
                            size: 60,
                            color: Colors.red.shade400,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Oops!',
                          style: GoogleFonts.roboto(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          errorMessage,
                          style: GoogleFonts.roboto(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton.icon(
                          onPressed: fetchAllRequests,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Try Again'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.cyan,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : (baptismRequests.isEmpty && dailyRequests.isEmpty)
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 80,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No Requests',
                            style: GoogleFonts.roboto(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'You don\'t have any requests yet',
                            style: GoogleFonts.roboto(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: fetchAllRequests,
                      color: Colors.cyan,
                      child: SafeArea(
                        child: ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            // Baptism Requests Section
                            if (baptismRequests.isNotEmpty) ...[
                              _buildSectionHeader('Baptism Requests', Icons.water_drop, baptismRequests.length),
                              const SizedBox(height: 12),
                              ...baptismRequests.asMap().entries.map((entry) {
                                return _buildBaptismCard(entry.value as Map<String, dynamic>, entry.key);
                              }).toList(),
                              const SizedBox(height: 24),
                            ],
                            
                            // Daily Requests Section
                            if (dailyRequests.isNotEmpty) ...[
                              _buildSectionHeader('Daily Requests', Icons.church, dailyRequests.length),
                              const SizedBox(height: 12),
                              ...dailyRequests.asMap().entries.map((entry) {
                                return _buildDailyRequestCard(entry.value as Map<String, dynamic>, entry.key);
                              }).toList(),
                            ],
                          ],
                        ),
                      ),
                    ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.cyan.shade700,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Text(
            title,
            style: GoogleFonts.roboto(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildBaptismCard(Map<String, dynamic> request, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.cyan.shade50, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.cyan.shade100, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.cyan.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.cyan,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.child_care,
                    color: Colors.white,
                    size: 15,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _getValue(request, 'cName'),
                          style: GoogleFonts.roboto(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.cyan.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                         // _getValue(request, 'cGenderName'),
                         _getValue(request, 'cApplicationCode'),
                          style: GoogleFonts.roboto(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.cyan.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),

            _buildDetailRow(
              Icons.cake,
              'Date of Birth',
              _getValue(request, 'dDoB'),
              Colors.pink.shade400,
            ),
            const SizedBox(height: 10),
            _buildDetailRow(
              Icons.water_drop,
              'Baptism Date',
              _getValue(request, 'dBaptismDate'),
              Colors.blue.shade400,
            ),
            const SizedBox(height: 10),
            _buildDetailRow(
              Icons.family_restroom,
              'Parents',
              '${_getValue(request, 'cFatherName')} & ${_getValue(request, 'cMotherName')}',
              Colors.green.shade400,
            ),
            const SizedBox(height: 10),
            _buildDetailRow(
              Icons.people,
              'God Parents',
              '${_getValue(request, 'cGodFatherName')} & ${_getValue(request, 'cGodMotherName')}',
              Colors.orange.shade400,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyRequestCard(Map<String, dynamic> request, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade50, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.purple.shade100, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const SizedBox(width: 12),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _getValue(request, 'cSacramentsCategory'),
                        style: GoogleFonts.roboto(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),

                      Text(_getValue(request, 'cApplicationCode'),
                      style: GoogleFonts.roboto(
                        fontSize: 12,fontWeight:FontWeight.bold,
                        color: Colors.grey.shade800
                      ),
                      )
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            _buildDetailRow(
              Icons.calendar_today,
              'Date & Time',
              _getValue(request, 'dDateTime'),
              Colors.blue.shade400,
            ),
            const SizedBox(height: 10),
            _buildDetailRow(
              Icons.category,
              'Category',
              _getValue(request, 'cSacramentsCategory'),
              Colors.purple.shade400,
            ),
          

          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.roboto(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  color: Colors.grey.shade800,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}