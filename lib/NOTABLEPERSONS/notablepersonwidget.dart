// import 'dart:async';

// import 'package:flutter/material.dart';
// import 'package:flutter/rendering.dart';
// import 'package:pdf/widgets.dart' as pw;
// import 'package:printing/printing.dart';

// // ── Model Class ──
// class NotablePerson {
//   final String name;
//   final String title;
//   final String years;
//   final List<String> achievements;

//   const NotablePerson({
//     required this.name,
//     required this.title,
//     required this.years,
//     required this.achievements,
//   });
// }

// // ── Data List ──
// final List<NotablePerson> notablePersons = const [
//   NotablePerson(
//     name: 'Fr. Thomas Mathew',
//     title: 'Head Priest – St. Mary\'s Church',
//     years: '1965 – Present',
//     achievements: [
//       '✦ Ordained as priest in 1990',
//       '✦ Served 20+ years in parish ministry',
//       '✦ Founded the church charity trust (2005)',
//       '✦ Led the church renovation project (2015)',
//       '✦ Known for weekly youth prayer meetings',
//     ],
//   ),
//   NotablePerson(
//     name: 'Fr. Joseph Varghese',
//     title: 'Senior Vicar – Holy Cross Parish',
//     years: '1958 – Present',
//     achievements: [
//       '✦ Ordained as priest in 1985',
//       '✦ Established free education centre for children',
//       '✦ Conducted 500+ marriage counselling sessions',
//       '✦ Led mission trips to rural Kerala villages',
//       '✦ Awarded Best Parish Priest (Diocese – 2010)',
//     ],
//   ),
//   NotablePerson(
//     name: 'Fr. George Kurian',
//     title: 'Assistant Priest – St. Peter\'s Church',
//     years: '1978 – Present',
//     achievements: [
//       '✦ Ordained as priest in 2005',
//       '✦ Leads Sunday school for 200+ children',
//       '✦ Organized annual parish family retreats',
//       '✦ Active in flood relief work (Kerala 2018)',
//       '✦ Heads the church music & choir ministry',
//     ],
//   ),
//   NotablePerson(
//     name: 'Fr. Paul Sebastian',
//     title: 'Parish Priest – St. John\'s Cathedral',
//     years: '1955 – Present',
//     achievements: [
//       '✦ Ordained as priest in 1982',
//       '✦ Served as missionary in Africa for 10 years',
//       '✦ Built a new church hall for 1000+ members',
//       '✦ Runs a monthly food donation programme',
//       '✦ Received the Diocese Service Award (2018)',
//     ],
//   ),
//   NotablePerson(
//     name: 'Fr. Mathew Chacko',
//     title: 'Deacon – Sacred Heart Church',
//     years: '1985 – Present',
//     achievements: [
//       '✦ Ordained as deacon in 2010',
//       '✦ Manages church social media & communications',
//       '✦ Leads the parish youth fellowship group',
//       '✦ Organises annual pilgrimages to holy sites',
//       '✦ Coordinates hospital & prison ministry visits',
//     ],
//   ),
// ];

// // ── Main Widget ──
// class NotablePersonsWidget extends StatefulWidget {       // StatefulWidget
//   const NotablePersonsWidget({super.key});

//   @override
//   State<NotablePersonsWidget> createState() => _NotablePersonsWidgetState();
// }

// class _NotablePersonsWidgetState extends State<NotablePersonsWidget> {
//   late ScrollController _scrollController;
//   Timer? _autoScrollTimer;
//   bool _isScrollingDown = true;

//   // ── Lifecycle ──
//   @override
//   void initState() {
//     super.initState();
//     _scrollController = ScrollController();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _startAutoScroll();
//     });
//   }

//   @override
//   void dispose() {
//     _autoScrollTimer?.cancel();
//     _scrollController.dispose();
//     super.dispose();
//   }

//   // ── Auto Scroll Logic ──
//   void _startAutoScroll() {
//     _autoScrollTimer?.cancel(); // cancel any existing timer before starting
//     _autoScrollTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
//       if (!_scrollController.hasClients) return;

//       final maxScroll = _scrollController.position.maxScrollExtent;
//       final currentScroll = _scrollController.offset;

//       if (_isScrollingDown) {
//         if (currentScroll >= maxScroll) {
//           _isScrollingDown = false;
//         } else {
//           _scrollController.jumpTo(currentScroll + 1.0);
//         }
//       } else {
//         if (currentScroll <= 0) {
//           _isScrollingDown = true;
//         } else {
//           _scrollController.jumpTo(currentScroll - 1.0);
//         }
//       }
//     });
//   }

//   // ── Person Details Dialog ──
//   void _showPersonDetails(BuildContext context, NotablePerson person) {
//     showDialog(
//       context: context,
//       barrierDismissible: true,
//       builder: (BuildContext dialogContext) {
//         return Dialog(
//           shape: RoundedRectangleBorder(
            
//             borderRadius: BorderRadius.circular(20),
//           ),
//           backgroundColor: const Color.fromARGB(255, 21, 134, 215),
//           child: Padding(
//             padding: const EdgeInsets.all(20),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // ── Header ──
//                 Row(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             person.name,
//                             style: const TextStyle(
//                               fontWeight: FontWeight.bold,
//                               fontSize: 17,
//                               color: Colors.white,
//                             ),
//                           ),
//                           const SizedBox(height: 4),
//                           Text(
//                             person.title,
//                             style: const TextStyle(
//                               fontSize: 13,
//                               color: Colors.white70,
//                             ),
//                           ),
//                           Text(
//                             person.years,
//                             style: const TextStyle(
//                               fontSize: 12,
//                               color: Colors.white60,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     GestureDetector(
//                       onTap: () => Navigator.of(dialogContext).pop(),
//                       child: const Icon(
//                         Icons.close,
//                         color: Colors.white,
//                         size: 22,
//                       ),
//                     ),
//                   ],
//                 ),

//                 const Divider(height: 24, color: Colors.white30),

//                 // ── Achievements ──
//                 ...person.achievements.map(
//                   (achievement) => Padding(
//                     padding: const EdgeInsets.only(bottom: 6),
//                     child: Text(
//                       achievement,
//                       style: const TextStyle(
//                         fontSize: 13,
//                         color: Colors.white,
//                       ),
//                     ),
//                   ),
//                 ),

//                 const SizedBox(height: 20),

//                 // ── Download Button ──
//                 SizedBox(
//                   width: double.infinity,
//                   child: ElevatedButton.icon(
//                     onPressed: () {
//                       Navigator.of(dialogContext).pop();
//                       _downloadPDF({
//                         'name': person.name,
//                         'role': person.title,
//                         'years': person.years,
//                         'facts': person.achievements.join('|'),
//                       });
//                     },
//                     icon: const Icon(Icons.picture_as_pdf, size: 18),
//                     label: const Text('Download PDF'),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.white,
//                       foregroundColor: Colors.indigo,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }

//   // ── PDF Download ──
//   Future<void> _downloadPDF(Map<String, String> person) async {
//     final pdf = pw.Document();
//     pdf.addPage(
//       pw.Page(
//         build: (ctx) => pw.Column(
//           crossAxisAlignment: pw.CrossAxisAlignment.start,
//           children: [
//             pw.Text(
//               person['name']!,
//               style: pw.TextStyle(
//                 fontSize: 20,
//                 fontWeight: pw.FontWeight.bold,
//               ),
//             ),
//             pw.SizedBox(height: 8),
//             pw.Text(person['role']!),
//             pw.Text(person['years']!),
//             pw.Divider(),
//             pw.Text(
//               'Key Achievements:',
//               style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
//             ),
//             pw.SizedBox(height: 6),
//             ...person['facts']!.split('|').map(
//                   (fact) => pw.Text('• $fact'),
//                 ),
//           ],
//         ),
//       ),
//     );
//     await Printing.layoutPdf(onLayout: (format) async => pdf.save());
//   }

//   // ── Build ──
//   @override
//   Widget build(BuildContext context) {                    // ✅ single build method
//     return Container(
//       width: MediaQuery.of(context).size.width * 0.95,
//       height: 135,
//       margin: const EdgeInsets.all(8),
//       decoration: BoxDecoration(
//         color: const Color.fromARGB(255, 68, 33, 212).withOpacity(0.3),
//         borderRadius: BorderRadius.circular(20),
//       ),
//       padding: const EdgeInsets.all(14),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // ── Title ──
//           const Text(
//             'Notable Persons',
//             style: TextStyle(
//               fontWeight: FontWeight.bold,
//               fontSize: 14,
//               color: Colors.white,
//             ),
//           ),
//           const SizedBox(height: 6),

//           // ── Auto Scrollable List ──
//           Expanded(
//             child: NotificationListener<ScrollNotification>(
//               onNotification: (notification) {
//                 if (notification is UserScrollNotification) {
//                   if (notification.direction != ScrollDirection.idle) {
//                     _autoScrollTimer?.cancel(); // pause on touch
//                   } else {
//                     _startAutoScroll();         // resume on release
//                   }
//                 }
//                 return false;
//               },
//               child: ListView.separated(
//                 controller: _scrollController,
//                 padding: EdgeInsets.zero,
//                 physics: const ClampingScrollPhysics(),
//                 itemCount: notablePersons.length,
//                 separatorBuilder: (context, index) =>
//                     const Divider(color: Colors.white24, height: 10),
//                 itemBuilder: (context, index) {
//                   final person = notablePersons[index];
//                   return GestureDetector(
//                     onTap: () => _showPersonDetails(context, person),
//                     child: Row(
//                       children: [
//                         // ── Avatar ──
//                         CircleAvatar(
//                           radius: 16,
//                           backgroundColor:
//                               const Color.fromARGB(255, 68, 33, 212)
//                                   .withOpacity(0.7),
//                           child: Text(
//                             person.name[0],
//                             style: const TextStyle(
//                               color: Colors.white,
//                               fontWeight: FontWeight.bold,
//                               fontSize: 14,
//                             ),
//                           ),
//                         ),
//                         const SizedBox(width: 10),

//                         // ── Name & Title ──
//                         Expanded(
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 person.name,
//                                 style: const TextStyle(
//                                   fontWeight: FontWeight.bold,
//                                   fontSize: 13,
//                                   color: Colors.white,
//                                 ),
//                               ),
//                               Text(
//                                 person.title,
//                                 style: const TextStyle(
//                                   fontSize: 11,
//                                   color: Colors.white70,
//                                 ),
//                                 maxLines: 1,
//                                 overflow: TextOverflow.ellipsis,
//                               ),
//                             ],
//                           ),
//                         ),

//                         // ── Info Icon ──
//                         const Icon(
//                           Icons.info_outline,
//                           color: Colors.white60,
//                           size: 18,
//                         ),
//                       ],
//                     ),
//                   );
//                 },
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }