import 'dart:convert';
import 'dart:io';
import 'package:Koottaayma/GUEST%20FOLDER/9guestchurchselectionpage.dart';
import 'package:Koottaayma/GUEST%20FOLDER/guestbottomnavigation.dart';
import 'package:Koottaayma/HTTPURL/httpurl.dart';
import 'package:Koottaayma/LOCATIONFETCHING/digipinservice.dart';
import 'package:Koottaayma/LOCATIONFETCHING/locationservice.dart';
import 'package:Koottaayma/SQFLITEVERSION1/DataBaseHelper.dart';
import 'package:Koottaayma/SQFLITEVERSION1/LabelDetails.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';

class Church {
  final int id;
  final String name;
  final int parishid;
  final int foraneid;
  final int dioceseid;

  Church({required this.id, required this.name, required this.parishid, required this.foraneid, required this.dioceseid});

  factory Church.fromJson(Map<String, dynamic> json) {
    return Church(
      id: json['nChurchID'],
      name: json['cChurchName'],
      parishid: json['nParishID'],
      foraneid: json['nForaneID'],
      dioceseid: json['nDioceseID']
    );
  }
}

class District {
  final int id;
  final String name;

  District({required this.id, required this.name});

  factory District.fromJson(Map<String, dynamic> json) {
    return District(
      id: json['nDistrictID'],
      name: json['cName'],
    );
  }
}

class Guestregister extends StatefulWidget {
  final int languageId;
  final int phoneNumber;
  const Guestregister({
    super.key,
    required this.languageId,
    required this.phoneNumber,
  });

  @override
  State<Guestregister> createState() => _GuestregisterState();
}

class _GuestregisterState extends State<Guestregister> {
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();
  final TextEditingController _digipinCtrl= TextEditingController();
  String? _selectedGender;
  int? _selectedGenderId;
  bool _isLoading = false;
   bool _gettingLocation = false;
  // Profile Picture
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();

  final List<Map<String, dynamic>> _genderOptions = [
    {'id': 1, 'name': 'Male'},
    {'id': 2, 'name': 'Female'},
  ];
  static const _blue  = Color(0xFF1976D2);
  static const _lblue = Color(0xFF42A5F5);
  final dbHelper = DatabaseHelper();
  List<LabelDetails> allLabels = [];
  String titleText = 'Register';
  String firstnameText = 'First Name';
  String firstnameHint = 'Enter your first name';
  String lastnameText = 'Last Name';
  String lastnameHint = 'Enter your last name';
  String addressText = 'Address';
  String addressHint = 'Enter your address';
  String dobText = 'Date of Birth';
  String dobHint = 'Select your date of birth';
  String genderText = 'Gender';
  String genderHint = 'Select your gender';
  String phonenumberText = 'Phone Number';
  String phonenumberHint = 'Enter your phone number';
  String churchText = 'Church';
  String churchHint = 'Select Church';
  String districtText = 'District';
  String districtHint = 'Select District';
  String continueText = 'Continue';
  String profilePictureText = 'Profile Picture';
  
  bool isLoading = true;
  String? errorMessage;
  List<Church> churches = [];
  List<District> districts = [];
  int? selectedChurchId;
  int? selectedParishId;
  int? selectedDistrictId;
  int? selectedForaneId;
  int? selectedDioceseId;
  bool isSubmitting = false;
   
  @override
  void initState() {
    super.initState();
    fetchGuestRegisterLabels();
    fetchDropdownData();
    _loadSavedPhone();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _addressController.dispose();
    _dobController.dispose();
    _phoneController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }
 void _updateDigipinFromInput() {

  final lat = double.tryParse(_latitudeController.text.trim());
  final lng = double.tryParse(_longitudeController.text.trim());

  // Clear the DIGIPIN until both values are valid numbers
  if (lat == null || lng == null) {
    _digipinCtrl.text = '';
    return;
  }

  // Basic range check
  if (lat < -90 || lat > 90 || lng < -180 || lng > 180) {
    _digipinCtrl.text = '';
    return;
  }

  try {
    final digiPin = DigiPinService.getDigiPin(lat, lng);
    _digipinCtrl.text = digiPin; // empty string if outside India's bounds
    print('Please enter valid latitude and longitude values.');
   _snack('Please enter valid latitude and longitude values.');
  } catch (e) {
    
    _digipinCtrl.text = '';
   
  }
}
 
//location service to get the current location of the user and fill the latitude and longitude fields automatically
Future<void> _getCurrentLocation() async {
  setState(() {
    _gettingLocation = true;
  });

  try {
    
    //locationservice.dart
    //LocationService is used LOCATION folder to get the current
    // location of the user and fill the latitude and longitude
    // fields automatically
    final position = await LocationService.getCurrentLocation();

    if (position != null) {
      // Get latitude
      _latitudeController.text = position.latitude.toString();

      // Get longitude
      _longitudeController.text = position.longitude.toString();

      print('Latitude: ${position.latitude}');
      print('Longitude: ${position.longitude}');

     // Generate DIGIPIN
      final digiPin = DigiPinService.getDigiPin(
        position.latitude,
        position.longitude,
      );

      print('Generated DIGIPIN: $digiPin');

      // Fill DIGIPIN field
      if (digiPin.isNotEmpty) {
        _digipinCtrl.text = digiPin;
      } else {
        _snack('Unable to generate DIGIPIN.');
      }

      if (mounted) {
        setState(() {});
      }

      _snack('Location detected successfully.');
    } else {
      _snack(
        'Unable to get location. Please check GPS and permission.',
      );
    }
  } catch (e) {
    print('LOCATION ERROR: $e');
    _snack('Unable to get location.');
  } finally {
    if (mounted) {
      setState(() {
        _gettingLocation = false;
      });
    }
  }
}


 void _snack(String msg) {
  final bool isError =
      msg.toLowerCase().contains('error') ||
      msg.toLowerCase().contains('failed') ||
      msg.toLowerCase().contains('invalid') ||
      msg.toLowerCase().contains('unable') ||
      msg.toLowerCase().contains('please');

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(msg),
      backgroundColor:
          isError ? Colors.red.shade600 : Colors.green.shade600,
      behavior: SnackBarBehavior.floating,
    ),
  );
}
// ── Decoration helpers is used to reduce code duplication for input fields and labels.
  InputDecoration _dec(String label, {Widget? suffix, Widget? prefix}) =>
   InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(fontSize: 13, color: Colors.grey),
    suffixIcon: suffix, prefixIcon: prefix,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    border:        OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                       borderSide: BorderSide(color: Colors.grey.shade300)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                       borderSide: const BorderSide(color: _blue, width: 1.5)),
    errorBorder:   OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                       borderSide: const BorderSide(color: Colors.red)),
    filled: true, fillColor: Colors.grey.shade50,
  );

  Widget _label(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 8, top: 4),
    child: Text(t, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
        color: _blue, letterSpacing: 0.5)),
  );

  String? _coord(String? v, {required bool lat}) {
    if (v == null || v.isEmpty) return 'Required';
    final n = double.tryParse(v);
    if (n == null) return 'Enter a valid number';
    if (lat  && (n < -90  || n > 90))  return 'Latitude: -90 to 90';
    if (!lat && (n < -180 || n > 180)) return 'Longitude: -180 to 180';
    return null;
  }


  // Pick image from gallery
  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _profileImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting image: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
//camera
Future<void> _pickImageFromCamera() async {
    final ImagePicker picker = ImagePicker();
    final XFile? photo = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
      preferredCameraDevice: CameraDevice.front, // Opens front camera by default
    );

    if (photo != null) {
      setState(() {
        _profileImage = File(photo.path);
      });
    }
  }
  // Show image source selection dialog
 Future<void> _showImageSourceDialog() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Select Profile Picture',
            style: GoogleFonts.roboto(fontWeight: FontWeight.bold),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.camera_alt, color: Colors.cyan),
                title: Text(
                  'Take a Photo',
                  style: GoogleFonts.roboto(),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromCamera();
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library, color: Colors.cyan),
                title: Text(
                  'Choose from Gallery',
                  style: GoogleFonts.roboto(),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromGallery();
                },
              ),
              if (_profileImage != null)
                ListTile(
                  leading: Icon(Icons.delete, color: Colors.red),
                  title: Text(
                    'Remove Photo',
                    style: GoogleFonts.roboto(),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _profileImage = null;
                    });
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _loadSavedPhone() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedPhone = prefs.getString('userPhone',);
    if (savedPhone != null && savedPhone.isNotEmpty) {
      setState(() {
        _phoneController.text = savedPhone;
      });
    }
  }

  Future<void> fetchDropdownData() async {
    try {
      final response = await http.get(
        Uri.parse(GuestDropdownSelection),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
          print(response.body);
        churches = (decoded['ChurchDetails'] as List)
            .map((e) => Church.fromJson(e))
            .toList();

        districts = (decoded['Districts'] as List)
            .map((e) => District.fromJson(e))
            .toList();

        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> submitGuestRegistration() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all the required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate gender
    if (_selectedGenderId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select gender'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate church selection
    if (selectedChurchId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a church'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(GuestRegitrationDetails),
      );

      // Add text fields
      request.fields['cFirstName'] = _firstNameController.text.trim();
      request.fields['cLastName'] = _lastNameController.text.trim();
      request.fields['cAddress'] = _addressController.text.trim();
      request.fields['dDoB'] = _dobController.text;
      request.fields['nPhoneNo'] = _phoneController.text.trim();
      request.fields['nGenderID'] = _selectedGenderId.toString();
      request.fields['nParishID'] = selectedParishId.toString();
      request.fields['nDistrictID'] = selectedDistrictId.toString();
      request.fields['nChurchID'] = selectedChurchId.toString();
      request.fields['nForaneID'] = selectedForaneId.toString();
      request.fields['nDioceseID'] = selectedDioceseId.toString();
      request.fields['nLatitude'] = _latitudeController.text.trim();
      request.fields['nLongitude'] = _longitudeController.text.trim();
      
    // Add image file if selected, otherwise send "empty"
    if (_profileImage != null) {
       request.files.add(
    await http.MultipartFile.fromPath('cImagePath', _profileImage!.path, ),
                        );
                    } 
     else {
  // Send "empty" when no image is selected
     request.fields['cImagePath'] = '';
         }
     
      print('Submitting registration data with multipart');
     
      // Send request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      setState(() {
        isSubmitting = false;
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration Successful!'),
            
            backgroundColor: Colors.green,
          ),
        );

        if (selectedChurchId == 2 && selectedDistrictId == 1) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => GuestHome(
                languageId: widget.languageId,
                phoneNumber: widget.phoneNumber,
              ),
            ),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => Guestbottomnavigation(
                languageId: widget.languageId,
                phoneNumber: widget.phoneNumber,
              ),
            ),
          );
        }
      } else {
        final errorMessage = jsonDecode(response.body)['message'] ?? 
            'Registration failed. Please try again.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        isSubmitting = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Network error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> fetchGuestRegisterLabels() async {
    const int nPageID = 3;
    const int nUserTypeID = 3;
    
    try {
      print('Fetching labels for page $nPageID, userType $nUserTypeID, language ${widget.languageId}');
      
      await dbHelper.debugPrintLabelDetails();
      
      final labels = await dbHelper.getLabelsForPage(
        nPageID, 
        widget.languageId,
        nUserTypeID,
      );
      
      print('Found ${labels.length} labels for guest registration page');
      
      if (labels.isEmpty) {
        setState(() {
          errorMessage = 'No labels found for selected language. Using default text.';
          isLoading = false;
        });
        return;
      }
      
      for (var label in labels) {
        print('Mapping label ID ${label.nLabelID}: ${label.cLabelKey}');
        switch (label.nLabelID) {
          case 1:
            titleText = label.cLabelKey;
            break;
          case 2:
            firstnameText = label.cLabelKey;
            break;
          case 3:
            firstnameHint = label.cLabelKey;
            break;
          case 4:
            lastnameText = label.cLabelKey;
            break;
          case 5:
            lastnameHint = label.cLabelKey;
            break;
          case 6:
            addressText = label.cLabelKey;
            break;
          case 7:
            addressHint = label.cLabelKey;
            break;
          case 8:
            dobText = label.cLabelKey;
            break;
          case 9:
            dobHint = label.cLabelKey;
            break;
          case 10:
            genderText = label.cLabelKey;
            break;
          case 11:
            genderHint = label.cLabelKey;
            break;
          case 12:
            phonenumberText = label.cLabelKey;
            break;
          case 13:
            phonenumberHint = label.cLabelKey;
            break;
        }
      }

      setState(() {
        allLabels = labels;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching guest registration labels: $e');
      setState(() {
        errorMessage = 'Error fetching labels: $e. Using default text.';
        isLoading = false;
      });
    }
  }

  String? _validateName(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter $fieldName';
    }
    return null;
  }

  String? _validateAddress(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter address';
    }
    return null;
  }

  String? _validateDOB(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please select date of birth';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter phone number';
    }
    if (value.trim().length != 10) {
      return 'Phone number must be 10 digits';
    }
    return null;
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      helpText: 'Select Date of Birth',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.cyan,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dobController.text = "${picked.day.toString().padLeft(2, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.year}";
      });
    }
  }

  Future<void> _selectGender(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Select Gender',
            style: GoogleFonts.roboto(fontWeight: FontWeight.bold),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: _genderOptions.map((gender) {
              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedGender = gender['name'];
                    _selectedGenderId = gender['id'];
                  });
                  Navigator.pop(context);
                },
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                  child: Row(
                    children: [
                      SizedBox(width: 12),
                      Text(
                        gender['name'],
                        style: GoogleFonts.roboto(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
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
        child: SafeArea(
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  SizedBox(height: 40),
                  // Title
                  Text(
                    titleText,
                    style: GoogleFonts.roboto(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          blurRadius: 10.0,
                          color: Colors.black26,
                          offset: Offset(2, 2),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 30),
                  // Form Container
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 10,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Profile Picture Section
                            Center(
                              child: Column(
                                children: [
                                  GestureDetector(
                                    onTap: _showImageSourceDialog,
                                    child: Container(
                                      width: 120,
                                      height: 120,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.grey[100],
                                        border: Border.all(
                                          color: Colors.cyan,
                                          width: 3,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black12,
                                            blurRadius: 10,
                                            offset: Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: _profileImage != null
                                          ? ClipOval(
                                              child: Image.file(
                                                _profileImage!,
                                                fit: BoxFit.cover,
                                                width: 120,
                                                height: 120,
                                              ),
                                            )
                                          : Icon(
                                              Icons.add_a_photo,
                                              size: 40,
                                              color: Colors.cyan,
                                            ),
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    profilePictureText,
                                    style: GoogleFonts.roboto(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  if (_profileImage == null)
                                    Text(
                                      'Tap to add photo',
                                      style: GoogleFonts.roboto(
                                        fontSize: 12,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            SizedBox(height: 30),
                            
                            // First Name
                            _buildLabel(firstnameText),
                            SizedBox(height: 8),
                            _buildTextField(
                              controller: _firstNameController,
                              hint: firstnameHint,
                              icon: Icons.person_outline,
                              validator: (value) => _validateName(value, firstnameText),
                              textCapitalization: TextCapitalization.words,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                              ],
                            ),
                            SizedBox(height: 20),
                            
                            // Last Name
                            _buildLabel(lastnameText),
                            SizedBox(height: 8),
                            _buildTextField(
                              controller: _lastNameController,
                              hint: lastnameHint,
                              icon: Icons.person_outline,
                              validator: (value) => _validateName(value, lastnameText),
                              textCapitalization: TextCapitalization.words,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                              ],
                            ),
                            SizedBox(height: 20),
                            
                            // Address
                            _buildLabel(addressText),
                            SizedBox(height: 8),
                            _buildTextField(
                              controller: _addressController,
                              hint: addressHint,
                              icon: Icons.home_outlined,
                              validator: _validateAddress,
                              maxLines: 2,
                              textCapitalization: TextCapitalization.sentences,
                            ),
                            SizedBox(height: 20),
                            _buildLabel('Location (Latitude & Longitude)'),
                                        Card(
                      elevation: 0, color: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          children: [
                                 SizedBox(
                                  width: double.infinity,
                                  height: 45,
                                   child: OutlinedButton.icon(
                                    onPressed: _gettingLocation ? null : _getCurrentLocation,
                                   icon: _gettingLocation
                                         ? const SizedBox(
                                             width: 18,
                                              height: 18,
                                            child: CircularProgressIndicator(
                                                   strokeWidth: 2,
                                                    ),
                                                  )
                                                 : const Icon(Icons.gps_fixed, size: 18),
                                                   label: Text(
                                                _gettingLocation  ? 'Getting Location...' : 'Get Current Location',
                                                             ),
                                               style: OutlinedButton.styleFrom(
                                                 foregroundColor: _blue,
                                            side: const BorderSide(color: _blue),
                                        shape: RoundedRectangleBorder(
                                               borderRadius: BorderRadius.circular(10)),
                                                         ),
                                                         ),
                                 ),
                                                         const SizedBox(height: 12),
                            // Latitude
                            TextFormField(
                              controller: _latitudeController,
                              style: const TextStyle(fontSize: 13),
                              readOnly: true,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*')),
                              ],
                              onChanged: (_) => setState(_updateDigipinFromInput),
                              decoration: _dec(
                                'Latitude',
                                prefix: const Icon(Icons.explore_outlined, size: 18),
                                suffix: Tooltip(
                                  message: 'Enter latitude between 2.5 and 38.5\ne.g. 9.9312',
                                  child: const Icon(Icons.info_outline, size: 17, color: Colors.grey),
                                ),
                              ),
                              validator: (v) => _coord(v, lat: true),
                            ),
                            const SizedBox(height: 4),
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Text('  Range: 2.5 to 38.5  •  e.g. 9.9312',
                                  style: TextStyle(fontSize: 10.5, color: Colors.grey)),
                            ),
                            const SizedBox(height: 12),

                            // Longitude
                            TextFormField(
                              controller: _longitudeController,
                              style: const TextStyle(fontSize: 13),
                           readOnly: true,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*')),
                              ],
                              onChanged: (_) => setState(_updateDigipinFromInput),
                              decoration: _dec(
                                'Longitude',
                                prefix: const Icon(Icons.explore_outlined, size: 18),
                                suffix: Tooltip(
                                  message: 'Enter longitude between 63.5 and 99.5\ne.g. 76.2673',
                                  child: const Icon(Icons.info_outline, size: 17, color: Colors.grey),
                                ),
                              ),
                              validator: (v) => _coord(v, lat: false),
                            ),
                            const SizedBox(height: 4),
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Text('  Range: 63.5 to 99.5  •  e.g. 76.2673',
                                  style: TextStyle(fontSize: 10.5, color: Colors.grey)),
                            ),
                     
                    const SizedBox(height: 12),

                      //         // DIGIPIN
                      //   TextFormField(
                      // controller:                                                                                                                                                                                   Ctrl,
                      //      readOnly: true,
                      //    style: const TextStyle(
                      //     fontSize: 14,
                      //    fontWeight: FontWeight.w600,
                      //         ),
                      //        decoration: _dec(
                      //         'DIGIPIN',
                      //         prefix: const Icon(
                      //          Icons.location_pin,
                      //                  size: 18,
                      //                ),
                      //         suffix: const Icon(
                      //          Icons.lock_outline,
                      //                    size: 17,
                      //           color: Colors.grey,
                      //                  ),
                      //                     ),
                      //             validator: (v) {
                      //             if (v == null || v.trim().isEmpty) {
                      //              return 'Please get your current location';
                      //                      }
                      //                  return null;
                      //                       },
                      //               ),

                              //     const SizedBox(height: 5),

                              //    const Align(
                              //  alignment: Alignment.centerLeft,
                              //        child: Text(
                              //            '  DIGIPIN generated from your current location',
                              //         style: TextStyle(
                              //        fontSize: 10.5,
                              //        color: Colors.grey,
                              //       ),
                              //          ),
                              //         ),
                            
                          ],
                        ),
                      ),
                    ),
                            
                            // Date of Birth
                            _buildLabel(dobText),
                            SizedBox(height: 8),
                            _buildTextField(
                              controller: _dobController,
                             hint: 'DD-MM-YYYY',
                              icon: Icons.calendar_today_outlined,
                              validator: _validateDOB,
                              readOnly: true,
                              onTap: () => _selectDate(context),
                            ),
                            SizedBox(height: 20),
                            
                            // Gender
                            _buildLabel(genderText),
                            SizedBox(height: 8),
                            GestureDetector(
                              onTap: () => _selectGender(context),
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          _selectedGenderId == 1
                                              ? Icons.male
                                              : _selectedGenderId == 2
                                                  ? Icons.female
                                                  : Icons.person_outline,
                                          color: _selectedGender == null 
                                              ? Colors.grey[400] 
                                              : Colors.cyan,
                                        ),
                                        SizedBox(width: 12),
                                        Text(
                                          _selectedGender ?? genderHint,
                                          style: GoogleFonts.roboto(
                                            color: _selectedGender == null 
                                                ? Colors.grey[600] 
                                                : Colors.black,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Icon(
                                      Icons.arrow_drop_down,
                                      color: Colors.grey[400],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: 20),
                            
                            // Phone Number
                            _buildLabel(phonenumberText),
                            SizedBox(height: 8),
                            _buildTextField(
                              controller: _phoneController,
                             hint: phonenumberHint,
                              icon: Icons.phone_outlined,
                              validator: _validatePhone,
                              keyboardType: TextInputType.phone,
                              maxLength: 10,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(10),
                              ],
                            ),
                            SizedBox(height: 20),
                            
                            // Church & District Row
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                //  CHURCH 
                                _buildLabel(churchText),
                                const SizedBox(height: 8),

                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey[300]!),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: isLoading
                                        ? const Padding(
                                            padding: EdgeInsets.symmetric(vertical: 16),
                                            child: Center(
                                              child: SizedBox(
                                                height: 20,
                                                width: 20,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: Colors.cyan,
                                                ),
                                              ),
                                            ),
                                          )
                                        : DropdownButton<int>(
                                            value: selectedChurchId,
                                            hint: Text(
                                              churchHint,
                                              style: GoogleFonts.roboto(
                                                fontSize: 14,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                            isExpanded: true,
                                            icon: Icon(Icons.arrow_drop_down, color: Colors.grey[400]),
                                            items: churches.map((church) {
                                              return DropdownMenuItem<int>(
                                                value: church.id,
                                                child: Text(
                                                  church.name,
                                                  style: GoogleFonts.roboto(fontSize: 14),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              );
                                            }).toList(),
                                            onChanged: (int? value) {
                                              if (value == null) return;
                                              final church =
                                                  churches.firstWhere((c) => c.id == value);
                                              setState(() {
                                                selectedChurchId = value;
                                                selectedParishId = church.parishid;
                                                selectedForaneId = church.foraneid;
                                                selectedDioceseId = church.dioceseid;
                                              });
                                            },
                                          ),
                                  ),
                                ),

                                const SizedBox(height: 16),

                                // DISTRICT 
                                _buildLabel(districtText),
                                const SizedBox(height: 8),

                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey[300]!),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: isLoading
                                        ? const Padding(
                                            padding: EdgeInsets.symmetric(vertical: 16),
                                            child: Center(
                                              child: SizedBox(
                                                height: 20,
                                                width: 20,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: Colors.cyan,
                                                ),
                                              ),
                                            ),
                                          )
                                        : DropdownButton<int>(
                                            value: selectedDistrictId,
                                            hint: Text(
                                              districtHint,
                                              style: GoogleFonts.roboto(
                                                fontSize: 14,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                            isExpanded: true,
                                            icon: Icon(Icons.arrow_drop_down, color: Colors.grey[400]),
                                            items: districts.map((district) {
                                              return DropdownMenuItem<int>(
                                                value: district.id,
                                                child: Text(
                                                  district.name,
                                                  style: GoogleFonts.roboto(fontSize: 14),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              );
                                            }).toList(),
                                            onChanged: (int? value) {
                                              setState(() {
                                                selectedDistrictId = value;
                                              });
                                            },
                                          ),
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(height: 32),
                            
                            // Submit Button
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: isSubmitting ? null : submitGuestRegistration,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.cyan,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 3,
                                ),
                                child: isSubmitting
                                    ? SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.5,
                                        ),
                                      )
                                    : Text(
                                        continueText,
                                        style: GoogleFonts.roboto(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.roboto(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
    int? maxLength,
    bool readOnly = false,
    VoidCallback? onTap,
    TextCapitalization textCapitalization = TextCapitalization.none,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      maxLength: maxLength,
      readOnly: readOnly,
      onTap: onTap,
      textCapitalization: textCapitalization,
      inputFormatters: inputFormatters,
      style: GoogleFonts.roboto(fontSize: 16),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.roboto(color: Colors.grey[600]),
        prefixIcon: Icon(icon, color: Colors.cyan),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.cyan, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red, width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        counterText: maxLength != null ? '' : null,
      ),
    );
  }
}