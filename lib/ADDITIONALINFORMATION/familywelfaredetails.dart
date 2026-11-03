import 'package:Koottaayma/HTTPURL/httpurl.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class FamilyWelfareDetails extends StatefulWidget {

  
  const FamilyWelfareDetails({Key? key,}) : super(key: key);
  
  @override
  _FamilyWelfareDetailsState createState() => _FamilyWelfareDetailsState();
}

class _FamilyWelfareDetailsState extends State<FamilyWelfareDetails> {
  Map<int, String> answers = {};
  String? houseType;
  bool isSubmitting = false;
  
  final List<Map<String, dynamic>> questions = [
    {
      "question": "1. House?",
      "options": ["Own", "Rented", "Other"],
      "questionId": 1
    },
    {
      "question": "2. Well?",
      "options": ["Yes", "No"],
      "questionId": 2
    },
    {
      "question": "3.Govt Water Connection?",
      "options": ["Yes", "No"],
      "questionId": 3
    },
    {
      "question": "4.Electricity?",
      "options": ["Yes", "No"],
      "questionId": 4
    },
    {
      "question": "5.Gas?",
      "options": ["Yes", "No"],
      "questionId": 5
    },
    {
      "question": "6.Gated?",
      "options": ["Yes", "No"],
      "questionId": 6
    },
    {
      "question": "7.Boundary Wall?",
      "options": ["Yes", "No"],
      "questionId": 7
    },
    {
      "question": "8.Ration Card?",
      "options": ["BPL", "APL"],
      "questionId": 8
    },
  ];

  // Map answer text to answer IDs
  int getAnswerID(int questionIndex, String answer) {
    // For question 1 (House type)
    if (questionIndex == 0) {
      switch (answer) {
        case "Own": return 1;
        case "Rented": return 2;
        case "Other": return 3;
        default: return 1;
      }
    }
    // For Yes/No questions
    if (answer == "Yes") return 1;
    if (answer == "No") return 2;
    // For Ration Card (BPL/APL)
    if (answer == "BPL") return 1;
    if (answer == "APL") return 2;
    
    return 1; // Default
  }

  Future<void> submitAnswers() async {
    // Validate all questions are answered
    if (answers.length < questions.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please answer all questions!"),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // If first answer is "Own", validate house type is selected
    if (answers[0] == "Own" && houseType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select house type!"),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      isSubmitting = true;
    });

 try {
  SharedPreferences prefs = await SharedPreferences.getInstance();

  int? savedFamilyMasterID = prefs.getInt('nFamilyMasterID');
  String? savedToken = prefs.getString('jwt');

  print("Loaded nFamilyMasterID from prefs: $savedFamilyMasterID");
  print("Loaded Token: $savedToken");

  List<Map<String, dynamic>> lstQuestions = [];

  for (int i = 0; i < questions.length; i++) {
    Map<String, dynamic> questionData = {
      "nQuestionID": questions[i]["questionId"],
      "nAnswerID": getAnswerID(i, answers[i]!),
    };

    if (i == 0 && answers[i] == "Own" && houseType != null) {
      questionData["cTypeName"] = houseType!.toLowerCase();
    }

    lstQuestions.add(questionData);
  }

  Map<String, dynamic> requestBody = {
    "lstQuestions": lstQuestions,
   // "nFamilyMasterID": savedFamilyMasterID   
  };

  print("Sending request: ${json.encode(requestBody)}");

  final response = await http.post(
    Uri.parse(FamilyWelfareAPI),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': '$savedToken',
    },
    body: json.encode(requestBody),
  );

  print("Response Status: ${response.statusCode}");
  print("Response Body: ${response.body}");

  if (response.statusCode == 200 || response.statusCode == 201) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Answers submitted successfully!"),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      Navigator.of(context).pop(true);
    }
  } else {
    throw Exception('Failed to submit: ${response.statusCode} - ${response.body}');
  }

} 
 catch (e) {
      print("Error submitting answers: $e");
      
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
          "Family Welfare Details",
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
                  var q = questions[index];
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 6),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // First question layout (two lines)
                          if (index == 0) ...[
                            Text(
                              q["question"],
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Row(
                              children: q["options"].map<Widget>((opt) {
                                return Expanded(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Radio<String>(
                                        value: opt,
                                        groupValue: answers[index],
                                        visualDensity: VisualDensity.compact,
                                        onChanged: (value) {
                                          setState(() {
                                            answers[index] = value!;
                                            if (value == "Rented" || value == "Other") {
                                              houseType = null;
                                            }
                                          });
                                        },
                                      ),
                                      Flexible(
                                        child: Text(
                                          opt,
                                          style: TextStyle(fontSize: 14),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ]
                          // All other questions layout (single line)
                          else ...[
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    q["question"],
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Row(
                                    children: q["options"].map<Widget>((opt) {
                                      return Expanded(
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Radio<String>(
                                              value: opt,
                                              groupValue: answers[index],
                                              visualDensity: VisualDensity.compact,
                                              onChanged: (value) {
                                                setState(() {
                                                  answers[index] = value!;
                                                });
                                              },
                                            ),
                                            Flexible(
                                              child: Text(
                                                opt,
                                                style: TextStyle(fontSize: 14),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ],
                            ),
                          ],
if (index == 0 && answers[index] == "Own") ...[
  SizedBox(height: 8),
  Padding(
    padding: const EdgeInsets.all(8.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "If own house?",
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        ),
        SizedBox(height: 8),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: ["Concrete", "Sheet", "Other"].map((opt) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Radio<String>(
                  value: opt,
                  groupValue: houseType,
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onChanged: (value) {
                    setState(() {
                      houseType = value;
                    });
                  },
                ),
                Text(
                  opt,
                  style: TextStyle(fontSize: 14),
                ),
              ],
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
                          onPressed: isSubmitting ? null : submitAnswers,
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
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}