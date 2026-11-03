import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class MyLivePage extends StatefulWidget {
  const MyLivePage({super.key});

  @override
  State<MyLivePage> createState() => _MyLivePageState();
}

class _MyLivePageState extends State<MyLivePage> {
  List<String> liveUrls = [
    'https://youtube.com/@archtvmofficial?si=oM6MqilwLN9I4NTF',
    'https://www.youtube.com/live/kwT6cTDa8KY?si=VznH1hk0EzTcX3NL  ',
    // 'https://www.youtube.com/watch?v=Br3mK04rD3I',
    // 'https://www.youtube.com/watch?v=t_xu4_cELUA',
  ];

  List<String> images = [
   // 'assets/poster4.jpg',
     'assets/poster8.jpg',
     'assets/poster6.jpg',
    // 'assets/poster7.jpg',
  ];
  List<String> titles = [
    ' Live Stream',
    'Christmas Live Stream',
    // 'Easter Live Stream',
    // 'Palm Sunday Live Stream',
  ];

  Future<void> _launchUrl(int index) async {
    final Uri url = Uri.parse(liveUrls[index]);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open URL')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.cyan,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Live Stream',
          style: GoogleFonts.roboto(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.cyan, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        
        child:  ListView.builder(
                itemCount: images.length,
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemBuilder: (context, index) {
                  return SafeArea(
                    child: Container(
              
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Poster image
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(25)),
                            child: Image(
                              image: AssetImage(images[index]),
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: 300,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Title
                                Text(
                                 titles[index],
                                  style: GoogleFonts.poppins(
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                    height: 1.3,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 12),
                                
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'START DATE: 29-JUNE-2026',
                                        style: GoogleFonts.roboto(
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.w500,
                                          fontSize: 10,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Text(
                                        'END DATE: 18-JULY-2026',
                                        style: GoogleFonts.roboto(
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.w500,
                                          fontSize: 10,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                // FIX 4: One button per card using the same index
                                Center(
                                  child: SizedBox(
                                    width: 150,
                                    height: 40,
                                    child: ElevatedButton.icon(
                                      onPressed: () => _launchUrl(index),
                                      icon: const Icon(
                                          Icons.play_circle_filled,
                                          size: 20),
                                      label: const Text(
                                        'Watch Live',
                                        style: TextStyle(fontSize: 14),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 8),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}