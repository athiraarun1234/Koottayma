import 'dart:convert';
import 'package:Koottaayma/HTTPURL/httpurl.dart';
import 'package:Koottaayma/SQFLITEVERSION1/DataBaseHelper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

Future<void> fetchNotificationAlert({
  required DatabaseHelper dbHelper,
  required void Function(bool show) onUpdateButton,
  required void Function(String msg) onError,
  required void Function() onFinally,
}) async {
  print('fetch notification alert API Called ');
  try {
    final prefs = await SharedPreferences.getInstance();
    final String? savedToken = prefs.getString('jwt');
    final int localHolymassUpdate = prefs.getInt('holymassUpdate') ?? 0;
    

    
    final response = await http.get(
      Uri.parse(NotificationALertAPI),
      headers: {
        'Authorization': '$savedToken'
        },
    );

    if (response.statusCode == 201) {
      final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
      final int familyUpdate = jsonResponse['FamilyUpdate'] ?? 0;
      final int apiHolymassUpdate = jsonResponse['bUpdateHolyMass'] ?? 0;

      print('FamilyUpdate: $familyUpdate');
      print('API holymassUpdate: $apiHolymassUpdate');
      print('Local holymassUpdate: $localHolymassUpdate');

      if (familyUpdate == 1) {
        await fetchAndSaveFamilyDetails(savedToken, dbHelper); 
        onUpdateButton(true);                              
      } 
      
      else if (apiHolymassUpdate != localHolymassUpdate) {
        await fetchAndSaveHolymassDetails(savedToken, dbHelper); 
        await prefs.setInt('holymassUpdate', apiHolymassUpdate);
        print('holymassUpdate saved locally: $apiHolymassUpdate ');
        onUpdateButton(true);                                  
      }
       else {
        print('No update needed ');
        onUpdateButton(false);                                 
      }
    } else {
      onError('Failed to load data');                         
    }
  } catch (e) {
    print('Error: $e');
    await Future.delayed(const Duration(seconds: 1));
    onError('Welcome to Home Page');
    onUpdateButton(false);
  } finally {
    onFinally();
  }
}

//  underscore removed — now accessible from homepage
Future<void> fetchAndSaveFamilyDetails(String? savedToken, DatabaseHelper dbHelper) async {
  print(' fetchAndSaveFamilyDetails CALLED');
  try {
    final prefs = await SharedPreferences.getInstance();
    final String? phoneNumber = prefs.getString('userPhone');

    if (phoneNumber == null || savedToken == null) {
      print('Phone or token missing');
      return;
    }

    int phoneNumberInt = int.tryParse(phoneNumber) ?? 0;

    final response = await http.post(
      Uri.parse(FamilyMemberDetails),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': '$savedToken',
      },
      body: jsonEncode({'nPhoneNo': phoneNumber}),
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode == 201) {
      var responseData = jsonDecode(response.body);
      List<dynamic> members = responseData is List ? responseData : [responseData];

      if (members.isNotEmpty) {
        await dbHelper.saveFamilyDetails(
          phoneNumber: phoneNumberInt,
          familyData: jsonEncode(members),
        );
        await dbHelper.updateLastSyncTime(phoneNumberInt);
        print(' Family data saved to SQLite');
      }

      await fetchAdditionalData(savedToken);
    }
  } catch (e) {
    print('Family fetch error: $e');
  }
}

Future<void> fetchAdditionalData(String savedToken) async {
  print(' fetchAdditionalData CALLED');
  try {
    final response = await http.get(
      Uri.parse(NotificationResetAPI),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': '$savedToken',
      },
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      var responseData = jsonDecode(response.body);
      print(' Additional data fetched: $responseData');
    } else {
      print(' GET API failed: ${response.statusCode}');
    }
  } catch (e) {
    print('Additional fetch error: $e');
  }
}

//  underscore removed — now accessible from homepage
Future<void> fetchAndSaveHolymassDetails(String? savedToken, DatabaseHelper dbHelper) async {
  print(' fetchAndSaveHolymassDetails CALLED');
  try {
    final prefs = await SharedPreferences.getInstance();
    final String? phoneNumber = prefs.getString('userPhone');

    if (phoneNumber == null || savedToken == null) {
      print('Phone or token missing');
      return;
    }

    int phoneNumberInt = int.tryParse(phoneNumber) ?? 0;

    final response = await http.get(
      Uri.parse(HolyMassAPI),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': '$savedToken',
      },
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode == 201 || response.statusCode == 200) {
      var responseData = jsonDecode(response.body);
      List<dynamic> massTimings = responseData is List ? responseData : [responseData];

      if (massTimings.isNotEmpty) {
        await dbHelper.saveHolyMassTimings(
          phoneNumber: phoneNumberInt,
          massTimingsData: jsonEncode(massTimings),
        );
        print(' Holy Mass data saved to SQLite');
      }
    } else {
      print('Holy Mass API failed: ${response.statusCode}');
    }
  } catch (e) {
    print('Holy Mass fetch error: $e');
  }
}