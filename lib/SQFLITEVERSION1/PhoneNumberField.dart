import 'package:Koottaayma/SQFLITEVERSION1/DataBaseHelper.dart';
import 'package:Koottaayma/SQFLITEVERSION1/LabelDetails.dart';
import 'package:Koottaayma/SQFLITEVERSION1/OTPVerification.dart';
import 'package:country_code_picker/country_code_picker.dart'; // ← import
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PhoneNumber extends StatefulWidget {
  final int languageId;
  final int phoneNumber;
  final int nUserTypeID;
  const PhoneNumber({
    super.key,
    required this.languageId,
    required this.phoneNumber,
    required this.nUserTypeID,
  });

  @override
  State<PhoneNumber> createState() => _PhoneNumberState();
}

class _PhoneNumberState extends State<PhoneNumber> {
  final dbHelper = DatabaseHelper();
  final TextEditingController phoneController = TextEditingController();
  List<LabelDetails> allLabels = [];
  String titleText = 'Verify Your Phone Number';
  String phoneNumberHint = 'Phone Number';
  String getOtpButtonText = 'GET OTP';
  String alreadyAccountText = 'Already Have An Account?';
  String signInText = '';
  String descriptionText =
      'We have sent you a One Time Password (OTP) on this mobile number';
  bool isLoading = true;
  bool isSendingOtp = false;
  String? errorMessage;

  // ─── Selected dial code (defaults to India +91) 
  String _selectedDialCode = '+91';

  @override
  void initState() {
    super.initState();
    fetchPhoneNumberLabels();
  }

  @override
  void dispose() {
    phoneController.dispose();
    super.dispose();
  }

  Future<void> fetchPhoneNumberLabels() async {
    try {
      print('Fetching labels for page 2, language ${widget.languageId}');
      await dbHelper.debugPrintLabelDetails();
      final labels = await dbHelper.getLabelsForPage(
          1, widget.languageId, widget.nUserTypeID);
      print('Found ${labels.length} labels for phone number page');

      if (labels.isEmpty) {
        setState(() {
          errorMessage =
              'No labels found for selected language. Using default text.';
          isLoading = false;
        });
        return;
      }

      for (var label in labels) {
        switch (label.nLabelID) {
          case 1:
            titleText = label.cLabelKey;
            break;
          case 2:
            descriptionText = label.cLabelKey;
            break;
          case 3:
            phoneNumberHint = label.cLabelKey;
            break;
          case 4:
            getOtpButtonText = label.cLabelKey;
            break;
          case 5:
            alreadyAccountText = label.cLabelKey;
            break;
          case 6:
            signInText = label.cLabelKey;
            break;
        }
      }

      setState(() {
        allLabels = labels;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching phone number labels: $e');
      setState(() {
        errorMessage = 'Error fetching labels: $e. Using default text.';
        isLoading = false;
      });
    }
  }

  Future<void> _sendOtp() async {
    final phone = phoneController.text.trim();

    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter phone number'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (phone.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid phone number'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => isSendingOtp = true);

    // ─── Uses the dial code selected from CountryCodePicker 
    final formattedPhone = '$_selectedDialCode$phone';
  debugPrint('Formatted phone sent to Firebase: $formattedPhone'); // 👈 

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: formattedPhone,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await FirebaseAuth.instance.signInWithCredential(credential);
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Phone verified automatically!'),
            backgroundColor: Colors.green,
          ),
        );
      },

      verificationFailed: (FirebaseAuthException e) {
         debugPrint('OTP failed for $formattedPhone: ${e.code} ${e.message}');
         debugPrint('Firebase OTP error code: ${e.code}');
         debugPrint('Firebase OTP error message: ${e.message}');
        setState(() => isSendingOtp = false);
        String message = 'Verification failed. Please try again.';
        if (e.code == 'invalid-phone-number') {
          message = 'Invalid phone number format.';
        } else if (e.code == 'too-many-requests') {
          message = 'Too many requests. Please try again later.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      },

      codeSent: (String verificationId, int? resendToken) {
       
        setState(() => isSendingOtp = false);
        if (!mounted) return;
         debugPrint('Navigating to OTPVerification with phoneNumber: $phone'); // 👈 

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OTPVerification(
              nUserTypeID: widget.nUserTypeID,
              languageId: widget.languageId,
            // phoneNumber: formattedPhone, 
              phoneNumber: int.parse(phone),
              verificationId: verificationId,
            ),
          ),
        );
      },

      codeAutoRetrievalTimeout: (String verificationId) {
        print('Auto-retrieval timeout. verificationId: $verificationId');
      },

      timeout: const Duration(seconds: 60),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    if (isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Colors.cyan,
                Color.fromARGB(255, 202, 236, 241),
                Colors.white,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomCenter,
            ),
            image: DecorationImage(
              image: const AssetImage('assets/god.png'),
              scale: 1,
              opacity: 0.5,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(height: size.height * 0.34),

                // Title & description
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titleText.split(' ').take(2).join(' '),
                      style: GoogleFonts.lato(
                          fontSize: 25, fontWeight: FontWeight.bold),
                    ),
                    if (titleText.split(' ').length > 2)
                      Text(
                        titleText.split(' ').skip(2).join(' '),
                        style: GoogleFonts.lato(
                            fontSize: 25, fontWeight: FontWeight.bold),
                      ),
                    const SizedBox(height: 10),
                    Text(
                      descriptionText,
                      style: GoogleFonts.lato(
                          fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),

                SizedBox(height: size.height * 0.05),

                // ── Phone input with CountryCodePicker 
                Container(
                  width: double.infinity,
                  height: size.height * 0.06,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      // ── Country Code Picker 
                      CountryCodePicker(
                        onChanged: (CountryCode code) {
                          setState(() {
                            _selectedDialCode = code.dialCode ?? '+91';
                          });
                        },
                        initialSelection: 'IN',       // default country: India
                        countryFilter: const ['IN'],//in this line is used to show only country code of india 
                        //if show all countries then remove countryfilter and also showdropdownbutton true.
                        favorite: const ['+91', 'IN'], 
                        showCountryOnly: false,
                        showOnlyCountryWhenClosed: false,
                        alignLeft: false,
                        showFlag: true,
                        showFlagDialog: true,
                       //showDropDownButton: true,
                        showDropDownButton:false,
                        textStyle: GoogleFonts.lato(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        dialogTextStyle: GoogleFonts.lato(fontSize: 14),
                        searchDecoration: InputDecoration(
                          hintText: 'Search country...',
                          hintStyle: GoogleFonts.lato(fontSize: 14),
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        boxDecoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        padding: EdgeInsets.zero,
                      ),

                      // Divider between picker and text field
                      Container(
                        width: 1,
                        height: 30,
                        color: Colors.grey[400],
                      ),

                      // ── Phone number text field ───────────────────────────
                      Expanded(
                        child: TextField(
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          maxLength: 15,
                          decoration: InputDecoration(
                            counterText: '',
                            hintText: phoneNumberHint,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: size.height * 0.03),

                // GET OTP Button
                GestureDetector(
                  onTap: isSendingOtp ? null : _sendOtp,
                  child: Container(
                    width: double.infinity,
                    height: size.height * 0.06,
                    decoration: BoxDecoration(
                      color: isSendingOtp ? Colors.blue[300] : Colors.blue,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: isSendingOtp
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              getOtpButtonText,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ),

                SizedBox(height: size.height * 0.02),

                // Already have account
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      alreadyAccountText,
                      style: GoogleFonts.lato(
                          fontSize: 14, color: Colors.grey[600]),
                    ),
                    const SizedBox(width: 5),
                    GestureDetector(
                      onTap: () {},
                      child: Text(
                        signInText,
                        style: GoogleFonts.lato(
                          fontSize: 14,
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                if (errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Text(
                      errorMessage!,
                      style: TextStyle(color: Colors.red[600], fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}