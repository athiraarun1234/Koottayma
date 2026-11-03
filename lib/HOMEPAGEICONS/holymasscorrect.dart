// import 'dart:convert';
// import 'package:MyCommunity/HTTPURL/httpurl.dart';
// import 'package:MyCommunity/SQFLITEVERSION1/DataBaseHelper.dart';
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:intl/intl.dart';
// import 'package:http/http.dart' as http;
// import 'package:sqflite/sqflite.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// class HolyMassModel {
//   final int nHolyMassMasterID;
//   final int nParishID;
//   final int nChurchID;
//   final int nWeekDayID;
//   final String dStartTime;
//   final String dDate;
//   final String cChurchName;
//   final String cProgrammeeName;

//   HolyMassModel({
//     required this.nHolyMassMasterID,
//     required this.nParishID,
//     required this.nChurchID,
//     required this.nWeekDayID,
//     required this.dStartTime,
//     required this.dDate,
//     required this.cChurchName,
//     required this.cProgrammeeName,
//   });

//   factory HolyMassModel.fromJson(Map<String, dynamic> json) {
//     return HolyMassModel(
//       nHolyMassMasterID: json['nHolyMassMasterID'],
//       nParishID: json['nParishID'],
//       nChurchID: json['nChurchID'],
//       nWeekDayID: json['nWeekDayID'],
//       dStartTime: json['dStartTime'],
//       dDate: json['dDate'],
//       cChurchName: json['cChurchName'],
//       cProgrammeeName: json['cProgrammeeName'] ?? '', // Handle missing field
//     );
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       'nHolyMassMasterID': nHolyMassMasterID,
//       'nParishID': nParishID,
//       'nChurchID': nChurchID,
//       'nWeekDayID': nWeekDayID,
//       'dStartTime': dStartTime,
//       'dDate': dDate,
//       'cChurchName': cChurchName,
//       'cProgrammeeName': cProgrammeeName,
//     };
//   }
// }

// class HolyMassDetails extends StatefulWidget {
//   const HolyMassDetails({super.key});

//   @override
//   State<HolyMassDetails> createState() => _HolyMassDetailsState();
// }

// class _HolyMassDetailsState extends State<HolyMassDetails> {
//   final int totalDays = 15;
//   final int centerIndex = 7;
//   int selectedDay = 7;
//   bool isLoading = false;
//   String? errorMessage;
//   late ScrollController _scrollController;
//   List<HolyMassModel> holyMassList = [];
//   List<HolyMassModel> allCachedMasses = []; // Store all cached data
//   final DatabaseHelper dbHelper = DatabaseHelper();
//   int? userPhoneNumber;

//   @override
//   void initState() {
//     super.initState();
//     _scrollController = ScrollController();

//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _scrollController.jumpTo((centerIndex - 2) * 98);
//       _initializeData();
//     });
//   }

//   DateTime getDateForIndex(int index) {
//     final today = DateTime.now();
//     final daysOffset = index - centerIndex;
//     return today.add(Duration(days: daysOffset));
//   }

//   bool isToday(int index) {
//     return index == centerIndex;
//   }

//   // Initialize data - check if cached data exists
//   Future<void> _initializeData() async {
//     await _getUserPhoneNumber();
//     await _loadHolyMassData();
//   }

//   // Get user phone number from SharedPreferences
//   Future<void> _getUserPhoneNumber() async {
//     try {
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       String? phone = prefs.getString('userPhone');
//       if (phone != null) {
//         userPhoneNumber = int.tryParse(phone);
//         print(' User phone number: $userPhoneNumber');
//       } else {
//         print(' No user phone number found in SharedPreferences');
//       }
//     } catch (e) {
//       print(' Error getting user phone: $e');
//     }
//   }

//   // Load Holy Mass data - SQLite first, API only if no cache
//   Future<void> _loadHolyMassData() async {
//     if (userPhoneNumber == null) {
//       setState(() {
//         errorMessage = 'User phone number not found. Please login again.';
//         isLoading = false;
//       });
//       return;
//     }

//     setState(() {
//       isLoading = true;
//       errorMessage = null;
//     });

//     try {
//       // Try to get cached data first
//       print(' Checking SQLite cache for user: $userPhoneNumber');
//       final cachedData = await dbHelper.getCachedHolyMassTimings(userPhoneNumber!);
      
//       if (cachedData != null && cachedData.isNotEmpty) {
       
//          print(' Found ${cachedData.length} cached Holy Mass records');
//         // Parse cached data
//         allCachedMasses = cachedData
//             .map((item) => HolyMassModel.fromJson(item as Map<String, dynamic>))
//             .toList();
        
//         // Filter for selected date
//         _filterMassesForDate(getDateForIndex(selectedDay));
        
//       } else {
//         print(' No cached data found. Fetching from API...');
//         // No cache - fetch from API
//         await _fetchFromAPIAndCache();
//       }
//     } catch (e) {
//       setState(() {
//         errorMessage = 'Error loading data: $e';
//         isLoading = false;
//       });
//       print(' Error in _loadHolyMassData: $e');
//     }
//   }

//   // Fetch from API and save to cache
//   Future<void> _fetchFromAPIAndCache() async {
//     if (userPhoneNumber == null) {
//       setState(() {
//         errorMessage = 'User phone number not found';
//         isLoading = false;
//       });
//       return;
//     }

//     try {
//       final url = Uri.parse(HolyMassAPI);

//       print(' Fetching Holy Mass data from API...');
//       final response = await http.get(
//         url,
//         headers: {
//           'Content-Type': 'application/json',
//         },
//       );

//       if (response.statusCode == 201 || response.statusCode == 200) {
//         final List<dynamic> data = json.decode(response.body);
        
//         if (data.isEmpty) {
//           setState(() {
//             errorMessage = 'No Holy Mass data available';
//             isLoading = false;
//           });
//           return;
//         }

//         print(' Fetched ${data.length} Holy Mass records from API');
        
//         // Parse all data
//         allCachedMasses = data
//             .map((item) => HolyMassModel.fromJson(item as Map<String, dynamic>))
//             .toList();
        
//         // Save to SQLite cache
//         await _saveToCacheDatabase(data);
        
//         print(' Data cached successfully for user: $userPhoneNumber');
        
//         // Filter for selected date
//         _filterMassesForDate(getDateForIndex(selectedDay));
        
//       } else {
//         setState(() {
//           errorMessage = 'Failed to load Holy Mass details (Status: ${response.statusCode})';
//           isLoading = false;
//         });
//       }
//     } catch (e) {
//       setState(() {
//         errorMessage = 'Network error: $e';
//         isLoading = false;
//       });
//       print(' Error fetching from API: $e');
//     }
//   }

//   // Save to cache database using your existing structure
//   Future<void> _saveToCacheDatabase(List<dynamic> data) async {
//     try {
//       final db = await dbHelper.database;
      
//       // Delete old cache for this user
//       await db.delete(
//         'holy_mass_timings_cache',
//         where: 'phone_number = ?',
//         whereArgs: [userPhoneNumber],
//       );
      
//       // Insert new cache
//       await db.insert(
//         'holy_mass_timings_cache',
//         {
//           'phone_number': userPhoneNumber,
//           'mass_timings_data': jsonEncode(data),
//           'cached_at': DateTime.now().toIso8601String(),
//         },
//         conflictAlgorithm: ConflictAlgorithm.replace,
//       );
      
//       print(' Saved cache to database');
//     } catch (e) {
//       print(' Error saving to cache: $e');
//     }
//   }

//   // Filter masses for a specific date from cached data
//   void _filterMassesForDate(DateTime date) {
//     setState(() {
//       isLoading = true;
//     });

//     final formattedDate = DateFormat('yyyy-MM-dd').format(date);
//     print(' Filtering masses for date: $formattedDate');

//     try {
//       final filteredList = allCachedMasses.where((mass) {
//         try {
//           // Handle both formats: "2024-12-25T10:30:00" and "2024-12-25"
//           final massDate = mass.dDate.split('T')[0];
//           return massDate == formattedDate;
//         } catch (e) {
//           return mass.dDate == formattedDate;
//         }
//       }).toList();

//       // Sort by time
//       filteredList.sort((a, b) => a.dStartTime.compareTo(b.dStartTime));

//       setState(() {
//         holyMassList = filteredList;
//         isLoading = false;
//       });

//       print(' Found ${filteredList.length} masses for $formattedDate');
//     } catch (e) {
//       setState(() {
//         errorMessage = 'Error filtering data: $e';
//         isLoading = false;
//       });
//       print(' Error filtering masses: $e');
//     }
//   }

//   // Refresh data from API (manual refresh)
//   Future<void> refreshDataFromAPI() async {
//     print(' Refreshing data from API...');
//     allCachedMasses.clear(); // Clear in-memory cache
//     await _fetchFromAPIAndCache();
//   }

//   // Clear cached data (for logout)
//   Future<void> clearCachedData() async {
//     if (userPhoneNumber == null) return;
    
//     try {
//       final db = await dbHelper.database;
//       await db.delete(
//         'holy_mass_timings_cache',
//         where: 'phone_number = ?',
//         whereArgs: [userPhoneNumber],
//       );
//       print(' Cleared cached Holy Mass data for user: $userPhoneNumber');
//     } catch (e) {
//       print(' Error clearing cached data: $e');
//     }
//   }

//   String _formatTime(String timeString) {
//     try {
//       final parts = timeString.split(':');
//       final hour = int.parse(parts[0]);
//       final minute = parts[1];
//       final period = hour >= 12 ? 'PM' : 'AM';
//       final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
//       return '$displayHour:$minute $period';
//     } catch (e) {
//       return timeString;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Colors.cyan,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: Colors.white),
//           onPressed: () => Navigator.pop(context),
//         ),
//         title: Text(
//           'Holy Mass date and time',
//           style: GoogleFonts.roboto(
//             fontSize: 20,
//             fontWeight: FontWeight.bold,
//             color: Colors.white,
//           ),
//         ),
//         centerTitle: true,
//         // actions: [
//         //   IconButton(
//         //     icon: Icon(Icons.refresh, color: Colors.white),
//         //     tooltip: 'Refresh from server',
//         //     onPressed: () {
//         //       refreshDataFromAPI();
//         //     },
//         //   ),
//         // ],
//       ),
//       body: Container(
//         width: double.infinity,
//         height: double.infinity,
//         child: Column(
//           children: [
//             // Date Selector
//             SizedBox(
//               height: 110,
//               child: ListView.builder(
//                 controller: _scrollController,
//                 scrollDirection: Axis.horizontal,
//                 physics: ClampingScrollPhysics(),
//                 itemCount: totalDays,
//                 padding: EdgeInsets.symmetric(horizontal: 8, vertical: 16),
//                 itemBuilder: (context, index) {
//                   final date = getDateForIndex(index);
//                   final String dayName = DateFormat('EEE').format(date);
//                   final String dateNum = DateFormat('dd').format(date);
//                   final String monthYear = DateFormat('MMM').format(date);

//                   final bool isSelected = selectedDay == index;
//                   final bool isTodayDate = isToday(index);

//                   return GestureDetector(
//                     onTap: () {
//                       setState(() {
//                         selectedDay = index;
//                       });
//                       // Filter from cached data instead of fetching
//                       _filterMassesForDate(getDateForIndex(index));
//                     },
//                     child: Container(
//                       width: 80,
//                       margin: EdgeInsets.only(right: 12),
//                       decoration: BoxDecoration(
//                         gradient: isSelected
//                             ? LinearGradient(
//                                 colors: [Colors.cyan, Colors.cyan.shade600],
//                                 begin: Alignment.topLeft,
//                                 end: Alignment.bottomRight,
//                               )
//                             : null,
//                         color: isSelected ? null : Colors.white,
//                         borderRadius: BorderRadius.circular(16),
//                         border: isTodayDate && !isSelected
//                             ? Border.all(color: Colors.cyan, width: 2)
//                             : null,
//                       ),
//                       child: Column(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Text(dayName,
//                               style: GoogleFonts.roboto(
//                                   fontSize: 13,
//                                   fontWeight: FontWeight.w600,
//                                   color: isSelected
//                                       ? Colors.white
//                                       : Colors.grey[600])),
//                           SizedBox(height: 4),
//                           Text(dateNum,
//                               style: GoogleFonts.roboto(
//                                   fontSize: 24,
//                                   fontWeight: FontWeight.bold,
//                                   color: isSelected
//                                       ? Colors.white
//                                       : Colors.black87)),
//                           Text(monthYear,
//                               style: GoogleFonts.roboto(
//                                 fontSize: 12,
//                                 color: isSelected
//                                     ? Colors.white
//                                     : Colors.grey[600],
//                               )),
//                         ],
//                       ),
//                     ),
//                   );
//                 },
//               ),
//             ),

//             // Holy Mass List
//             Expanded(
//               child: isLoading
//                   ? Center(
//                       child: CircularProgressIndicator(
//                         color: Colors.cyan,
//                       ),
//                     )
//                   : errorMessage != null
//                       ? Center(
//                           child: Column(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             children: [
//                               Icon(Icons.error_outline,
//                                   size: 60, color: Colors.grey),
//                               SizedBox(height: 16),
//                               Padding(
//                                 padding: const EdgeInsets.symmetric(horizontal: 32.0),
//                                 child: Text(
//                                   errorMessage!,
//                                   textAlign: TextAlign.center,
//                                   style: GoogleFonts.roboto(
//                                     fontSize: 16,
//                                     color: Colors.grey[600],
//                                   ),
//                                 ),
//                               ),
//                               SizedBox(height: 16),
//                               ElevatedButton(
//                                 onPressed: () {
//                                   refreshDataFromAPI();
//                                 },
//                                 style: ElevatedButton.styleFrom(
//                                   backgroundColor: Colors.cyan,
//                                   foregroundColor: Colors.white,
//                                 ),
//                                 child: Text('Retry'),
//                               ),
//                             ],
//                           ),
//                         )
//                       : holyMassList.isEmpty
//                           ? Center(
//                               child: Column(
//                                 mainAxisAlignment: MainAxisAlignment.center,
//                                 children: [
//                                   Icon(Icons.church_outlined,
//                                       size: 60, color: Colors.grey),
//                                   SizedBox(height: 16),
//                                   Text(
//                                     'No Holy Mass scheduled',
//                                     style: GoogleFonts.roboto(
//                                       fontSize: 16,
//                                       color: Colors.grey[600],
//                                     ),
//                                   ),
//                                   SizedBox(height: 8),
//                                   Text(
//                                     'for ${DateFormat('MMMM d, yyyy').format(getDateForIndex(selectedDay))}',
//                                     style: GoogleFonts.roboto(
//                                       fontSize: 14,
//                                       color: Colors.grey[500],
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             )
//                           : SafeArea(
//                             child: ListView.builder(
//                                 padding: EdgeInsets.all(16),
//                                 itemCount: holyMassList.length,
//                                 itemBuilder: (context, index) {
//                                   final mass = holyMassList[index];
//                                   return Card(
//                                     elevation: 3,
//                                     color: Colors.cyan[50],
//                                     margin: EdgeInsets.only(bottom: 16),
//                                     shape: RoundedRectangleBorder(
//                                       borderRadius: BorderRadius.circular(12),
//                                     ),
//                                     child: Padding(
//                                       padding: const EdgeInsets.all(16.0),
//                                       child: Column(
//                                         crossAxisAlignment:
//                                             CrossAxisAlignment.start,
//                                         children: [
//                                           Row(
//                                             children: [
//                                               Container(
//                                                 padding: EdgeInsets.all(12),
//                                                 decoration: BoxDecoration(
//                                                   color: Colors.cyan
//                                                       .withOpacity(0.1),
//                                                   borderRadius:
//                                                       BorderRadius.circular(10),
//                                                 ),
//                                                 child: Icon(
//                                                   Icons.church,
//                                                   color: Colors.cyan,
//                                                   size: 28,
//                                                 ),
//                                               ),
//                                               SizedBox(width: 12),
//                                               Expanded(
//                                                 child: Column(
//                                                   crossAxisAlignment:
//                                                       CrossAxisAlignment.start,
//                                                   children: [
//                                                     Text(
//                                                       mass.cChurchName,
//                                                       style: GoogleFonts.roboto(
//                                                         fontSize: 18,
//                                                         fontWeight:
//                                                             FontWeight.bold,
//                                                         color: Colors.black87,
//                                                       ),
//                                                     ),
//                                                          Text(
//                                                       mass.cProgrammeeName,
//                                                       style: GoogleFonts.roboto(
//                                                         fontSize: 14,
//                                                         fontWeight:
//                                                             FontWeight.bold,
//                                                         color: Colors.black87,
//                                                       ),
//                                                     ),
//                                                     SizedBox(height: 4),
//                                                     Row(
//                                                       children: [
//                                                         Icon(Icons.access_time,
//                                                             size: 16,
//                                                             color:
//                                                                 Colors.grey[600]),
//                                                         SizedBox(width: 4),
//                                                         Text(
//                                                           _formatTime(
//                                                               mass.dStartTime),
//                                                           style:
//                                                               GoogleFonts.roboto(
//                                                             fontSize: 16,
//                                                             color:
//                                                                 Colors.grey[700],
//                                                             fontWeight:
//                                                                 FontWeight.w500,
//                                                           ),
//                                                         ),
//                                                       ],
//                                                     ),
//                                                   ],
//                                                 ),
//                                               ),
//                                             ],
//                                           ),
//                                           SizedBox(height: 12),
//                                           Divider(),
//                                           SizedBox(height: 8),
//                                           Row(
//                                             children: [
//                                               Icon(Icons.calendar_today,
//                                                   size: 16,
//                                                   color: Colors.grey[600]),
//                                               SizedBox(width: 8),
//                                               Text(
//                                                 DateFormat('EEEE, MMMM d, yyyy')
//                                                     .format(DateTime.parse(
//                                                         mass.dDate.split('T')[0])),
//                                                 style: GoogleFonts.roboto(
//                                                   fontSize: 14,
//                                                   color: Colors.grey[600],
//                                                 ),
//                                               ),
//                                             ],
//                                           ),
//                                         ],
//                                       ),
//                                     ),
//                                   );
//                                 },
//                               ),
//                           ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _scrollController.dispose();
//     super.dispose();
//   }
// }