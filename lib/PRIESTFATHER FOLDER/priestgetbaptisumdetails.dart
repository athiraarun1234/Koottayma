import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BaptisumRequest extends StatefulWidget {
  const BaptisumRequest({super.key});

  @override
  State<BaptisumRequest> createState() => _BaptisumRequestState();
}

class _BaptisumRequestState extends State<BaptisumRequest> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.cyan,
        elevation: 0,
        title: Text('Baptism Request Details',
            style: GoogleFonts.roboto(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500)),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context)),
      ),
      body: Column(children: [
        Container(
          height: 250,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25)
          ),
          child: Column(
            children: [
              Text('baby name'),
              Text('parents name'),
              Text('God parents name'),
              Text('Application code:'),
              ElevatedButton(onPressed:() {
                
              }, child: Text('Generate certificate')),
            ],
          ),
        )
      ],),
    );
  }
}