// import 'dart:convert';
// import 'package:MyCommunity/HTTPURL/httpurl.dart';
// import 'package:MyCommunity/SQFLITEVERSION1/DataBaseHelper.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:http/http.dart' as http;

// Future<void> fetchNotificationAlert({
//   required DatabaseHelper dbHelper,
//   required void Function(bool show) onUpdateButton,
//   required void Function(String msg) onError,
//   required void Function() onFinally,
// }) async {
//   print('fetch notification alert API Called ');
//   try {
//     final prefs = await SharedPreferences.getInstance();
//     final String? savedToken = prefs.getString('jwt');
//     final int localHolymassUpdate = prefs.getInt('holymassUpdate') ?? 0;
//    final int localBibleUpdate = prefs.getInt('bibleUpdate') ?? 0; // NEW

//     final response = await http.get(
//       Uri.parse(NotificationALertAPI),
//       headers: {'Authorization': '$savedToken'},
//     );

//     if (response.statusCode == 201) {
//       final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
//       final int familyUpdate = jsonResponse['FamilyUpdate'] ?? 0;
//       final int apiHolymassUpdate = jsonResponse['bUpdateHolyMass'] ?? 0;
//      final int apiBibleUpdate = jsonResponse['bUpdateBibleReadings'] ?? 0; 

//       print('FamilyUpdate: $familyUpdate');
//       print('API holymassUpdate: $apiHolymassUpdate');
//       print('Local holymassUpdate: $localHolymassUpdate');
//      print('API bibleUpdate: $apiBibleUpdate');       
//      print('Local bibleUpdate: $localBibleUpdate');   

//       if (familyUpdate == 1) {
//         await fetchAndSaveFamilyDetails(savedToken, dbHelper);
//         onUpdateButton(true);

//       } else if (apiHolymassUpdate != localHolymassUpdate) {
//         await fetchAndSaveHolymassDetails(savedToken, dbHelper);
//         await prefs.setInt('holymassUpdate', apiHolymassUpdate);
//         print('holymassUpdate saved locally: $apiHolymassUpdate');
//         onUpdateButton(true);


//       } 
//         else if (apiBibleUpdate != localBibleUpdate) {
//         await fetchAndSaveBibleReadings(savedToken, dbHelper); 
//         await prefs.setInt('bibleUpdate', apiBibleUpdate);     
//         print('bibleUpdate saved locally: $apiBibleUpdate');
//         onUpdateButton(true);
  
//       } 
//       else {
//         print('No update needed');
//         onUpdateButton(false);
//       }
//     } else {
//       onError('Failed to load data');
//     }
//   } catch (e) {
//     print('Error: $e');
//     await Future.delayed(const Duration(seconds: 1));
//     onError('Welcome to Home Page');
//     onUpdateButton(false);
//   } finally {
//     onFinally();
//   }
// }

// //  underscore removed — now accessible from homepage
// Future<void> fetchAndSaveFamilyDetails(String? savedToken, DatabaseHelper dbHelper) async {
//   print(' fetchAndSaveFamilyDetails CALLED');
//   try {
//     final prefs = await SharedPreferences.getInstance();
//     final String? phoneNumber = prefs.getString('userPhone');

//     if (phoneNumber == null || savedToken == null) {
//       print('Phone or token missing');
//       return;
//     }

//     int phoneNumberInt = int.tryParse(phoneNumber) ?? 0;

//     final response = await http.post(
//       Uri.parse(FamilyMemberDetails),
//       headers: {
//         'Content-Type': 'application/json',
//         'Authorization': '$savedToken',
//       },
//       body: jsonEncode({'nPhoneNo': phoneNumber}),
//     ).timeout(const Duration(seconds: 15));

//     if (response.statusCode == 201) {
//       var responseData = jsonDecode(response.body);
//       List<dynamic> members = responseData is List ? responseData : [responseData];

//       if (members.isNotEmpty) {
//         await dbHelper.saveFamilyDetails(
//           phoneNumber: phoneNumberInt,
//           familyData: jsonEncode(members),
//         );
//         await dbHelper.updateLastSyncTime(phoneNumberInt);
//         print(' Family data saved to SQLite');
//       }

//       await fetchAdditionalData(savedToken);
//     }
//   } catch (e) {
//     print('Family fetch error: $e');
//   }
// }

// Future<void> fetchAdditionalData(String savedToken) async {
//   print(' fetchAdditionalData CALLED');
//   try {
//     final response = await http.get(
//       Uri.parse(NotificationResetAPI),
//       headers: {
//         'Content-Type': 'application/json',
//         'Authorization': '$savedToken',
//       },
//     ).timeout(const Duration(seconds: 15));

//     if (response.statusCode == 200) {
//       var responseData = jsonDecode(response.body);
//       print(' Additional data fetched: $responseData');
//     } else {
//       print(' GET API failed: ${response.statusCode}');
//     }
//   } catch (e) {
//     print('Additional fetch error: $e');
//   }
// }

// //  underscore removed — now accessible from homepage
// Future<void> fetchAndSaveHolymassDetails(String? savedToken, DatabaseHelper dbHelper) async {
//   print(' fetchAndSaveHolymassDetails CALLED');
//   try {
//     final prefs = await SharedPreferences.getInstance();
//     final String? phoneNumber = prefs.getString('userPhone');

//     if (phoneNumber == null || savedToken == null) {
//       print('Phone or token missing');
//       return;
//     }

//     int phoneNumberInt = int.tryParse(phoneNumber) ?? 0;

//     final response = await http.get(
//       Uri.parse(HolyMassAPI),
//       headers: {
//         'Content-Type': 'application/json',
//         'Authorization': '$savedToken',
//       },
//     ).timeout(const Duration(seconds: 15));

//     if (response.statusCode == 201 || response.statusCode == 200) {
//       var responseData = jsonDecode(response.body);
//       List<dynamic> massTimings = responseData is List ? responseData : [responseData];

//       if (massTimings.isNotEmpty) {
//         await dbHelper.saveHolyMassTimings(
//           phoneNumber: phoneNumberInt,
//           massTimingsData: jsonEncode(massTimings),
//         );
//         print(' Holy Mass data saved to SQLite');
//       }
//     } else {
//       print('Holy Mass API failed: ${response.statusCode}');
//     }
//   } catch (e) {
//     print('Holy Mass fetch error: $e');
//   }
// }
// Future<void> fetchAndSaveBibleReadings(
//     String? savedToken, DatabaseHelper dbHelper) async {
//   print('fetchAndSaveBibleReadings CALLED');
//   try {
//     final prefs = await SharedPreferences.getInstance();
//     final String? phoneNumber = prefs.getString('userPhone');

//     if (phoneNumber == null || savedToken == null) {
//       print('Phone or token missing');
//       return;
//     }

//     final int phoneNumberInt = int.tryParse(phoneNumber) ?? 0;

//     final response = await http.get(
//       Uri.parse(BibleReadingsAPI), // reuse the same URL from BiblePage
//       headers: {
//         'Content-Type': 'application/json',
//         'Authorization': '$savedToken',
//       },
//     ).timeout(const Duration(seconds: 15));

//     if (response.statusCode == 200 || response.statusCode == 201) {
//       // Overwrite existing SQLite cache with fresh data
//       await dbHelper.saveGospelReadings(
//         phoneNumber: phoneNumberInt,
//         gospelData: response.body,
//       );
//       print('Bible readings updated in SQLite');
//     } else {
//       print('Bible readings API failed: ${response.statusCode}');
//     }
//   } catch (e) {
//     print('Bible readings fetch error: $e');
//   }
// }
////////////////////////////
//bible page code 
// STEP 1 — Entry point: SQLite first, API only if empty
// Future<void> _loadReadingsData(DateTime date, {bool forceRefresh = false}) async {
//   if (userPhoneNumber == null) await _getUserPhoneNumber();

//   setState(() {
//     isLoading = true;
//     errorMessage = null;
//   });

//   if (userPhoneNumber == null) {
//     setState(() {
//       errorMessage = 'User phone number not found. Please login again.';
//       isLoading = false;
//     });
//     return;
//   }

//   if (forceRefresh) {
//     print('Force refresh — fetching from API...');
//     await _fetchFromAPIAndCache(date);
//     return;
//   }

//   try {
//     print('Checking SQLite for cached gospel readings...');
//     final cachedData = await _dbHelper.getCachedGospelReadings(userPhoneNumber!);

//     if (cachedData != null && cachedData.isNotEmpty) {
//       print('Loading gospel readings from SQLite');
//       allCachedReadings = cachedData;
//       _filterReadingsForDate(date);
//       return;
//     }

//     // SQLite empty — fetch from API
//     print('No cached data found. Fetching from API...');
//     await _fetchFromAPIAndCache(date);

//   } catch (e) {
//     setState(() {
//       errorMessage = 'Error loading readings: $e';
//       isLoading = false;
//     });
//     print('Error in _loadReadingsData: $e');
//   }
// }

// // STEP 2 — Fetch from API and save to SQLite cache
// Future<void> _fetchFromAPIAndCache(DateTime date) async {
//   if (userPhoneNumber == null) {
//     setState(() {
//       errorMessage = 'User phone number not found';
//       isLoading = false;
//     });
//     return;
//   }

//   try {
//     final url = Uri.parse(BibleReadingsAPI);

//     print('Fetching Bible readings from API...');
//     final response = await http.get(
//       url,
//       headers: {
//         'Content-Type': 'application/json',
//       },
//     ).timeout(
//       const Duration(seconds: 15),
//       onTimeout: () {
//         throw Exception('Connection timeout - server not responding');
//       },
//     );

//     print('Server response status: ${response.statusCode}');

//     if (response.statusCode == 200 || response.statusCode == 201) {
//       final Map<String, dynamic> data = json.decode(response.body);

//       // Parse all readings into cache
//       allCachedReadings = data;

//       // Save to SQLite
//       await _saveToCacheDatabase(response.body);

//       print('Bible readings fetched and cached for user: $userPhoneNumber');

//       // Filter for selected date
//       _filterReadingsForDate(date);

//     } else {
//       setState(() {
//         errorMessage = 'Server error (${response.statusCode}). Cannot load readings.';
//         isLoading = false;
//       });
//       print('Server returned error: ${response.statusCode}');
//     }
//   } catch (e) {
//     setState(() {
//       errorMessage = 'Cannot connect to server. Please check your internet connection.';
//       isLoading = false;
//     });
//     print('Error fetching from API: $e');
//   }
// }

// // STEP 3 — Save raw JSON string to SQLite cache
// Future<void> _saveToCacheDatabase(String rawJson) async {
//   try {
//     if (userPhoneNumber == null) return;

//     await _dbHelper.saveGospelReadings(
//       phoneNumber: userPhoneNumber!,
//       gospelData: rawJson,
//     );

//     print('Bible readings saved to SQLite cache');
//   } catch (e) {
//     print('Error saving to cache: $e');
//   }
// }

// // STEP 4 — Filter cached readings for a specific date
// void _filterReadingsForDate(DateTime date) {
//   setState(() {
//     isLoading = true;
//   });

//   final formattedDate = DateFormat('yyyy-MM-dd').format(date);
//   print('Filtering readings for date: $formattedDate');

//   try {
//     final filteredData = {
//       'FirstReadingDetails': (allCachedReadings['FirstReadingDetails'] as List?)
//               ?.where((item) => item['dDate'] == formattedDate)
//               .toList() ??
//           [],
//       'SecondReadingDetails': (allCachedReadings['SecondReadingDetails'] as List?)
//               ?.where((item) => item['dDate'] == formattedDate)
//               .toList() ??
//           [],
//       'GospelReadingDetails': (allCachedReadings['GospelReadingDetails'] as List?)
//               ?.where((item) => item['dDate'] == formattedDate)
//               .toList() ??
//           [],
//     };

//     print('Found ${filteredData['FirstReadingDetails']?.length ?? 0} first readings');
//     print('Found ${filteredData['SecondReadingDetails']?.length ?? 0} second readings');
//     print('Found ${filteredData['GospelReadingDetails']?.length ?? 0} gospel readings');

//     setState(() {
//       readingsData = filteredData;
//       isLoading = false;
//       errorMessage = null;
//     });

//   } catch (e) {
//     setState(() {
//       errorMessage = 'Error filtering readings: $e';
//       isLoading = false;
//     });
//     print('Error filtering readings: $e');
//   }
// }