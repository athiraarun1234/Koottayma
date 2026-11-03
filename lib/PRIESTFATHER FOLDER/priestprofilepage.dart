import 'dart:async';
import 'dart:convert';
import 'package:Koottaayma/HTTPURL/formatdate.dart';
import 'package:Koottaayma/HTTPURL/httpurl.dart';
import 'package:Koottaayma/SQFLITEVERSION1/PhoneNumberField.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // needed for SystemNavigator.pop()
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Priest {
  final int priestMasterID;
  final int dioceseID;
  final int foraneID;
  final int parishID;
  final String priestName;
  final String phoneNo;
  final String email;
  final String dob;
  final String address;
  final String pinCode;
  final String aadharNo;
  final String joiningDate;
  final String relievingDate;
  final String cProfilePic;

  const Priest({
    required this.priestMasterID,
    required this.dioceseID,
    required this.foraneID,
    required this.parishID,
    required this.priestName,
    required this.phoneNo,
    required this.email,
    required this.dob,
    required this.address,
    required this.pinCode,
    required this.aadharNo,
    required this.joiningDate,
    required this.relievingDate,
    required this.cProfilePic,
  });

  factory Priest.fromJson(Map<String, dynamic> json) {
    return Priest(
      priestMasterID:      (json['nPriestMasterID'] as int?)   ?? 0,
           dioceseID:      (json['nDioceseID']      as int?)   ?? 0,
            foraneID:      (json['nForaneID']        as int?)  ?? 0,
            parishID:      (json['nParishID']        as int?)  ?? 0,
          priestName:       json['cPriestName']?.toString()    ?? 'Unknown',
             phoneNo:       json['nPhoneNo']?.toString()       ?? 'N/A',
               email:       json['eEmail']?.toString()         ?? 'N/A',
                 dob:       json['dDoB']?.toString()           ?? 'N/A',
             address:       json['cAddress']?.toString()       ?? 'N/A',
             pinCode:       json['nPinCode']?.toString()       ?? 'N/A',
            aadharNo:       json['nAadharNo']?.toString()      ?? 'N/A',
         joiningDate:       json['dJoiningDate']?.toString()   ?? 'N/A',
       relievingDate:       json['dRelievingDate']?.toString() ?? 'N/A',
       cProfilePic:         json['cProfilePic']?.toString()     ?? 'N/A',
    );
  }
}

class PriestService {
  Future<List<Priest>> fetchPriestDetails() async {
    final prefs = await SharedPreferences.getInstance();

    final String? phoneNumber = prefs.getString('userPhone');
    final String savedToken   = prefs.getString('jwt') ?? '';

    if (savedToken.isEmpty) {
      throw Exception('Authentication token is missing. Please log in again.');
    }

    try {
      final response = await http
          .post(
            Uri.parse(PriestProfilePageAPI),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': ' $savedToken',
            },
            body: json.encode({
              'nPhoneNo': phoneNumber,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        dynamic raw = decoded['data'] ?? decoded['priests'] ?? decoded;

        if (raw is Map) {
          return [Priest.fromJson(raw as Map<String, dynamic>)];
        } else if (raw is List) {
          return raw
              .map((item) => Priest.fromJson(item as Map<String, dynamic>))
              .toList();
        }
        return [];
      } else {
        throw Exception(
            'Server error: ${response.statusCode}\n${response.body}');
      }
    } on TimeoutException {
      throw Exception('Request timed out. Please check your connection.');
    } on http.ClientException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }
}

class PriestProfilePage extends StatefulWidget {
  const PriestProfilePage({super.key});

  @override
  State<PriestProfilePage> createState() => _PriestProfilePageState();
}

class _PriestProfilePageState extends State<PriestProfilePage> {
  late Future<List<Priest>> _future;

  @override
  void initState() {
    super.initState();
    _future = PriestService().fetchPriestDetails();
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await _logout(context);
              },
              child: const Text('Logout'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                SystemNavigator.pop(); // Exits the app
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Exit'),
            ),
          ],
        );
      },
    );
  }

  // logout function
  Future<void> _logout(BuildContext context) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      // Get language ID before clearing (to preserve it)
      String? savedLanguageId = prefs.getString('languageid');

      // Clear user-specific data (logout the user)
      await prefs.remove('isRegistered');
      await prefs.remove('userPhone');
      await prefs.remove('usertype');
      await prefs.remove('userTypeKey');

      debugPrint('User logged out successfully');
      debugPrint('Preserved language ID: $savedLanguageId');

      // Navigate to login page
      int languageId = int.tryParse(savedLanguageId ?? '0') ?? 0;

      if (!context.mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => PhoneNumber(
            languageId: languageId,
            phoneNumber: 0,
            nUserTypeID: 0,
          ),
        ),
        (route) => false,
      );
    } catch (e) {
      debugPrint('Error during logout: $e');

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logout failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildLogoutButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _showLogoutConfirmation(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.red.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.logout, color: Colors.red[700], size: 16),
            const SizedBox(width: 4),
            Text(
              'Logout',
              style: GoogleFonts.roboto(
                color: Colors.red[700],
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE0F7FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
        automaticallyImplyLeading: false,
       // title: const Text('Priest Profile'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(child: _buildLogoutButton(context)),
          ),
        ],
      ),
      body: FutureBuilder<List<Priest>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Colors.cyan),
                  SizedBox(height: 16),
                  Text('Loading priest profile…'),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 60, color: Colors.redAccent),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load profile\n${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () => setState(
                          () => _future = PriestService().fetchPriestDetails()),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          final priests = snapshot.data ?? [];
          if (priests.isEmpty) {
            return const Center(child: Text('No priest data found.'));
          }

          return ListView.builder(
            itemCount: priests.length,
            itemBuilder: (_, i) =>
                _PriestCard(priest: priests[i], isFirst: i == 0),
          );
        },
      ),
    );
  }
}

class _PriestCard extends StatelessWidget {
  final Priest priest;
  final bool isFirst;

  const _PriestCard({required this.priest, this.isFirst = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: isFirst ? 75 : 32),
      Container(
  decoration: BoxDecoration(
    shape: BoxShape.circle,
    border: Border.all(color: Colors.white, width: 4),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.3),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  ),
  child: CircleAvatar(
    radius: 30,
    child: ClipOval(
    //  child: Icon(Icons.person),
      child: Image.network(
        priest.cProfilePic,
        width: 60,
        height: 60,
        fit: BoxFit.cover,
      ),
    ),
  ),
),
        const SizedBox(height: 16),
        Text(
          priest.priestName,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 17, 79, 110),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Parish Priest',
          style: TextStyle(
            fontSize: 15,
            color: Color.fromARGB(255, 113, 77, 22),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 20),

        // _buildCard(
        //   title: 'Parish',
        //   icon: Icons.church,
        //   children: [
        //     _buildInfoRow(Icons.location_on, 'Parish ID : ${priest.parishID}'),
        //     _buildInfoRow(Icons.map,          'Forane ID : ${priest.foraneID}'),
        //     _buildInfoRow(Icons.flag,         'Diocese ID: ${priest.dioceseID}'),
        //   ],
        // ),
        const SizedBox(height: 12),

        _buildCard(
          title: 'About',
          icon: Icons.person_outline,
          children: [
            _buildInfoRow(Icons.calendar_today,
                'Joined   : ${DateFormatter.formatDate(priest.joiningDate)}'),
            _buildInfoRow(Icons.event_available,
                'Relieved : ${DateFormatter.formatDate(priest.relievingDate)}'),
          ],
        ),
        const SizedBox(height: 12),

        _buildCard(
          title: 'Contact',
          icon: Icons.contact_phone,
          children: [
            _buildInfoRow(Icons.phone, priest.phoneNo),
            _buildInfoRow(Icons.email, priest.email),
          ],
        ),
        const SizedBox(height: 24),

        if (!isFirst) const Divider(thickness: 2, indent: 24, endIndent: 24),
      ],
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: const Color.fromARGB(255, 37, 89, 102), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 36, 100, 118),
                    ),
                  ),
                ],
              ),
              const Divider(height: 20),
              ...children,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color.fromARGB(255, 123, 186, 196)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}