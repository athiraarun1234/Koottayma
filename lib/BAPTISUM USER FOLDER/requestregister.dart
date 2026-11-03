import 'dart:io';
import 'package:Koottaayma/HTTPURL/httpurl.dart';
import 'package:Koottaayma/SQFLITEVERSION1/PhoneNumberField.dart';
import 'package:Koottaayma/USER%20FOLDER/8usersacramentalrequest.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';

class BaptisumRequestPage extends StatefulWidget {
  const BaptisumRequestPage({super.key});

  @override
  State<BaptisumRequestPage> createState() => _BaptisumRequestPageState();
}

class _BaptisumRequestPageState extends State<BaptisumRequestPage> {
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _NameController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
   final TextEditingController _baptismdateController = TextEditingController();
  
  // Godfather controllers
  final TextEditingController _godfatherIdController = TextEditingController();
  final TextEditingController _godfatherNameController = TextEditingController();
  
  // Godmother controllers
  final TextEditingController _godmotherIdController = TextEditingController();
  final TextEditingController _godmotherNameController = TextEditingController();
   int? languageId;
 int? _selectedGodfatherFamilyMemberId;
  int? _selectedGodmotherFamilyMemberId;
  List<dynamic> userid = [];
  String? _selectedGender;
  int? _selectedGenderId;
  bool _isLoading = false;
  bool _isGodfatherSearching = false;
  bool _isGodmotherSearching = false;
  
  bool _godfatherFound = false;
  bool _godmotherFound = false;
  
    String? _phoneNumber;
    String? nFamilyMasterID;
    String? nDioceseID;
    String? nForaneID;
    String? nParishID;
    String? nFamilyUnitID;
    String? nWardID;
  
  // Dropdown results
  List<Map<String, dynamic>> _godfatherResults = [];
  List<Map<String, dynamic>> _godmotherResults = [];
  bool _showGodfatherDropdown = false;
  bool _showGodmotherDropdown = false;
  
  Timer? _godfatherDebounce;
  Timer? _godmotherDebounce;

  final List<Map<String, dynamic>> _genderOptions = [
    {'id': 1, 'name': 'Male'},
    {'id': 2, 'name': 'Female'},
  ];

  // Focus nodes for managing dropdown visibility
  final FocusNode _godfatherFocusNode = FocusNode();
  final FocusNode _godmotherFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    
    _godfatherIdController.addListener(_onGodfatherIdChanged);
    _godmotherIdController.addListener(_onGodmotherIdChanged);
    
    // Fetch key values on initialization
    _fetchKeyValues();
    
    // Hide dropdown when focus is lost
    _godfatherFocusNode.addListener(() {
      if (!_godfatherFocusNode.hasFocus) {
        Future.delayed(Duration(milliseconds: 200), () {
          if (mounted) {
            setState(() {
              _showGodfatherDropdown = false;
            });
          }
        });
      }
    });
    
    _godmotherFocusNode.addListener(() {
      if (!_godmotherFocusNode.hasFocus) {
        Future.delayed(Duration(milliseconds: 200), () {
          if (mounted) {
            setState(() {
              _showGodmotherDropdown = false;
            });
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _godfatherDebounce?.cancel();
    _godmotherDebounce?.cancel();
    _godfatherFocusNode.dispose();
    _godmotherFocusNode.dispose();
    _NameController.dispose();
    _dobController.dispose();
    _baptismdateController.dispose();
    _godfatherIdController.dispose();
    _godfatherNameController.dispose();
    _godmotherIdController.dispose();
    _godmotherNameController.dispose();
    super.dispose();
  }


  void _onGodfatherIdChanged() {
    if (_godfatherDebounce?.isActive ?? false) _godfatherDebounce!.cancel();
    
    final code = _godfatherIdController.text.trim();
    
    if (code.isEmpty) {
      setState(() {
        _godfatherFound = false;
        _godfatherNameController.clear();
        _godfatherResults.clear();
        _showGodfatherDropdown = false;
      });
      return;
    }
    
    _godfatherDebounce = Timer(const Duration(milliseconds: 500), () {
      _searchGodfather();
    });
  }

  void _onGodmotherIdChanged() {
    if (_godmotherDebounce?.isActive ?? false) _godmotherDebounce!.cancel();
    
    final code = _godmotherIdController.text.trim();
    
    if (code.isEmpty) {
      setState(() {
        _godmotherFound = false;
        _godmotherNameController.clear();
        _godmotherResults.clear();
        _showGodmotherDropdown = false;
      });
      return;
    }
    
    _godmotherDebounce = Timer(const Duration(milliseconds: 5), () {
      _searchGodmother();
    });
  }

  String? _validateName(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    if (value.trim().length < 2) {
      return '$fieldName must be at least 2 characters';
    }
    if (value.trim().length > 50) {
      return '$fieldName must not exceed 50 characters';
    }
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value.trim())) {
      return '$fieldName should contain only letters';
    }
    return null;
  }

  String? _validateId(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName ID is required';
    }
    if (value.trim().length < 3) {
      return 'Invalid ID format';
    }
    return null;
  }

  String? _validateDOB(String? value) {
    if (value == null || value.isEmpty) {
      return 'Date of Birth is required';
    }
    
    try {
      final parts = value.split('-');
      if (parts.length != 3) {
        return 'Invalid date format';
      }
      
      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);
      
      final selectedDate = DateTime(year, month, day);
      final now = DateTime.now();
      final age = now.year - selectedDate.year;
      
      // if (selectedDate.isAfter(now)) {
      //   return 'Date cannot be in the future';
      // }
      
      if (age > 120) {
        return 'Please enter a valid date';
      }
    } catch (e) {
      return 'Invalid date';
    }
    
    return null;
  }
  //GOD FATHER SERACHING WITH MEMBER CODE
 Future<void> _searchGodfather() async {
  final code = _godfatherIdController.text.trim();
  
  if (code.isEmpty) {
    return;
  }

  setState(() {
    _isGodfatherSearching = true;
    _godfatherFound = false;
    _godfatherResults.clear();
  });

  try {
     SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedToken = prefs.getString('jwt');
    final response = await http.post(
      Uri.parse(GodNameSearching),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': '$savedToken', 
      },
      body: json.encode({
        'cMemberCode': code,
        'jwt': savedToken,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final responseData = json.decode(response.body);
      
      List<Map<String, dynamic>> results = [];
      
      if (responseData is List) {
        results = responseData.map((item) => {
          'code': item['cMemberCode'] ?? '',
          'name': item['cDisplayName'] ?? '',
          'id': item['nFamilyMemberID']?.toString() ?? '', 
          'familyMemberId': item['nFamilyMemberID'], 
        }).toList().cast<Map<String, dynamic>>();
      } else if (responseData is Map) {
        results = [{
          'code': responseData['cMemberCode'] ?? '',
          'name': responseData['cDisplayName'] ?? '',
          'id': responseData['nFamilyMemberID']?.toString() ?? '', 
          'familyMemberId': responseData['nFamilyMemberID'], 
        }];
      }
      
      setState(() {
        _godfatherResults = results;
        _showGodfatherDropdown = results.isNotEmpty;
        
        // If only one result, auto-select it
        if (results.length == 1) {
          _selectGodfather(results[0]);
        }
      });
    } 
    else if (response.statusCode == 404) {
      setState(() {
        _godfatherResults.clear();
        _showGodfatherDropdown = false;
        _godfatherFound = false;
      });
    } else {
      setState(() {
        _godfatherResults.clear();
        _showGodfatherDropdown = false;
        _godfatherFound = false;
      });
    }
  } catch (e) {
    print('Godfather search error: $e');
    setState(() {
      _godfatherResults.clear();
      _showGodfatherDropdown = false;
      _godfatherFound = false;
    });
  } finally {
    setState(() {
      _isGodfatherSearching = false;
    });
  }
}
//GOD MOTHER SERACHING WITH MEMBER CODE
  Future<void> _searchGodmother() async {
    final code = _godmotherIdController.text.trim();
    
    if (code.isEmpty) {
      return;
    }

    setState(() {
      _isGodmotherSearching = true;
      _godmotherFound = false;
      _godmotherResults.clear();
    });

    try {
       SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedToken = prefs.getString('jwt');
      final response = await http.post(
        Uri.parse(GodNameSearching),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': '$savedToken', 
          },
        body: json.encode({
          'cMemberCode': code,
           'jwt': savedToken,
          }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        
        List<Map<String, dynamic>> results = [];
        
          if (responseData is List) {
          results = responseData.map((item) => {
          'code': item['cMemberCode'] ?? '',
          'name': item['cDisplayName'] ?? '',
          'id': item['nFamilyMemberID']?.toString() ?? '', 
          'familyMemberId': item['nFamilyMemberID'], 
        }).toList().cast<Map<String, dynamic>>();
      } else if (responseData is Map) {
        results = [{
          'code': responseData['cMemberCode'] ?? '',
          'name': responseData['cDisplayName'] ?? '',
          'id': responseData['nFamilyMemberID']?.toString() ?? '', 
          'familyMemberId': responseData['nFamilyMemberID'], 
        }];
      }
        
        setState(() {
          _godmotherResults = results;
          _showGodmotherDropdown = results.isNotEmpty;
          
          // If only one result, auto-select it
          if (results.length == 1) {
            _selectGodmother(results[0]);
          }
        });
      } else if (response.statusCode == 404) {
        setState(() {
          _godmotherResults.clear();
          _showGodmotherDropdown = false;
          _godmotherFound = false;
        });
      } else {
        setState(() {
          _godmotherResults.clear();
          _showGodmotherDropdown = false;
          _godmotherFound = false;
        });
      }
    } catch (e) {
      print('Godmother search error: $e');
      setState(() {
        _godmotherResults.clear();
        _showGodmotherDropdown = false;
        _godmotherFound = false;
      });
    } finally {
      setState(() {
        _isGodmotherSearching = false;
      });
    }
  }
void _selectGodfather(Map<String, dynamic> member) {
  setState(() {
    _selectedGodfatherFamilyMemberId = member['familyMemberId']; 
    _godfatherNameController.text = member['name'] ?? '';
    //_godfatherIdController.text = member['code'] ?? '';
    _godfatherFound = true;
    _showGodfatherDropdown = false;
  });
  _godfatherFocusNode.unfocus();
}

  void _selectGodmother(Map<String, dynamic> member) {
    setState(() {
        _selectedGodmotherFamilyMemberId = member['familyMemberId']; 
      _godmotherNameController.text = member['name'] ?? '';
     // _godmotherIdController.text = member['code'] ?? '';
      _godmotherFound = true;
      _showGodmotherDropdown = false;
    });
    _godmotherFocusNode.unfocus();
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(''),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showSuccessDialog(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 5),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      helpText: 'Select Date of Birth',
    );
    if (picked != null) {
      setState(() {
        _dobController.text = "${picked.day.toString().padLeft(2, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.year}";
      });
    }
  }
  // For Baptism Date
Future<void> _selectBaptismDate(BuildContext context) async {
  final DateTime? picked = await showDatePicker(
    context: context,
    initialDate: DateTime.now(),
    firstDate: DateTime.now(),
    lastDate: DateTime(2040),
    helpText: 'Select Baptism Date',
  );
  if (picked != null) {
    setState(() {
      _baptismdateController.text = "${picked.day.toString().padLeft(2, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.year}";
    });
  }
}

  Future<void> _selectGender(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select Gender'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: _genderOptions.map((gender) {
              return ListTile(
                title: Text(gender['name']),
                onTap: () {
                  setState(() {
                    _selectedGender = gender['name'];
                    _selectedGenderId = gender['id'];
                  });
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }
   
  // Fetch all ids nFamilyMasterID,nDioceseID,nForaneID,nParishID,nFamilyUnitID,nWardID

Future<void> _fetchKeyValues() async {
  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _phoneNumber = prefs.getString('userPhone');
    String? savedToken = prefs.getString('jwt');

    if (_phoneNumber == null || _phoneNumber!.isEmpty) {
      _showErrorDialog('Phone number not found. Please login again.');
      return;
    }
   
    if (savedToken == null) {
     _showErrorDialog ('Authentication token not found. Please login again.') ;
      return;
    }
    print('Attempting to connect to: $GetAllIDs');
    print('Sending phone number: $_phoneNumber');

    final response = await http.post(
      Uri.parse(GetAllIDs),
      headers: {
    'Content-Type': 'application/json',
    'Authorization': '$savedToken', 
  },
      body: json.encode({
        'nPhoneNo': _phoneNumber,
        'jwt': savedToken,
        }),

    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        throw Exception('Request timed out. Check your backend server.');
      },
    );

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      final responseData = json.decode(response.body);

      // Fetch all IDs
 
       nFamilyMasterID = responseData['nFamilyMasterID']?.toString();
       nDioceseID = responseData['nDioceseID']?.toString();
       nForaneID = responseData['nForaneID']?.toString();
       nParishID = responseData['nParishID']?.toString();
       nFamilyUnitID = responseData['nFamilyUnitID']?.toString();
       nWardID = responseData['nWardID']?.toString();

      // Save them in SharedPreferences
     
      await prefs.setString('userFamilyMasterID', nFamilyMasterID ?? '');
      await prefs.setString('userDioceseID', nDioceseID ?? '');
      await prefs.setString('userForaneID', nForaneID ?? '');
      await prefs.setString('userParishID', nParishID ?? '');
      await prefs.setString('userFamilyUnitID', nFamilyUnitID ?? '');
      await prefs.setString('userWardID', nWardID ?? '');

      setState(() {
      
      });

      print('Fetched IDs:');
      print('FamilyMasterID: $nFamilyMasterID');
      print('DioceseID: $nDioceseID');
      print('ForaneID: $nForaneID');
      print('ParishID: $nParishID');
      print('FamilyUnitID: $nFamilyUnitID');
      print('WardID: $nWardID');
    }  else {
      print('Failed with status: ${response.statusCode}');
      print('Response: ${response.body}');
      _showErrorDialog('Failed to fetch user details. Status: ${response.statusCode}');
    }
  } on TimeoutException catch (e) {
    print('Timeout error: $e');
    _showErrorDialog('Request timed out. Check your connection.');
  } on SocketException catch (e) {
    print('Network error: $e');
    _showErrorDialog('Cannot connect to server. Check your network.');
  } catch (e) {
    print('Error fetching key values: $e');
    _showErrorDialog('Error: ${e.toString()}');
  }
}

Future<void> _submitForm() async {
  if (!_formKey.currentState!.validate()) {
    return;
  }

  if (_selectedGenderId == null) {
    _showErrorDialog('Please select gender');
    return;
  }

  if (_godfatherNameController.text.trim().isEmpty) {
    _showErrorDialog('Please provide Godfather name');
    return;
  }

  if (_godmotherNameController.text.trim().isEmpty) {
    _showErrorDialog('Please provide Godmother name');
    return;
  }
  
  setState(() {
    _isLoading = true;
  });

  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedToken = prefs.getString('jwt');
    final requestBody = {
       'jwt': savedToken,
      'cChildName': _NameController.text.trim(),
      'dDoB': _dobController.text,
      'dDate': _baptismdateController.text,
      'nGenderID': _selectedGenderId,
      // If godfather found in database (has family member ID), send ID, else send name
      'nGodFatherID': _selectedGodfatherFamilyMemberId ?? _godfatherNameController.text.trim(),
      // If godmother found in database (has family member ID), send ID, else send name
      'nGodMotherID': _selectedGodmotherFamilyMemberId ?? _godmotherNameController.text.trim(),
      'nFamilyMasterID': nFamilyMasterID,
      'nDioceseID': nDioceseID,
      'nForaneID': nForaneID,
      'nParishID': nParishID,
      'nFamilyUnitID': nFamilyUnitID,
      'nWardID': nWardID,
    };

    print('Submitting baptism request: $requestBody');

    final response = await http.post(
      Uri.parse(BaptismAllPost),
      headers: {'Content-Type': 'application/json',
      'Authorization': '$savedToken', },
      body: json.encode(requestBody),
    );

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

  if (response.statusCode == 200 || response.statusCode == 201) {
  // Parse reference code from response
  String referenceCode = '';
  try {
    final decoded = jsonDecode(response.body);
    if (decoded is String) {
      referenceCode = decoded;
    } else if (decoded is Map) {
      referenceCode = decoded['referenceCode']?.toString() ??
                      decoded['message']?.toString() ?? '';
    }
  } catch (_) {
    referenceCode = response.body.replaceAll('"', '').trim();
  }

  _showSuccessDialog(
    referenceCode.isNotEmpty
        ? 'Baptism request submitted successfully!\nReference Code: $referenceCode'
        : 'Baptism request submitted successfully!',
  );
      
      _formKey.currentState!.reset();
      _NameController.clear();
      _dobController.clear();
      _baptismdateController.clear();
      _godfatherIdController.clear();
      _godfatherNameController.clear();
      _godmotherIdController.clear();
      _godmotherNameController.clear();
      
      setState(() {
        _selectedGender = null;
        _selectedGenderId = null;
        _godfatherFound = false;
        _godmotherFound = false;
        _selectedGodfatherFamilyMemberId = null;
        _selectedGodmotherFamilyMemberId = null;
        _godfatherResults.clear();
        _godmotherResults.clear();
      });
       Navigator.pushReplacement(
       context,
       MaterialPageRoute(builder: (context) => UserSacramentalsRequest()),
  );
    } 
    else if (response.statusCode == 208) {
      _showErrorDialog('Your request is already processing. Please wait.');
    }
    else if (response.statusCode == 409) {
      _showErrorDialog('A baptism request has already been submitted.');
    }
      else if (response.statusCode == 401 ||
               response.statusCode == 403 ||
               response.statusCode == 417) {
      // Redirect to PhoneNumber page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PhoneNumber(
            languageId: languageId ?? 0,
            phoneNumber: 0,
            nUserTypeID: 0,
          ),
        ),
      );
    }
     else {
      _showErrorDialog('Failed to submit request (Status: ${response.statusCode})');
    }
  } catch (e) {
    _showErrorDialog('Network error: ${e.toString()}');
  } finally {
    setState(() {
      _isLoading = false;
    });
  }
}

  Widget _buildDropdownList(List<Map<String, dynamic>> results, Function(Map<String, dynamic>) onSelect) {
    return Container(
      constraints: BoxConstraints(maxHeight: 200),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ListView.builder(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: results.length,
        itemBuilder: (context, index) {
          final member = results[index];
          return ListTile(
            dense: true,
            title: Text(
              member['name'] ?? '',
              style: TextStyle(fontSize: 14),
            ),
            subtitle: Text(
              'Code: ${member['code']}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            onTap: () => onSelect(member),
            trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.cyan),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.cyan,
                Color.fromARGB(255, 158, 218, 228),
                Colors.white,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                SizedBox(height: 80),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Center(
                      child: Text(
                        'Baptism Registration',
                        style: GoogleFonts.lato(
                          color: Colors.black,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(18.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Baby Name
                              Text('Baby Name', style: GoogleFonts.notoSansJavanese()),
                              SizedBox(height: 5),
                              TextFormField(
                                controller: _NameController,
                                validator: (value) => _validateName(value, 'Baby name'),
                                textCapitalization: TextCapitalization.words,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                                ],
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(5),
                                    borderSide: BorderSide(color: Colors.grey[300]!),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(5),
                                    borderSide: BorderSide(color: Colors.red),
                                  ),
                                  hintText: 'Enter Baby Name',
                                  fillColor: Colors.grey[200],
                                  filled: true,
                                  suffixIcon: Icon(Icons.person, color: Colors.grey[400]),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                ),
                              ),
                              SizedBox(height: 15),
                              
                              // DOB
                              Text('Date Of Birth', style: GoogleFonts.notoSansJavanese()),
                              SizedBox(height: 5),
                              TextFormField(
                                controller: _dobController,
                                validator: _validateDOB,
                                readOnly: true,
                                onTap: () => _selectDate(context),
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(5),
                                    borderSide: BorderSide(color: Colors.grey[300]!),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(5),
                                    borderSide: BorderSide(color: Colors.red),
                                  ),
                                  hintText: 'DD-MM-YYYY',
                                  fillColor: Colors.grey[200],
                                  filled: true,
                                  suffixIcon: Icon(Icons.calendar_month, color: Colors.grey[400]),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                ),
                              ),
                              SizedBox(height: 20),
                              // Baptism Date
                              Text('Baptism Date', style: GoogleFonts.notoSansJavanese()),
                              SizedBox(height: 5),
                              TextFormField(
                                controller: _baptismdateController,
                                validator: _validateDOB,
                                readOnly: true,
                                onTap: () => _selectBaptismDate(context),
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(5),
                                    borderSide: BorderSide(color: Colors.grey[300]!),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(5),
                                    borderSide: BorderSide(color: Colors.red),
                                  ),
                                  hintText: 'DD-MM-YYYY',
                                  fillColor: Colors.grey[200],
                                  filled: true,
                                  suffixIcon: Icon(Icons.calendar_month, color: Colors.grey[400]),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                ),
                              ),
                              SizedBox(height: 20),
                              
                              // Gender
                              Text('Baby Gender', style: GoogleFonts.notoSansJavanese()),
                              SizedBox(height: 5),
                              GestureDetector(
                                onTap: () => _selectGender(context),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(5),
                                    border: Border.all(
                                      color: Colors.grey[300]!,
                                    ),
                                  ),
                                  child: InputDecorator(
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                      suffixIcon: Icon(Icons.arrow_drop_down_sharp),
                                    ),
                                    child: Text(
                                      _selectedGender ?? 'Select Baby Gender',
                                      style: TextStyle(
                                        color: _selectedGender == null ? Colors.grey[600] : Colors.black,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 20),
                              
                            // Godfather Section
Text('God Father Code', style: GoogleFonts.notoSansJavanese(fontSize: 14)),
SizedBox(height: 10),

// Godfather ID field with dropdown
Stack(
  children: [
    Column(
      children: [
        TextFormField(
          controller: _godfatherIdController,
          focusNode: _godfatherFocusNode,
          validator: null,
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(5),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            hintText: 'Enter Member Code (Optional)',
            fillColor: Colors.grey[200],
            filled: true,
            suffixIcon: _isGodfatherSearching
                ? Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.cyan,
                      ),
                    ),
                  )
                : _godfatherFound
                    ? Icon(Icons.check_circle, color: Colors.green)
                    : null,
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
        if (_showGodfatherDropdown && _godfatherResults.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: _buildDropdownList(_godfatherResults, _selectGodfather),
          ),
      ],
    ),
  ],
),

SizedBox(height: 15),

Text('God Father Name', style: GoogleFonts.notoSansJavanese(fontSize: 14)),
SizedBox(height: 5),
TextFormField(
  controller: _godfatherNameController,
  validator: (value) => _validateName(value, 'Godfather name'),
  textCapitalization: TextCapitalization.words,
  readOnly: _godfatherFound, // it read-only if found in database
  inputFormatters: [
    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
  ],
  decoration: InputDecoration(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(5),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(5),
      borderSide: BorderSide(color: Colors.grey[300]!),
    ),
    hintText: 'Enter GodFather Name',
    fillColor: _godfatherFound ? Colors.green[50] : Colors.grey[200],
    filled: true,
    prefixIcon: Icon(
      Icons.person,
      color: _godfatherFound ? Colors.green[700] : Colors.grey[400],
    ),
    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
  ),
),

SizedBox(height: 20),

// Godmother Section
Text('God Mother Code', style: GoogleFonts.notoSansJavanese(fontSize: 14)),
SizedBox(height: 10),

// Godmother ID field with dropdown
Stack(
  children: [
    Column(
      children: [
        TextFormField(
          controller: _godmotherIdController,
          focusNode: _godmotherFocusNode,
          validator: null,
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(5),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            hintText: 'Enter Member Code (Optional)',
            fillColor: Colors.grey[200],
            filled: true,
            suffixIcon: _isGodmotherSearching
                ? Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.cyan,
                      ),
                    ),
                  )
                : _godmotherFound
                    ? Icon(Icons.check_circle, color: Colors.green)
                    : null,
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
        if (_showGodmotherDropdown && _godmotherResults.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: _buildDropdownList(_godmotherResults, _selectGodmother),
          ),
      ],
    ),
  ],
),

SizedBox(height: 15),

// Godmother Name field
Text('God Mother Name', style: GoogleFonts.notoSansJavanese(fontSize: 14)),
SizedBox(height: 5),
TextFormField(
  controller: _godmotherNameController,
  validator: (value) => _validateName(value, 'GodMother Name'),
  textCapitalization: TextCapitalization.words,
  readOnly: _godmotherFound, 
  inputFormatters: [
    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
  ],
  decoration: InputDecoration(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(5),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(5),
      borderSide: BorderSide(color: Colors.grey[300]!),
    ),
    hintText: 'Enter GodMother Name',
    fillColor: _godmotherFound ? Colors.green[50] : Colors.grey[200],
    filled: true,
    prefixIcon: Icon(
      Icons.person,
      color: _godmotherFound ? Colors.green[700] : Colors.grey[400],
    ),
    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
  ),
),

SizedBox(height: 30),
                              
                              // Submit Button
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _submitForm,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.cyan,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: _isLoading
                                      ? CircularProgressIndicator(color: Colors.white)
                                      : Text(
                                          'Submit Request',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                              ),
                              SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
