import 'dart:convert';


import 'package:Koottaayma/HTTPURL/httpurl.dart';
import 'package:Koottaayma/SQFLITEVERSION1/DataBaseHelper.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class SunDaySchoolPage extends StatefulWidget {
  final int languageId;
  final int phoneNumber;

  const SunDaySchoolPage({
    Key? key,
    required this.languageId,
    required this.phoneNumber,
  }) : super(key: key);

  @override
  State<SunDaySchoolPage> createState() => _SunDaySchoolPageState();
}

class _SunDaySchoolPageState extends State<SunDaySchoolPage> {
  final dbHelper = DatabaseHelper();

  List<dynamic> StudentDetails = [];
  bool isLoading = true;
  String errorMessage = '';
  bool isLoadingFromBackend = false;
  bool isSavingAttendance = false;
  String dataSource = '';

  @override
  void initState() {
    super.initState();
    fetchStudentDetails();
  }

  // Calculate total students
  int get totalStudents => StudentDetails.length;

  // Calculate total absentees
  int get totalAbsentees =>
      StudentDetails.where((s) => s['isAbsent'] == true).length;

  String formatDOB(String dobString) {
    try {
      DateTime dob = DateTime.parse(dobString);
      String formattedDate =
          "${dob.day.toString().padLeft(2, '0')}-${dob.month.toString().padLeft(2, '0')}-${dob.year}";
      return formattedDate;
    } catch (e) {
      return "N/A";
    }
  }

  Future<void> saveAttendance() async {
    if (StudentDetails.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No students to save attendance for'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      isSavingAttendance = true;
    });

    try {
        SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedToken = prefs.getString('jwt');
      final first = StudentDetails.first;

      //  Collect only absent students
      List<Map<String, dynamic>> absentMembers = StudentDetails
          .where((student) => student['isAbsent'] == true)
          .map((student) => {
                'nMemberID': student['nMemberID'],
                // 'isAbsent': student['isAbsent'],
              })
          .toList();

      //  Prepare final data object (not list)
      Map<String, dynamic> attendanceData = {
        'nDioceseID': first['nDioceseID'],
        'nForaneID': first['nForaneID'],
        'nParishID': first['nParishID'],
        'nSundaySchoolClassMasterID': first['nSSClassMasterID'],
        'nSundayClassTeacherID': first['nSundaySchoolTeacherID'],
        'dDate': first['cTodaysDate'],
        'lstAbsentMembers': absentMembers,
      };

      print('Sending attendance data: ${jsonEncode(attendanceData)}');

      //  Send POST request
      final response = await http.post(
        Uri.parse(SaveAttendance),
        headers: {
          'Content-Type': 'application/json',
           'Authorization': '$savedToken',
        },
        body: jsonEncode(attendanceData, 
        ),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Connection timeout');
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        print('Attendance saved successfully!');
        print('Response data: $responseData');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Attendance saved successfully!',
                style: GoogleFonts.roboto(fontSize: 13),
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      } else if (response.statusCode == 400) {
        throw Exception('Bad request: Please check the data being sent.');
      } else {
        throw Exception(
            'Attendance save failed: ${response.reasonPhrase ?? "Unknown error"}');
      }
    } on http.ClientException catch (e) {
      print('Network error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Network error. Check your connection.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error occurred while saving attendance: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save attendance: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isSavingAttendance = false;
        });
      }
    }
  }

  // Fetch saved absentees for today
  Future<List<int>> _fetchSavedAbsentees(String phoneNumber, String currentDate) async {
    try {
       SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedToken = prefs.getString('jwt');
      print('Fetching saved absentees for phone: $phoneNumber, date: $currentDate');
      
      var response = await http
          .post(
            Uri.parse(GetAbsentees),
            headers: {
            'Content-Type': 'application/json',
            'Authorization': '$savedToken', },
            body: jsonEncode({
              'nPhoneNumber': phoneNumber,
              'jwt':savedToken,
            }),
          )
          .timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Connection timeout');
        },
      );

      print('Absentees Response status: ${response.statusCode}');
      print('Absentees Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        var responseData = jsonDecode(response.body);
        List<int> absenteeMemberIds = [];

        if (responseData is List) {
          // Filter and extract member IDs only for the current date
          for (var absentee in responseData) {
            if (absentee['nMemberID'] != null && absentee['dDate'] != null) {
              // Parse the date from response and compare with current date
              String absenteeDate = absentee['dDate'].toString().split('T')[0];
              String compareDate = currentDate.split('T')[0];
              
              if (absenteeDate == compareDate) {
                absenteeMemberIds.add(absentee['nMemberID'] as int);
                print(' Match found: ${absentee['cMemberName']} (ID: ${absentee['nMemberID']}) - Date: $absenteeDate');
              }
            }
          }
        }

        print('Found ${absenteeMemberIds.length} absentees for $currentDate: $absenteeMemberIds');
        return absenteeMemberIds;
      } else {
        print(' No saved attendance found for this date or server error');
        return [];
      }
    } catch (e) {
      print(' Error fetching saved absentees: $e');
      return [];
    }
  }

  // Fetch student details to mark absentees
  Future<void> fetchStudentDetails() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? phoneNumber = prefs.getString('userPhone');
    
      if (phoneNumber == null) {
        setState(() {
          isLoading = false;
          errorMessage = 'Phone number not found. Please login again.';
        });
        return;
      }

      await _fetchFromBackend(phoneNumber);
    } catch (e) {
      print('Error in fetchStudentDetails: $e');
      setState(() {
        isLoading = false;
        errorMessage = 'Error: ${e.toString()}';
      });
    }
  }

  Future<void> _fetchFromBackend(String phoneNumber) async {
    setState(() {
      isLoadingFromBackend = true;
    });

    try {
       SharedPreferences prefs = await SharedPreferences.getInstance();
       String? savedToken = prefs.getString('jwt');
      // Fetch student list
      var response = await http
          .post(
            Uri.parse(SundaySchoolStudentsList),
            headers: {'Content-Type': 'application/json',
            'Authorization': '$savedToken', },
            body: jsonEncode({'nPhoneNumber': phoneNumber,
             'jwt': savedToken,
            }),
          )
          .timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Connection timeout');
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        var responseData = jsonDecode(response.body);
        List<dynamic> students = [];

        if (responseData is List) {
          students = responseData;
        } else if (responseData is Map && responseData['students'] != null) {
          students = responseData['students'];
        } else {
          throw Exception('Unexpected response format');
        }

        // Get current date from the first student or use today's date
        String currentDate = students.isNotEmpty && students.first['cTodaysDate'] != null
            ? students.first['cTodaysDate']
            : DateTime.now().toIso8601String().split('T')[0];

        // Fetch saved absentees for today's date
        List<int> savedAbsenteeMemberIds = await _fetchSavedAbsentees(phoneNumber, currentDate);

        // Initialize isAbsent field for each student based on saved attendance
        for (var student in students) {
          int memberId = student['nMemberID'] ?? 0;
          student['isAbsent'] = savedAbsenteeMemberIds.contains(memberId);
        }

        print(' Marked ${savedAbsenteeMemberIds.length} students as absent based on saved data for $currentDate');

        setState(() {
          StudentDetails = students;
          isLoading = false;
          isLoadingFromBackend = false;
          dataSource = 'backend';
        });
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } on http.ClientException catch (e) {
      setState(() {
        isLoading = false;
        isLoadingFromBackend = false;
        errorMessage = 'Network error. Check your connection.';
      });
      print('Network error: $e');
    } catch (e) {
      setState(() {
        isLoading = false;
        isLoadingFromBackend = false;
        errorMessage = 'Failed to load data: ${e.toString()}';
      });
      print('Error fetching from backend: $e');
    }
  }

  // Pull to refresh
  Future<void> _refreshData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? phoneNumber = prefs.getString('userPhone');
    if (phoneNumber != null) {
      await _fetchFromBackend(phoneNumber);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(color: Colors.cyan),
        ),
      );
    }

    if (errorMessage.isNotEmpty) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 60, color: Colors.red),
              SizedBox(height: 16),
              Text(errorMessage, style: GoogleFonts.roboto(fontSize: 16)),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: fetchStudentDetails,
                child: Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (StudentDetails.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Text('No students found',
              style: GoogleFonts.roboto(fontSize: 16)),
        ),
      );
    }

    // Get common info from first student
    final firstStudent = StudentDetails[0];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SizedBox.expand(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.cyan,
                Color.fromARGB(255, 202, 236, 241),
                Colors.white
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: RefreshIndicator(
              onRefresh: _refreshData,
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      SizedBox(height: 15),
                      // Header
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 6,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.school_rounded,
                                  size: 24,
                                  color: Colors.cyan,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  "Sunday School",
                                  style: GoogleFonts.roboto(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.cyan[800],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.calendar_today,
                                    size: 14, color: Colors.cyan[700]),
                                SizedBox(width: 5),
                                Text(
                                  firstStudent['cTodaysDate'] != null
                                      ? formatDOB(firstStudent['cTodaysDate'])
                                      : DateFormat('dd-MM-yyyy')
                                          .format(DateTime.now()),
                                  style: GoogleFonts.roboto(fontSize: 12),
                                ),
                                  Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.cyan.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.switch_account, color: Colors.cyan, size: 22),
            ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Teacher: ${firstStudent['cTeacherName'] ?? 'N/A'}',
                                  style: GoogleFonts.roboto(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: Colors.cyan[800],
                                  ),
                                ),
                                Text(
                                  'Class: ${firstStudent['cSSClassName'] ?? 'N/A'}',
                                  style: GoogleFonts.roboto(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: Colors.cyan[800],
                                  ),
                                )
                              ],
                            )
                          ],
                        ),
                      ),
                      SizedBox(height: 12),

                      // Student List
                      Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 6,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.only(left: 8, bottom: 6),
                              child: Text(
                                'Mark Absentees',
                                style: GoogleFonts.roboto(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.cyan[800],
                                ),
                              ),
                            ),
                            ...StudentDetails.asMap().entries.map((entry) {
                              int index = entry.key;
                              Map<String, dynamic> student = entry.value;
                              return Container(
                                margin: EdgeInsets.only(bottom: 5),
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: student['isAbsent'] == true
                                      ? Colors.red[50]
                                      : Colors.green[50],
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: student['isAbsent'] == true
                                        ? Colors.red[200]!
                                        : Colors.green[200]!,
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 14,
                                      backgroundColor:
                                          student['isAbsent'] == true
                                              ? Colors.red[100]
                                              : Colors.green[100],
                                      child: Icon(
                                        student['isAbsent'] == true
                                            ? Icons.person_off
                                            : Icons.person,
                                        size: 16,
                                        color: student['isAbsent'] == true
                                            ? Colors.red[700]
                                            : Colors.green[700],
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        '${student['cStudentName'] ?? 'N/A'}',
                                        style: GoogleFonts.roboto(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.grey[800],
                                        ),
                                      ),
                                    ),
                                    Checkbox(
                                      value: student['isAbsent'] == true,
                                      activeColor: Colors.red,
                                      checkColor: Colors.white,
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      visualDensity: VisualDensity.compact,
                                      onChanged: (bool? value) {
                                        setState(() {
                                          StudentDetails[index]['isAbsent'] =
                                              value ?? false;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                      SizedBox(height: 12),

                      // Statistics
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.06),
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.people,
                                      size: 20, color: Colors.blue[600]),
                                  SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Total Students',
                                        style: GoogleFonts.roboto(
                                          fontSize: 10,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      Text(
                                        '$totalStudents',
                                        style: GoogleFonts.roboto(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.06),
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.person_off,
                                      size: 20, color: Colors.red[600]),
                                  SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Absentees',
                                        style: GoogleFonts.roboto(
                                          fontSize: 10,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      Text(
                                        '$totalAbsentees',
                                        style: GoogleFonts.roboto(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.red[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 30),

                      // Save Button
                      Container(
                        width: double.infinity,
                        height: 45,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.cyan, Colors.cyan[700]!],
                          ),
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.cyan.withOpacity(0.3),
                              blurRadius: 6,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: isSavingAttendance ? null : saveAttendance,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: isSavingAttendance
                              ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.save,
                                        size: 18, color: Colors.white),
                                    SizedBox(width: 8),
                                    Text(
                                      'Save Attendance',
                                      style: GoogleFonts.roboto(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}