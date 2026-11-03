
// import 'package:Koottaayma/USER%20FOLDER/6bottomnavigation.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:razorpay_flutter/razorpay_flutter.dart';

// class PaymentGateway extends StatefulWidget {
//   final int languageId;
//   final int phoneNumber;
//    PaymentGateway({super.key, required this.languageId, required this.phoneNumber  });


//   @override
//   State<PaymentGateway> createState() => _PaymentGatewayState();
// }

// class _PaymentGatewayState extends State<PaymentGateway> {
//    Razorpay? _razorpay;

//   @override
//   void initState() {
//     super.initState();

//     _razorpay = Razorpay();

//     _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, handlePaymentErrorResponse);
//     _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, handlePaymentSuccessResponse);
//     _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, handleExternalWalletSelected);
//   }

//   @override
//   void dispose() {
//     _razorpay?.clear();
//     super.dispose();
//   }

//   void handlePaymentErrorResponse(PaymentFailureResponse response) {
//     print('Payment Failed: ${response.message}');
//   }

//   void handlePaymentSuccessResponse(PaymentSuccessResponse response) {
//     print('Payment Success: ${response.paymentId}');
//   }

//   void handleExternalWalletSelected(ExternalWalletResponse response) {
//     print('External Wallet: ${response.walletName}');
//   }

//   void openCheckout() {
//     var options = {
//       'key': 'rzp_test_TnJe98ukh1L2GZ',
//       //'key': 'rzp_live_YourLiveKey', // Use live key in production  
//       'amount': 1000, // amount in paise (100 = ₹1)
//       'name': 'Koottaayma ( കൂട്ടായ്മ )',
//       'description': 'Subscription Fees',
//       'prefill': {
//       'contact': widget.phoneNumber.toString(),
//       }
//     };
// print('razorpay phonenumber: ${widget.phoneNumber}');
//     try {
//       _razorpay!.open(options);
//     } catch (e) {
//       print('Error: $e');
//     }
//   }

//     @override
//   Widget build(BuildContext context) {
//  return PopScope(
//   canPop: false,
//   onPopInvoked: (didPop) {
//     if (didPop) return;

//     Navigator.pushAndRemoveUntil(
//       context,
//       MaterialPageRoute(builder: (context) =>
//        BottomNavigation(
//        languageId: widget.languageId,
//        phoneNumber: widget.phoneNumber)),
//       (route) => false,
//     );
//   },

//     child: Scaffold(
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
//         decoration: BoxDecoration(
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
//                 style: GoogleFonts.roboto(
//                   color: Colors.white,
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//                SizedBox(height: 20),

//               // Subscription card
//               _buildPaymentCard(
//                 title: "Subscription",
//                // subtitle: "Get premium access and remove limits",
//                 imagePath: "assets/subscription.png",
//                 onTap: openCheckout,
//               ),
//                SizedBox(height: 24),

//               // Donation card
//               _buildPaymentCard(
//                 title: "Donation",
//               //  subtitle: "Support our mission and development efforts",
//                 imagePath: "assets/donation.png",
//                 onTap: openCheckout,
//               ),
//             ],
//           ),
//         ),
//       ),
//      ), );
//   }

//   Widget _buildPaymentCard({
//     required String title,
//   // required String subtitle,
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
//               offset:  Offset(0, 5),
//             ),
//           ],
//         ),
//         child: Column(
//           children: [
//             ClipRRect(
//               borderRadius:  BorderRadius.vertical(top: Radius.circular(20)),
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
//                //   const SizedBox(height: 6),
//                   // Text(
//                   //   subtitle,
//                   //   textAlign: TextAlign.center,
//                   //   style: GoogleFonts.poppins(
//                   //     fontSize: 14,
//                   //     color: Colors.grey.shade700,
//                   //   ),
//                   // ),
//                 //  const SizedBox(height: 12),
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
//                           offset:Offset(0, 3),
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
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }