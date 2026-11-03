
// import 'package:MyCommunity/5homepage.dart';
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:otp_text_field/otp_field.dart';
// import 'package:otp_text_field/otp_field_style.dart';
// import 'package:otp_text_field/style.dart';


// class OTPVerification extends StatefulWidget {

//   const OTPVerification({Key? key,}) : super(key: key);

//   @override
//   State<OTPVerification> createState() => _OTPVerificationState();
// }

// class _OTPVerificationState extends State<OTPVerification> {
//   @override
//   void initState() {
//     super.initState();
   
//   }

 
//   @override
//   Widget build(BuildContext context) {
//      final size = MediaQuery.of(context).size;

//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: SingleChildScrollView(
//         child: Container(
//           decoration: BoxDecoration(
//            gradient: LinearGradient(
//           colors: [Colors.cyan, const Color.fromARGB(255, 202, 236, 241),Colors.white],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomCenter,
//                ),
//             image: DecorationImage(image: AssetImage('assets/god.png',),scale: 1,opacity: 0.5
//             )
        
//              ),
//            child: Padding(
//              padding: const EdgeInsets.all(20.0),
//              child: Column(
//         mainAxisAlignment: MainAxisAlignment.start,
//          children: [
//             SizedBox(height: size.height * 0.1),
//           Column(crossAxisAlignment: CrossAxisAlignment.start,
//           mainAxisAlignment: MainAxisAlignment.start,
//             children: [
              
//             Text('OTP Verification',style: GoogleFonts.lato(fontSize: 25,fontWeight: FontWeight.bold),),
          
           
//                 SizedBox(height: size.height * 0.01),
//             Text('Enter the code from the SMS we sent to your phone number',style: GoogleFonts.lato(),)
//              ],
//           ),
//             SizedBox(height: size.height * 0.35),
//                                OTPTextField(
//                                        length: 5, // Number of OTP fields
//                                        width: MediaQuery.of(context).size.width,
//                                        fieldWidth: 50, // Increase this value to make each box wider
//                                        style: TextStyle(
//                                         fontSize: 20, // Increase font size inside the boxes
//                                          ),
//                                        fieldStyle: FieldStyle.box,
//                                     otpFieldStyle: OtpFieldStyle(
//                                     backgroundColor: Colors.transparent,
//                                     borderColor: Color(0xFF512DA8),
//                                       ),
//                                    ),
             
         
//                 SizedBox(height: size.height * 0.03),
//              GestureDetector(
//               onTap: () {
//                 Navigator.push(context, MaterialPageRoute(builder: (context) => HomePage(),));
//               },
//                child: Container(
//                  width:double.infinity,
//                  height: size.height * 0.06,
//                  decoration:  BoxDecoration(
//                  color: Colors.blue,
//                  borderRadius: BorderRadius.circular(10)
//                  ),
//                  child: Center(
//                    child: Text(
//                      'Submit',
//                      style: GoogleFonts.poppins(
//                        color: Colors.white,
//                        fontSize: 17,
//                        fontWeight: FontWeight.bold,
//                      ),
//                    ),
//                  ),
//                ),
//              ),
//               SizedBox(height: size.height*0.015,),
//                   Divider(),
//                   Row(mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Text("Already have an account?",style: GoogleFonts.poppins(fontSize: 12),),
//                       SizedBox(width: size.width*0.03,),
//                          Text("Sign in ",style: GoogleFonts.poppins(color: Colors.blue,fontSize: 12),)
//                     ],
//                   )
//          ],
//              ),
//            )     
//         ),
//       ),
//     );
//   }                  
// }
