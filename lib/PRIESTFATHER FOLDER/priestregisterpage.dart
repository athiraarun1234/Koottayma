import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

class PriestRegister extends StatefulWidget {
  const PriestRegister({super.key});

  @override
  State<PriestRegister> createState() => _PriestRegisterState();
}

class _PriestRegisterState extends State<PriestRegister> {
  final _formKey = GlobalKey<FormState>();

  // Text controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _ordinationDateController =
      TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _aadharController = TextEditingController();
  final TextEditingController _fatherNameController = TextEditingController();
  final TextEditingController _motherNameController = TextEditingController();
  final TextEditingController _dioceseController = TextEditingController();
  final TextEditingController _foraneController = TextEditingController();
  final TextEditingController _parishController = TextEditingController();

  DateTime? _selectedDob;
  DateTime? _selectedOrdinationDate;

  File? _profileImage;
  File? _aadharFrontImage;
  File? _aadharBackImage;

  final ImagePicker _picker = ImagePicker();
  bool _isSubmitting = false;
  
  @override
  void dispose() {
    _nameController.dispose();
    _dobController.dispose();
    _ordinationDateController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _aadharController.dispose();
    _fatherNameController.dispose();
    _motherNameController.dispose();
    _dioceseController.dispose();
    _foraneController.dispose();
    _parishController.dispose();
    super.dispose();
  }

  Future<void> _selectDate({required bool isDob}) async {
    final DateTime now = DateTime.now();
    final DateTime initial = isDob
        ? (_selectedDob ?? DateTime(now.year - 30))
        : (_selectedOrdinationDate ?? now);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.cyan,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        final formatted = DateFormat('dd-MM-yyyy').format(picked);
        if (isDob) {
          _selectedDob = picked;
          _dobController.text = formatted;
        } else {
          _selectedOrdinationDate = picked;
          _ordinationDateController.text = formatted;
        }
      });
    }
  }

  Future<void> _pickProfileImage() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera, color: Colors.cyan),
                title: const Text('Camera'),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? image =
                      await _picker.pickImage(source: ImageSource.camera);
                  if (image != null) {
                    setState(() => _profileImage = File(image.path));
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.cyan),
                title: const Text('Gallery'),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? image =
                      await _picker.pickImage(source: ImageSource.gallery);
                  if (image != null) {
                    setState(() => _profileImage = File(image.path));
                  }
                },
              ),
              if (_profileImage != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.redAccent),
                  title: const Text('Remove Photo'),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _profileImage = null);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage({required bool isFront}) async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera, color: Colors.cyan),
                title: const Text('Camera'),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? image =
                      await _picker.pickImage(source: ImageSource.camera);
                  if (image != null) {
                    setState(() {
                      if (isFront) {
                        _aadharFrontImage = File(image.path);
                      } else {
                        _aadharBackImage = File(image.path);
                      }
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.cyan),
                title: const Text('Gallery'),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? image =
                      await _picker.pickImage(source: ImageSource.gallery);
                  if (image != null) {
                    setState(() {
                      if (isFront) {
                        _aadharFrontImage = File(image.path);
                      } else {
                        _aadharBackImage = File(image.path);
                      }
                    });
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLength = 100,
    String? Function(String?)? validator,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        onTap: onTap,
        keyboardType: keyboardType,
        maxLength: maxLength,
        style: GoogleFonts.roboto(fontSize: 15),
        decoration: InputDecoration(
          counterText: '',
          labelText: label,
          labelStyle: GoogleFonts.roboto(color: Colors.cyan.shade700),
          prefixIcon: Icon(icon, color: Colors.cyan),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.cyan.shade100),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.cyan, width: 1.5),
          ),
        ),
        validator: validator ??
            (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter $label';
              }
              return null;
            },
      ),
    );
  }

  Widget _buildProfilePicture() {
    return Center(
      child: GestureDetector(
        onTap: _pickProfileImage,
        child: Stack(
          children: [
            CircleAvatar(
              radius: 55,
              backgroundColor: Colors.white,
              child: CircleAvatar(
                radius: 52,
                backgroundColor: Colors.cyan.shade50,
                backgroundImage:
                    _profileImage != null ? FileImage(_profileImage!) : null,
                child: _profileImage == null
                    ? Icon(Icons.person, size: 55, color: Colors.cyan.shade200)
                    : null,
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: CircleAvatar(
                radius: 16,
                backgroundColor: Colors.cyan,
                child: const Icon(Icons.camera_alt,
                    size: 16, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePicker({
    required String label,
    required File? image,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.roboto(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.cyan.shade800,
            ),
          ),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: onTap,
            child: Container(
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.cyan.shade100),
              ),
              child: image == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo,
                            size: 36, color: Colors.cyan.shade300),
                        const SizedBox(height: 6),
                        Text(
                          'Tap to upload $label',
                          style: GoogleFonts.roboto(
                              color: Colors.cyan.shade300, fontSize: 13),
                        ),
                      ],
                    )
                  : Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(image, fit: BoxFit.cover),
                        ),
                        Positioned(
                          top: 6,
                          right: 6,
                          child: CircleAvatar(
                            radius: 14,
                            backgroundColor: Colors.black54,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: const Icon(Icons.edit,
                                  size: 15, color: Colors.white),
                              onPressed: onTap,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // void _submitForm() {
  //   if (!_formKey.currentState!.validate()) {
  //     return;
  //   }
  //   if (_aadharFrontImage == null || _aadharBackImage == null) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(
  //         content: Text('Please upload both Aadhar front and back images'),
  //         backgroundColor: Colors.redAccent,
  //       ),
  //     );
  //     return;
  //   }

  //   setState(() => _isSubmitting = true);

  //   final formData = {
  //     'profileImagePath': _profileImage?.path,
  //     'name': _nameController.text.trim(),
  //     'dob': _dobController.text.trim(),
  //     'ordinationDate': _ordinationDateController.text.trim(),
  //     'phone': _phoneController.text.trim(),
  //     'email': _emailController.text.trim(),
  //     'aadharNo': _aadharController.text.trim(),
  //     'aadharFrontPath': _aadharFrontImage!.path,
  //     'aadharBackPath': _aadharBackImage!.path,
  //     'fatherName': _fatherNameController.text.trim(),
  //     'motherName': _motherNameController.text.trim(),
  //     'birthDiocese': _dioceseController.text.trim(),
  //     'birthForane': _foraneController.text.trim(),
  //     'birthParish': _parishController.text.trim(),
  //   };

  //   debugPrint('Priest Register Form Data: $formData');

  //   Future.delayed(const Duration(seconds: 1), () {
  //     if (!mounted) return;
  //     setState(() => _isSubmitting = false);
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(
  //         content: Text('Priest registered successfully'),
  //         backgroundColor: Colors.cyan,
  //       ),
  //     );
  //   });
  // }

  
   // ─── POST to Backend 
  Future<void> _submitForm() async {
     if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_aadharFrontImage == null || _aadharBackImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload both Aadhar front and back images'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    const String apiUrl = 'https://backend.com/api/api/priestregister'; 

    final formData = {
      'profileImagePath': _profileImage?.path,
      'name': _nameController.text.trim(),
      'dob': _dobController.text.trim(),
      'ordinationDate': _ordinationDateController.text.trim(),
      'phone': _phoneController.text.trim(),
      'email': _emailController.text.trim(),
      'aadharNo': _aadharController.text.trim(),
      'aadharFrontPath': _aadharFrontImage!.path,
      'aadharBackPath': _aadharBackImage!.path,
      'fatherName': _fatherNameController.text.trim(),
      'motherName': _motherNameController.text.trim(),
      'birthDiocese': _dioceseController.text.trim(),
      'birthForane': _foraneController.text.trim(),
      'birthParish': _parishController.text.trim(),
    };
   debugPrint('Priest Register Form Data: $formData');
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          // 'Authorization': 'Bearer YOUR_TOKEN', 
        },
        body: jsonEncode(formData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSnack('Submitted successfully!', isError: false);
       
      } else {
        _showSnack('Error ${response.statusCode}: ${response.reasonPhrase}');
      }
    } on SocketException {
      _showSnack('No internet connection');
    } catch (e) {
      _showSnack('Something went wrong: $e');
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _showSnack(String msg, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
    ));
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.cyan,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Priest Register',
          style: GoogleFonts.roboto(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle:true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.cyan, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.0, 0.25],
          ),
        ),
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildProfilePicture(),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Tap to add profile photo',
                    style: GoogleFonts.roboto(
                      fontSize: 12,
                      color: Colors.cyan.shade900,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Personal Details',
                          style: GoogleFonts.roboto(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.cyan.shade800,
                          ),
                        ),
                        _buildTextField(
                          controller: _nameController,
                          label: 'Name',
                          icon: Icons.person,
                        ),
                        _buildTextField(
                          controller: _dobController,
                          label: 'Date of Birth',
                          icon: Icons.cake,
                          readOnly: true,
                          onTap: () => _selectDate(isDob: true),
                        ),
                        _buildTextField(
                          controller: _ordinationDateController,
                          label: 'Date of Ordination',
                          icon: Icons.church,
                          readOnly: true,
                          onTap: () => _selectDate(isDob: false),
                        ),
                        _buildTextField(
                          controller: _phoneController,
                          label: 'Phone No',
                          icon: Icons.phone,
                          keyboardType: TextInputType.phone,
                          maxLength: 10,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter phone number';
                            }
                            if (value.trim().length != 10) {
                              return 'Enter a valid 10 digit phone number';
                            }
                            return null;
                          },
                        ),
                        _buildTextField(
                          controller: _emailController,
                          label: 'Email ID',
                          icon: Icons.email,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter email id';
                            }
                            final emailRegex =
                                RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[\w\-]{2,4}$');
                            if (!emailRegex.hasMatch(value.trim())) {
                              return 'Enter a valid email id';
                            }
                            return null;
                          },
                        ),
                        _buildTextField(
                          controller: _aadharController,
                          label: 'Aadhar No',
                          icon: Icons.credit_card,
                          keyboardType: TextInputType.number,
                          maxLength: 12,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter aadhar number';
                            }
                            if (value.trim().length != 12) {
                              return 'Enter a valid 12 digit aadhar number';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Aadhar Card Images',
                          style: GoogleFonts.roboto(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.cyan.shade800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildImagePicker(
                          label: 'Aadhar Front Image',
                          image: _aadharFrontImage,
                          onTap: () => _pickImage(isFront: true),
                        ),
                        _buildImagePicker(
                          label: 'Aadhar Back Image',
                          image: _aadharBackImage,
                          onTap: () => _pickImage(isFront: false),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Family Details',
                          style: GoogleFonts.roboto(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.cyan.shade800,
                          ),
                        ),
                        _buildTextField(
                          controller: _fatherNameController,
                          label: "Father's Name",
                          icon: Icons.man,
                        ),
                        _buildTextField(
                          controller: _motherNameController,
                          label: "Mother's Name",
                          icon: Icons.woman,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Birth Diocese Details',
                          style: GoogleFonts.roboto(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.cyan.shade800,
                          ),
                        ),
                        _buildTextField(
                          controller: _dioceseController,
                          label: 'Birth Diocese Name',
                          icon: Icons.account_balance,
                        ),
                        _buildTextField(
                          controller: _foraneController,
                          label: 'Birth Forane Name',
                          icon: Icons.location_city,
                        ),
                        _buildTextField(
                          controller: _parishController,
                          label: 'Birth Parish Name',
                          icon: Icons.church_outlined,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyan,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(
                            'Submit',
                            style: GoogleFonts.roboto(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}