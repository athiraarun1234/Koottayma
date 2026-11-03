
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';

// class PhoneNumberField extends StatefulWidget {
//   const PhoneNumberField({Key? key}) : super(key: key);

//   @override
//   State<PhoneNumberField> createState() => _PhoneNumberFieldState();
// }

// class _PhoneNumberFieldState extends State<PhoneNumberField> {
//   final TextEditingController _phoneController = TextEditingController();
//   bool _isLoading = false;

//   @override
//   void initState() {
//     super.initState();
//   }

//   @override
//   void dispose() {
//     _phoneController.dispose();
//     super.dispose();
//   }

//   Future<void> _verifyPhoneNumber() async {
//     String phoneNumber = _phoneController.text.trim();

//     if (phoneNumber.isEmpty) {
//       _showSnackBar('Please enter a phone number');
//       return;
//     }

//     setState(() {
//       _isLoading = true;
//     });

//     try {
//       final response = await http.post(
//         Uri.parse('https://lv4hfxvb-7000.inc1.devtunnels.ms/verifyusers/'),
//         headers: {
//           'Content-Type': 'application/json',
//         },
//         body: jsonEncode({
//           'phone': phoneNumber,
//         }),
//       );

//       setState(() {
//         _isLoading = false;
//       });

//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         String userType = data['user']?.toString().toLowerCase() ?? '';

//         // Navigate based on user type
//         if (userType == 'user') {
//           Navigator.pushReplacement(
//             context,
//             MaterialPageRoute(builder: (context) => HomePage()),
//           );
//         } else if (userType == 'admin') {
//           Navigator.pushReplacement(
//             context,
//             MaterialPageRoute(builder: (context) => AdminPage()),
//           );
//         } else if (userType == 'guest') {
//           Navigator.pushReplacement(
//             context,
//             MaterialPageRoute(builder: (context) => GuestPage()),
//           );
//         } else {
//           _showSnackBar('Unknown user type');
//         }
//       } else {
//         _showSnackBar('Verification failed. Please try again.');
//       }
//     } catch (e) {
//       setState(() {
//         _isLoading = false;
//       });
//       _showSnackBar('Error: ${e.toString()}');
//     }
//   }

//   void _showSnackBar(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: Colors.red,
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final size = MediaQuery.of(context).size;

//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: SingleChildScrollView(
//         child: Container(
//           decoration: BoxDecoration(
//             gradient: LinearGradient(
//               colors: [
//                 Colors.cyan,
//                 const Color.fromARGB(255, 202, 236, 241),
//                 Colors.white
//               ],
//               begin: Alignment.topLeft,
//               end: Alignment.bottomCenter,
//             ),
//             image: DecorationImage(
//               image: AssetImage('assets/god.png'),
//               scale: 1,
//               opacity: 0.5,
//             ),
//           ),
//           child: Padding(
//             padding: const EdgeInsets.all(20.0),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.start,
//               children: [
//                 SizedBox(height: size.height * 0.2),
//                 Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   mainAxisAlignment: MainAxisAlignment.start,
//                   children: [
//                     Text(
//                       'Verify Your',
//                       style: GoogleFonts.lato(
//                         fontSize: 25,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     Text(
//                       'Phone Number',
//                       style: GoogleFonts.lato(
//                         fontSize: 25,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     SizedBox(height: size.height * 0.01),
//                     Text(
//                       'We have send you an one time password(OTP) on this mobile number',
//                       style: GoogleFonts.lato(),
//                     )
//                   ],
//                 ),
//                 SizedBox(height: size.height * 0.21),
//                 TextFormField(
//                   controller: _phoneController,
//                   keyboardType: TextInputType.phone,
//                   decoration: InputDecoration(
//                     hintText: 'Phone Number',
//                     hintStyle: TextStyle(color: Colors.black45, fontSize: 15),
//                     fillColor: Colors.white,
//                     filled: true,
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(5),
//                       borderSide: BorderSide.none,
//                     ),
//                   ),
//                 ),
//                 SizedBox(height: size.height * 0.03),
//                 GestureDetector(
//                   onTap: _isLoading ? null : _verifyPhoneNumber,
//                   child: Container(
//                     width: double.infinity,
//                     height: size.height * 0.06,
//                     decoration: BoxDecoration(
//                       color: _isLoading ? Colors.grey : Colors.blue,
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                     child: Center(
//                       child: _isLoading
//                           ? CircularProgressIndicator(color: Colors.white)
//                           : Text(
//                               'GET OTP',
//                               style: GoogleFonts.poppins(
//                                 color: Colors.white,
//                                 fontSize: 17,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                     ),
//                   ),
//                 ),
//                 SizedBox(height: size.height * 0.015),
//                 Divider(),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Text(
//                       "Already have an account?",
//                       style: GoogleFonts.poppins(fontSize: 12),
//                     ),
//                     SizedBox(width: size.width * 0.03),
//                     Text(
//                       "Sign in ",
//                       style: GoogleFonts.poppins(
//                         color: Colors.blue,
//                         fontSize: 12,
//                       ),
//                     )
//                   ],
//                 )
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// // Placeholder pages - Replace these with your actual page implementations
// class HomePage extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('User Home Page')),
//       body: Center(child: Text('Welcome User!')),
//     );
//   }
// }

// class AdminPage extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('Admin Page')),
//       body: Center(child: Text('Welcome Admin!')),
//     );
//   }
// }

// class GuestPage extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('Guest Page')),
//       body: Center(child: Text('Welcome Guest!')),
//     );
//   }
// }