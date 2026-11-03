import 'package:Koottaayma/ADMIN%20FOLDER/2adminbottomnavigation.dart';
import 'package:Koottaayma/BETSEIDHA/betseidhaguestbottom.dart';
import 'package:Koottaayma/BETSEIDHA/betseidhauserbottom.dart';
import 'package:Koottaayma/BETSEIDHA/bpriestbottom.dart';
import 'package:Koottaayma/DEVICEINFO/deviceinfo.dart';
import 'package:Koottaayma/GUEST%20FOLDER/8guestregister.dart';
import 'package:Koottaayma/GUEST%20FOLDER/guestbottomnavigation.dart';
import 'package:Koottaayma/HTTPURL/httpurl.dart';
import 'package:Koottaayma/PRIESTFATHER%20FOLDER/priestbottomnavigation.dart';
import 'package:Koottaayma/SQFLITEVERSION1/DataBaseHelper.dart';
import 'package:Koottaayma/SQFLITEVERSION1/LabelDetails.dart';
import 'package:Koottaayma/TEACHER%20%20FOLDER/9sundayschool.dart';
import 'package:Koottaayma/USER%20FOLDER/6bottomnavigation.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:otp_text_field/otp_field.dart';
import 'package:otp_text_field/style.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class OTPVerification extends StatefulWidget {
  final int languageId;
  final int phoneNumber; //if passing formatted phoneno that is phonenumber with country code then it is must be string
  final int nUserTypeID;
  final String verificationId;
 
  const OTPVerification({
    super.key, 
    required this.languageId,
    required this.phoneNumber,
    required this.nUserTypeID,
    required this.verificationId,
  });

  @override
  State<OTPVerification> createState() => _OTPVerificationState();
}

class _OTPVerificationState extends State<OTPVerification> {
  final dbHelper = DatabaseHelper();
  OtpFieldController otpController = OtpFieldController();
  String otpCode = '';
  List<LabelDetails> allLabels = [];
  
  // Label texts
  String titleText = 'Enter OTP';
  String descriptionText = 'Enter the code from the SMS we sent to your phone number';
  String verifyButtonText = 'Submit';
  String resendText = "Didn't receive OTP?";
  String resendLinkText = 'Resend';
  
  // Loading states
  bool isLoading = true;
  bool isVerifying = false;
  String? errorMessage;

   


  @override
  void initState() {
    super.initState();
    fetchOTPLabels();
  }

  Future<void> fetchOTPLabels() async {
    try {
      print('Fetching labels for OTP page (page 3), language ${widget.languageId}');
      
      final labels = await dbHelper.getLabelsForPage(2, widget.languageId, widget.nUserTypeID);
      print('Found ${labels.length} labels for OTP page');
      
      if (labels.isEmpty) {
        setState(() {
          errorMessage = 'No labels found for OTP page. Using default text.';
          isLoading = false;
        });
        return;
      }
      
      for (var label in labels) {
        print('Mapping OTP label ID ${label.nLabelID}: ${label.cLabelKey}');
        switch (label.nLabelID) {
          case 1:
            titleText = label.cLabelKey;
            break;
          case 2:
            descriptionText = label.cLabelKey;
            break;
          case 3:
            verifyButtonText = label.cLabelKey;
            break;
          case 4:
            resendText = label.cLabelKey;
            break;
          case 5:
            resendLinkText = label.cLabelKey;
            break;
        }
      }

      setState(() {
        allLabels = labels;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching OTP labels: $e');
      setState(() {
        errorMessage = 'Error fetching labels: $e. Using default text.';
        isLoading = false;
      });
    }
  }

  Future<void> verifyOTP() async {
   // Fetch device info for logging and debugging
    final deviceData = await DeviceInfoService.getDeviceInfo();
    print('DEVICE DATA: $deviceData');

   if (otpCode.length < 6) {
    _showSnackBar('Please enter complete OTP', Colors.orange);
    return;
  }

  setState(() => isVerifying = true);

  try {
   
    PhoneAuthCredential credential = PhoneAuthProvider.credential(
      verificationId: widget.verificationId, // ← use widget.verificationId
      smsCode: otpCode,                       // ← use otpCode from OTP field
    );
    await FirebaseAuth.instance.signInWithCredential(credential);
    print('Firebase sign-in successful');

    String? fcmToken = await FirebaseMessaging.instance.getToken();
    print("FCM Token in login: $fcmToken");

    //  THEN your existing HTTP call continues below
    print('Verifying OTP for phone: ${widget.phoneNumber}');
    final response = await http.post(
      Uri.parse(VerifyUserPhoneNUmber),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        
        'nPhoneNumber': widget.phoneNumber,
        'cFCMToken': fcmToken,
        'nDeviceType':1,
        

      }),
    );
   
      
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
     
      setState(() => isVerifying = false);

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        
        print('Response data type: ${responseData.runtimeType}');
        print('Response data: $responseData');

        //  NEW CODE: Save response to SQLite immediately
        try {
          await _saveCompleteResponseToDatabase(responseData, widget.phoneNumber);
          print(' Complete response saved to SQLite successfully');
        } catch (e) {
          print(' Error saving response to SQLite: $e');
        }
  
        if (responseData is Map<String, dynamic>) {
          List<Map<String, dynamic>> availableRoles = [];
          
          responseData.forEach((roleKey, roleValue) {
            if (roleValue is List && roleValue.isNotEmpty) {
              final roleData = roleValue[0] as Map<String, dynamic>;
              
              // Extract baptism count for THIS specific role
              int roleBaptismCount = 0;
              if (roleData.containsKey('nBaptismCount')) {
                roleBaptismCount = roleData['nBaptismCount'] ?? 0;
                print('Baptism Count for $roleKey: $roleBaptismCount');
              }
              
              // Extract guest count
              int roleGuestCount = 0;
              if (roleData.containsKey('nGuestCount')) {
                roleGuestCount = roleData['nGuestCount'] ?? 0;
                print('Guest Count for $roleKey: $roleGuestCount');
              }
              
              String? jwtToken;
              if (roleData.containsKey('UserToken') && 
                  roleData['UserToken'] is Map<String, dynamic>) {
                jwtToken = roleData['UserToken']['jwt']?.toString();
              }
              
              String? username;
              if (roleData.containsKey('UserToken') && 
                  roleData['UserToken'] is Map<String, dynamic>) {
                username = roleData['UserToken']['username']?.toString();
              }
              
              // Extract database name
              String? databaseName = roleData['cDataBaseName']?.toString();
              
              String? roleType;
              roleData.forEach((key, value) {
                if (key.startsWith('nUserType')) {
                  roleType = value.toString();
                }
              });
              
              // Add role if roleType exists
              // Guest can have null token (first time), other roles must have token
              if (roleType != null) {
                String roleLower = roleType!.toLowerCase();
                
                // For non-guest roles, token is required
                if (roleLower != 'guest' && jwtToken == null) {
                  print('Skipping role $roleKey - missing required JWT token');
                  return;
                }
                
                availableRoles.add({
                  'key': roleKey,
                  'type': roleLower,
                  'displayName': roleType,
                  'jwt': jwtToken, // Can be null for first-time guest
                  'username': username,
                  'baptismCount': roleBaptismCount, // Store baptism count with role
                  'guestCount': roleGuestCount, // Store guest count with role
                  'database': databaseName, // Store database name with role
                });
                print('Found role: $roleKey with token: ${jwtToken ?? "none (new guest)"}, baptismCount: $roleBaptismCount, guestCount: $roleGuestCount, database: $databaseName');
              }
            }
          });
          
          print('Available roles: $availableRoles');
          
          if (availableRoles.isEmpty) {
            _showSnackBar('No valid roles found', Colors.red);
            return;
          }
          // Subscribe to FCM topic for all members after successful OTP verification
             await FirebaseMessaging.instance.subscribeToTopic("all_members");
          if (availableRoles.length > 1) {
            _showRoleSelectionDialog(availableRoles);
          } else {
            await _saveUserDataAndNavigate(availableRoles[0]);
          }
        } else {
          _showSnackBar('Unexpected response format', Colors.red);
        }
      }
      else if (response.statusCode == 400) {
        _showSnackBar('Invalid OTP. Please try again.', Colors.red);
      } else {
        _showSnackBar('Verification failed. Please try again.', Colors.red);
      }
    } catch (e, stackTrace) {
      setState(() => isVerifying = false);
    _showSnackBar('Please check and enter the correct verification code again.', Colors.red);
      print('OTP verification error: $e');
      print('Stack trace: $stackTrace');
    }
  }

  //  NEW FUNCTION: Save complete API response to SQLite
  Future<void> _saveCompleteResponseToDatabase(
    Map<String, dynamic> responseData,
    int phoneNumber,
  ) async {
    try {
      print(' Starting to save API response to SQLite...');
      
      // Loop through each role (User, Guest, Priest, Admin, Teacher)
      for (var roleEntry in responseData.entries) {
        String roleKey = roleEntry.key; // "User", "Guest", etc.
        var roleValue = roleEntry.value;
        
        if (roleValue is List && roleValue.isNotEmpty) {
          var roleData = roleValue[0];
          
          // Save the complete role data as JSON string
          await dbHelper.saveCompleteUserData(
            roleKey: roleKey,
            phoneNumber: phoneNumber,
            completeData: jsonEncode(roleData),
          );
          
          print(' Saved $roleKey data to SQLite');
          
          // Also save specific sections if needed
          if (roleData is Map<String, dynamic>) {
            
            // Save Gospel Readings
            if (roleData.containsKey('GospelReadings')) {
              await dbHelper.saveGospelReadings(
                phoneNumber: phoneNumber,
                gospelData: jsonEncode(roleData['GospelReadings']),
              );
              print(' Saved Gospel Readings');
            }
            
            // Save Special Programs
            if (roleData.containsKey('lstSpecialPrograms')) {
              await dbHelper.saveSpecialPrograms(
                phoneNumber: phoneNumber,
                programsData: jsonEncode(roleData['lstSpecialPrograms']),
              );
              print(' Saved Special Programs');
            }
            
            // Save Holy Mass Timings
            if (roleData.containsKey('lstHolyMassTimings')) {
              await dbHelper.saveHolyMassTimings(
                phoneNumber: phoneNumber,
                massTimingsData: jsonEncode(roleData['lstHolyMassTimings']),
              );
              print(' Saved Holy Mass Timings');
            }
            
            // Save Family Details
            if (roleData.containsKey('lstFamilyDetails')) {
              await dbHelper.saveFamilyDetails(
                phoneNumber: phoneNumber,
                familyData: jsonEncode(roleData['lstFamilyDetails']),
              );
              print(' Saved Family Details');
            }

              // Save Japamala Details
            if (roleData.containsKey('GetJapamala')) {
              await dbHelper.saveJapamalaDetails(
                phoneNumber: phoneNumber,
                japamalaData: jsonEncode(roleData['GetJapamala']),
              );
              print(' Saved japamala Details');
            }
              
              // Save karunayudekontha Details
            if (roleData.containsKey('GetJapamalaOthers')) {
              await dbHelper.saveKarunayuddeKonthaDetails(
                phoneNumber: phoneNumber,
                karunayudekonthaData: jsonEncode(roleData['GetJapamalaOthers']),
              );
              print(' Saved karunayude kontha Details');
            }

               // Save padapooja Details
            if (roleData.containsKey('GetJapamalaOthers2')) {
              await dbHelper.savePadapoojaDetails(
                phoneNumber: phoneNumber,
                padapoojaData: jsonEncode(roleData['GetJapamalaOthers2']),
              );
              print(' Saved padapooja Details');
            }


             // Save kurishinttevazhi Details
            if (roleData.containsKey('KurishinteVazhi')) {
              await dbHelper.saveKurishinttevazhiDetails(
                phoneNumber: phoneNumber,
                kurishinttevazhiData: jsonEncode(roleData['KurishinteVazhi']),
              );
              print(' Saved kurishinttevazhi Details');
            }

             // Save parish Details
            if (roleData.containsKey('lstParishDetails')) {
              await dbHelper.saveParishDetails(
                phoneNumber: phoneNumber,
                parishData: jsonEncode(roleData['lstParishDetails']),
              );
              print(' Saved parish Details');
            }
             //   SelectedChurchDetails
           if (roleData.containsKey('SelectedChurchDetails')) {
              await dbHelper.saveChurchDetails(
                phoneNumber: phoneNumber,
                churchData: jsonEncode(roleData['SelectedChurchDetails']),
              );
              print(' Saved parish Details');
            }

            //today verse 
              if (roleData.containsKey('TodaysVerse')) {
              await dbHelper.saveTodayVerse(
                phoneNumber: phoneNumber,
                todayverseData: jsonEncode(roleData['TodaysVerse']),
              );
              print(' Saved today verse Details');
            }
          }
        }
      }
      
      // Save sync timestamp
      await dbHelper.updateLastSyncTime(phoneNumber);
      print(' All data cached successfully in SQLite');
      
    } catch (e, stackTrace) {
      print('Error in _saveCompleteResponseToDatabase: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Show dialog to select role when multiple roles exist
  void _showRoleSelectionDialog(List<Map<String, dynamic>> roles) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Select Your Role',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'You have multiple roles associated with this number. Please select one to continue:',
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
                SizedBox(height: 20),
                ...roles.map((role) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: Material(
                      elevation: 2,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: () {
                          Navigator.of(context).pop();
                          _saveUserDataAndNavigate(role);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _getRoleIcon(role['type']!),
                                color: _getRoleColor(role['type']!),
                                size: 28,
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      role['displayName']!,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  // Get icon for each role type
  IconData _getRoleIcon(String roleType) {
    switch (roleType) {
      case 'admin':
        return Icons.admin_panel_settings;
      case 'teacher':
        return Icons.school;
      case 'user':
        return Icons.person;
      case 'guest':
        return Icons.person_outline;
      case 'priest':
        return Icons.church;
      default:
        return Icons.account_circle;
    }
  }

  Color _getRoleColor(String roleType) {
    switch (roleType) {
      case 'admin':
        return Colors.red;
      case 'teacher':
        return Colors.blue;
      case 'user':
        return Colors.green;
      case 'guest':
        return Colors.orange;
      case 'priest':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Future<void> _saveUserDataAndNavigate(Map<String, dynamic> roleData) async {
    try {
      String userType = roleData['type']!;
      String userTypeKey = roleData['key']!;
      String? token = roleData['jwt']; // Nullable for first-time guest
      int baptismCount = roleData['baptismCount'] ?? 0;
      int guestCount = roleData['guestCount'] ?? 0; // Get from roleData
      
      // Try both 'database' and 'cDataBaseName' fields
      String? database = roleData['database'] ?? roleData['cDataBaseName'];
      
      print("User Type: $userType");
      print("Role Data: $roleData");
      print("Baptism Count for selected role: $baptismCount");
      print("Guest count for selected role: $guestCount");
      print("Database: $database");
    final String? fcmtoken = await FirebaseMessaging.instance.getToken();
      // Save to SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('userPhone', widget.phoneNumber.toString());
      await prefs.setString('languageid', widget.languageId.toString());
      await prefs.setString('usertype', userType);
      await prefs.setString('userTypeKey', userTypeKey);
      await prefs.setBool('isRegistered', true);
      await prefs.setString('fcmToken', fcmtoken ?? ''); 
      
      // Save database name if it exists
      if (database != null && database.isNotEmpty) {
        await prefs.setString('database', database);
        print('Database saved: $database'); // Debug
      } else {
        await prefs.remove('database');
        print('No database found in roleData'); // Debug
      }
      
      // Save token only if it exists
      if (token != null) {
        await prefs.setString('jwt', token);
      } else {
        await prefs.remove('jwt');
      }
      
      // Save baptism count and guest count for the selected role
      await prefs.setInt('baptismCount', baptismCount);
      await prefs.setInt('guestCount', guestCount);
      
      // Debug prints
      String? phone = prefs.getString('userPhone');
      String? languageId = prefs.getString('languageid');
      String? savedUserType = prefs.getString('usertype');
      bool? isRegistered = prefs.getBool('isRegistered');
      int? savedBaptismCount = prefs.getInt('baptismCount');
      int? savedGuestCount = prefs.getInt('guestCount');
      String? savedToken = prefs.getString('jwt');
      String? savedDatabase = prefs.getString('database');

      print('Saved Phone: $phone');
      print('Saved Language ID: $languageId');
      print('Saved User Type: $savedUserType');
      print('Saved User Type Key: $userTypeKey');
      print('Is Registered: $isRegistered');
      print('Saved Baptism Count: $savedBaptismCount');
      print('Saved Guest Count: $savedGuestCount');
      print('Saved Database: $savedDatabase');
      print('Navigating as: $userType with database: $database');
      print('Saved JWT Token: ${savedToken ?? "none (new guest)"}');

      // Navigation based on user type (case-insensitive comparison)
      String userTypeLower = userType.toLowerCase();
      
      if (userTypeLower == 'user') {
        print('user navigation - database value: "$database"'); // Debug
        
        if (database != null && database.isNotEmpty) {
          if (database == 'Koottaayma') {
            print('Navigating to My Community user Page'); // Debug
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => BottomNavigation(
                languageId: widget.languageId, 
                phoneNumber: widget.phoneNumber,),
              ),
            );
          } else if (database == 'Bethsaida') {
            print('Navigating to Betseidha Priest Page'); // Debug
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => BetseidhaUserBottomNaigation(
                  languageId: widget.languageId,
                  phoneNumber: widget.phoneNumber,
                ),
              ),
            );
          } 
        } 
      }
      else if (userTypeLower == 'admin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => AdminBottomNavigation(
              languageId: widget.languageId,
              phoneNumber: widget.phoneNumber,
            ),
          ),
        );
      } else if (userTypeLower == 'teacher') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => SunDaySchoolPage( 
              languageId: widget.languageId,
              phoneNumber: widget.phoneNumber,
            ),
          ),
        );
      } 
      else if (userTypeLower == 'guest') {
        print('guest navigation - database value: "$database"'); // Debug
        print('isRegistered value: "$isRegistered"'); // Debug
        
        // Case-insensitive check for isRegistered - handles "True", "true", "False", "false"
        bool registered = isRegistered?.toString().toLowerCase() == 'true';
        
        print('Parsed registered value: $registered'); // Debug to confirm parsing
        
        // Check if user is registered first, regardless of database
        if (!registered) {
          // User is not registered - navigate to registration page first
          print('User not registered, navigating to guest registration page');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => Guestregister(
                languageId: widget.languageId, 
                phoneNumber: widget.phoneNumber,
              ),
            ),
          );
        }
        // Only check database if user is registered
        else if (database != null && database.isNotEmpty && database != 'null') {
          if (database == 'Koottaayma') {
            print('Navigating to Koottaayma Guest Page');
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => Guestbottomnavigation(
                  languageId: widget.languageId,
                  phoneNumber: widget.phoneNumber,
                ),
              ),
            );
          } else if (database == 'Bethsaida') {
            print('Navigating to Betseidha Guest Page');
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => BetseidhaGuestbottomnavigation(
                  languageId: widget.languageId,
                  phoneNumber: widget.phoneNumber,
                ),
              ),
            );
          } else {
            print('Unknown database: $database');
          }
        } else {
          // User is registered but database is null - shouldn't happen normally
          print('User registered but no database assigned - navigating to registration');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => Guestregister(
                languageId: widget.languageId, 
                phoneNumber: widget.phoneNumber,
              ),
            ),
          );
        }
      }
      else if (userTypeLower == 'priest') {
        print('Priest navigation - database value: "$database"'); // Debug
        
        // Handle priest navigation based on database
        if (database != null && database.isNotEmpty) {
          if (database == 'Koottaayma') {
            print('Navigating to My Community Priest Page'); // Debug
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => PriestBottomNavigation(
                  languageId: widget.languageId,
                  phoneNumber: widget.phoneNumber,
                ),
              ),
            );
          } else if (database == 'Bethsaida') {
            print('Navigating to Betseidha Priest Page'); // Debug
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => BetseidhaPriestBottom(
                  languageId: widget.languageId,
                  phoneNumber: widget.phoneNumber,
                ),
              ),
            );
          } else {
            print('Database "$database" not recognized, using default priest page'); // Debug
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => PriestBottomNavigation(
                  languageId: widget.languageId,
                  phoneNumber: widget.phoneNumber,
                ),
              ),
            );
          }
        } 
        else {
          print('No database specified, using default priest page'); // Debug
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => PriestBottomNavigation(
                languageId: widget.languageId,
                phoneNumber: widget.phoneNumber,
              ),
            ),
          );
        }
      } else {
        print('Unknown user type: "$userType", navigating to guest page'); // Debug
        // Default fallback
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => Guestregister(
              languageId: widget.languageId, 
              phoneNumber: widget.phoneNumber,
            ),
          ),
        );
      }
      
    } catch (e) {
      print('Error saving data and navigating: $e');
      print('Stack trace: ${StackTrace.current}'); // More detailed error
      _showSnackBar('Navigation error: ${e.toString()}', Colors.red);
    }
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    if (isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Container(
          height: size.height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.cyan,
                const Color.fromARGB(255, 202, 236, 241),
                Colors.white
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomCenter,
            ),
            image: DecorationImage(
              image: AssetImage('assets/god.png'),
              scale: 1,
              opacity: 0.5,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: size.height * 0.45),
                
                // Title
                Text(
                  titleText,
                  style: GoogleFonts.lato(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                SizedBox(height: 15),
                
                // Description
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    descriptionText,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.lato(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                
                SizedBox(height: 10),
                
                SizedBox(height: size.height * 0.05),
                
                // OTP Input Field
                OTPTextField(
                  controller: otpController,
                  length: 6,
                  width: MediaQuery.of(context).size.width,
                  textFieldAlignment: MainAxisAlignment.spaceAround,
                  fieldWidth: 45,
                  fieldStyle: FieldStyle.box,
                  outlineBorderRadius: 15,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  onChanged: (pin) {
                    setState(() {
                      otpCode = pin;
                    });
                  },
                  onCompleted: (pin) {
                    setState(() {
                      otpCode = pin;
                    });
                  },
                ),
                
                SizedBox(height: size.height * 0.05),
                
                // Verify Button
                GestureDetector(
                  onTap: isVerifying ? null : verifyOTP,
                  child: Container(
                    width: double.infinity,
                    height: size.height * 0.06,
                    decoration: BoxDecoration(
                      color: isVerifying ? Colors.grey : Colors.blue,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: isVerifying ? [] : [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.3),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: isVerifying
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              verifyButtonText,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ),
                
                SizedBox(height: size.height * 0.03),
                
                // Error message display
                if (errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        errorMessage!,
                        style: TextStyle(
                          color: Colors.red[700],
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                
                Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}