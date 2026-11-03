import 'dart:convert';
import 'package:Koottaayma/ADDITIONALINFORMATION/familywelfaredetails.dart';
import 'package:Koottaayma/ADDITIONALINFORMATION/fisherydetails.dart';
import 'package:Koottaayma/ADDITIONALINFORMATION/medicaldetails.dart';
import 'package:Koottaayma/HTTPURL/httpurl.dart';
import 'package:Koottaayma/SQFLITEVERSION1/DataBaseHelper.dart';
import 'package:Koottaayma/SQFLITEVERSION1/PhoneNumberField.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dots_indicator/dots_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:google_fonts/google_fonts.dart' hide Config;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final dbHelper = DatabaseHelper();

  List<dynamic> userProfiles = [];
  bool isLoading = true;
  String errorMessage = '';
  int selectedMemberIndex = 0;
  bool isLoadingFromBackend = false;
  String dataSource = '';
  final ScrollController _scrollController = ScrollController();
  int? nFamilyMasterID;

  @override
  void initState() {
    super.initState();
    fetchUserProfile();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
String formatDOB(String dobString) {
  try {
    DateTime dob = DateTime.parse(dobString);
    const List<String> monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    String formattedDate =
        "${dob.day.toString().padLeft(2, '0')}-${monthNames[dob.month - 1]}-${dob.year}";

    DateTime today = DateTime.now();

    int years = today.year - dob.year;
    int months = today.month - dob.month;
    int days = today.day - dob.day;

    // Adjust days
    if (days < 0) {
      months--;
      // Get days in the previous month
      DateTime prevMonth = DateTime(today.year, today.month, 0);
      days += prevMonth.day;
    }

    // Adjust months
    if (months < 0) {
      years--;
      months += 12;
    }

    return "$formattedDate ($years Years $months Months $days Days)";
  } catch (e) {
    return "N/A";
  }
}

  void _showNavigationFamilyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Add Details",
                style: GoogleFonts.roboto(
                    fontWeight: FontWeight.bold,
                    color: const Color.fromARGB(255, 65, 150, 161)),
              ),
              IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: Icon(Icons.cancel, color: Colors.cyan))
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => FamilyWelfareDetails()),
                );
              },
              child: Text("Add Family Welfare Details"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => MemberFisheryDetails()),
                );
              },
              child: Text("Add Fishery details"),
            ),
          ],
        );
      },
    );
  }

  void _showNavigationMemberDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Add Details",
                style: GoogleFonts.roboto(
                    fontWeight: FontWeight.bold,
                    color: const Color.fromARGB(255, 65, 150, 161)),
              ),
              IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: Icon(Icons.cancel, color: Colors.cyan))
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => MemberMedicalDetails()),
                );
              },
              child: Text("Add Medical details"),
            ),
          ],
        );
      },
    );
  }

   //UPDATED: Main fetch method with new cache system
 
  Future<void> fetchUserProfile() async {
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

      int phoneNumberInt = int.tryParse(phoneNumber) ?? 0;

      //  Step 1: Try loading from new cache system
      print(' Checking new cache system for family details...');
      final cachedFamilyData =
          await dbHelper.getCachedFamilyDetails(phoneNumberInt);

      if (cachedFamilyData != null && cachedFamilyData.isNotEmpty) {
        // Load from cache
        print(' Loading ${cachedFamilyData.length} members from cache');
        setState(() {
          userProfiles = cachedFamilyData;
          isLoading = false;
          dataSource = 'cache';
        });

        //  Check if cache is stale (older than 24 hours)
        final lastSync = await dbHelper.getLastSyncTimeForUser(phoneNumberInt);
        if (lastSync != null) {
          final hoursSinceSync = DateTime.now().difference(lastSync).inHours;
          if (hoursSinceSync > 24) {
            print(' Cache is stale, refreshing in background...');
            _fetchFromBackendInBackground(phoneNumberInt, savedToken);
          }
        }
      } else {
        // No cached data, fetch from backend
        print(' No cached data found, fetching from backend...');
        await _fetchFromBackend(phoneNumberInt, savedToken);
      }
    } catch (e) {
      print('Error in fetchUserProfile: $e');
      setState(() {
        isLoading = false;
        errorMessage = 'Error: ${e.toString()}';
      });
    }
  }
void showLogoutConfirmation(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await logout(context);
            },
            child: const Text('Logout'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              SystemNavigator.pop(); // Exits the app
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Exit'),
          ),
        ],
      );
    },
  );
}
//logout function
  Future<void> logout(BuildContext context) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      // Get language ID before clearing (to preserve it)
      String? savedLanguageId = prefs.getString('languageid');

      // Clear user-specific data (logout the user)
      await prefs.remove('isRegistered');
      await prefs.remove('userPhone');
      await prefs.remove('usertype');
      await prefs.remove('userTypeKey');

      print('User logged out successfully');
      print('Preserved language ID: $savedLanguageId');

      // Navigate to login page
      int languageId = int.tryParse(savedLanguageId ?? '0') ?? 0;

      if (!context.mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => PhoneNumber(
            languageId: languageId,
            phoneNumber: 0,
            nUserTypeID: 0,
          ),
        ),
        (route) => false,
      );
    } catch (e) {
      print('Error during logout: $e');
      
      if (!context.mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logout failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
 
  Future<void> _fetchFromBackend(int phoneNumber, String? savedToken) async {
    setState(() {
      isLoadingFromBackend = true;
    });

    try {
      var response = await http.post(
        Uri.parse(FamilyMemberDetails),
        headers: {
          'Content-Type': 'application/json',
          if (savedToken != null) 'Authorization': '$savedToken',
        },
        body: jsonEncode({
          'nPhoneNo': phoneNumber.toString(),
        }),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Connection timeout');
        },
      );

      print(' Response status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        var responseData = jsonDecode(response.body);

        // Extract nFamilyMasterID and nFamilyMemberID
        int? nFamilyMasterID;
        int? nFamilyMemberID;

        if (responseData is List && responseData.isNotEmpty) {
          nFamilyMasterID = responseData[0]['nFamilyMasterID'];
          nFamilyMemberID = responseData[0]['nFamilyMemberID'];
        } else if (responseData is Map) {
          nFamilyMasterID = responseData['nFamilyMasterID'];
          nFamilyMemberID = responseData['nFamilyMemberID'];
        }

        // Save IDs to SharedPreferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setInt('nFamilyMasterID', nFamilyMasterID ?? 0);
        await prefs.setInt('nFamilyMemberID', nFamilyMemberID ?? 0);
        print(" Saved nFamilyMasterID: $nFamilyMasterID");
        print(" Saved nFamilyMemberID: $nFamilyMemberID");

        List<dynamic> members = [];
        if (responseData is List) {
          members = responseData;
        } else if (responseData is Map) {
          members = [responseData];
        }

        //  Save to NEW cache system
        if (members.isNotEmpty) {
          print(' Saving ${members.length} members to new cache system...');
          await dbHelper.saveFamilyDetails(
            phoneNumber: phoneNumber,
            familyData: jsonEncode(members),
          );
          
          // Update sync time
          await dbHelper.updateLastSyncTime(phoneNumber);
          print(' Successfully saved to new cache');
        }

        setState(() {
          userProfiles = members;
          isLoading = false;
          isLoadingFromBackend = false;
          dataSource = 'backend';
        });
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } on http.ClientException catch (e) {
      setState(() {
        isLoading = false;
        isLoadingFromBackend = false;
        errorMessage = 'Network error. Check your connection.';
      });
      print(' Network error: $e');
    } catch (e) {
      setState(() {
        isLoading = false;
        isLoadingFromBackend = false;
        errorMessage = 'Failed to load data: ${e.toString()}';
      });
      print(' Error fetching from backend: $e');
    }
  }

  Future<void> _fetchFromBackendInBackground(
      int phoneNumber, String? savedToken) async {
    try {
      print(' Updating cache in background...');
      var response = await http.post(
        Uri.parse(FamilyMemberDetails),
        headers: {
          'Content-Type': 'application/json',
          if (savedToken != null)
           'Authorization': '$savedToken',
        },
        body: jsonEncode({
          'nPhoneNo': phoneNumber.toString(),
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        var responseData = jsonDecode(response.body);
        List<dynamic> members = [];

        if (responseData is List) {
          members = responseData;
        } else if (responseData is Map) {
          members = [responseData];
        }

        if (members.isNotEmpty) {
        
          await dbHelper.saveFamilyDetails(
            phoneNumber: phoneNumber,
            familyData: jsonEncode(members),
          );
          
          // Update sync time
          await dbHelper.updateLastSyncTime(phoneNumber);
          print(' Background cache update completed');

          if (mounted) {
            setState(() {
              userProfiles = members;
              dataSource = 'backend';
            });
          }
        }
      }
    } catch (e) {
      print(' Background update failed: $e');
    }
  }

 
  Future<void> _refreshData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? phoneNumber = prefs.getString('userPhone');
    String? savedToken = prefs.getString('jwt');

    if (phoneNumber != null) {
      int phoneNumberInt = int.tryParse(phoneNumber) ?? 0;
      await _fetchFromBackend(phoneNumberInt, savedToken);
    }
  }
  Future<bool> _showExitDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Exit App'),
            content: const Text('Are you sure you want to exit the app?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Yes'),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return PopScope(
      canPop: false, // BLOCK system back
      onPopInvoked: (didPop) async {
        if (didPop) return;

        final exit = await _showExitDialog(context);
        if (exit) {
          // Closes the app
          SystemNavigator.pop();
        }
      },
    child:Scaffold(
      backgroundColor: Colors.white70,
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.cyan,
              Color.fromARGB(255, 158, 218, 228),
              Colors.white,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _refreshData,
            color: Colors.cyan,
            child: SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  SizedBox(height: size.height * 0.01),
                Padding(
  padding: const EdgeInsets.only(left: 22, right: 22, top: 10),
  child: Row(
    children: [
      Text(
        'Family Members',
        style: GoogleFonts.roboto(
          color: Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      Spacer(),
      if (userProfiles.isNotEmpty)
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.8),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${userProfiles.length} Member${userProfiles.length > 1 ? 's' : ''}',
            style: GoogleFonts.roboto(
              color: Colors.cyan[800],
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      SizedBox(width: 8),

      //  LOGOUT BUTTON
    GestureDetector(
  onTap: () => showLogoutConfirmation(context), // 👈 only this changes
  child: Container(
    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.red.withOpacity(0.1),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.red.withOpacity(0.4)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.logout, color: Colors.red[700], size: 16),
        SizedBox(width: 4),
        Text(
          'Logout',
          style: GoogleFonts.roboto(
            color: Colors.red[700],
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  ),
),
    ],
  ),
),

                  // Family Info Container
                  if (userProfiles.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.all(size.width * 0.03),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                  vertical: 5, horizontal: 10),
                              decoration: BoxDecoration(
                                color: Colors.cyan[50],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  SizedBox(width: 8),
                                  Text(
                                    'Family Name: ',
                                    style: GoogleFonts.roboto(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 12,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      '${userProfiles[selectedMemberIndex]['cFamilyName'] ?? 'N/A'}',
                                      style: GoogleFonts.roboto(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 17,
                                        color: Colors.blue,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 5),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.cyan[50],
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                children: [
                                  SizedBox(width: 8),
                                  Text(
                                    ' Book No: ',
                                    style: GoogleFonts.roboto(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 12,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      '${userProfiles[selectedMemberIndex]['cFamilyNo'] ?? 'N/A'}',
                                      style: GoogleFonts.roboto(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                        color: Colors.blue,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 2),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: Column(
                                    children: [
                                      buildInfoItem(
                                        "Diocese",
                                        userProfiles[selectedMemberIndex]
                                                ['cDioceseName'] ??
                                            'N/A',
                                      ),
                                      buildInfoItem(
                                        "Forane",
                                        userProfiles[selectedMemberIndex]
                                                ['cForaneName'] ??
                                            'N/A',
                                      ),
                                      buildInfoItem(
                                        "Parish",
                                        userProfiles[selectedMemberIndex]
                                                ['cParishName'] ??
                                            'N/A',
                                      ),
                                      buildInfoItem(
                                        "Family Unit",
                                        userProfiles[selectedMemberIndex]
                                                ['cFamilyUnitName'] ??
                                            'N/A',
                                      ),
                                      buildInfoItem(
                                        "Ward",
                                        userProfiles[selectedMemberIndex]
                                                ['cWardName'] ??
                                            'N/A',
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: 12),
                                GestureDetector(
                                  onTap: () {
                                    _showNavigationFamilyDialog(context);
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 10),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.cyan[400]!,
                                          Colors.cyan[600]!
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.cyan.withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SizedBox(width: 4),
                                        Text(
                                          'Add',
                                          style: GoogleFonts.roboto(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
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
                    ),

                  // Loading, Error, or Empty states
                  if (isLoading)
                    Container(
                      height: size.height * 0.15,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(color: Colors.cyan),
                            SizedBox(height: 15),
                            Text(
                              'Loading family members...',
                              style: GoogleFonts.roboto(
                                color: Colors.grey[700],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (errorMessage.isNotEmpty)
                    Container(
                      height: size.height * 0.2,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline,
                                color: Colors.red, size: 48),
                            SizedBox(height: 10),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 32),
                              child: Text(
                                errorMessage,
                                style: TextStyle(color: Colors.red),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            SizedBox(height: 15),
                            ElevatedButton.icon(
                              onPressed: fetchUserProfile,
                              icon: Icon(Icons.refresh),
                              label: Text('Retry'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.cyan,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (userProfiles.isEmpty)
                    Container(
                      height: size.height * 0.15,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline,
                                color: Colors.grey, size: 48),
                            SizedBox(height: 10),
                            Text('No family members found'),
                            SizedBox(height: 15),
                            TextButton.icon(
                              onPressed: fetchUserProfile,
                              icon: Icon(Icons.refresh),
                              label: Text('Refresh'),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.cyan[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    // Member cards ListView
                    Container(
                      height: size.height * 0.165,
                      child: ListView.builder(
                        controller: _scrollController,
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.symmetric(
                            horizontal: size.width * 0.03),
                        itemCount: userProfiles.length,
                        itemBuilder: (context, index) {
                          final profile = userProfiles[index];
                          bool isSelected = selectedMemberIndex == index;

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedMemberIndex = index;
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: AnimatedContainer(
                                duration: Duration(milliseconds: 300),
                                height: 200,
                                width: 350,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected
                                        ? Colors.cyan
                                        : Colors.transparent,
                                    width: 3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: isSelected
                                          ? Colors.cyan.withOpacity(0.3)
                                          : Colors.black.withOpacity(0.1),
                                      blurRadius: isSelected ? 15 : 10,
                                      offset: Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            '${profile['cMemberCode'] ?? 'N/A'}',
                                            style: GoogleFonts.roboto(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          Text(
                                            ':',
                                            style: GoogleFonts.roboto(
                                                fontWeight: FontWeight.bold),
                                          ),
                                          SizedBox(width: size.width * 0.01),
                                          Expanded(
                                            child: Text(
                                              '${profile['cFirstName'] ?? 'N/A'} ${profile['cLastName'] ?? ''}',
                                              style: GoogleFonts.roboto(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black87,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          SizedBox(width: size.width * 0.01),
                                          Text(
                                            '(${profile['cRelationName'] ?? 'N/A'})',
                                            style: GoogleFonts.roboto(
                                              fontSize: 16,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 8),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
      Center(
  child: profile['cImagePath'] != null && profile['cImagePath'].isNotEmpty
      ? FutureBuilder<FileInfo?>(
          future: CustomCacheManager.instance
              .getFileFromCache(profile['cImagePath'])
              .then((fileInfo) {
                if (fileInfo != null && fileInfo.file.existsSync()) {
                  return fileInfo;
                }
                return null;
              }),
          builder: (context, snapshot) {
            // Block 1 — still checking, show placeholder ONLY
            if (snapshot.connectionState != ConnectionState.done) {
              return const CircleAvatar(
                radius: 25,
                child: CircularProgressIndicator(strokeWidth: 2),
              );
            }

            // Block 2 — cache HIT, load from disk
            if (snapshot.data != null) {
              return CircleAvatar(
                radius: 25,
                backgroundImage: FileImage(snapshot.data!.file),
              );
            }

            // Block 3 — confirmed MISS, only NOW hit the network
            return CachedNetworkImage(
              cacheManager: CustomCacheManager.instance,
              imageUrl: profile['cImagePath'],
              imageBuilder: (context, imageProvider) => CircleAvatar(
                radius: 25,
                backgroundImage: imageProvider,
              ),
              placeholder: (context, url) => const CircleAvatar(
                radius: 25,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              errorWidget: (context, url, error) => const CircleAvatar(
                radius: 25,
                child: Icon(Icons.person, size: 28),
              ),
            );
          },
        )
      : const CircleAvatar(
          radius: 25,
          child: Icon(Icons.person, size: 28),
        ),
),
                                          SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Row(
                                                  children: [
                                                    Icon(Icons.calendar_month,
                                                        size: 14,
                                                        color: Colors.grey),
                                                    SizedBox(width: 4),
                                                    Text(
                                                      formatDOB(
                                                          profile['dDoB'] ??
                                                              ''),
                                                      style: TextStyle(
                                                          fontSize: 12,
                                                          color: Colors.black),
                                                    ),
                                                    SizedBox(width: 5),
                                                  //add the gender icon here
                                                  ],
                                                ),SizedBox(height: 4),
                                                  Row(
                                                    children: [
                                                      Icon(Icons.wc, size: 14, color: Colors.grey),
                                                       SizedBox(width: 4),
                                                      Text(
                                                          '${profile['nGenderID'] == 1 ? 'Male' : profile['nGenderID'] == 2 ? 'Female' : 'N/A'}',
                                                          style: TextStyle(
                                                              fontSize: 12,
                                                              color: Colors.black),
                                                        ),
                                                    ],
                                                  ),
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: _buildInfoRow(
                                                        Icons.phone,
                                                        profile['nPhoneNo']
                                                                ?.toString() ??
                                                            'N/A',
                                                      ),
                                                    ),
                                                    SizedBox(width: 8),
                                                    GestureDetector(
                                                      onTap: () {
                                                        _showNavigationMemberDialog(
                                                            context);
                                                      },
                                                      child: Container(
                                                        padding: EdgeInsets
                                                            .symmetric(
                                                                horizontal: 20,
                                                                vertical: 10),
                                                        decoration:
                                                            BoxDecoration(
                                                          gradient:
                                                              LinearGradient(
                                                            colors: [
                                                              Colors.cyan[400]!,
                                                              Colors.cyan[600]!
                                                            ],
                                                          ),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(20),
                                                          boxShadow: [
                                                            BoxShadow(
                                                              color: Colors.cyan
                                                                  .withOpacity(
                                                                      0.3),
                                                              blurRadius: 8,
                                                              offset:
                                                                  Offset(0, 2),
                                                            ),
                                                          ],
                                                        ),
                                                        child: Row(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            Icon(
                                                              Icons.add,
                                                              color:
                                                                  Colors.white,
                                                              size: 16,
                                                            ),
                                                            SizedBox(width: 4),
                                                            Text(
                                                              'Add',
                                                              style: GoogleFonts
                                                                  .roboto(
                                                                color: Colors
                                                                    .white,
                                                                fontSize: 13,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
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
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                  // Dots Indicator
                  if (userProfiles.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: DotsIndicator(
                        dotsCount: userProfiles.length,
                        position: selectedMemberIndex.toDouble(),
                        decorator: DotsDecorator(
                          size: const Size.square(8.0),
                          activeSize: const Size(20.0, 8.0),
                          activeShape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5.0),
                          ),
                          color: Colors.grey.shade400,
                          activeColor: Colors.cyan,
                        ),
                      ),
                    ),

                     // Selected member's detailed information
                  if (userProfiles.isNotEmpty) ...[
                    SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.cyan[800], size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Details for ${userProfiles[selectedMemberIndex]['cFirstName'] ?? 'Member'}',
                              style: GoogleFonts.roboto(
                                color: Colors.black,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          
                        ],
                      ),
                    ),
                    SizedBox(height: 10),
                    
                    // Expandable sections for selected member
                    Padding(
                      padding: const EdgeInsets.all(18.0),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                          
                            Divider(height: 1, thickness: 1, color: Colors.grey[200]),
                            _buildExpandableSection(
                              'Educational Details',
                              userProfiles[selectedMemberIndex],
                              [
                                'cEducationName',
                                'cInstitutionName',
                                'dYearofPassing'
                                
                              ],
                              Icons.school,
                            ),
                            Divider(height: 1, thickness: 1, color: Colors.grey[200]),
                            _buildExpandableSection(
                              'Physical Details',
                              userProfiles[selectedMemberIndex],
                              ['nHeight', 'nWeight', 'cBloodGroup'],
                              Icons.health_and_safety,
                            ),
                            Divider(height: 1, thickness: 1, color: Colors.grey[200]),
                          ],
                        ),
                      ),
                    ),
                  ],

                  SizedBox(height: size.height * 0.02),
                ],
              ),
            ),
          ),
        ),
      ),
    ),);
  }

Widget buildInfoItem(String label, String value) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 4,
        height: 4,
        margin: const EdgeInsets.only(top: 6, right: 6),
        decoration: BoxDecoration(
          color: Colors.cyan,
          shape: BoxShape.circle,
        ),
      ),
      SizedBox(
        width: 80,
        child: Text(
          "$label",
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 12,
            color: Colors.grey[700],
          ),
        ),
      ),
    Expanded(
        child: Text( ": $value",
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 12,
            color: Colors.grey[900],
          ),
        ),
      ),
    ],
  );
}

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey),
        SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 12, color: Colors.black,fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
  
 Widget _buildExpandableSection(
  String title,
  Map<String, dynamic> data,
  List<String> fields,
  IconData icon,
) {
  return Theme(
    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
    child: ExpansionTile(
      leading: Icon(icon, color: Colors.cyan[700]),
      title: Text(
        title,
        style: GoogleFonts.roboto(
          color: Colors.black87,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
      iconColor: Colors.cyan[700],
      collapsedIconColor: Colors.grey[600],
      children: fields.map((field) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  _formatFieldName(field),
                  style: GoogleFonts.roboto(
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                    fontSize: 13,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  field == 'dYearofPassing'
                      ? _formatDate(data[field]?.toString())
                      : (data[field]?.toString() ?? 'N/A'),
                  style: GoogleFonts.roboto(
                    color: Colors.black87,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    ),
  );
}


 String _formatFieldName(String field) {
    if (field == 'dYearofPassing') return 'Year of Passing';
  String formatted = field.substring(1);
  return formatted
      .replaceAllMapped(
        RegExp(r'([A-Z])'),
        (match) => ' ${match.group(0)}',
      )
      .trim();
      
      
}

String _formatDate(String? dateStr) {
  if (dateStr == null || dateStr.isEmpty) return 'N/A';
  try {
    DateTime date = DateTime.parse(dateStr);
    // Format: Jan 2016
    return "${_getMonthName(date.month)} ${date.year}";
  } catch (e) {
    return dateStr; // fallback if parsing fails
  }
}

String _getMonthName(int month) {
  const months = [
    "Jan", "Feb", "Mar", "Apr", "May", "Jun",
    "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
  ];
  return months[month - 1];
}
}

class CustomCacheManager {
  static const key = 'customCacheKey';

  static CacheManager instance = CacheManager(
    Config(
      key,
      stalePeriod: const Duration(days: 30), // ✅ Keep cache for 30 days
      maxNrOfCacheObjects: 200,              // ✅ Allow enough objects
      repo: JsonCacheInfoRepository(databaseName: key),
      fileService: HttpFileService(),
    ),
  );
}