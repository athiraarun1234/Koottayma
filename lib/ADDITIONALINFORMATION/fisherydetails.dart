import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MemberFisheryDetails extends StatefulWidget {
  @override
  _MemberFisheryDetailsState createState() => _MemberFisheryDetailsState();
}

class _MemberFisheryDetailsState extends State<MemberFisheryDetails> {
  Map<int, bool> answers = {};
 
  
  final List<String> questions = [
    "1. Boat?",
    "2. Net?",
    "3. Are you a fisherman?",
    "4. Are you selling fish?",
    "5. Brokerage?",
    "6. Shed?",
    "7. Accessories?",
    "8. Engine oil?",
    "9. Kerosene??",
  ];

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
          height: 40,
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
            padding: EdgeInsets.all(8),
            child: Column(
              children: [
                ...List.generate(questions.length, (index) {
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 5),
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
                                 
                                  });
                                },
                                activeColor: Colors.cyan,
                              ),
                              Expanded(
                                child: Text(
                                  questions[index],
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),    
                        ]
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
                        
                          onPressed: () {  },
                          child: const Text(
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