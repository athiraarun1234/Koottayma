import 'package:Koottaayma/BAPTISUM%20USER%20FOLDER/requestregister.dart';
import 'package:Koottaayma/USER%20FOLDER/8showingbaptisumcertificates.dart';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class UserSacramentalsRequest extends StatefulWidget {
  const UserSacramentalsRequest({super.key});

  @override
  State<UserSacramentalsRequest> createState() =>
      _UserSacramentalsRequestState();
}

class _UserSacramentalsRequestState extends State<UserSacramentalsRequest> {
  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> sacraments = [
      {
        'image': 'assets/sac1.png',
        'title': 'Baptism',
        'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => BaptisumRequestPage()),
            ),
      },
      {
        'image': 'assets/sac2.png',
        'title': 'Confirmation',
        'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => UserTextUploading()),
            ),
      },
      {
        'image': 'assets/sac3.png',
        'title': 'Penance /\nReconciliation',
        'onTap': () {
          // Add navigation when page is ready
        },
      },
      {
        'image': 'assets/sac4.png',
        'title': 'Eucharist',
        'onTap': () {
          // Add navigation when page is ready
        },
      },
      {
        'image': 'assets/sac5.png',
        'title': 'Ordination',
        'onTap': () {
          // Add navigation when page is ready
        },
      },
      {
        'image': 'assets/sac6.png',
        'title': 'Matrimony /\nMarriage',
        'onTap': () {
          // Add navigation when page is ready
        },
      },
      {
        'image': 'assets/sac7.png',
        'title': 'Anointing of\nthe Sick',
        'onTap': () {
          // Add navigation when page is ready
        },
      },
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.cyan,
        elevation: 0,
        title: Text(
          'Request for Sacramentals',
          style: GoogleFonts.roboto(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.cyan, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text(
                'Select a Sacrament',
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  color: Colors.white70,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.builder(
                  itemCount: sacraments.length,
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,     // 2 columns → 2×2 grid per screen
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 1.0, // perfect square
                  ),
                  itemBuilder: (context, index) {
                    final item = sacraments[index];
                    return _buildGridCard(
                      image: item['image'] as String,
                      title: item['title'] as String,
                      onTap: item['onTap'] as VoidCallback,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridCard({
    required String image,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Full image covering the entire card
              Image.asset(
                image,
                fit: BoxFit.cover,
              ),

              // Dark gradient overlay at the bottom for caption readability
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.65),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.roboto(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.3,
                    ),
                  ),
                ),
              ),

              // Cyan arrow badge at top-right
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.cyan.withOpacity(0.85),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios,
                    size: 10,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}