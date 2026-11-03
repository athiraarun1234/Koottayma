
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
class TeacherHomePage extends StatefulWidget {

  const TeacherHomePage({Key? key,}) : super(key: key);

  @override
  State<TeacherHomePage> createState() => _TeacherHomePageState();
}

class _TeacherHomePageState extends State<TeacherHomePage> {
  
  @override
  void initState() {
  super.initState();
 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SizedBox.expand(
        child: Container(
          decoration: BoxDecoration(
           gradient: LinearGradient(
          colors: [Colors.cyan, const Color.fromARGB(255, 202, 236, 241),Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomCenter,
               ),
             ),
             child: Column(
              children: [
                  SizedBox(height: 15),
                    // Header
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(
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
                                    Icons.church,
                                    size: 24,
                                    color: Colors.cyan,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    "Good Morning",
                                    style: GoogleFonts.roboto(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.cyan[800],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 6),
                            Text('Welcome to Sunday School',style: GoogleFonts.roboto(fontWeight: FontWeight.bold,fontSize: 20,
                            color: Colors.cyan[800]),)
                            ],
                          ),
                        ),
                    
                      ),
                      
                    ),
                    Container(
                      height: 80,
                      width: 350,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Colors.cyan
                      ),
                      child: Row(
                        children: [
                          Container(height: 80,
                          width: 80,
                          decoration: BoxDecoration(color: Colors.white,borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.cyan,width: 5)),
                            child: Image.asset('assets/sundayschools.jpg',scale: 1.5,)),
                            SizedBox(width: 10,),
                          Text('Sunday School Attendance',style: GoogleFonts.roboto(color: Colors.white,fontSize: 18,fontWeight:FontWeight.bold),),
                        ],
                      ),
                    ),
                    SizedBox(height: 25,),
                      Container(
                      height: 80,
                      width: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Colors.cyan
                      ),
                      child: Padding(
                        padding:EdgeInsets.only(left: 10),
                        child: Center(child: Text('Switch to User',style: GoogleFonts.roboto(color: Colors.white,fontSize: 18,fontWeight:FontWeight.bold),)),
                      ),
                    ),
              ],
             ),
         
        ),
      ),   
    );
  }                  
}
