//connect pageimport 'dart:async';
import 'dart:async';
import 'dart:convert';
import 'package:Koottaayma/HTTPURL/httpurl.dart';
import 'package:Koottaayma/SQFLITEVERSION1/DataBaseHelper.dart';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class ParishDetailsModel {
  final int nChurchMasterID;
  final int nParishID;
  final String cParishName;
  final String cChurchName;

  ParishDetailsModel({
    required this.nChurchMasterID,
    required this.nParishID,
    required this.cParishName,
    required this.cChurchName,
  });

  factory ParishDetailsModel.fromJson(Map<String, dynamic> json) {
    return ParishDetailsModel(
      nChurchMasterID: json['nChurchMasterID'],
      nParishID: json['nParishID'],
      cParishName: json['cParishName'],
      cChurchName: json['cChurchName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nChurchMasterID': nChurchMasterID,
      'nParishID': nParishID,
      'cParishName': cParishName,
      'cChurchName': cChurchName,
    };
  }
}

class ConnectPage extends StatefulWidget {
  const ConnectPage({super.key});

  @override
  State<ConnectPage> createState() => _ConnectPageState();
}

class _ConnectPageState extends State<ConnectPage> {
  final DatabaseHelper dbHelper = DatabaseHelper();

  List<Map<String, dynamic>> churches = [];
  List<bool> _selectedChurches = [];

  bool isLoading = true;
  String errorMessage = '';

  int? userPhoneNumber;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _getUserPhoneNumber();
    await _loadParishDetails();
    await _loadSelectedChurches(); // NEW: Load previously selected churches
  }

  /// Refresh data from API (manual refresh)
  Future<void> refreshDataFromAPI() async {
    print(' Refreshing data from API...');
    churches.clear(); // Clear in-memory cache
    await _fetchAndCacheParishDetails();
    await _loadSelectedChurches(); // Reload selected churches after refresh
  }

  /// NEW: Fetch selected churches from GET API
  Future<void> _loadSelectedChurches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? savedToken = prefs.getString('jwt');
      
      if (savedToken == null || savedToken.isEmpty) {
        print(' No token found, skipping selected churches fetch');
        return;
      }

     
      final url = Uri.parse('https://lv4hfxvb-7000.inc1.devtunnels.ms/holymass/selectedchurchdetails/'); 
      
      print(' Fetching selected churches from API...');
      
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': '$savedToken',
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Request timed out');
        },
      );

      print(' Selected Churches Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> selectedData = jsonDecode(response.body);
        print(' Received ${selectedData.length} selected churches');
        
        // Extract the selected church IDs
        List<int> selectedChurchIDs = [];
        for (var item in selectedData) {
          int churchID = item['nSelectedChurchID'];
          selectedChurchIDs.add(churchID);
        }
        
        print(' Selected Church IDs: $selectedChurchIDs');
        
        // Update the checkboxes based on selected IDs
        _updateSelectedCheckboxes(selectedChurchIDs);
        
      } else if (response.statusCode == 404) {
        print(' No selected churches found (404)');
        // No selections yet, that's fine
      } else {
        print(' Error fetching selected churches: ${response.statusCode}');
      }
      
    } catch (e) {
      print(' Error loading selected churches: $e');
      // Don't show error to user, just log it
    }
  }

  /// NEW: Update checkboxes based on selected church IDs from API
  void _updateSelectedCheckboxes(List<int> selectedChurchIDs) {
    setState(() {
      for (int i = 0; i < churches.length; i++) {
        int churchID = churches[i]['nChurchMasterID'] ?? churches[i]['nParishID'];
        
        // Check if this church ID is in the selected list
        _selectedChurches[i] = selectedChurchIDs.contains(churchID);
      }
    });
    
    print(' Updated ${_selectedChurches.where((s) => s).length} checkboxes');
  }

  Future<void> _saveSelectedChurches() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<int> selectedChurchIDs = [];
      
      for (int i = 0; i < churches.length; i++) {
        if (_selectedChurches[i]) {
          int churchID = churches[i]['nChurchMasterID'] ?? churches[i]['nParishID'];
          selectedChurchIDs.add(churchID);
        }
      }
      
      await prefs.setString('selectedChurches_$userPhoneNumber', jsonEncode(selectedChurchIDs));
      print(' Saved selected churches: $selectedChurchIDs');
    } catch (e) {
      print(' Error saving selected churches: $e');
    }
  }

  /// Get user phone number from SharedPreferences
  Future<void> _getUserPhoneNumber() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? phone = prefs.getString('userPhone');
      if (phone != null) {
        userPhoneNumber = int.tryParse(phone);
        print(' User phone number: $userPhoneNumber');
      } else {
        print(' No user phone number found in SharedPreferences');
      }
    } catch (e) {
      print(' Error getting user phone: $e');
    }
  }

  /// Load parish details - SQLITE FIRST, only API if cache is empty
  Future<void> _loadParishDetails() async {
    if (userPhoneNumber == null) {
      setState(() {
        errorMessage = 'User phone number not found. Please log in again.';
        isLoading = false;
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      print(' STEP 1: Checking SQLite cache for user $userPhoneNumber...');
      
      // Always try SQLite cache FIRST
      final cachedData = await dbHelper.getCachedParishDetails(userPhoneNumber!);

      if (cachedData != null && cachedData.isNotEmpty) {
        print(' Cache HIT: Loaded ${cachedData.length} parishes from SQLite');
        
        setState(() {
          churches = List<Map<String, dynamic>>.from(cachedData);
          _selectedChurches = List<bool>.filled(churches.length, false);
          isLoading = false;
        });
        
      } else {
        print(' Cache MISS - Need to fetch from API');
        
        await _fetchAndCacheParishDetails();
      }

    } catch (e, stackTrace) {
      print(' Critical error in _loadParishDetails: $e');
      print('Stack trace: $stackTrace');
      
      setState(() {
        isLoading = false;
        errorMessage = 'Failed to load parish data: ${e.toString()}';
      });
    }
  }

  /// Fetch parish details from API and save to cache (GET REQUEST)
  /// This should only be called when SQLite cache is empty
  Future<void> _fetchAndCacheParishDetails() async {
    try {
      print(' Making GET API call to fetch parishes...');
      print(' Phone number: $userPhoneNumber');

      final uri = Uri.parse(ConnectChurchGetAPI);

      print(' Request URL: $uri');

      final response = await http.get(uri,
            headers: {
              'Accept': 'application/json',
            },
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw TimeoutException(
                'Request timed out. Please check your internet connection.',
              );
            },
          );

      print(' API Response');
      print('   Status Code: ${response.statusCode}');

      if (response.statusCode != 200) {
        throw Exception(
          'Server error (${response.statusCode})',
        );
      }

      if (response.body.isEmpty) {
        throw Exception('Empty response from server');
      }

      final decoded = jsonDecode(response.body);
      print(' Decoded response type: ${decoded.runtimeType}');

      /// FINAL parish list
      List<Map<String, dynamic>> parishList = [];

      //  CASE 1: API returns LIST directly
      if (decoded is List) {
        parishList = decoded.cast<Map<String, dynamic>>();
      }

      //  CASE 2: API returns MAP with status + data
      else if (decoded is Map<String, dynamic>) {
        final status = decoded['status']?.toString().toLowerCase();

        if (status != 'success') {
          throw Exception(decoded['message'] ?? 'API returned error');
        }

        final data = decoded['data'];

        if (data is List) {
          parishList = data.cast<Map<String, dynamic>>();
        } else {
          throw Exception('Invalid data format in API response');
        }
      }

      else {
        throw Exception('Unexpected API response format');
      }

      print(' Received ${parishList.length} parishes from API');

      if (parishList.isEmpty) {
        setState(() {
          isLoading = false;
          churches = [];
          _selectedChurches = [];
          errorMessage = 'No parishes found.';
        });
        return;
      }

      ///  Save to SQLite cache
      final jsonString = jsonEncode(parishList);
      print(' Saving parish data to SQLite (${jsonString.length} chars)');

      await dbHelper.saveParishDetails(
        phoneNumber: userPhoneNumber!,
        parishData: jsonString,
      );

      ///  Verify cache was saved successfully
      final cached = await dbHelper.getCachedParishDetails(userPhoneNumber!);
      if (cached == null || cached.isEmpty) {
        print(' Cache verification failed - data not saved properly');
      } else {
        print(' Cache verified: ${cached.length} items saved to SQLite');
      }

      /// Update UI
      setState(() {
        churches = parishList;
        _selectedChurches = List<bool>.filled(parishList.length, false);
        isLoading = false;
        errorMessage = '';
      });

    } on TimeoutException catch (e) {
      print(' Timeout error: $e');
      setState(() {
        isLoading = false;
        errorMessage =
            'Request timed out.\nPlease check your internet connection.';
      });
    } on FormatException catch (e) {
      print(' JSON format error: $e');
      setState(() {
        isLoading = false;
        errorMessage =
            'Invalid response from server.\nPlease try again later.';
      });
    } catch (e, stackTrace) {
      print(' Unexpected error in _fetchAndCacheParishDetails: $e');
      print('Stack trace: $stackTrace');
      setState(() {
        isLoading = false;
        errorMessage =
            'Unexpected error occurred.\nPlease try again.';
      });
    }
  }

 Future<List<dynamic>> approveChurchSelection() async {
  List<int> selectedChurchIDs = [];

  for (int i = 0; i < churches.length; i++) {
    if (_selectedChurches[i]) {
      int churchID = churches[i]['nChurchMasterID'] ?? churches[i]['nParishID'];
      selectedChurchIDs.add(churchID);
    }
  }

  if (selectedChurchIDs.isEmpty) throw Exception("No churches selected");

  final prefs = await SharedPreferences.getInstance();
  final String? savedToken = prefs.getString('jwt');
  final String? phone = prefs.getString('userPhone');

  if (savedToken == null || savedToken.isEmpty) {
    throw Exception("Please activate your account. Your account is not active.");
  }
  if (phone == null || phone.isEmpty) {
    throw Exception("Phone number not found.");
  }

  final url = Uri.parse(ConnectChurchSelectionAPI);
  print("Sending church IDs: $selectedChurchIDs");

  final response = await http.post(
    url,
    headers: {
      "Content-Type": "application/json",
      "Authorization": savedToken,
    },
    body: jsonEncode({
      "nPhoneNo": phone,
      "nChurchID": selectedChurchIDs,
    }),
  );

  print("Approval - Response Code: ${response.statusCode}");
  print("Approval - Response Body: ${response.body}");

  if (response.statusCode == 200 || response.statusCode == 201) {
    //  Parse and return the church data directly from POST response
    final List<dynamic> churchData = jsonDecode(response.body);
    print(" Received ${churchData.length} churches from POST response");
    return churchData;
  } else if (response.statusCode == 409) {
    throw Exception("Church already exists");
  } else if (response.statusCode == 502) {
    throw Exception("Please activate your account. Your account is not active.");
  } else if (response.statusCode == 500) {
    throw Exception("Server error: ${response.body}");
  } else {
    throw Exception(
        "Failed to approve church. Status: ${response.statusCode}");
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
          'Select your favourite church',
          style: GoogleFonts.roboto(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: refreshDataFromAPI,
          )
        ],
      ),
      body: _buildContent(),
      bottomNavigationBar: churches.isNotEmpty ? _buildConfirmButton() : null,
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.cyan),
            ),
            SizedBox(height: 16),
            Text(
              'Loading parishes...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    if (errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red[300],
              ),
              SizedBox(height: 16),
              Text(
                'Oops!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              SizedBox(height: 8),
              Text(
                errorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadParishDetails,
                icon: Icon(Icons.refresh),
                label: Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyan,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (churches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.church_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              'No parishes available',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 24),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: churches.length,
      itemBuilder: (_, index) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: _buildChurchCard(index),
      ),
    );
  }

  Widget _buildChurchCard(int index) {
    final church = churches[index];
    final isSelected = _selectedChurches[index];
    final logoPath = church['cLogoPath'] ?? '';

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedChurches[index] = !_selectedChurches[index];
        });
        _saveSelectedChurches();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.cyan : Colors.grey.shade200,
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected 
                  ? Colors.cyan.withOpacity(0.2) 
                  : Colors.black.withOpacity(0.05),
              blurRadius: isSelected ? 12 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Church Logo/Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.cyan.shade50 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? Colors.cyan.shade200 : Colors.grey.shade300,
                    width: 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: logoPath.isNotEmpty
                      ? Image.network(
                          logoPath,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                  strokeWidth: 2.5,
                                  color: Colors.cyan,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.church_outlined,
                              size: 36,
                              color: Colors.grey.shade400,
                            );
                          },
                        )
                      : Icon(
                          Icons.church_outlined,
                          size: 36,
                          color: isSelected ? Colors.cyan : Colors.grey.shade400,
                        ),
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Church Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      church['cChurchName'] ?? 'Unknown church',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.roboto(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: isSelected ? Colors.brown.shade900 : Colors.grey.shade900,
                        height: 1.3,
                      ),
                    ),
                    if (church['cParishName'] != null && church['cParishName'] != '') ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              church['cParishName'],
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.roboto(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Checkbox
              Transform.scale(
                scale: 1.1,
                child: Checkbox(
                  value: isSelected,
                  activeColor: Colors.cyan,
                  checkColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                  side: BorderSide(
                    color: isSelected ? Colors.cyan : Colors.grey.shade400,
                    width: 2,
                  ),
                  onChanged: (val) {
                    setState(() {
                      _selectedChurches[index] = val ?? false;
                    });
                    _saveSelectedChurches();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmButton() {
    final selectedCount = _selectedChurches.where((selected) => selected).length;
    final hasSelection = selectedCount > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 5,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton(
     onPressed: hasSelection
    ? () async {
        try {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => Center(child: CircularProgressIndicator()),
          );

          //  Get data directly from POST response
          final List<dynamic> churchData = await approveChurchSelection();

          Navigator.pop(context); // Close loading dialog

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Church selected successfully'),
              backgroundColor: Colors.green,
            ),
          );

          //  Pass POST response data directly to homepage
          Navigator.pop(context, churchData);

        } catch (e) {
          Navigator.pop(context);
          String errorMessage = e.toString().replaceAll('Exception: ', '');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    : null,

          style: ElevatedButton.styleFrom(
            backgroundColor: hasSelection ? Colors.cyan : Colors.grey.shade300,
            disabledBackgroundColor: Colors.grey.shade300,
            foregroundColor: hasSelection ? Colors.white : Colors.grey.shade600,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: hasSelection ? 4 : 0,
          ),
          child: Text(
            hasSelection
                ? 'Confirm Selection ($selectedCount ${selectedCount == 1 ? 'Church' : 'Churches'})'
                : 'Select at least one church',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}