import 'dart:convert';
import 'dart:io';
import 'package:Koottaayma/HTTPURL/formatdate.dart';
import 'package:Koottaayma/HTTPURL/httpurl.dart';
import 'package:Koottaayma/SQFLITEVERSION1/DataBaseHelper.dart';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SpecialNotificationModel {
  final String nSpecialProgramID;
  final String dStartDate;
  final String dEndDate;
  final String cImagePath;
  final String cMessageText;

  SpecialNotificationModel({
    required this.nSpecialProgramID,
    required this.dStartDate,
    required this.dEndDate,
    required this.cImagePath,
    required this.cMessageText,
  });

  factory SpecialNotificationModel.fromJson(Map<String, dynamic> json) {
    return SpecialNotificationModel(
      nSpecialProgramID: json['nSpecialProgramID']?.toString() ?? "",
      dStartDate: json['dStartDate'] ?? "",
      dEndDate: json['dEndDate'] ?? "",
      cImagePath: json['cImagePath'] ?? "",
      cMessageText: json['cMessageText'] ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nSpecialProgramID': nSpecialProgramID,
      'dStartDate': dStartDate,
      'dEndDate': dEndDate,
      'cImagePath': cImagePath,
      'cMessageText': cMessageText,
    };
  }
}

class Churchnotification extends StatefulWidget {
  const Churchnotification({super.key});

  @override
  State<Churchnotification> createState() => _ChurchnotificationState();
}

class _ChurchnotificationState extends State<Churchnotification> {
  bool isLoading = false;
  String? errorMessage;
  List<SpecialNotificationModel> notifications = [];
  Set<String> submittedInterests = {};
  int? userPhoneNumber;
  
  // Database helper instance
  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  /// Initialize data - check if cached data exists
  Future<void> _initializeData() async {
    await _getUserPhoneNumber();
    await _loadSpecialNotifications();
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

  /// Main function to load special notifications
  Future<void> _loadSpecialNotifications() async {
    if (userPhoneNumber == null) {
      setState(() {
        errorMessage = 'User phone number not found. Please login again.';
        isLoading = false;
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Try to get cached data first
      print(' Checking SQLite cache for user: $userPhoneNumber');
      final cachedData = await _dbHelper.getCachedSpecialPrograms(userPhoneNumber!);
      
      if (cachedData != null && cachedData.isNotEmpty) {
        print(' Found ${cachedData.length} cached Special Programs');
        
        // Parse cached data
        notifications = cachedData
            .map((item) => SpecialNotificationModel.fromJson(item as Map<String, dynamic>))
            .toList();
        
        // Load saved attendance
        await _loadSavedAttendance();
        
        setState(() {
          isLoading = false;
        });
        
        print(' Loaded data from cache successfully');
      } else {
        print(' No cached data found. Fetching from API...');
        // No cache - fetch from API
        await _fetchFromAPIAndCache();
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error loading data: $e';
        isLoading = false;
      });
      print(' Error in _loadSpecialNotifications: $e');
    }
  }

  /// Fetch from API and save to cache
  Future<void> _fetchFromAPIAndCache() async {
    if (userPhoneNumber == null) {
      setState(() {
        errorMessage = 'User phone number not found';
        isLoading = false;
      });
      return;
    }

    try {
      final url = Uri.parse(SpecialProgramsAPI);

      print(' Fetching Special Programs from API...');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print(" API Response Status: ${response.statusCode}");

      if (response.statusCode == 201 || response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        
        if (data.isEmpty) {
          setState(() {
            errorMessage = 'No Special Programs available';
            isLoading = false;
          });
          return;
        }

        print(' Fetched ${data.length} Special Programs from API');
        
        // Parse all data
        notifications = data
            .map((item) => SpecialNotificationModel.fromJson(item as Map<String, dynamic>))
            .toList();
        
        // Save to SQLite cache
        await _saveToCacheDatabase(data);
        
        // Load saved attendance
        await _loadSavedAttendance();
        
        setState(() {
          isLoading = false;
        });
        
        print(' Data cached successfully for user: $userPhoneNumber');
      } else {
        setState(() {
          errorMessage = 'Failed to load Special Programs (Status: ${response.statusCode})';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Network error: $e';
        isLoading = false;
      });
      print(' Error fetching from API: $e');
    }
  }

  /// Save to cache database
  Future<void> _saveToCacheDatabase(List<dynamic> data) async {
    try {
      final db = await _dbHelper.database;
      
      // Delete old cache for this user
      await db.delete(
        'special_programs_cache',
        where: 'phone_number = ?',
        whereArgs: [userPhoneNumber],
      );
      
      // Insert new cache
      await db.insert(
        'special_programs_cache',
        {
          'phone_number': userPhoneNumber,
          'programs_data': jsonEncode(data),
          'cached_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      print(' Saved cache to database');
    } catch (e) {
      print(' Error saving to cache: $e');
    }
  }

  /// Refresh data from API (manual refresh)
  Future<void> refreshDataFromAPI() async {
    print(' Refreshing data from API...');
    notifications.clear(); // Clear in-memory cache
    await _fetchFromAPIAndCache();
  }

  /// Clear cached data (for logout)
  Future<void> clearCachedData() async {
    if (userPhoneNumber == null) return;
    
    try {
      final db = await _dbHelper.database;
      await db.delete(
        'special_programs_cache',
        where: 'phone_number = ?',
        whereArgs: [userPhoneNumber],
      );
      
      // Clear cached network images from CachedNetworkImage
      for (var notification in notifications) {
        if (notification.cImagePath.isNotEmpty) {
          await CachedNetworkImage.evictFromCache(notification.cImagePath);
        }
      }
      
      print(' Cleared cached Special Programs data for user: $userPhoneNumber');
    } catch (e) {
      print(' Error clearing cached data: $e');
    }
  }

  /// Load saved attendance and populate submittedInterests
  Future<void> _loadSavedAttendance() async {
    try {
      List<int> savedAttendIds = await _fetchSavedAttend();
      
      // Convert int IDs to String and add to submittedInterests set
      setState(() {
        submittedInterests = savedAttendIds.map((id) => id.toString()).toSet();
      });
      
      print(" Loaded saved attendance IDs: $submittedInterests");
    } catch (e) {
      print(" Error loading saved attendance: $e");
    }
  }

  /// Submit interest request
  Future<void> InterestRequest(String nSpecialProgramID) async {
    if (nSpecialProgramID.isEmpty) {
      throw Exception("Program ID is empty. Cannot submit interest.");
    }

    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString('jwt');

    if (savedToken == null || savedToken.isEmpty) {
      throw Exception("Please activate your account. Your account is not active.");
    }

    final url = Uri.parse(InterestRequestAPI);

    print(" Sending Interest Request for ID: $nSpecialProgramID");

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": savedToken,
      },
      body: json.encode({
        'nSpecialProgramsID': nSpecialProgramID,
      }),
    );
    print(" Interest Request - Response Code: ${response.statusCode}");

    if (response.statusCode == 200 || response.statusCode == 201) {
      return;
    }
    else if (response.statusCode == 502) {
      print("Please activate your account. Your account is not active.");
    
    }
     else {
      throw Exception("Failed to send request: ${response.body}");
    }
  }

  /// Get saved attend requests
  Future<List<int>> _fetchSavedAttend() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? savedToken = prefs.getString('jwt');

      if (savedToken == null || savedToken.isEmpty) {
        throw Exception("Token not found");
      }

      final url = InterestRequestAPI;
      
      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': savedToken,
            },
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw Exception('Connection timeout'),
          );

      print(" Saved Attend API Response Status: ${response.statusCode}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final List<dynamic> responseData = jsonDecode(response.body);

        List<int> savedIds = responseData
            .map<int>((item) {
              var id = item['nSpecialProgramsID'];
              if (id is int) {
                return id;
              } else if (id is String) {
                return int.parse(id);
              }
              return 0;
            })
            .where((id) => id != 0)
            .toList();
            
        print(" Fetched saved attend IDs: $savedIds");
        return savedIds;
      } else {
        print(" Failed to fetch saved attend: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print(' Error fetching saved attend: $e');
      return [];
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
          'Special Events',
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
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : errorMessage != null
                  ? Center(
                      child: Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              errorMessage!,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                     
                         
                          ],
                        ),
                      ),
                    )
                  : notifications.isEmpty
                      ? Center(
                          child: Container(
                            padding: EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.notifications_off,
                                    size: 60, color: Colors.grey[600]),
                                SizedBox(height: 12),
                                Text(
                                  "No Notifications Found",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[800],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: notifications.length,
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemBuilder: (context, index) {
                            final item = notifications[index];
                            final isSubmitted = submittedInterests.contains(item.nSpecialProgramID);

                            return SafeArea(
                              child: Container(
                                margin: EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.08),
                                      blurRadius: 10,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Image at the top - using CachedNetworkImage
                                    if (item.cImagePath.isNotEmpty)
                                      ClipRRect(
                                        borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(16),
                                          topRight: Radius.circular(16),
                                        ),
                                        child: CachedNetworkImage(
                                          imageUrl: item.cImagePath,
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          height: 400,
                                          placeholder: (context, url) => Container(
                                            height: 400,
                                            color: Colors.grey[300],
                                            child: Center(
                                              child: CircularProgressIndicator(
                                                color: Colors.cyan,
                                              ),
                                            ),
                                          ),
                                          errorWidget: (context, url, error) => Container(
                                            height: 180,
                                            decoration: BoxDecoration(
                                              color: Colors.grey[300],
                                              borderRadius: BorderRadius.only(
                                                topLeft: Radius.circular(16),
                                                topRight: Radius.circular(16),
                                              ),
                                            ),
                                            child: Center(
                                              child: Icon(
                                                Icons.image_not_supported,
                                                size: 40,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),

                                    // Content Section
                                    Padding(
                                      padding: EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Title
                                          Text(
                                            item.cMessageText,
                                            style: GoogleFonts.poppins(
                                              color: Colors.black87,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 16,
                                              height: 1.3,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          SizedBox(height: 12),
                                          // Date Information
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'START DATE',
                                                      style: GoogleFonts.roboto(
                                                        color: Colors.grey[600],
                                                        fontWeight: FontWeight.w500,
                                                        fontSize: 10,
                                                        letterSpacing: 0.5,
                                                      ),
                                                    ),
                                                    SizedBox(height: 4),
                                                 Text(
                                                DateFormatter.formatDate(item.dStartDate),
                                                   style: GoogleFonts.roboto(
                                                   color: Colors.black87,
                                                   fontWeight: FontWeight.w600,
                                                   fontSize: 13,
                                                       ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              SizedBox(width: 16),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'END DATE',
                                                      style: GoogleFonts.roboto(
                                                        color: Colors.grey[600],
                                                        fontWeight: FontWeight.w500,
                                                        fontSize: 10,
                                                        letterSpacing: 0.5,
                                                      ),
                                                    ),
                                                    SizedBox(height: 4),
                                                    Text(
                                                       DateFormatter.formatDate(item.dEndDate),
                                                      style: GoogleFonts.roboto(
                                                        color: Colors.black87,
                                                        fontWeight: FontWeight.w600,
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              // INTEREST BUTTON
                                              GestureDetector(
                                                onTap: (isSubmitted || item.nSpecialProgramID.isEmpty) 
                                                    ? null 
                                                    : () async {
                                                  try {
                                                    // Show loading indicator
                                                    showDialog(
                                                      context: context,
                                                      barrierDismissible: false,
                                                      builder: (context) => Center(
                                                        child: CircularProgressIndicator(
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    );

                                                    await InterestRequest(item.nSpecialProgramID);

                                                    // Close loading dialog
                                                    if (mounted) Navigator.pop(context);

                                                    // Mark as submitted
                                                    setState(() {
                                                      submittedInterests.add(item.nSpecialProgramID);
                                                    });

                                                    if (mounted) {
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        const SnackBar(
                                                          content: Text("Interest submitted successfully!"),
                                                          backgroundColor: Colors.green,
                                                          behavior: SnackBarBehavior.floating,
                                                          duration: Duration(seconds: 2),
                                                        ),
                                                      );
                                                    }
                                                  } catch (e) {
                                                    // Close loading dialog
                                                    if (mounted) Navigator.pop(context);

                                                    if (mounted) {
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        SnackBar(
                                                          content: Text("Error: ${e.toString()}"),
                                                          backgroundColor: Colors.red,
                                                          behavior: SnackBarBehavior.floating,
                                                        ),
                                                      );
                                                    }
                                                  }
                                                },
                                                child: Container(
                                                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                  decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                      colors: (isSubmitted || item.nSpecialProgramID.isEmpty)
                                                          ? [Colors.grey, Colors.grey]
                                                          : [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                                                    ),
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      if (isSubmitted)
                                                        Row(
                                                          children: [
                                                            Icon(Icons.check, color: Colors.white, size: 14),
                                                            SizedBox(width: 4),
                                                            Text(
                                                              'INTERESTED',
                                                              style: GoogleFonts.roboto(
                                                                color: Colors.white,
                                                                fontWeight: FontWeight.bold,
                                                                fontSize: 10,
                                                                letterSpacing: 1,
                                                              ),
                                                            ),
                                                          ],
                                                        )
                                                      else
                                                        Text(
                                                          'INTEREST',
                                                          style: GoogleFonts.roboto(
                                                            color: Colors.white,
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: 10,
                                                            letterSpacing: 1,
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
        ),
      ),
    );
  }
}