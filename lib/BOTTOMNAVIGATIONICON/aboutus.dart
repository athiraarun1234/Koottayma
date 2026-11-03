import 'package:flutter/material.dart';

class AboutUsPage extends StatefulWidget {
  const AboutUsPage({super.key});

  @override
  State<AboutUsPage> createState() => _AboutUsPageState();
}

class _AboutUsPageState extends State<AboutUsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.cyan,
        centerTitle: true, //  Use centerTitle instead of wrapping in Center
        title: const Text(
          "About Us",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SingleChildScrollView( //  Prevents overflow on small screens
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, //  Align content to left
            children: [
              // Church Image
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10), //  Rounded corners
                  image: const DecorationImage(
                    image: AssetImage('assets/vettucad.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              const SizedBox(height: 12), // Spacing

              // Description 1
              const Text(
                "Welcome to Madre de Deus Church, Vettucaud, a sacred haven that stands as a beacon of faith and devotion. "
                "Nestled by the serene shores, our church is renowned for the Christ The King Shrine, where believers gather "
                "in reverence and joy, celebrating the boundless love of Christ.",
                style: TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.justify, //  Justified text
              ),

              const SizedBox(height: 8),

              // Description 2
              const Text(
                "The Madre de Deus Church, also known as the Mother of God Church, is a church located in Vettukad "
                "in Kerala, India's Thiruvananthapuram district.",
                style: TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.justify,
              ),

              const SizedBox(height: 16),

              // Info Rows — using _infoRow helper
              _infoRow("Address:", "Veli Sanghumugham Rd, Balanagar, Vettukadu, Thiruvananthapuram, Kerala 695021"),
              _infoRow("Founder:", "Francis Xavier"),
              _infoRow("Denomination:", "Catholic Church"),
              _infoRow("Founded:", "1544 AD"),
              _infoRow("Priest:", "Rev. Dr. Edison YM"),
            ],
          ),
        ),
      ),
    );
  }

  //  Reusable row widget — fixes text overflow with Flexible
  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, //  Align top for long values
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(width: 4),
          Flexible( // Prevents Row overflow for long text
            child: Text(value),
          ),
        ],
      ),
    );
  }
}