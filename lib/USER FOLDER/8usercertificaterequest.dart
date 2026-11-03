
import 'package:Koottaayma/BAPTISUM%20USER%20FOLDER/approveletter.dart';
import 'package:Koottaayma/USER%20FOLDER/8showingbaptisumcertificates.dart';
import 'package:Koottaayma/USER%20FOLDER/9baptisumcertificatepdf.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class UserCertificateRequest extends StatefulWidget {
  const UserCertificateRequest({super.key});

  @override
  State<UserCertificateRequest> createState() => _UserCertificateRequestState();
}

class _UserCertificateRequestState extends State<UserCertificateRequest> {
  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> certificates = [
      {
        'image': 'assets/sac1.png',
        'title': 'Baptism\nCertificate',
        'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => Mycertificate()),
            ),
      },
      {
        'image': 'assets/sac6.png',
        'title': 'Marriage\nCertificate',
        'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => UserTextUploading()),
            ),
      },
      {
        'image': 'assets/cert3.png',
        'title': 'Obituary\nCertificate',
        'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => UserTextUploading()),
            ),
      },
      {
        'image': 'assets/sac1.png',
        'title': 'Baptism\nApproval Letter',
        'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ApprovelLetterpdf()),
            ),
      },
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.cyan,
        elevation: 0,
        title: Text(
          'Request for Certificates',
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
              // Text(
              //   'Select a Certificate Type',
              //   style: GoogleFonts.roboto(
              //     fontSize: 14,
              //     color: Colors.white70,
              //     fontWeight: FontWeight.w400,
              //   ),
              // ),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.builder(
                  itemCount: certificates.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,       // 2 columns → 2×2 grid
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 1.0,   // perfect square
                  ),
                  itemBuilder: (context, index) {
                    final cert = certificates[index];
                    return _buildGridCard(
                      image: cert['image'] as String,
                      title: cert['title'] as String,
                      onTap: cert['onTap'] as VoidCallback,
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

              // Gradient overlay at the bottom for caption readability
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

              // Subtle tap ripple indicator (top-right corner arrow)
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