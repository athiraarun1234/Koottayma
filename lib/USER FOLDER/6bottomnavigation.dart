

import 'package:Koottaayma/BAPTISUM%20USER%20FOLDER/getreferencecode.dart';
import 'package:Koottaayma/BOTTOMNAVIGATIONICON/razorpayamountsetting.dart';
import 'package:Koottaayma/BOTTOMNAVIGATIONICON/razorpaypayment.dart';
import 'package:Koottaayma/HOMEPAGEICONS/saint.dart';
import 'package:Koottaayma/OBITUARY/getfamilymembers.dart';
import 'package:Koottaayma/SQFLITEVERSION1/7accountpage1.dart';
import 'package:Koottaayma/SQFLITEVERSION1/DataBaseHelper.dart';
import 'package:Koottaayma/SQFLITEVERSION1/LabelDetails.dart';
import 'package:Koottaayma/SQFLITEVERSION1/PhoneNumberField.dart';
import 'package:Koottaayma/USER%20FOLDER/5homepage.dart';
import 'package:Koottaayma/USER%20FOLDER/8usercertificaterequest.dart';
import 'package:Koottaayma/USER%20FOLDER/8userdailyrequest.dart';
import 'package:Koottaayma/USER%20FOLDER/8usersacramentalrequest.dart';
import 'package:Koottaayma/USER%20FOLDER/myrequests.dart';
import 'package:Koottaayma/USER%20FOLDER/priestmessageshowingpage.dart';
import 'package:Koottaayma/USER%20FOLDER/usersacramentalsnewpage.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
///////////////////////// aaaaaaaaaaaaaaaaa
class BottomNavigation extends StatefulWidget {
 final int languageId;
 final int phoneNumber;
  const BottomNavigation({super.key,
 required this.languageId , required this.phoneNumber,
  });

  @override
  State<BottomNavigation> createState() => _BottomNavigationState();
}

class _BottomNavigationState extends State<BottomNavigation> {
  // Initialize _selectedIndex
  int _selectedIndex = 0;
   bool _isLoading = false;
    bool isLoading = true;
  String? errorMessage;
  // Screens for navigation
  late List<Widget> _pages;
  final dbHelper=DatabaseHelper();
  List<LabelDetails>allLabels=[];
  String titleText='User My Community';
  String firsttabtext='Home';
  String secondtabtext='Messages';
  String thirdtabtext='Accounts';
  String fourthtabtext='My Requests';
  String fifthtabtext='About';
  String sixthtabtext='Forgot Password';
  String seventhtabtext='Logout';
 @override
  void initState() {
    super.initState();
    _pages = [
      HomePage(),
      SaintPage(languageId: widget.languageId, phoneNumber: widget.phoneNumber),
      const SizedBox(),
      PaymentGateway(languageId: widget.languageId, phoneNumber: widget.phoneNumber),
      AccountPage(),
    ];
    fetchBottomPageLabels();

  }
  void _onItemTapped(int index) {
    if (index == 2) {
      showHalfContainer();
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }
 
void showHalfContainer() {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => FractionallySizedBox(
      heightFactor: 0.5, //  Increased slightly to fit 2 rows
      widthFactor: 1.0,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Header
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.cyan[100],
                  child: const Icon(Icons.message, size: 25),
                ),
                const SizedBox(width: 20),
                Text(
                  "Requests",
                  style: GoogleFonts.roboto(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(color: Colors.cyan),

            //  Row 1 — 4 icons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                      //  Navigator.push(context, MaterialPageRoute(builder: (context) => UserSacramentalsRequest()));
                          Navigator.push(context, MaterialPageRoute(builder: (context) => UserSacramentalsNewPage()));
                      },
                      child: Container(
                        height: 75,
                        width: 75,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.cyan),
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Image.asset('assets/msgicon1.png'),
                      ),
                    ),
                    const Text('Sacramentals'),
                  ],
                ),
                Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => UserDailyRequest()));
                      },
                      child: Container(
                        height: 75,
                        width: 75,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.cyan),
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Image.asset('assets/msgicon2.png'),
                      ),
                    ),
                    const Text('Daily Request'),
                  ],
                ),
                Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => UserCertificateRequest()));
                      },
                      child: Container(
                        height: 75,
                        width: 75,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.cyan),
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Image.asset('assets/msgicon4.png'),
                      ),
                    ),
                    const Text('Certificate'),
                  ],
                ),
                Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => DocumentaionUploading()));
                      },
                      child: Container(
                        height: 75,
                        width: 75,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.cyan),
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Image.asset('assets/msgicon3.png'),
                      ),
                    ),
                    const Text('Documents'),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            //  Row 2 — Events icon (left-aligned)
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(width: 16),
                Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => ObituaryMemberDetails())); // 🔁 Replace with your Events page
                      },
                      child: Container(
                        height: 75,
                        width: 75,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.cyan),
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Image.asset('assets/msgicon7.png'), 
                      ),
                    ),
                    const Text('Obituary'),
                  ],
                ),
              ],
            ),

          ],
        ),
      ),
    ),
  );
}
   Future<void> fetchBottomPageLabels() async {
    const int nPageID = 4;
    const int nUserTypeID = 3;
    
    try {
      print('Fetching labels for page $nPageID, userType $nUserTypeID, language ${widget.languageId}');
      
      await dbHelper.debugPrintLabelDetails();
      
      final labels = await dbHelper.getLabelsForPage(
        nPageID, 
        widget.languageId,
        nUserTypeID,
      );
      
      print('Found ${labels.length} labels for guest registration page');
      
      if (labels.isEmpty) {
        setState(() {
          errorMessage = 'No labels found for selected language. Using default text.';
          isLoading = false;
        });
        return;
      }
      
      for (var label in labels) {
        print('Mapping label ID ${label.nLabelID}: ${label.cLabelKey}');
        switch (label.nLabelID) {
          case 1:
            titleText = label.cLabelKey;
            break;
          case 2:
            firsttabtext = label.cLabelKey;
            break;
          case 3:
            secondtabtext = label.cLabelKey;
            break;
          case 4:
            thirdtabtext = label.cLabelKey;
            break;
          case 5:
           fourthtabtext = label.cLabelKey;
            break;
          case 6:
            fifthtabtext = label.cLabelKey;
            break;
          case 7:
           sixthtabtext = label.cLabelKey;
            break;
          case 8:
            seventhtabtext = label.cLabelKey;
            break;
         
        }
      }

      setState(() {
        allLabels = labels;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching guest registration labels: $e');
      setState(() {
        errorMessage = 'Error fetching labels: $e. Using default text.';
        isLoading = false;
      });
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
      child: Scaffold(
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Colors.cyan[700],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        Column(
                          children: [
                            const Text(''),
                            Text(
                              'User My Community',
                              style: GoogleFonts.roboto(
                                fontSize: 23,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: Icon(Icons.home, size: 20, color: Colors.cyan[800]),
                title: Text(
                 firsttabtext,
                  style: GoogleFonts.roboto(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _selectedIndex = 0;
                  });
                },
              ),
              ListTile(
                leading: Icon(Icons.message, size: 20, color: Colors.cyan[800]),
                title: Text(
                  'Messages',
                  style: GoogleFonts.roboto(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) =>  PriestMessages()));
                },
              ),
              ListTile(
                leading: Icon(Icons.person, size: 20, color: Colors.cyan[800]),
                title: Text(
                  'Accounts',
                  style: GoogleFonts.roboto(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _selectedIndex = 2;
                  });
                },
              ),
              ListTile(
                leading: Icon(Icons.request_page, size: 20, color: Colors.cyan[800]),
                title: Text(
                  'My Requests',
                  style: GoogleFonts.roboto(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => Baptisumgetdetails(baptismData: {},dailyRequest: {}),));
                },
              ),
              ListTile(
                leading: Icon(Icons.info, size: 20, color: Colors.cyan[800]),
                title: Text(
                  'About',
                  style: GoogleFonts.roboto(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () {
                  // Add navigation logic
                },
              ),
              ListTile(
                leading: Icon(Icons.password, size: 20, color: Colors.cyan[800]),
                title: Text(
                  'Forgot Password',
                  style: GoogleFonts.roboto(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () {
                  // Add navigation logic
                },
              ),
              ListTile(
                leading: Icon(Icons.logout, size: 20, color: Colors.cyan[800]),
                title: Text(
                  'Logout',
                  style: GoogleFonts.roboto(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  showLogoutConfirmation(context);
                },
              ),
            ],
          ),
        ),
                      
          body: _pages[_selectedIndex],
          bottomNavigationBar: SafeArea(
          child: CurvedNavigationBar(
            backgroundColor: Colors.transparent, // Background color of the body
            color: const Color.fromARGB(255, 199, 246, 252), // Background color of the bar
            buttonBackgroundColor: Colors.cyan[50], // Background color of the active button
            height: 60,
            index: _selectedIndex,
            items: <Widget>[
              Icon(Icons.home, size: 26, color: Colors.cyan),
            //  Icon(Icons.church, size: 26, color: Colors.cyan),
             Image.asset('assets/saint.png',width: 25,height: 30,),
              Image.asset('assets/add.png',width: 40,height: 40,),
             Image.asset('assets/payment.png',width: 30,height: 30,),
             // Icon( Icons.church, size: 26, color: Colors.cyan),
              Icon(Icons.person, size: 26, color: Colors.cyan),
              
            ],
            onTap: (index) {
              _onItemTapped(index);
            },
            animationDuration: Duration(milliseconds: 300),
            animationCurve: Curves.easeInOut,
          ),
        ),
                       ),
    );
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
}                                                                                                                                 