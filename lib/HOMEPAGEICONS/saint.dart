import 'package:Koottaayma/HTTPURL/formatdate.dart';
import 'package:Koottaayma/HTTPURL/httpurl.dart';
import 'package:Koottaayma/USER%20FOLDER/6bottomnavigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class SaintPage extends StatefulWidget {
    final int languageId; 
  final int phoneNumber;
  const SaintPage({super.key, required this.languageId, required this.phoneNumber });

  @override
  State<SaintPage> createState() => _SaintPageState();
}

class _SaintPageState extends State<SaintPage> {
  List<dynamic> saintsData = [];
  List<dynamic> filteredSaints = [];
  bool isLoading = true;
  String? errorMessage;

  // 'all' or 'feast'
  String selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    fetchSaintsData();
  }

  String formatDateWithEra(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'N/A';
    try {
      DateTime date = DateFormat('dd-MM-yyyy').parse(dateStr);
      String formatted = DateFormat('dd-MMM-yyyy').format(date);
      String era = date.year > 0 ? "AD" : "BC";
      return "$formatted $era";
    } catch (e) {
      return 'Invalid date';
    }
  }

  bool _isTodayFeast(dynamic saint) {
    final feastStr = saint['dFeastDay'];
    if (feastStr == null || feastStr.toString().isEmpty) return false;
    try {
      DateTime feastDate;
      try {
        feastDate = DateTime.parse(feastStr);
      } catch (_) {
        feastDate = DateFormat('dd-MM').parse(feastStr);
      }
      final today = DateTime.now();
      return feastDate.day == today.day && feastDate.month == today.month;
    } catch (_) {
      return false;
    }
  }

  void _applyFilter(String filter) {
    setState(() {
      selectedFilter = filter;
      if (filter == 'feast') {
        filteredSaints = saintsData.where(_isTodayFeast).toList();
      } else {
        filteredSaints = List.from(saintsData);
      }
    });
  }

  Future<void> fetchSaintsData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? savedToken = prefs.getString('jwt');
      final response = await http.get(
        Uri.parse(SaintAPI),
        headers: {
          'Authorization': '$savedToken',
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          saintsData = data;
          if (selectedFilter == 'feast') {
            filteredSaints = saintsData.where(_isTodayFeast).toList();
          } else {
            filteredSaints = List.from(saintsData);
          }
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage =
              'Failed to load saints. Status: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
   return PopScope(
  canPop: false,
  onPopInvoked: (didPop) {
       if (didPop) return;
       Navigator.pushAndRemoveUntil(
       context,
       MaterialPageRoute(builder: (context) =>
       BottomNavigation(
       languageId: widget.languageId,
       phoneNumber: widget.phoneNumber)),
      (route) => false,
    );
  },
    child:Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.cyan,
        elevation: 0,
        automaticallyImplyLeading: false,
        // leading: IconButton(
        //   icon: const Icon(Icons.arrow_back, color: Colors.white),
        //   onPressed: () => Navigator.pop(context),
        // ),
        title: Text(
          'Saints',
          style: GoogleFonts.roboto(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: fetchSaintsData,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline,
                          size: 64, color: Colors.red.shade300),
                      const SizedBox(height: 16),
                      Text(
                        errorMessage!,
                        style: GoogleFonts.roboto(
                          fontSize: 16,
                          color: Colors.red,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: fetchSaintsData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.cyan,
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // ── Filter Buttons 
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 12.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: _FilterButton(
                              label: 'Feast',
                              icon: Icons.celebration,
                              isSelected: selectedFilter == 'feast',
                              onTap: () => _applyFilter('feast'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _FilterButton(
                              label: 'All',
                              icon: Icons.people_alt,
                              isSelected: selectedFilter == 'all',
                              onTap: () => _applyFilter('all'),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Content 
                    Expanded(
                      child: filteredSaints.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    selectedFilter == 'feast'
                                        ? Icons.event_busy
                                        : Icons.person_off,
                                    size: 64,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    selectedFilter == 'feast'
                                        ? 'No feast day saints for today\n(${DateFormat('dd MMM').format(DateTime.now())})'
                                        : 'No saints found',
                                    style: GoogleFonts.roboto(
                                      fontSize: 16,
                                      color: Colors.grey,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            )
                          : Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0, vertical: 4.0),
                              child: GridView.builder(
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10,
                                  childAspectRatio: 1,
                                ),
                                itemCount: filteredSaints.length,
                                itemBuilder: (context, index) {
                                  final saint = filteredSaints[index];
                                  return _buildSaintCard(saint);
                                },
                              ),
                            ),
                    ),
                  ],
                ),
    ),);
  }

  Widget _buildSaintCard(Map<String, dynamic> saint) {
    final hasImage = saint['cImagePath'] != null &&
        saint['cImagePath'].toString().isNotEmpty;

    return GestureDetector(
      onTap: () => _showSaintDetails(saint),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 75,
              height: 75,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.cyan.shade100,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipOval(
                child: hasImage
                    ? Image.network(
                        saint['cImagePath'],
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return _buildPlaceholderAvatar(saint['cGenderName']);
                        },
                      )
                    : _buildPlaceholderAvatar(saint['cGenderName']),
              ),
            ),

            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                saint['cOriginalName']?.toString().trim() ?? 'Unknown Saint',
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderAvatar(String? gender) {
    return Container(
      color: Colors.cyan.shade100,
      child: Icon(
        Icons.person,
        size: 50,
        color: Colors.cyan.shade700,
      ),
    );
  }

  void _showSaintDetails(Map<String, dynamic> saint) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Header with image
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.cyan.shade100,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.3),
                                spreadRadius: 3,
                                blurRadius: 7,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: (saint['cImagePath'] != null &&
                                    saint['cImagePath'].toString().isNotEmpty)
                                ? Image.network(
                                    saint['cImagePath'],
                                    fit: BoxFit.cover,
                                    loadingBuilder:
                                        (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return const Center(
                                        child: CircularProgressIndicator(),
                                      );
                                    },
                                    errorBuilder:
                                        (context, error, stackTrace) {
                                      return _buildPlaceholderAvatar(
                                          saint['cGenderName']);
                                    },
                                  )
                                : _buildPlaceholderAvatar(saint['cGenderName']),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          saint['cOriginalName']?.toString().trim() ??
                              'Unknown',
                          style: GoogleFonts.roboto(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        if (saint['cNickName'] != null &&
                            saint['cNickName'].toString().isNotEmpty)
                          Text(
                            saint['cNickName'],
                            style: GoogleFonts.roboto(
                              fontSize: 16,
                              fontStyle: FontStyle.italic,
                              color: Colors.grey.shade600,
                            ),
                          ),

                        // Feast date badge
                        if (saint['dFeastDay'] != null &&
                            saint['dFeastDay'].toString().isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.cyan.shade50,
                              border: Border.all(color: Colors.cyan),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.celebration,
                                    size: 16, color: Colors.cyan),
                                const SizedBox(width: 6),
                                Text(
                                  'Feast: ${DateFormatter.formatDateWithDay(saint['dFeastDay'])}',
                                  style: GoogleFonts.roboto(
                                    fontSize: 13,
                                    color: Colors.cyan.shade800,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Personal Information
                //  _buildDetailRow('Gender', saint['cGenderName']),
                  _buildDetailRow(
                      'Date of Birth', formatDateWithEra(saint['dDoB'])),
                  _buildDetailRow('Birth Location', saint['cBirthLocation']),
                //  _buildDetailRow('Father', saint['cFatherName']),
                //  _buildDetailRow('Mother', saint['cMotherName']),

                  const SizedBox(height: 16),

                  // Professional Life
                //  _buildDetailRow('Job', saint['cJob']),
                  _buildDetailRow(
                      'Organization (Short)', saint['cSNOrganization']),
                  _buildDetailRow(
                      'Organization (Full)', saint['cFNOrganization']),

                  const SizedBox(height: 16),

                  // Canonization Details
                  _buildDetailRow('Canonized Date',
                      
                          DateFormatter.formatDateWithDay(saint['dCanonizedDate'])),
                  _buildDetailRow(
                      'Canonized Location', saint['cCanonizedLocation']),
                  _buildDetailRow('Patron Saint Of', saint['cPatronSaint']),

                  const SizedBox(height: 16),

                  // Proclamation
                //  _buildDetailRow('Proclaimed As', saint['cProclaimedAs']),
                 // _buildDetailRow('Proclaimed By', saint['cProclaimedBy']),
                 // _buildDetailRow('Proclaimed Date',
                  //    _formatDateWithDay(saint['dProclaimedDate'])),
                  const SizedBox(height: 16),

                  // Other Information
                 // _buildDetailRow('Last Breath Date',
                    ////  _formatDateWithDay(saint['dDoLB'])),
               //   _buildDetailRow(
                    //  'Last Breath Place', saint['cLastBirthPlace']),

                  const SizedBox(height: 24),

                  // Close button
                  SafeArea(
                    child: Center(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.cyan,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 48,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: Text(
                          'Close',
                          style: GoogleFonts.roboto(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: GoogleFonts.roboto(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value?.toString() ?? 'N/A',
              style: GoogleFonts.roboto(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reusable Filter Button Widget 
class _FilterButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.cyan : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.cyan,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.cyan.withOpacity(0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? Colors.white : Colors.cyan,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.roboto(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.cyan,
              ),
            ),
          ],
        ),
      ),
    );
  }
}