
// import 'package:MyCommunity/GUEST%20FOLDER/9guestchurchselectionpage.dart';
// import 'package:MyCommunity/HTTPURL/httpurl.dart';
// import 'package:MyCommunity/SQFLITEVERSION1/DataBaseHelper.dart';
// import 'package:MyCommunity/SQFLITEVERSION1/LabelDetails.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';

// import 'package:shared_preferences/shared_preferences.dart';

// class Guestregister extends StatefulWidget {
//   final int languageId;
//   final int phoneNumber;
//   const Guestregister({
//     super.key,
//     required this.languageId,
//     required this.phoneNumber,
//   });

//   @override
//   State<Guestregister> createState() => _GuestregisterState();
// }

// class _GuestregisterState extends State<Guestregister> {
//   final _formKey = GlobalKey<FormState>();
  
//   final TextEditingController _firstNameController = TextEditingController();
//   final TextEditingController _lastNameController = TextEditingController();
//   final TextEditingController _addressController = TextEditingController();
//   final TextEditingController _dobController = TextEditingController();
//   final TextEditingController _phoneController = TextEditingController();
  
//   String? _selectedGender;
//   int? _selectedGenderId;
//   bool _isLoading = false;

//   final List<Map<String, dynamic>> _genderOptions = [
//     {'id': 1, 'name': 'Male'},
//     {'id': 2, 'name': 'Female'},
//   ];
  
//   final dbHelper = DatabaseHelper();
//   List<LabelDetails> allLabels = [];
//   String titleText = 'Register';
//   String firstnameText = 'First Name';
//   String firstnameHint = 'Enter your first name';
//   String lastnameText = 'Last Name';
//   String lastnameHint = 'Enter your last name';
//   String addressText = 'Address';
//   String addressHint = 'Enter your address';
//   String dobText = 'Date of Birth';
//   String dobHint = 'Select your date of birth';
//   String genderText = 'Gender';
//   String genderHint = 'Select your gender';
//   String phonenumberText = 'Phone Number';
//   String phonenumberHint = 'Enter your phone number';
  
//   bool isLoading = true;
//   String? errorMessage;
   
//   @override
//   void initState() {
//     super.initState();
//     fetchGuestRegisterLabels();
//   }

//   @override
//   void dispose() {
//     _firstNameController.dispose();
//     _lastNameController.dispose();
//     _addressController.dispose();
//     _dobController.dispose();
//     _phoneController.dispose();
//     super.dispose();
//   }

//   Future<void> fetchGuestRegisterLabels() async {
//     const int nPageID = 3;
//     const int nUserTypeID = 3;
    
//     try {
//       print('Fetching labels for page $nPageID, userType $nUserTypeID, language ${widget.languageId}');
      
//       await dbHelper.debugPrintLabelDetails();
      
//       final labels = await dbHelper.getLabelsForPage(
//         nPageID, 
//         widget.languageId,
//         nUserTypeID,
//       );
      
//       print('Found ${labels.length} labels for guest registration page');
      
//       if (labels.isEmpty) {
//         setState(() {
//           errorMessage = 'No labels found for selected language. Using default text.';
//           isLoading = false;
//         });
//         return;
//       }
      
//       for (var label in labels) {
//         print('Mapping label ID ${label.nLabelID}: ${label.cLabelKey}');
//         switch (label.nLabelID) {
//           case 1:
//             titleText = label.cLabelKey;
//             break;
//           case 2:
//             firstnameText = label.cLabelKey;
//             break;
//           case 3:
//             firstnameHint = label.cLabelKey;
//             break;
//           case 4:
//             lastnameText = label.cLabelKey;
//             break;
//           case 5:
//             lastnameHint = label.cLabelKey;
//             break;
//           case 6:
//             addressText = label.cLabelKey;
//             break;
//           case 7:
//             addressHint = label.cLabelKey;
//             break;
//           case 8:
//             dobText = label.cLabelKey;
//             break;
//           case 9:
//             dobHint = label.cLabelKey;
//             break;
//           case 10:
//             genderText = label.cLabelKey;
//             break;
//           case 11:
//             genderHint = label.cLabelKey;
//             break;
//           case 12:
//             phonenumberText = label.cLabelKey;
//             break;
//           case 13:
//             phonenumberHint = label.cLabelKey;
//             break;
//         }
//       }

//       setState(() {
//         allLabels = labels;
//         isLoading = false;
//       });
//     } catch (e) {
//       print('Error fetching guest registration labels: $e');
//       setState(() {
//         errorMessage = 'Error fetching labels: $e. Using default text.';
//         isLoading = false;
//       });
//     }
//   }

//   String? _validateName(String? value, String fieldName) {
//     if (value == null || value.trim().isEmpty) {
//       return '';
//     }
//     return null;
//   }

//   String? _validateAddress(String? value) {
//     if (value == null || value.trim().isEmpty) {
//       return '';
//     }
//     return null;
//   }

//   String? _validateDOB(String? value) {
//     if (value == null || value.isEmpty) {
//       return '';
//     }
//     return null;
//   }

//   String? _validatePhone(String? value) {
//     if (value == null || value.trim().isEmpty) {
//       return '';
//     }
//     if (value.trim().length != 10) {
//       return '';
//     }
//     return null;
//   }

//   String? _validateGender() {
//     if (_selectedGenderId == null) {
//       return '';
//     }
//     return null;
//   }

//   Future<void> _selectDate(BuildContext context) async {
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: DateTime.now().subtract(Duration(days: 365 * 18)), 
//       firstDate: DateTime(1900),
//       lastDate: DateTime.now(),
//       helpText: 'Select Date of Birth',
//     );
//     if (picked != null) {
//       setState(() {
//         _dobController.text = "${picked.day.toString().padLeft(2, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.year}";
//       });
//     }
//   }

//   Future<void> _selectGender(BuildContext context) async {
//     await showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Text('Select Gender'),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: _genderOptions.map((gender) {
//               return ListTile(
//                 title: Text(gender['name']),
//                 onTap: () {
//                   setState(() {
//                     _selectedGender = gender['name'];
//                     _selectedGenderId = gender['id'];
//                   });
//                   Navigator.pop(context);
//                 },
//               );
//             }).toList(),
//           ),
//         );
//       },
//     );
//   }

//   Future<void> _registerGuest() async {
//     if (!_formKey.currentState!.validate()) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Please fill all the required fields'),
//           backgroundColor: Colors.red,
//         ),
//       );
//       return;
//     }

//     final genderError = _validateGender();
//     if (genderError != null && genderError.isNotEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Please select gender'),
//           backgroundColor: Colors.red,
//         ),
//       );
//       return;
//     }

//     setState(() {
//       _isLoading = true;
//     });

//     try {
//       final response = await http.post(
//         Uri.parse(GuestDetails),
//         headers: {
//           'Content-Type': 'application/json',
//         },
//         body: jsonEncode({
//           'cFirstName': _firstNameController.text.trim(),
//           'cLastName': _lastNameController.text.trim(),
//           'cAddress': _addressController.text.trim(),
//           'dDoB': _dobController.text,
//           'nPhoneNo': _phoneController.text.trim(),
//           'nGenderID': _selectedGenderId,
//         }),
//       );

//       setState(() {
//         _isLoading = false;
//       });

//       if (response.statusCode == 200 || response.statusCode == 201) {
//         // In your registration completion code
//           SharedPreferences prefs = await SharedPreferences.getInstance();
//              await prefs.setBool('isRegistered', true);
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Registration Successful!'),
//             backgroundColor: Colors.green,
//           ),
//         );
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(builder: (context) => GuestHome(languageId: widget.languageId, phoneNumber: widget.phoneNumber,)),
//         );
//       } else {
//         final errorMessage = jsonDecode(response.body)['message'] ?? 
//             'Registration failed. Please try again.';
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(errorMessage),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     } catch (e) {
//       setState(() {
//         _isLoading = false;
//       });
      
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Network error: ${e.toString()}'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: SingleChildScrollView(
//         child: Container(
//           width: double.infinity,
//           decoration: BoxDecoration(
//             gradient: LinearGradient(
//               colors: [
//                 Colors.cyan,
//                 Color.fromARGB(255, 158, 218, 228),
//                 Colors.white,
//               ],
//               begin: Alignment.topLeft,
//               end: Alignment.bottomCenter,
//             ),
//           ),
//           child: SingleChildScrollView(
//             child: Form(
//               key: _formKey,
//               //autovalidateMode: AutovalidateMode.disabled, 
//               child: Column(
//                 children: [
//                   SizedBox(height: 80),
//                   Column(
//                     crossAxisAlignment: CrossAxisAlignment.center,
//                     children: [
//                       Center(
//                         child: Text(
//                           titleText,
//                           style: GoogleFonts.lato(
//                             color: Colors.black,
//                             fontSize: 28,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       ),
//                       SizedBox(height: 10),
//                       Padding(
//                         padding: const EdgeInsets.all(8.0),
//                         child: Container(
//                           width: double.infinity,
//                           decoration: BoxDecoration(
//                             color: Colors.white,
//                             borderRadius: BorderRadius.circular(10),
//                           ),
//                           child: Padding(
//                             padding: const EdgeInsets.all(18.0),
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Text(firstnameText, style: GoogleFonts.notoSansJavanese()),
//                                 SizedBox(height: 5),
//                                 TextFormField(
//                                   controller: _firstNameController,
//                                   validator: (value) => _validateName(value, firstnameText),
//                                   textCapitalization: TextCapitalization.words,
//                                   inputFormatters: [
//                                     FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
//                                   ],
//                                   decoration: InputDecoration(
//                                     border: OutlineInputBorder(
//                                       borderRadius: BorderRadius.circular(5),
//                                     ),
//                                     enabledBorder: OutlineInputBorder(
//                                       borderRadius: BorderRadius.circular(5),
//                                       borderSide: BorderSide(color: Colors.grey[300]!),
//                                     ),
//                                     errorStyle: TextStyle(height: 0), 
//                                     errorBorder: OutlineInputBorder(
//                                       borderRadius: BorderRadius.circular(5),
//                                       borderSide: BorderSide(color: Colors.red, width: 2),
//                                     ),
//                                     focusedErrorBorder: OutlineInputBorder(
//                                       borderRadius: BorderRadius.circular(5),
//                                       borderSide: BorderSide(color: Colors.red, width: 2),
//                                     ),
//                                     hintText: firstnameHint,
//                                     fillColor: Colors.grey[200],
//                                     filled: true,
//                                     suffixIcon: Icon(Icons.person, color: Colors.grey[400]),
//                                     contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
//                                   ),
//                                 ),
//                                 SizedBox(height: 20),
//                                 Text(lastnameText, style: GoogleFonts.notoSansJavanese()),
//                                 SizedBox(height: 5),
//                                 TextFormField(
//                                   controller: _lastNameController,
//                                   validator: (value) => _validateName(value, lastnameText),
//                                   textCapitalization: TextCapitalization.words,
//                                   inputFormatters: [
//                                     FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
//                                   ],
//                                   decoration: InputDecoration(
//                                     border: OutlineInputBorder(
//                                       borderRadius: BorderRadius.circular(5),
//                                     ),
//                                     enabledBorder: OutlineInputBorder(
//                                       borderRadius: BorderRadius.circular(5),
//                                       borderSide: BorderSide(color: Colors.grey[300]!),
//                                     ),
//                                     errorStyle: TextStyle(height: 0), 
//                                     errorBorder: OutlineInputBorder(
//                                       borderRadius: BorderRadius.circular(5),
//                                       borderSide: BorderSide(color: Colors.red, width: 2),
//                                     ),
//                                     focusedErrorBorder: OutlineInputBorder(
//                                       borderRadius: BorderRadius.circular(5),
//                                       borderSide: BorderSide(color: Colors.red, width: 2),
//                                     ),
//                                     hintText: lastnameHint,
//                                     fillColor: Colors.grey[200],
//                                     filled: true,
//                                     suffixIcon: Icon(Icons.person, color: Colors.grey[400]),
//                                     contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
//                                   ),
//                                 ),
//                                 SizedBox(height: 20),
//                                 Text(addressText, style: GoogleFonts.notoSansJavanese()),
//                                 SizedBox(height: 5),
//                                 TextFormField(
//                                   controller: _addressController,
//                                   validator: _validateAddress,
//                                   maxLines: 2,
//                                   textCapitalization: TextCapitalization.sentences,
//                                   decoration: InputDecoration(
//                                     border: OutlineInputBorder(
//                                       borderRadius: BorderRadius.circular(5),
//                                     ),
//                                     enabledBorder: OutlineInputBorder(
//                                       borderRadius: BorderRadius.circular(5),
//                                       borderSide: BorderSide(color: Colors.grey[300]!),
//                                     ),
//                                     errorStyle: TextStyle(height: 0), 
//                                     errorBorder: OutlineInputBorder(
//                                       borderRadius: BorderRadius.circular(5),
//                                       borderSide: BorderSide(color: Colors.red, width: 2),
//                                     ),
//                                     focusedErrorBorder: OutlineInputBorder(
//                                       borderRadius: BorderRadius.circular(5),
//                                       borderSide: BorderSide(color: Colors.red, width: 2),
//                                     ),
//                                     hintText: addressHint,
//                                     fillColor: Colors.grey[200],
//                                     filled: true,
//                                     suffixIcon: Icon(Icons.place, color: Colors.grey[400]),
//                                     contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
//                                   ),
//                                 ),
//                                 SizedBox(height: 20),
//                                 Text(dobText, style: GoogleFonts.notoSansJavanese()),
//                                 SizedBox(height: 5),
//                                 TextFormField(
//                                   controller: _dobController,
//                                   validator: _validateDOB,
//                                   readOnly: true,
//                                   onTap: () => _selectDate(context),
//                                   decoration: InputDecoration(
//                                     border: OutlineInputBorder(
//                                       borderRadius: BorderRadius.circular(5),
//                                     ),
//                                     enabledBorder: OutlineInputBorder(
//                                       borderRadius: BorderRadius.circular(5),
//                                       borderSide: BorderSide(color: Colors.grey[300]!),
//                                     ),
//                                     errorStyle: TextStyle(height: 0), 
//                                     errorBorder: OutlineInputBorder(
//                                       borderRadius: BorderRadius.circular(5),
//                                       borderSide: BorderSide(color: Colors.red, width: 2),
//                                     ),
//                                     focusedErrorBorder: OutlineInputBorder(
//                                       borderRadius: BorderRadius.circular(5),
//                                       borderSide: BorderSide(color: Colors.red, width: 2),
//                                     ),
//                                     hintText: 'DD-MM-YYYY',
//                                     fillColor: Colors.grey[200],
//                                     filled: true,
//                                     suffixIcon: Icon(Icons.calendar_month, color: Colors.grey[400]),
//                                     contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
//                                   ),
//                                 ),
//                                 SizedBox(height: 20),
//                                 Text(genderText, style: GoogleFonts.notoSansJavanese()),
//                                 SizedBox(height: 5),
//                                 GestureDetector(
//                                   onTap: () => _selectGender(context),
//                                   child: Container(
//                                     decoration: BoxDecoration(
//                                       color: Colors.grey[200],
//                                       borderRadius: BorderRadius.circular(5),
//                                       border: Border.all(
//                                         color: Colors.grey[300]!,
//                                       ),
//                                     ),
//                                     child: InputDecorator(
//                                       decoration: InputDecoration(
//                                         border: InputBorder.none,
//                                         contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
//                                         suffixIcon: Icon(Icons.arrow_drop_down_sharp),
//                                       ),
//                                       child: Text(
//                                         _selectedGender ?? genderHint,
//                                         style: TextStyle(
//                                           color: _selectedGender == null ? Colors.grey[600] : Colors.black,
//                                         ),
//                                       ),
//                                     ),
//                                   ),
//                                 ),
//                                 SizedBox(height: 20),
//                                 Text(phonenumberText, style: GoogleFonts.notoSansJavanese()),
//                                 SizedBox(height: 5),
//                                 TextFormField(
//                                   controller: _phoneController,
//                                   validator: _validatePhone,
//                                   keyboardType: TextInputType.phone,
//                                   maxLength: 10,
//                                   inputFormatters: [
//                                     FilteringTextInputFormatter.digitsOnly,
//                                     LengthLimitingTextInputFormatter(10),
//                                   ],
//                                   decoration: InputDecoration(
//                                     border: OutlineInputBorder(
//                                       borderRadius: BorderRadius.circular(5),
//                                     ),
//                                     enabledBorder: OutlineInputBorder(
//                                       borderRadius: BorderRadius.circular(5),
//                                       borderSide: BorderSide(color: Colors.grey[300]!),
//                                     ),
//                                     errorStyle: TextStyle(height: 0), // Hides error text
//                                     errorBorder: OutlineInputBorder(
//                                       borderRadius: BorderRadius.circular(5),
//                                       borderSide: BorderSide(color: Colors.red, width: 2),
//                                     ),
//                                     focusedErrorBorder: OutlineInputBorder(
//                                       borderRadius: BorderRadius.circular(5),
//                                       borderSide: BorderSide(color: Colors.red, width: 2),
//                                     ),
//                                     hintText: phonenumberHint,
//                                     fillColor: Colors.grey[200],
//                                     filled: true,
//                                     suffixIcon: Icon(Icons.phone, color: Colors.grey[400]),
//                                     contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
//                                     counterText: '', 
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),
//                       ),
//                       SizedBox(height: 10),
//                       ElevatedButton(
//                         onPressed: _isLoading ? null : _registerGuest,
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.cyan,
//                           foregroundColor: Colors.white,
//                           minimumSize: Size(300, 45),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                           elevation: 5,
//                         ),
//                         child: _isLoading
//                             ? SizedBox(
//                                 height: 20,
//                                 width: 20,
//                                 child: CircularProgressIndicator(
//                                   color: Colors.white,
//                                   strokeWidth: 2,
//                                 ),
//                               )
//                             : Text(
//                                 titleText,
//                                 style: TextStyle(fontSize: 18),
//                               ),
//                       ),
//                       SizedBox(height: 20),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }