
import 'package:Koottaayma/HTTPURL/httpurl.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class MemberMedicalDetails extends StatefulWidget {
 

  const MemberMedicalDetails({
    Key? key,

  }) : super(key: key);

  @override
  _MemberMedicalDetailsState createState() => _MemberMedicalDetailsState();
}

class _MemberMedicalDetailsState extends State<MemberMedicalDetails> {
  Map<int, bool> answers = {};
  String? diabetesType;
  String? cancerType;
  String? thyroidType;
  String? liverType;
  String? strokeType;
  bool isSubmitting = false;

  final List<String> questions = [
    "1. Diabetes?",
    "2. Cholesterol?",
    "3. Anemia?",
    "4. Cancer?",
    "5. Thyroid?",
    "6. Liver?",
    "7. Skin?",
    "8. Allergy?",
    "9. Stroke?",
    "10. BedRidden?",
    "11. Others?",
  ];

  // Map question index to disease ID
  int _getDiseaseID(int index) {
    return index + 1; 
  }

  // Convert treatment type to option type (Govt = 1, Private = 2)
  int? _getOptionType(String? treatmentType) {
    if (treatmentType == null) return null;
    return treatmentType == "Govt" ? 1 : 2;
  }

  Future<void> _submitMedicalDetails() async {
    setState(() {
      isSubmitting = true;
    });

    try {
        SharedPreferences prefs = await SharedPreferences.getInstance();

       int? savedFamilyMasterID = prefs.getInt('nFamilyMasterID');
       String? savedToken = prefs.getString('jwt');
      int? savedFamilyMemberID = prefs.getInt('nFamilyMemberID');
      // Build the diseases list
      List<Map<String, dynamic>> lstDiseases = [];

      for (int i = 0; i < questions.length; i++) {
        if (answers[i] == true) {
          Map<String, dynamic> disease = {
            "nDiseaseID": _getDiseaseID(i),
            "bOptionYN": 1, // Yes
          };

          // Add treatment type if applicable
          if (i == 0 && diabetesType != null) {
            disease["nOptionType"] = _getOptionType(diabetesType);
          } else if (i == 3 && cancerType != null) {
            disease["nOptionType"] = _getOptionType(cancerType);
          } else if (i == 4 && thyroidType != null) {
            disease["nOptionType"] = _getOptionType(thyroidType);
          } else if (i == 5 && liverType != null) {
            disease["nOptionType"] = _getOptionType(liverType);
          } else if (i == 8 && strokeType != null) {
            disease["nOptionType"] = _getOptionType(strokeType);
          }

          lstDiseases.add(disease);
        } else if (answers[i] == false) {
         
          lstDiseases.add({
            "nDiseaseID": _getDiseaseID(i),
            "bOptionYN": 2, // 
          });
        }
      }
      Map<String, dynamic> requestBody = {
        "nFamilyMasterID":savedFamilyMasterID,
        "nMemberID": savedFamilyMemberID,
        "lstDiseases": lstDiseases,
      };

      print("Request Body: ${jsonEncode(requestBody)}");

      // Make API call
      final response = await http.post(
        Uri.parse(FamilyMemberMedicalDetails), 
        headers: {
          'Content-Type': 'application/json',
         
          'Authorization': '$savedToken',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Success
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Medical details submitted successfully!"),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          // Navigate back or to next screen
          Navigator.of(context).pop();
        }
      } else {
        // Error
        throw Exception('Failed to submit: ${response.statusCode}');
      }
    } catch (e) {
      print("Error submitting medical details: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${e.toString()}"),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: Colors.cyan,
        title: Text(
          "Medical Details",
          style: GoogleFonts.roboto(color: Colors.white),
        ),
      ),
      body: SizedBox.expand(
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
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                ...List.generate(questions.length, (index) {
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Checkbox(
                                value: answers[index] ?? false,
                                onChanged: (value) {
                                  setState(() {
                                    answers[index] = value ?? false;
                                    // Clear sub-options when unchecked
                                    if (index == 0 && !answers[index]!) {
                                      diabetesType = null;
                                    }
                                    if (index == 3 && !answers[index]!) {
                                      cancerType = null;
                                    }
                                    if (index == 4 && !answers[index]!) {
                                      thyroidType = null;
                                    }
                                    if (index == 5 && !answers[index]!) {
                                      liverType = null;
                                    }
                                    if (index == 8 && !answers[index]!) {
                                      strokeType = null;
                                    }
                                  });
                                },
                                activeColor: Colors.cyan,
                              ),
                              Expanded(
                                child: Text(
                                  questions[index],
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          // Show follow-up for Diabetes
                          if (index == 0 && (answers[index] ?? false)) ...[
                            Padding(
                              padding: const EdgeInsets.only(left: 16.0, top: 8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Treatment Mode?",
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Row(
                                    children: ["Govt", "Private"].map((opt) {
                                      return Expanded(
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Radio<String>(
                                              value: opt,
                                              groupValue: diabetesType,
                                              onChanged: (value) {
                                                setState(() {
                                                  diabetesType = value!;
                                                });
                                              },
                                              activeColor: Colors.cyan,
                                            ),
                                            Text(opt),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          // Show follow-up for Cancer
                          if (index == 3 && (answers[index] ?? false)) ...[
                            Padding(
                              padding: const EdgeInsets.only(left: 16.0, top: 8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Treatment Mode?",
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Row(
                                    children: ["Govt", "Private"].map((opt) {
                                      return Expanded(
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Radio<String>(
                                              value: opt,
                                              groupValue: cancerType,
                                              onChanged: (value) {
                                                setState(() {
                                                  cancerType = value!;
                                                });
                                              },
                                              activeColor: Colors.cyan,
                                            ),
                                            Text(opt),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          if (index == 4 && (answers[index] ?? false)) ...[
                            Padding(
                              padding: const EdgeInsets.only(left: 16.0, top: 8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Treatment Mode?",
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Row(
                                    children: ["Govt", "Private"].map((opt) {
                                      return Expanded(
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Radio<String>(
                                              value: opt,
                                              groupValue: thyroidType,
                                              onChanged: (value) {
                                                setState(() {
                                                  thyroidType = value!;
                                                });
                                              },
                                              activeColor: Colors.cyan,
                                            ),
                                            Text(opt),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          if (index == 5 && (answers[index] ?? false)) ...[
                            Padding(
                              padding: const EdgeInsets.only(left: 16.0, top: 8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Treatment Mode?",
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Row(
                                    children: ["Govt", "Private"].map((opt) {
                                      return Expanded(
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Radio<String>(
                                              value: opt,
                                              groupValue: liverType,
                                              onChanged: (value) {
                                                setState(() {
                                                  liverType = value!;
                                                });
                                              },
                                              activeColor: Colors.cyan,
                                            ),
                                            Text(opt),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          if (index == 8 && (answers[index] ?? false)) ...[
                            Padding(
                              padding: const EdgeInsets.only(left: 16.0, top: 8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Treatment Mode?",
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Row(
                                    children: ["Govt", "Private"].map((opt) {
                                      return Expanded(
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Radio<String>(
                                              value: opt,
                                              groupValue: strokeType,
                                              onChanged: (value) {
                                                setState(() {
                                                  strokeType = value!;
                                                });
                                              },
                                              activeColor: Colors.cyan,
                                            ),
                                            Text(opt),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }),
                SizedBox(height: 20),
                SafeArea(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.cyan,
                            foregroundColor: Colors.white,
                            elevation: 5,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: isSubmitting ? null : _submitMedicalDetails,
                          child: isSubmitting
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  "Submit",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                        ),
                      ),
                    ),
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