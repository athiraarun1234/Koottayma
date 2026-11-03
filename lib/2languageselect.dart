
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';


// class LanguageModel {
//   final int nLanguageID;
//   final String cLanguageName;

//   LanguageModel({
//     required this.nLanguageID,
//     required this.cLanguageName,
//   });

//   factory LanguageModel.fromJson(Map<String, dynamic> json) {
//     return LanguageModel(
//       nLanguageID: json['nLanguageID'],
//       cLanguageName: json['cLanguageName'],
//     );
//   }
// }

// class Selectlanguagestype extends StatefulWidget {
//   const Selectlanguagestype({super.key});

//   @override
//   State<Selectlanguagestype> createState() => _SelectlanguagestypeState();
// }

// class _SelectlanguagestypeState extends State<Selectlanguagestype> {
//   final Color backgroundColor = Colors.white;

//   List<LanguageModel> languages = [];
//   LanguageModel? selectedLanguage;
//   bool isLoading = true;
//   String? errorMessage;

//   @override
//   void initState() {
//     super.initState();
//     fetchLanguages();
//   }
// Future<void> fetchLanguages() async {
//   try {
//     print('Fetching languages from API...');
//     final response = await http.get(
//       Uri.parse('https://lv4hfxvb-7000.inc1.devtunnels.ms/fetchlanguagedetails/'),
//       headers: {'Content-Type': 'application/json'},
//     );

//     print('Response status code: ${response.statusCode}');
//     print('Response body: ${response.body}');

//     if (response.statusCode == 200 || response.statusCode == 201) {
//       final dynamic decodedData = json.decode(response.body);
      
//       List<dynamic> languageList;
      
//       // Handle both response formats
//       if (decodedData is Map<String, dynamic>) {
//         // Response is a Map with 'details' key
//         if (decodedData.containsKey('details')) {
//           languageList = decodedData['details'] as List<dynamic>;
//         } else {
//           // Response is a Map but doesn't have 'details' key
//           setState(() {
//             errorMessage = 'Invalid response format: missing details field';
//             isLoading = false;
//           });
//           return;
//         }
//       } else if (decodedData is List<dynamic>) {
//         // Response is directly a List
//         languageList = decodedData;
//       } else {
//         setState(() {
//           errorMessage = 'Invalid response format: unexpected data type';
//           isLoading = false;
//         });
//         return;
//       }
      
//       setState(() {
//         languages = languageList
//             .map((json) => LanguageModel.fromJson(json as Map<String, dynamic>))
//             .toList();
//         isLoading = false;
//       });
      
//       print('Successfully loaded ${languages.length} languages');
      
//     } else {
//       setState(() {
//         errorMessage = 'Server error: ${response.statusCode}\nResponse: ${response.body}';
//         isLoading = false;
//       });
//     }
//   } catch (e) {
//     print('Exception caught: $e');
//     setState(() {
//       errorMessage = 'Network error: $e';
//       isLoading = false;
//     });
//   }
// }
//   @override
//   Widget build(BuildContext context) {
//     final size = MediaQuery.of(context).size;

//     return Scaffold(
//       backgroundColor: backgroundColor,
    
//       body: Container(
//            decoration: BoxDecoration(
//          gradient: LinearGradient(
//         colors: [Colors.cyan, const Color.fromARGB(255, 202, 236, 241),Colors.white],
//         begin: Alignment.topLeft,
//         end: Alignment.bottomCenter,
//              ),
//           image: DecorationImage(image: AssetImage('assets/god.png',),scale: 1,opacity: 0.5
//           )

//            ),
//         child: Column(mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const SizedBox(height: 20),
//             const Center(
//               child: Text(
//                 '',
//                 style: TextStyle(
//                   color: Colors.blue,
//                   fontSize: 15,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//             SizedBox(height: size.height * 0.08),
        
//             /// Dropdown Container
//             Padding(
//               padding: const EdgeInsets.all(18.0),
//               child: Container(
//                 width: double.infinity,
//                 height: size.height*0.06,
//                 padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                 decoration: BoxDecoration(
//                   color: Colors.grey[200],
//                   borderRadius: BorderRadius.circular(8),
                
//                 ),
//                  child: isLoading
//                 ? const Center(
//                     child: SizedBox(
//                       height: 20,
//                       width: 20,
//                       child: CircularProgressIndicator(strokeWidth: 2),
//                     ),
//                   )
//                 : errorMessage != null
//                     ? Text(
//                         'Error loading languages',
//                         style: TextStyle(color: Colors.red[600]),
//                       )
//                     : DropdownButtonHideUnderline(
//                         child: DropdownButton<LanguageModel>(
//                           value: selectedLanguage,
//                           hint: const Text("Select a language"),
//                           isExpanded: true,
//                           items: languages.map((LanguageModel language) {
//                             return DropdownMenuItem<LanguageModel>(
//                               value: language,
//                               child: Text(language.cLanguageName),
//                             );
//                           }).toList(),
//                           onChanged: (LanguageModel? newValue) {
//                             setState(() {
//                               selectedLanguage = newValue;
//                             });
//                           },
//                         ),
//                       ),
//               ),
//             ),
//           // Error message display
//           if (errorMessage != null)
//             Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Text(
//                 errorMessage!,
//                 style: TextStyle(color: Colors.red[600]),
//                 textAlign: TextAlign.center,
//               ),
//             ),

//           // Retry button for error cases
//           if (errorMessage != null)
//             ElevatedButton(
//               onPressed: () {
//                 setState(() {
//                   isLoading = true;
//                   errorMessage = null;
//                 });
//                 fetchLanguages();
//               },
//               child: const Text('Retry'),
//             ),
//             SizedBox(height: size.height * 0.01),
        
//             /// Next Button
//               GestureDetector(
//             onTap: () {
//               if (selectedLanguage != null) {
//                 // Pass the selected language data to the next screen
//                 print('Selected Language ID: ${selectedLanguage!.nLanguageID}');
//                 print('Selected Language Name: ${selectedLanguage!.cLanguageName}');
                
//                 // Navigator.push(
//                 //   context,
//                 //   MaterialPageRoute(
//                 //     builder: (context) => PhoneNumberField(
                      
//                 //     ),
//                 //   ),
//                 // );
//               } else {
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   const SnackBar(content: Text("Please select a language")),
//                 );
//               }
//             },
//               child: Padding(
//                 padding: const EdgeInsets.all(18.0),
//                 child: Container(
//                   width:double.infinity,
//                   height: size.height * 0.06,
//                   decoration:  BoxDecoration(
//                   color: Colors.blue,
//                   borderRadius: BorderRadius.circular(10)
//                   ),
//                   child: Center(
//                     child: Text(
//                       'Continue',
//                       style: GoogleFonts.poppins(
//                         color: Colors.white,
//                         fontSize: 14,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             )
//           ],
//         ),
//       ),
//     );
//   }
// }
