import 'dart:convert';
import 'package:Koottaayma/ADMIN%20FOLDER/2adminbottomnavigation.dart';
import 'package:Koottaayma/BETSEIDHA/betseidhaguestbottom.dart';
import 'package:Koottaayma/BETSEIDHA/betseidhauserbottom.dart';
import 'package:Koottaayma/BETSEIDHA/bpriestbottom.dart';
import 'package:Koottaayma/GUEST%20FOLDER/guestbottomnavigation.dart';
import 'package:Koottaayma/HTTPURL/httpurl.dart';
import 'package:Koottaayma/PRIESTFATHER%20FOLDER/priestbottomnavigation.dart';
import 'package:Koottaayma/SQFLITEVERSION1/DataBaseHelper.dart';
import 'package:Koottaayma/SQFLITEVERSION1/LanguageModel.dart';
import 'package:Koottaayma/SQFLITEVERSION1/PhoneNumberField.dart';
import 'package:Koottaayma/TEACHER%20%20FOLDER/9sundayschool.dart';
import 'package:Koottaayma/USER%20FOLDER/6bottomnavigation.dart';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Language extends StatefulWidget {
       
  const Language({super.key,});

  @override
  State<Language> createState() => _LanguageState();
}

 class _LanguageState extends State<Language> {
  final Color backgroundColor = Colors.white;
  final dbHelper = DatabaseHelper();
  List<LanguageModel> languages = [];
  LanguageModel? selectedLanguage;
  bool isLoading = true;
  String? errorMessage;
  bool isNextLoading = false;

  @override
  void initState() {
    super.initState();
    initializeAndCheckLanguage();
  }

  // Initialize database and check for saved language
  Future<void> initializeAndCheckLanguage() async {
    try {
     
      await dbHelper.runMigrationForUserPreferences();
     
      await checkAndNavigate();
    } catch (e) {
      print('Error initializing: $e');
      
      loadLanguagesWithSync();
    }
  }

// Update your checkAndNavigate method
Future<void> checkAndNavigate() async {
  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final savedLanguageId = await dbHelper.getSavedLanguageId();
    final savedUserType = prefs.getString('usertype');
    final savedPhone = prefs.getString('userPhone');
    final isRegistered = prefs.getBool('isRegistered') ?? false;
    final savedDatabase = prefs.getString('database') ?? '';  

    print('--- Checking saved data ---');
    print('Language ID: $savedLanguageId');
    print('User Type: $savedUserType');
    print('Phone: $savedPhone');
    print('Is Registered: $isRegistered');
    print('Database: "$savedDatabase"');

    if (savedLanguageId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {

        Widget destinationPage;
        int languageId = int.tryParse(savedLanguageId.toString()) ?? 0;
        int phoneNumber = int.tryParse(savedPhone ?? '0') ?? 0;

        //  FIRST: Check Login + Registration Completed
        if (savedUserType != null && savedPhone != null && isRegistered) {

          switch (savedUserType.toLowerCase()) {

            case 'user':
              if (savedDatabase == 'Koottaayma') {
                destinationPage = BottomNavigation(languageId: languageId, phoneNumber: phoneNumber,);
              } else if (savedDatabase == 'Betseidha') {
                destinationPage = BetseidhaUserBottomNaigation(
                  languageId: languageId,
                  phoneNumber: phoneNumber,
                );
              }
               else {
                destinationPage = BottomNavigation(languageId: languageId, phoneNumber: phoneNumber,); // default
              }
              break;

            case 'admin':
              destinationPage = AdminBottomNavigation(
                languageId: languageId,
                phoneNumber: phoneNumber,
              );
              break;

            case 'teacher':
              destinationPage = SunDaySchoolPage(
                languageId: languageId,
                phoneNumber: phoneNumber,
              );
              break;

            case 'guest':
              // if (!isRegistered) {
              //   // guest logged in but registration incomplete ➡️ guest register page
              //   destinationPage = Guestregister(
              //     languageId: languageId,
              //     phoneNumber: phoneNumber,
              //   );
              // } 
              if (savedDatabase == 'Koottaayma') {
                destinationPage = Guestbottomnavigation(
                  languageId: languageId,
                  phoneNumber: phoneNumber,
                );
              } else if (savedDatabase == 'Bethsaida') {
                destinationPage = BetseidhaGuestbottomnavigation(
                  languageId: languageId,
                  phoneNumber: phoneNumber,
                );
              } 
              // else {
              //   destinationPage = Guestregister(
              //     languageId: languageId,
              //     phoneNumber: phoneNumber,
              //   );
              // }
             else{
                 destinationPage =PhoneNumber(
                 languageId: languageId,
                 phoneNumber: 0,
                 nUserTypeID: 0,
          );
              }
              break;

            case 'priest':
              if (savedDatabase == 'Koottaayma') {
                destinationPage = PriestBottomNavigation(
                  languageId: languageId,
                  phoneNumber: phoneNumber,
                );
              } else if (savedDatabase == 'Bethsaida') {
                destinationPage = BetseidhaPriestBottom(
                  languageId: languageId,
                  phoneNumber: phoneNumber,
                );
              } else {
                destinationPage = PriestBottomNavigation(
                  languageId: languageId,
                  phoneNumber: phoneNumber,
                );
              }
              break;

            default:
              destinationPage = PhoneNumber(
                languageId: languageId,
                phoneNumber: 0,
                nUserTypeID: 0,
              );
          }
        } 
        
        // Not registered OR logged out
        else {
          destinationPage = PhoneNumber(
            languageId: languageId,
            phoneNumber: 0,
            nUserTypeID: 0,
          );
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => destinationPage),
        );
      });
    } else {
      print('No language saved — Loading language selection');
      loadLanguagesWithSync();
    }
  } catch (e) {
    print('Error checking saved data: $e');
    loadLanguagesWithSync();
  }
}

  Future<void> loadLanguagesWithSync() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      // Check if we need to refresh data
      final needsUpdate = await dbHelper.checkAndUpdateLanguages();
      
      if (needsUpdate) {
        print('Needs update from API...');
        // Fetch fresh data from API
        await fetchLanguagesFromAPI();
      } else {
        print('Loading from local database...');
        // Load from local database
        final storedLanguages = await dbHelper.getStoredLanguages();
        setState(() {
          languages = storedLanguages;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error in loadLanguagesWithSync: $e');
      setState(() {
        errorMessage = 'Error loading languages: $e';
        isLoading = false;
      });
    }
  }

  Future<void> fetchLanguagesFromAPI() async {
    try {
      print('Fetching languages from API...');
      final response = await http.get(
         Uri.parse(GetLanguages),
      //  Uri.parse('https://79056d4q-7000.inc1.devtunnels.ms/fetchlanguagedetails/'),
        headers: {'Content-Type': 'application/json'},
      );

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final dynamic decodedData = json.decode(response.body);
        
        List<dynamic> languageList;
        
        if (decodedData is Map<String, dynamic>) {
          if (decodedData.containsKey('details')) {
            languageList = decodedData['details'] as List<dynamic>;
          } else {
            setState(() {
              errorMessage = 'Invalid response format: missing details field';
              isLoading = false;
            });
            return;
          }
        } else if (decodedData is List<dynamic>) {
          languageList = decodedData;
        } else {
          setState(() {
            errorMessage = 'Invalid response format: unexpected data type';
            isLoading = false;
          });
          return;
        }
        
        final fetchedLanguages = languageList
            .map((json) => LanguageModel.fromJson(json as Map<String, dynamic>))
            .toList();
        
        // Clear existing languages and insert new ones
        await dbHelper.clearLanguages();
        
        // Store languages in SQLite
        for (var language in fetchedLanguages) {
          await dbHelper.insertLanguage(language);
        }
        
        // Update sync metadata
        await dbHelper.updateSyncMetadata('languages', version: '1.0');
        
        setState(() {
          languages = fetchedLanguages;
          isLoading = false;
        });
        
        print('Successfully loaded and stored ${languages.length} languages');
        
      } else {
        setState(() {
          errorMessage = 'Server Busy';
          isLoading = false;
        });
      }
    } catch (e) {
      print('Exception caught: $e');
      // Try to load from local storage if API fails
      final hasStored = await dbHelper.hasStoredLanguages();
      if (hasStored) {
        final storedLanguages = await dbHelper.getStoredLanguages();
        setState(() {
          languages = storedLanguages;
          isLoading = false;
          errorMessage = 'Using offline data. Network error: $e';
        });
      } else {
        setState(() {
          errorMessage = 'Network error and no offline data available: $e';
          isLoading = false;
        });
      }
    }
  }

  Future<void> fetchLanguageDataAndSetupDatabase() async {
    if (selectedLanguage == null) return;

    setState(() => isNextLoading = true);

    try {
      // Check if labels need updating
      final needsUpdate = await dbHelper.checkAndUpdateLabels(selectedLanguage!.nLanguageID);
      
      if (needsUpdate) {
        print('Fetching fresh labels from API for language ID: ${selectedLanguage!.nLanguageID}');
        await fetchLabelsFromAPI();
      } else {
        print('Labels are up to date for language ${selectedLanguage!.nLanguageID}');
      }

      // Save the selected language ID for future sessions
      await dbHelper.saveSelectedLanguageId(selectedLanguage!.nLanguageID);

      // Navigate to next page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
           PhoneNumber(
            languageId: selectedLanguage!.nLanguageID, 
            phoneNumber: 1234567890,
            nUserTypeID: 0,
          ),
        ),
      );
    } catch (e) {
      print('Exception in fetchLanguageDataAndSetupDatabase: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: Add the labels for corresponding selected language. Please contact the developer: $e'),
          duration: Duration(seconds: 5),
        ),
      );
    } finally {
      setState(() => isNextLoading = false);
    }
  }

  Future<void> fetchLabelsFromAPI() async {
    try {
      // Clear existing labels for this language before fetching new ones
      await dbHelper.clearLabelsForLanguage(selectedLanguage!.nLanguageID);

      // Fetch labels from API
      final response = await http.post(
       Uri.parse(GetLanguageLabels),
      //  Uri.parse('https://79056d4q-7000.inc1.devtunnels.ms/getlabeldetails/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nLanguageID': selectedLanguage!.nLanguageID,
          'nDeviseEnvironmentID': 2
        }),
      );

      print('Labels API Response Status: ${response.statusCode}');
      print('Labels API Response Body: ${response.body}');

      if (response.statusCode == 201) {
        final dynamic responseData = json.decode(response.body);
        print('Labels response data type: ${responseData.runtimeType}');
        
        // Handle different response formats
        List<dynamic>? apiResponseList;
        
        if (responseData is List) {
          apiResponseList = responseData;
        } else if (responseData is Map<String, dynamic>) {
          if (responseData.containsKey('data')) {
            apiResponseList = responseData['data'] as List?;
          } else if (responseData.containsKey('details')) {
            apiResponseList = responseData['details'] as List?;
          } else if (responseData.containsKey('result')) {
            apiResponseList = responseData['result'] as List?;
          } else {
            apiResponseList = [responseData];
          }
        }
        
        if (apiResponseList == null) {
          throw Exception('Unable to parse response data structure');
        }
        
        String? createTableQuery;
        List<dynamic>? detailsList;

        // Parse response data
        for (int i = 0; i < apiResponseList.length; i++) {
          var item = apiResponseList[i];
          
          if (item is Map<String, dynamic>) {
            if (item.containsKey('queries') && item['queries'] != null) {
              createTableQuery = item['queries'] as String;
            }
            
            if (item.containsKey('details') && item['details'] != null) {
              detailsList = item['details'] as List<dynamic>;
            }
            
            if (item.containsKey('nLanguageID') && 
                item.containsKey('nPageID') && 
                item.containsKey('nLabelID') &&
                item.containsKey('cLabelKey')) {
              if (detailsList == null) detailsList = [];
              detailsList.add(item);
            }
          }
        }

        // Execute table creation query if exists
        if (createTableQuery != null && createTableQuery.isNotEmpty) {
          try {
            await dbHelper.executeQuery(createTableQuery);
          } catch (e) {
            print('Error executing table creation query (continuing anyway): $e');
          }
        }

        // Insert label details
        if (detailsList != null && detailsList.isNotEmpty) {
          int insertedCount = 0;
          
          for (var detail in detailsList) {
            if (detail is Map<String, dynamic>) {
              if (!detail.containsKey('nLanguageID') || 
                  !detail.containsKey('nPageID') || 
                  !detail.containsKey('nLabelID') ||
                  !detail.containsKey('cLabelKey')) {
                continue;
              }
              
              int detailLanguageId;
              try {
                detailLanguageId = int.parse(detail['nLanguageID'].toString());
              } catch (e) {
                continue;
              }
              
              if (detailLanguageId == selectedLanguage!.nLanguageID) {
                try {
                  await dbHelper.insertLabelDetails(detail);
                  insertedCount++;
                } catch (e) {
                  print('Error inserting label detail: $e');
                }
              }
            }
          }
          
          print('Total inserted records: $insertedCount');
          
          if (insertedCount > 0) {
            // Update sync metadata for labels
            await dbHelper.updateSyncMetadata(
              'labels', 
              languageId: selectedLanguage!.nLanguageID,
              version: '1.0'
            );
            print('Updated sync metadata for language ${selectedLanguage!.nLanguageID}');
          }
          
          if (insertedCount == 0) {
            throw Exception('No records were inserted for the selected language');
          }
          
        } else {
          throw Exception('No label details found in API response');
        }
      } else {
        throw Exception('Failed to fetch label data: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception in fetchLabelsFromAPI: $e');
      rethrow;
    }
  }

  // Add manual refresh method
  Future<void> forceRefreshLanguages() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    
    // Clear all sync data to force refresh
    await dbHelper.clearAllSyncMetadata();
    await loadLanguagesWithSync();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Languages refreshed from server')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.cyan, const Color.fromARGB(255, 202, 236, 241), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomCenter,
          ),
          image: DecorationImage(
            image: AssetImage('assets/god.png'),
            scale: 1,
            opacity: 0.5
          )
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            SizedBox(height: size.height * 0.45),
            
            /// Dropdown Container
            Padding(
              padding: const EdgeInsets.all(18.0),
              child: Container(
                width: double.infinity,
                height: size.height * 0.06,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: isLoading
                  ? const Center(
                      child: SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : DropdownButtonHideUnderline(
                      child: DropdownButton<LanguageModel>(
                        value: selectedLanguage,
                        hint: const Text("Select a language"),
                        isExpanded: true,
                        items: languages.map((LanguageModel language) {
                          return DropdownMenuItem<LanguageModel>(
                            value: language,
                            child: Text(language.cLanguageName),
                          );
                        }).toList(),
                        onChanged: (LanguageModel? newValue) {
                          setState(() {
                            selectedLanguage = newValue;
                          });
                        },
                      ),
                    ),
              ),
            ),

            // Error message display
            if (errorMessage != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  errorMessage!,
                  style: TextStyle(color: Colors.red[600]),
                  textAlign: TextAlign.center,
                ),
              ),

            // Retry button for error cases
            if (errorMessage != null && errorMessage!.contains('Network error'))
              ElevatedButton(
                onPressed: forceRefreshLanguages,
                child: const Text('Retry'),
              ),

            SizedBox(height: size.height * 0.01),

            /// Next Button
            Padding(
              padding: const EdgeInsets.all(18.0),
              child: GestureDetector(
                onTap: selectedLanguage != null && !isNextLoading
                  ? fetchLanguageDataAndSetupDatabase
                  : () {
                      if (selectedLanguage == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Please select a language")),
                        );
                      }
                    },
                child: Container(
                  width: double.infinity,
                  height: size.height * 0.06,
                  decoration: BoxDecoration(
                    color: selectedLanguage != null && !isNextLoading 
                      ? Colors.blue 
                      : Colors.grey,
                    borderRadius: BorderRadius.circular(10)
                  ),
                  child: Center(
                    child: isNextLoading
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Continue',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                  ),
                ),
              
              ),
            )
          ],
        ),
      ),
    );
  }
}                                                                                                                                           