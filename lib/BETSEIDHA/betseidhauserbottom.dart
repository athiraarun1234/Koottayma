
import 'package:Koottaayma/BETSEIDHA/betseidhapriestsendingmessagesget.dart';
import 'package:Koottaayma/BETSEIDHA/betseidhauseraccount.dart';
import 'package:Koottaayma/BETSEIDHA/betseihapriestapprovalmembermessages.dart';
import 'package:Koottaayma/BETSEIDHA/betusermediasend%20.dart';
import 'package:Koottaayma/SQFLITEVERSION1/PhoneNumberField.dart';
import 'package:Koottaayma/USER%20FOLDER/5homepage.dart';
import 'package:Koottaayma/USER%20FOLDER/8userdailyrequest.dart';

import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BetseidhaUserBottomNaigation extends StatefulWidget {
  
  const BetseidhaUserBottomNaigation({super.key, required int languageId, required int phoneNumber,});

  @override
  State<BetseidhaUserBottomNaigation> createState() => _BetseidhaUserBottomNaigationState();
}

class _BetseidhaUserBottomNaigationState extends State<BetseidhaUserBottomNaigation> {
  int _selectedIndex = 0;
  // Screens for navigation
  final List<Widget> _pages = [
    HomePage(),
   const SizedBox(),
    BetseidhaUserAccountPage(),
  //  const SizedBox(),
  ];


void _onItemTapped(int index) {
    if (index == 1) {
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
        heightFactor: 0.4,
        widthFactor: 1.0,
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.cyan[100],
                    child: const Icon(Icons.message, size: 25),
                  ),
                  const SizedBox(width: 20),
                  Text(
                    "Chat Support",
                    style: GoogleFonts.roboto(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const Divider(color: Colors.cyan),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) =>BetseidhaUserMediaUploadSelector(),));
                        },
                        child: Container(
                          height: 100,
                          width: 100,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.cyan),
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Image.asset('assets/msgicon1.png'),
                        ),
                      ),
                      const Text('Upload'),
                    ],
                  ),
                  Column(
                    children: [
                      GestureDetector(
                        onTap: () {
                         // _showNavigationDailyRequest(context);
                            Navigator.push(context, MaterialPageRoute(builder: (context) =>UserDailyRequest() ,));
                        },
                        child: Container(
                          height: 100,
                          width: 100,
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
                  // Column(
                  //   children: [
                  //     GestureDetector(
                  //       onTap: () {
                  //         Navigator.push(context, MaterialPageRoute(builder: (context) => UserCertificateRequest(),));
                  //       },
                  //       child: Container(
                  //         height: 100,
                  //         width: 100,
                  //         decoration: BoxDecoration(
                  //           border: Border.all(color: Colors.cyan),
                  //           color: Colors.white,
                  //           borderRadius: BorderRadius.circular(25),
                  //         ),
                  //         child: Image.asset('assets/msgicon4.png',),
                  //       ),
                  //     ),
                  //     const Text('Certificate'),
                  //   ],
                  // ),
                ],
              ),
            
            ],
          ),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Add drawer menu
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.cyan[700]
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                   //  Image.asset('assets/vetoculoscope.png', scale: 20,),
                      Column(
                        children: [
                          Text(''),
                          Text(
                            'My betseidha user',
                            style: GoogleFonts.roboto(
                              fontSize: 23,
                              fontWeight: FontWeight.bold,
                              color: Colors.white
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
              
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.home, size: 20, color: Colors.cyan[800],),
              title: Text('Home', style: GoogleFonts.roboto(fontSize: 15, fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                setState(() {
                  _selectedIndex = 0;
                });
              },
            ),
            ListTile(
              leading: Icon(Icons.message, size: 20, color: Colors.cyan[800], ),
              title: Text('Member Messages', style: GoogleFonts.roboto(fontSize: 15, fontWeight: FontWeight.bold)),
              onTap: () {
               Navigator.push(context, MaterialPageRoute(builder: (context) =>Betseidhapriestapprovalusermessages(),));
              },
            ),
            ListTile(
              leading: Icon(Icons.person, size: 20, color: Colors.cyan[800], ),
              title: Text('Accounts', style: GoogleFonts.roboto(fontSize: 15, fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                setState(() {
                  _selectedIndex = 2;
                });
              },
            ),
            // Divider(),
              ListTile(
              leading: Icon(Icons.newspaper, size: 20, color: Colors.cyan[800],),
              title: Text('Daily News', style: GoogleFonts.roboto(fontSize: 15, fontWeight: FontWeight.bold)),
              onTap: () {
              
              },
            ),
            ListTile(
              leading: Icon(Icons.info, size: 20, color: Colors.cyan[800],),
              title: Text('About', style: GoogleFonts.roboto(fontSize: 15, fontWeight: FontWeight.bold)),
              onTap: () {
              
              },
            ),
            ListTile(
              leading: Icon(Icons.message, size: 20, color: Colors.cyan[800], ),
              title: Text('Priest Messages', style: GoogleFonts.roboto(fontSize: 15, fontWeight: FontWeight.bold)),
              onTap: () {
               Navigator.push(context, MaterialPageRoute(builder: (context) =>Betseidhapriestsendingmessages(),));
              }
            ),
            ListTile(
              leading: Icon(Icons.logout, size: 20, color: Colors.cyan[800],),
              title: Text('Logout', style: GoogleFonts.roboto(fontSize: 15, fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                // Show logout confirmation
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
           //   Icon(Icons.message, size: 26, color: Colors.cyan),
            
            Image.asset('assets/add.png',width: 40,height: 40,),
            //  Icon(Icons.message, size: 26, color: Colors.cyan),
            
            Icon(Icons.person, size: 26, color: Colors.cyan),
            
          ],
          onTap: (index) {
            _onItemTapped(index);
          },
          animationDuration: Duration(milliseconds: 300),
          animationCurve: Curves.easeInOut,
        ),
      ),
    );
  }
   // Show logout confirmation
void showLogoutConfirmation(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Logout'),
        content: Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
            },
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop(); // Close the dialog
              await logout(context); // Call the logout function
            },
            child: Text('Logout'),
          ),
        ],
      );
    },
  );
}


Future<void> logout(BuildContext context) async {
  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    
    // Get language ID before clearing (to preserve it)
    String? savedLanguageId = prefs.getString('languageid');
    
    // Clear user-specific data (logout the user)
    // In your logout function

    await prefs.remove('isRegistered');

    await prefs.remove('userPhone');
    await prefs.remove('usertype');
    await prefs.remove('userTypeKey');
    // Keep languageid so user doesn't have to select language again
    
    print('User logged out successfully');
    print('Preserved language ID: $savedLanguageId');
    
    // Navigate to login page
    int languageId = int.tryParse(savedLanguageId ?? '0') ?? 0;
    
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => PhoneNumber(
          languageId: languageId,
          phoneNumber: 0,
          nUserTypeID: 0,
        ),
      ),
      (route) => false, // Remove all previous routes from stack
    );
  } catch (e) {
    print('Error during logout: $e');
    // Show error message to user
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Logout failed: ${e.toString()}'),
        backgroundColor: Colors.red,
      ),
    );
  }
}
}

