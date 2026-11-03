// import 'dart:async';
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';

// class Priest {
//   final int priestMasterID;
//   final int dioceseID;
//   final int foraneID;
//   final int parishID;
//   final String priestName;
//   final String phoneNo;
//   final String email;
//   final String dob;
//   final String address;
//   final String pinCode;
//   final String aadharNo;
//   final String joiningDate;
//   final String relievingDate;

//   const Priest({
//     required this.priestMasterID,
//     required this.dioceseID,
//     required this.foraneID,
//     required this.parishID,
//     required this.priestName,
//     required this.phoneNo,
//     required this.email,
//     required this.dob,
//     required this.address,
//     required this.pinCode,
//     required this.aadharNo,
//     required this.joiningDate,
//     required this.relievingDate,
//   });

//   factory Priest.fromJson(Map<String, dynamic> json) {
//     return Priest(
//       priestMasterID: (json['nPriestMasterID'] as int?) ?? 0,
//       dioceseID:      (json['nDioceseID']      as int?) ?? 0,
//       foraneID:       (json['nForaneID']        as int?) ?? 0,
//       parishID:       (json['nParishID']        as int?) ?? 0,
//       priestName:    json['cPriestName']?.toString()    ?? 'Unknown',
//       phoneNo:       json['nPhoneNo']?.toString()       ?? 'N/A',
//       email:         json['eEmail']?.toString()         ?? 'N/A',
//       dob:           json['dDoB']?.toString()           ?? 'N/A',
//       address:       json['cAddress']?.toString()       ?? 'N/A',
//       pinCode:       json['nPinCode']?.toString()       ?? 'N/A',
//       aadharNo:      json['nAadharNo']?.toString()      ?? 'N/A',
//       joiningDate:   json['dJoiningDate']?.toString()   ?? 'N/A',
//       relievingDate: json['dRelievingDate']?.toString() ?? 'N/A',
//     );
//   }
// }

// class PriestService {
//   final String _postUrl =
//       'https://lv4hfxvb-7000.inc1.devtunnels.ms/churchdetails/allpriestdetails/';

//   Future<List<Priest>> fetchPriestDetails() async {
//     final prefs = await SharedPreferences.getInstance();

//     // ── FIX 1: read both values from SharedPreferences ──────────────────────
//     final String? phoneNumber = prefs.getString('userPhone');
//     final String savedToken   = prefs.getString('jwt') ?? '';

//     if (savedToken.isEmpty) {
//       throw Exception('Authentication token is missing. Please log in again.');
//     }

//     try {
//       final response = await http
//           .post(
//             Uri.parse(_postUrl),
//             headers: {
//               'Content-Type': 'application/json',
//               // ── FIX 2: removed the accidental leading space before the token
//               'Authorization': 'Bearer $savedToken',
//             },
//             body: json.encode({
//               // ── Passes the phone number in the POST body as required
//               'nPhoneNo': phoneNumber,
//             }),
//           )
//           .timeout(const Duration(seconds: 15));

//       if (response.statusCode == 200) {
//         final decoded = json.decode(response.body);
//         dynamic raw = decoded['data'] ?? decoded['priests'] ?? decoded;

//         if (raw is Map) {
//           return [Priest.fromJson(raw as Map<String, dynamic>)];
//         } else if (raw is List) {
//           return raw
//               .map((item) => Priest.fromJson(item as Map<String, dynamic>))
//               .toList();
//         }
//         return [];
//       } else {
//         throw Exception(
//             'Server error: ${response.statusCode}\n${response.body}');
//       }
//     } on TimeoutException {
//       throw Exception('Request timed out. Please check your connection.');
//     } on http.ClientException catch (e) {
//       throw Exception('Network error: ${e.message}');
//     }
//   }
// }

// class PriestProfilePage extends StatefulWidget {
//   const PriestProfilePage({super.key});

//   @override
//   State<PriestProfilePage> createState() => _PriestProfilePageState();
// }

// class _PriestProfilePageState extends State<PriestProfilePage> {
//   late Future<List<Priest>> _future;

//   @override
//   void initState() {
//     super.initState();
//     // ── FIX 3: actually assign the future so FutureBuilder has something to await
//     _future = PriestService().fetchPriestDetails();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFE0F7FA),
//       body: FutureBuilder<List<Priest>>(
//         future: _future,
//         builder: (context, snapshot) {
//           // ── Loading ──────────────────────────────────────────────────────
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   CircularProgressIndicator(color: Colors.cyan),
//                   SizedBox(height: 16),
//                   Text('Loading priest profile…'),
//                 ],
//               ),
//             );
//           }

//           // ── Error ────────────────────────────────────────────────────────
//           if (snapshot.hasError) {
//             return Center(
//               child: Padding(
//                 padding: const EdgeInsets.all(24),
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     const Icon(Icons.error_outline,
//                         size: 60, color: Colors.redAccent),
//                     const SizedBox(height: 16),
//                     Text(
//                       'Failed to load profile\n${snapshot.error}',
//                       textAlign: TextAlign.center,
//                       style: const TextStyle(color: Colors.black54),
//                     ),
//                     const SizedBox(height: 20),
//                     ElevatedButton.icon(
//                       onPressed: () =>
//                           setState(() => _future = PriestService().fetchPriestDetails()),
//                       icon: const Icon(Icons.refresh),
//                       label: const Text('Retry'),
//                     ),
//                   ],
//                 ),
//               ),
//             );
//           }

//           // ── Empty ────────────────────────────────────────────────────────
//           final priests = snapshot.data ?? [];
//           if (priests.isEmpty) {
//             return const Center(child: Text('No priest data found.'));
//           }

//           // ── Data ─────────────────────────────────────────────────────────
//           return ListView.builder(
//             itemCount: priests.length,
//             itemBuilder: (_, i) =>
//                 _PriestCard(priest: priests[i], isFirst: i == 0),
//           );
//         },
//       ),
//     );
//   }
// }

// class _PriestCard extends StatelessWidget {
//   final Priest priest;
//   final bool isFirst;

//   const _PriestCard({required this.priest, this.isFirst = false});

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         SizedBox(height: isFirst ? 75 : 32),

//         Container(
//           decoration: BoxDecoration(
//             shape: BoxShape.circle,
//             border: Border.all(color: Colors.white, width: 4),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.3),
//                 blurRadius: 10,
//                 offset: const Offset(0, 4),
//               ),
//             ],
//           ),
//           child: const CircleAvatar(
//             radius: 30,
//             backgroundColor: Colors.cyan,
//             child: Icon(Icons.person, size: 30, color: Colors.white),
//           ),
//         ),
//         const SizedBox(height: 16),
//         Text(
//           priest.priestName,
//           style: const TextStyle(
//             fontSize: 22,
//             fontWeight: FontWeight.bold,
//             color: Color.fromARGB(255, 17, 79, 110),
//           ),
//         ),
//         const SizedBox(height: 4),
//         const Text(
//           'Parish Priest',
//           style: TextStyle(
//             fontSize: 15,
//             color: Color.fromARGB(255, 113, 77, 22),
//             letterSpacing: 1.2,
//           ),
//         ),
//         const SizedBox(height: 20),

//         _buildCard(
//           title: 'Parish',
//           icon: Icons.church,
//           children: [
//             _buildInfoRow(Icons.location_on, 'Parish ID : ${priest.parishID}'),
//             _buildInfoRow(Icons.map,          'Forane ID : ${priest.foraneID}'),
//             _buildInfoRow(Icons.flag,         'Diocese ID: ${priest.dioceseID}'),
//           ],
//         ),
//         const SizedBox(height: 12),

//         _buildCard(
//           title: 'About',
//           icon: Icons.person_outline,
//           children: [
//             _buildInfoRow(Icons.badge,           'Priest ID : ${priest.priestMasterID}'),
//             _buildInfoRow(Icons.calendar_today,  'Joined   : ${priest.joiningDate}'),
//             _buildInfoRow(Icons.event_available, 'Relieved : ${priest.relievingDate}'),
//           ],
//         ),
//         const SizedBox(height: 12),

//         _buildCard(
//           title: 'Contact',
//           icon: Icons.contact_phone,
//           children: [
//             _buildInfoRow(Icons.phone, priest.phoneNo),
//             _buildInfoRow(Icons.email, priest.email),
//           ],
//         ),
//         const SizedBox(height: 24),

//         if (!isFirst) const Divider(thickness: 2, indent: 24, endIndent: 24),
//       ],
//     );
//   }

//   Widget _buildCard({
//     required String title,
//     required IconData icon,
//     required List<Widget> children,
//   }) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16),
//       child: Card(
//         elevation: 3,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//         color: Colors.white,
//         child: Padding(
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 children: [
//                   Icon(icon,
//                       color: const Color.fromARGB(255, 37, 89, 102), size: 20),
//                   const SizedBox(width: 8),
//                   Text(
//                     title,
//                     style: const TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.bold,
//                       color: Color.fromARGB(255, 36, 100, 118),
//                     ),
//                   ),
//                 ],
//               ),
//               const Divider(height: 20),
//               ...children,
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildInfoRow(IconData icon, String text) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 5),
//       child: Row(
//         children: [
//           Icon(icon, size: 18, color: const Color.fromARGB(255, 123, 186, 196)),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Text(
//               text,
//               style: const TextStyle(fontSize: 14, color: Colors.black87),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }