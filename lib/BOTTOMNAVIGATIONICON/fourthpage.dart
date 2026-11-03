import 'package:flutter/material.dart';
import 'package:path/path.dart';
// 'key': 'rzp_test_SaVemZCGzNnXcb',//original key from razorpay
class MyFourthPage extends StatefulWidget {
  const MyFourthPage({super.key});

  @override
  State<MyFourthPage> createState() => _MyFourthPageState();
}

class _MyFourthPageState extends State<MyFourthPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Fourth Page"),
      ),
      body:
       buildconatiner("Fourth Page", const Color.fromARGB(255, 30, 94, 141)),
    );
  }
}
Widget buildconatiner(String text, Color color) {
  return Container(
    height: 100,
    width: 100,
    color: color,
    child: Center(
      child: Text(
        text,
        style:  TextStyle(color: Colors.white, fontSize: 16),
      ),
    ),
  );
}






                      


///////////////new code is in razorpaypayment.dart file
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';

// class PaymentScreen extends StatefulWidget {
//   const PaymentScreen({Key? key}) : super(key: key);

//   @override
//   State<PaymentScreen> createState() => _PaymentScreenState();
// }

// class _PaymentScreenState extends State<PaymentScreen> {
//   void openCheckout() {
//     // TODO: Integrate payment logic here
//     debugPrint("Open checkout tapped!");
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         elevation: 0,
//         automaticallyImplyLeading: false,
//         centerTitle: true,
//         backgroundColor: Colors.cyan.shade600,
//         title: Text(
//           "Payments",
//           style: GoogleFonts.poppins(
//             color: Colors.white,
//             fontWeight: FontWeight.w600,
//             fontSize: 20,
//             letterSpacing: 0.3,
//           ),
//         ),
//       ),
//       body: Container(
//         width: double.infinity,
//         height: double.infinity,
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             colors: [
//               Color(0xFF00BCD4),
//               Color(0xFFB2EBF2),
//               Color(0xFFFFFFFF),
//             ],
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//           ),
//         ),
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 "Select a payment option",
//                 style: GoogleFonts.poppins(
//                   color: Colors.white,
//                   fontSize: 18,
//                   fontWeight: FontWeight.w700,
//                 ),
//               ),
//               const SizedBox(height: 20),

//               // Subscription card
//               _buildPaymentCard(
//                 title: "Subscription",
//                 subtitle: "Get premium access and remove limits",
//                 imagePath: "assets/subscription.png",
//                 onTap: openCheckout,
//               ),
//               const SizedBox(height: 24),

//               // Donation card
//               _buildPaymentCard(
//                 title: "Donation",
//                 subtitle: "Support our mission and development efforts",
//                 imagePath: "assets/donation.png",
//                 onTap: openCheckout,
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildPaymentCard({
//     required String title,
//     required String subtitle,
//     required String imagePath,
//     required VoidCallback onTap,
//   }) {
//     return InkWell(
//       borderRadius: BorderRadius.circular(20),
//       onTap: onTap,
//       child: Ink(
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(20),
//           color: Colors.white.withOpacity(0.9),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.08),
//               blurRadius: 10,
//               offset: const Offset(0, 5),
//             ),
//           ],
//         ),
//         child: Column(
//           children: [
//             ClipRRect(
//               borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
//               child: Image.asset(
//                 imagePath,
//                 fit: BoxFit.cover,
//                 height: 180,
//                 width: double.infinity,
//               ),
//             ),
//             Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Column(
//                 children: [
//                   Text(
//                     title,
//                     style: GoogleFonts.poppins(
//                       fontSize: 20,
//                       fontWeight: FontWeight.w600,
//                       color: Colors.cyan.shade800,
//                     ),
//                   ),
//                   const SizedBox(height: 6),
//                   Text(
//                     subtitle,
//                     textAlign: TextAlign.center,
//                     style: GoogleFonts.poppins(
//                       fontSize: 14,
//                       color: Colors.grey.shade700,
//                     ),
//                   ),
//                   const SizedBox(height: 12),
//                   Container(
//                     height: 45,
//                     width: 150,
//                     decoration: BoxDecoration(
//                       gradient: LinearGradient(
//                         colors: [Colors.cyan.shade600, Colors.teal.shade400],
//                         begin: Alignment.centerLeft,
//                         end: Alignment.centerRight,
//                       ),
//                       borderRadius: BorderRadius.circular(30),
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.cyan.withOpacity(0.4),
//                           blurRadius: 8,
//                           offset: const Offset(0, 3),
//                         ),
//                       ],
//                     ),
//                     alignment: Alignment.center,
//                     child: Text(
//                       "Pay Now",
//                       style: GoogleFonts.poppins(
//                         color: Colors.white,
//                         fontWeight: FontWeight.w600,
//                         fontSize: 16,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             )
//           ],
//         ),
//       ),
//     );
//   }
// }
///////////////////old code
//  @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor:Colors.white,
//       appBar: AppBar(
//         automaticallyImplyLeading: false,
//         centerTitle: true,
//         backgroundColor: Colors.cyan,
//         title:  Text(
//           "Payments",
//           style: TextStyle(
//             color: Colors.white,
//             fontWeight: FontWeight.w600,
//             fontSize: 18,
//             letterSpacing: 0.3,
//           ),
//         ),
//       ),
//       body: Container(
//          width: double.infinity,
//         height: double.infinity,
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             colors: [
//               Colors.cyan,
//               Color.fromARGB(255, 158, 218, 228),
//               Colors.white,
//             ],
//             begin: Alignment.topLeft,
//             end: Alignment.bottomCenter,
//           ),
//         ),
//         child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               SizedBox(height: 14),
//           Text( "Select a payment option:" ,
//           style: GoogleFonts.poppins(
//             color: Colors.white,
//             fontSize: 16,
//             fontWeight: FontWeight.w600,
//           )),

//               Center(
//                 child: GestureDetector(
//                           onTap: () => openCheckout(),
//                           child: Container(
//                           margin: EdgeInsets.only(top: 24),
//                           width: 330,
//                          height: 220,
//                     decoration: BoxDecoration(
//                       borderRadius: BorderRadius.circular(20),
//                       color: const Color.fromARGB(255, 23, 107, 114).withOpacity(0.5),
//                       border: Border.all(color: Colors.white.withOpacity(0.2)),
//                     ),
//                     child: ClipRRect(
//                       borderRadius: BorderRadius.circular(20),
//                       child: Stack(
//                         alignment: Alignment.center,
//                         children: [
//                           Positioned.fill(
//                             child: Image.asset(
//                 'assets/icon5.png',
//                 fit: BoxFit.cover,
//                 color: Colors.white.withOpacity(0.65),
//                 colorBlendMode: BlendMode.modulate,
//                             ),
//                           ),
//                           Column(
//                          mainAxisAlignment: MainAxisAlignment.center,
//                             children: [
//                 Image.asset(
//                   'assets/subscription.png',
//                   fit: BoxFit.contain,
//                   width: 200,
//                   height: 200,
//                 ),
//                             ],
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//               ),

//           Center(
//             child: GestureDetector(
//             onTap: () => openCheckout(),
//             child: Container(
//             margin: EdgeInsets.only(top: 24),
//             width: 330,
//             height: 220,
//                 decoration: BoxDecoration(
//                   borderRadius: BorderRadius.circular(20),
//                   color: const Color.fromARGB(255, 23, 107, 114).withOpacity(0.5),
//                   border: Border.all(color: Colors.white.withOpacity(0.2)),
//                 ),
//                 child: ClipRRect(
//                   borderRadius: BorderRadius.circular(20),
//                   child: Stack(
//                     alignment: Alignment.center,
//                     children: [
//             Positioned.fill(
//               child: Image.asset(
//                 'assets/icon5.png',
//                 fit: BoxFit.cover,
//                 color: Colors.white.withOpacity(0.65),
//                 colorBlendMode: BlendMode.modulate,
//               ),
//             ),
//             Column(
           
//               children: [
//                 Image.asset(
//                   'assets/donation.png',
//                   fit: BoxFit.contain,
//                   width: 330,
//                   height: 200,
//                 ),
//               ],
//             ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ),
      
//             ],
//           ),
//         ),
//       ),
//     );
//   }


