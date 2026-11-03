import 'dart:convert';
import 'package:Koottaayma/HTTPURL/httpurl.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BetseidhaUserAccountPage extends StatefulWidget {
  const BetseidhaUserAccountPage({Key? key}) : super(key: key);

  @override
  State<BetseidhaUserAccountPage> createState() =>
      _BetseidhaUserAccountPageState();
}

class _BetseidhaUserAccountPageState extends State<BetseidhaUserAccountPage> {
  bool _isLoading = false;
  Map<String, dynamic>? userData; // only the "UserToken" fields
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  String formatDob(String? dob) {
    if (dob == null || dob.isEmpty) return 'N/A';
    try {
      return DateFormat('dd-MMM-yyyy').format(DateTime.parse(dob));
    } catch (_) {
      return dob;
    }
  }

  Future<bool> _showExitDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Exit App'),
            content: const Text('Are you sure you want to exit the app?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Yes'),
              ),
            ],
          ),
        ) ??
        false;
  }

  /// Response shape: { "Guest": [ { "UserToken": { ... } } ] }
  /// Returns ONLY the UserToken map (username, nPhoneNo, cAddress, ...).
  Map<String, dynamic> _extractUserToken(dynamic decoded) {
    dynamic node = decoded;
    if (node is Map && node['data'] != null) node = node['data'];

    Map<String, dynamic>? tokenFrom(dynamic entry) {
      if (entry is Map && entry['UserToken'] is Map) {
        return Map<String, dynamic>.from(entry['UserToken']);
      }
      return null;
    }

    // Plain list of entries
    if (node is List) {
      for (final e in node) {
        final t = tokenFrom(e);
        if (t != null) return t;
      }
    }

    if (node is Map) {
      // UserToken at top level
      final direct = tokenFrom(node);
      if (direct != null) return direct;

      // "Guest" (or any other key) holding a list
      for (final value in node.values) {
        if (value is List) {
          for (final e in value) {
            final t = tokenFrom(e);
            if (t != null) return t;
          }
        }
      }
    }

    throw Exception('User details not found in response');
  }

  Future<void> _fetchUserData() async {
    setState(() {
      _isLoading = true;
      errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? phoneNumber = prefs.getString('userPhone');

      if (phoneNumber == null || phoneNumber.isEmpty) {
        throw Exception('Phone number not found. Please log in again.');
      }

      String? fcmToken = prefs.getString('fcmToken');
      if (fcmToken == null || fcmToken.isEmpty) {
        fcmToken = await FirebaseMessaging.instance.getToken();
        if (fcmToken != null) await prefs.setString('fcmToken', fcmToken);
      }

      final response = await http.post(
        Uri.parse(VerifyUserPhoneNUmber),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nPhoneNumber': phoneNumber,
          'cFCMToken': fcmToken,
          'nDeviceType': 1,
        }),
      );

      print('API STATUS: ${response.statusCode}');
      print('API RESPONSE: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = json.decode(utf8.decode(response.bodyBytes));
        final user = _extractUserToken(decoded);

        if (user['jwt'] != null) {
          await prefs.setString('jwt', user['jwt'].toString());
        }
        if (user['nUserID'] != null) {
          await prefs.setString('userId', user['nUserID'].toString());
        }

        if (!mounted) return;
        setState(() {
          userData = user;
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load user data: ${response.statusCode}');
      }
    } catch (e) {
      print('FETCH USER ERROR: $e');
      if (!mounted) return;
      setState(() {
        errorMessage = e.toString();
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
              'Please contact your church priest to activate your account.'),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  String _getInitials(String? fullName) {
    if (fullName == null || fullName.trim().isEmpty) return 'U';
    final names = fullName.trim().split(RegExp(r'\s+'));
    if (names.length >= 2) {
      return '${names[0][0]}${names[1][0]}'.toUpperCase();
    }
    return names[0][0].toUpperCase();
  }

  String _getGender(dynamic id) {
    final value = int.tryParse(id?.toString() ?? '');
    if (value == 1) return 'Male';
    if (value == 2) return 'Female';
    return 'Not specified';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final exit = await _showExitDialog(context);
        if (exit) SystemNavigator.pop();
      },
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              backgroundColor: Colors.cyan,
              automaticallyImplyLeading: false,
              
              flexibleSpace: FlexibleSpaceBar(
                background: _isLoading || userData == null
                    ? const SizedBox()
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 40),
                          Container(
                            width: 85,
                            height: 85,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.shade400,
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ClipOval(child: _defaultAvatar()),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            userData!['username']?.toString() ?? 'User',
                            style: GoogleFonts.roboto(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            userData!['nPhoneNo']?.toString() ?? '',
                            style: GoogleFonts.roboto(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            SliverToBoxAdapter(
              child: _isLoading
                  ? SizedBox(
                      height: MediaQuery.of(context).size.height - 200,
                      child: const Center(child: CircularProgressIndicator()),
                    )
                  : errorMessage != null
                      ? _buildErrorState()
                      : userData != null
                          ? _buildContent()
                          : const SizedBox(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return SizedBox(
      height: 400,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 40, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Please contact the church priest to activate your account. Please log in again to continue using the app.',
                textAlign: TextAlign.center,
                style: GoogleFonts.roboto(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'Personal Information',
              style: GoogleFonts.roboto(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoCard(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          _buildInfoTile(
            icon: Icons.person_outline,
            label: 'Name',
            value: userData!['username']?.toString() ?? 'N/A',
          ),
          _buildDivider(),
          _buildInfoTile(
            icon: Icons.phone_outlined,
            label: 'Phone Number',
            value: userData!['nPhoneNo']?.toString() ?? 'N/A',
          ),
          _buildDivider(),
          _buildInfoTile(
            icon: Icons.wc_outlined,
            label: 'Gender',
            value: _getGender(userData!['nGenderID']),
          ),
          _buildDivider(),
          _buildInfoTile(
            icon: Icons.cake_outlined,
            label: 'Date of Birth',
            value: formatDob(userData!['dDoB']?.toString()),
          ),
          _buildDivider(),
          _buildInfoTile(
            icon: Icons.badge_outlined,
            label: 'User Type',
            value: userData!['nCategoryID']?.toString() ?? 'N/A',
          ),
          _buildDivider(),
          _buildInfoTile(
            icon: Icons.location_on_outlined,
            label: 'Address',
            value: userData!['cAddress']?.toString() ?? 'N/A',
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, isLast ? 16 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.cyan.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: Colors.cyan.shade700),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.roboto(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.roboto(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(height: 1, thickness: 1, color: Colors.grey.shade100),
    );
  }

  Widget _defaultAvatar() {
    return Container(
      color: Colors.cyan.shade100,
      alignment: Alignment.center,
      child: Text(
        _getInitials(userData?['username']?.toString()),
        style: GoogleFonts.roboto(
          fontSize: 30,
          fontWeight: FontWeight.bold,
          color: Colors.cyan.shade700,
        ),
      ),
    );
  }
}