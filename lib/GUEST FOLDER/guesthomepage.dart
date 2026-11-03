// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// class Church {
//   final int id;
//   final String name;

//   Church({required this.id, required this.name});

//   factory Church.fromJson(Map<String, dynamic> json) {
//     return Church(
//       id: json['nChurchID'],
//       name: json['cChurchName'],
//     );
//   }
// }

// class District {
//   final int id;
//   final String name;

//   District({required this.id, required this.name});

//   factory District.fromJson(Map<String, dynamic> json) {
//     return District(
//       id: json['nDistrictID'],
//       name: json['cName'],
//     );
//   }
// }

// class GuestHome extends StatefulWidget {
//   final int languageId;
//   final int phoneNumber;
  
//   const GuestHome({super.key, required this.languageId, required this.phoneNumber});

//   @override
//   State<GuestHome> createState() => _GuestHomeState();
// }

// class _GuestHomeState extends State<GuestHome> {
//   List<Church> churches = [];
//   List<District> districts = [];
//   int? selectedChurchId;
//   int? selectedDistrictId;
//   bool isLoading = true;
//   bool isSubmitting = false;

//   // Registration data from SharedPreferences
//   String? firstName;
//   String? lastName;
//   String? address;
//   String? dob;
//   String? phoneNo;
//   int? genderId;

//   @override
//   void initState() {
//     super.initState();
//     loadRegistrationData();
//     fetchDropdownData();
//   }

//   Future<void> loadRegistrationData() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
    
//     setState(() {
//       firstName = prefs.getString('cFirstName');
//       lastName = prefs.getString('cLastName');
//       address = prefs.getString('cAddress');
//       dob = prefs.getString('dDoB');
//       phoneNo = prefs.getString('nPhoneNo');
//       genderId = prefs.getInt('nGenderID');
//     });

//     print('Loaded registration data:');
//     print('Name: $firstName $lastName');
//     print('Address: $address');
//     print('DOB: $dob');
//     print('Phone: $phoneNo');
//     print('Gender ID: $genderId');
//   }

//   Future<void> fetchDropdownData() async {
//     try {
//       final response = await http.get(
//         Uri.parse("https://79056d4q-7000.inc1.devtunnels.ms/guestdetails/getchurch/"),
//       );

//       if (response.statusCode == 201 || response.statusCode == 200) {
//         final decoded = jsonDecode(response.body);

//         churches = (decoded['ChurchDetails'] as List)
//             .map((e) => Church.fromJson(e))
//             .toList();

//         districts = (decoded['Districts'] as List)
//             .map((e) => District.fromJson(e))
//             .toList();

//         setState(() {
//           isLoading = false;
//         });
//       }
//     } catch (e) {
//       print('Error fetching data: $e');
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }

//   Future<void> submitGuestRegistration() async {
//     if (selectedChurchId == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Please select a church/parish'),
//           backgroundColor: Colors.red,
//         ),
//       );
//       return;
//     }

//     setState(() {
//       isSubmitting = true;
//     });

//     try {
//       // Prepare the complete registration data
//       final registrationData = {
//         'cFirstName': firstName,
//         'cLastName': lastName,
//         'cAddress': address,
//         'nPhoneNo': phoneNo,
//         'nGenderID': genderId,
//         'nParishID': selectedChurchId, // Add selected church/parish
//       };

//       print('Submitting registration data: $registrationData');

//       final response = await http.post(
//         Uri.parse("https://79056d4q-7000.inc1.devtunnels.ms/guestdetails/"), // Update with your actual endpoint
//         headers: {
//           'Content-Type': 'application/json',
//         },
//         body: jsonEncode(registrationData),
//       );

//       setState(() {
//         isSubmitting = false;
//       });

//       if (response.statusCode == 200 || response.statusCode == 201) {
//         // Clear SharedPreferences after successful submission
//         SharedPreferences prefs = await SharedPreferences.getInstance();
//         await prefs.remove('cFirstName');
//         await prefs.remove('cLastName');
//         await prefs.remove('cAddress');
//         await prefs.remove('dDoB');
//         await prefs.remove('nPhoneNo');
//         await prefs.remove('nGenderID');

//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('Registration Successful!'),
//             backgroundColor: Colors.green,
//           ),
//         );

//         // Navigate to next page or home
//         // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => NextPage()));
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
//         isSubmitting = false;
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
//       body: Container(
//         width: double.infinity,
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             colors: [
//               Colors.cyan,
//               Color.fromARGB(255, 158, 218, 228),
//               Colors.white,
//             ],
//             begin: Alignment.topLeft,
//             end: Alignment.bottomCenter,
//           ),
//         ),
//         child: SingleChildScrollView(
//           child: Column(
//             children: [
//               // Header Section with Image
//               Container(
//                 height: 290,
//                 width: double.infinity,
//                 decoration: BoxDecoration(
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.black.withOpacity(1),
//                       spreadRadius: 2,
//                       blurRadius: 10,
//                     ),
//                   ],
//                   image: const DecorationImage(
//                     image: AssetImage('assets/Logo.jpg'),
//                     fit: BoxFit.cover,
//                     opacity: 0.4,
//                   ),
//                 ),
//                 child: SafeArea(
//                   child: Padding(
//                     padding: const EdgeInsets.only(left: 30, right: 30),
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         const SizedBox(height: 20),
//                         Text(
//                           'Find your',
//                           style: GoogleFonts.kodchasan(
//                             fontSize: 25,
//                             fontWeight: FontWeight.bold,
//                             color: Colors.white,
//                           ),
//                         ),
//                         Text(
//                           'worship place?',
//                           style: GoogleFonts.kodchasan(
//                             fontSize: 25,
//                             fontWeight: FontWeight.bold,
//                             color: Colors.white,
//                           ),
//                         ),
//                         const SizedBox(height: 30),
//                         // Dropdowns Row
//                         Row(
//                           children: [
//                             // Church Dropdown
//                             Container(
//                               height: 40,
//                               width: 150,
//                               padding: const EdgeInsets.symmetric(horizontal: 8),
//                               decoration: BoxDecoration(
//                                 color: Colors.white,
//                                 borderRadius: BorderRadius.circular(5),
//                               ),
//                               child: DropdownButtonHideUnderline(
//                                 child: isLoading
//                                     ? const Center(
//                                         child: SizedBox(
//                                           height: 20,
//                                           width: 20,
//                                           child: CircularProgressIndicator(strokeWidth: 2),
//                                         ),
//                                       )
//                                     : DropdownButton<int>(
//                                         value: selectedChurchId,
//                                         hint: const Text(
//                                           "Select Church",
//                                           style: TextStyle(fontSize: 12),
//                                         ),
//                                         isExpanded: true,
//                                         icon: const Icon(Icons.arrow_drop_down, size: 20),
//                                         items: churches.map((church) {
//                                           return DropdownMenuItem<int>(
//                                             value: church.id,
//                                             child: Text(
//                                               church.name,
//                                               style: const TextStyle(fontSize: 12),
//                                               overflow: TextOverflow.ellipsis,
//                                             ),
//                                           );
//                                         }).toList(),
//                                         onChanged: (value) {
//                                           setState(() {
//                                             selectedChurchId = value;
//                                           });
//                                         },
//                                       ),
//                               ),
//                             ),
//                             const SizedBox(width: 25),
//                             // District Dropdown
//                             Container(
//                               height: 40,
//                               width: 150,
//                               padding: const EdgeInsets.symmetric(horizontal: 8),
//                               decoration: BoxDecoration(
//                                 color: Colors.white,
//                                 borderRadius: BorderRadius.circular(5),
//                               ),
//                               child: DropdownButtonHideUnderline(
//                                 child: isLoading
//                                     ? const Center(
//                                         child: SizedBox(
//                                           height: 20,
//                                           width: 20,
//                                           child: CircularProgressIndicator(strokeWidth: 2),
//                                         ),
//                                       )
//                                     : DropdownButton<int>(
//                                         value: selectedDistrictId,
//                                         hint: const Text(
//                                           "Select District",
//                                           style: TextStyle(fontSize: 12),
//                                         ),
//                                         isExpanded: true,
//                                         icon: const Icon(Icons.arrow_drop_down, size: 20),
//                                         items: districts.map((district) {
//                                           return DropdownMenuItem<int>(
//                                             value: district.id,
//                                             child: Text(
//                                               district.name,
//                                               style: const TextStyle(fontSize: 12),
//                                               overflow: TextOverflow.ellipsis,
//                                             ),
//                                           );
//                                         }).toList(),
//                                         onChanged: (value) {
//                                           setState(() {
//                                             selectedDistrictId = value;
//                                           });
//                                         },
//                                       ),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
              
//               // Complete Registration Button
//               const SizedBox(height: 20),
//               Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 28.0),
//                 child: ElevatedButton(
//                   onPressed: isSubmitting ? null : submitGuestRegistration,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: const Color.fromARGB(255, 49, 76, 126),
//                     foregroundColor: Colors.white,
//                     minimumSize: const Size(double.infinity, 45),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(5),
//                     ),
//                   ),
//                   child: isSubmitting
//                       ? const SizedBox(
//                           height: 20,
//                           width: 20,
//                           child: CircularProgressIndicator(
//                             color: Colors.white,
//                             strokeWidth: 2,
//                           ),
//                         )
//                       : const Text(
//                           'Complete Registration',
//                           style: TextStyle(fontSize: 16),
//                         ),
//                 ),
//               ),
              
//               // Near You Section
//               const SizedBox(height: 30),
//               Padding(
//                 padding: const EdgeInsets.all(28.0),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Text(
//                           'Near You',
//                           style: GoogleFonts.roboto(
//                             color: Colors.black,
//                             fontSize: 18,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                         Text(
//                           'View All',
//                           style: GoogleFonts.roboto(
//                             color: Colors.black,
//                             fontSize: 14,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 10),
//                     SizedBox(
//                       height: 300,
//                       child: ListView.builder(
//                         scrollDirection: Axis.horizontal,
//                         itemCount: 5,
//                         itemBuilder: (context, index) {
//                           return Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Container(
//                               height: 300,
//                               width: 330,
//                               decoration: BoxDecoration(
//                                 image: const DecorationImage(
//                                   image: AssetImage('assets/church1.png'),
//                                   fit: BoxFit.cover,
//                                 ),
//                                 color: Colors.white,
//                                 borderRadius: BorderRadius.circular(35),
//                               ),
//                               child: Padding(
//                                 padding: const EdgeInsets.all(16.0),
//                                 child: Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   mainAxisAlignment: MainAxisAlignment.end,
//                                   children: [
//                                     Text(
//                                       'Betseidha',
//                                       textAlign: TextAlign.left,
//                                       style: GoogleFonts.roboto(
//                                         fontWeight: FontWeight.bold,
//                                         color: Colors.white,
//                                         fontSize: 18,
//                                       ),
//                                     ),
//                                     Row(
//                                       children: [
//                                         const Icon(
//                                           Icons.place,
//                                           color: Colors.white,
//                                           size: 13,
//                                         ),
//                                         const SizedBox(width: 4),
//                                         Text(
//                                           'Vizhinjam, Kerala',
//                                           style: GoogleFonts.roboto(
//                                             color: Colors.white,
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ),
//                           );
//                         },
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
// ///////////////////////////////////
// ///import 'package:MyCommunity/GUEST%20FOLDER/9guestchurchselectionpage.dart';
// // import 'package:MyCommunity/HTTPURL/httpurl.dart';
// // import 'package:MyCommunity/SQFLITEVERSION1/DataBaseHelper.dart';
// // import 'package:MyCommunity/SQFLITEVERSION1/LabelDetails.dart';
// // import 'package:flutter/material.dart';
// // import 'package:flutter/services.dart';
// // import 'package:google_fonts/google_fonts.dart';
// // import 'package:shared_preferences/shared_preferences.dart';

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

//   Future<void> _saveToSharedPreferences() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
    
//     // Save registration details
//     await prefs.setString('cFirstName', _firstNameController.text.trim());
//     await prefs.setString('cLastName', _lastNameController.text.trim());
//     await prefs.setString('cAddress', _addressController.text.trim());
//     await prefs.setString('dDoB', _dobController.text);
//     await prefs.setString('nPhoneNo', _phoneController.text.trim());
//     await prefs.setInt('nGenderID', _selectedGenderId!);
//     await prefs.setBool('isRegistered', true);
    
//     print('Data saved to SharedPreferences');
//   }

//   Future<void> _proceedToChurchSelection() async {
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
//       // Save to SharedPreferences
//       await _saveToSharedPreferences();

//       setState(() {
//         _isLoading = false;
//       });

//       // Navigate to church selection page
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(
//           builder: (context) => GuestHome(
//             languageId: widget.languageId,
//             phoneNumber: widget.phoneNumber,
//           ),
//         ),
//       );
//     } catch (e) {
//       setState(() {
//         _isLoading = false;
//       });
      
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Error saving data: ${e.toString()}'),
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
//                       fillColor: Colors.grey[200],
//            filled: true,
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
//                                     errorStyle: TextStyle(height: 0),
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
//                         onPressed: _isLoading ? null : _proceedToChurchSelection,
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
//                                 'Continue',
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