
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:Koottaayma/BAPTISUM%20USER%20FOLDER/requestregister.dart';
import 'package:Koottaayma/USER%20FOLDER/8showingbaptisumcertificates.dart';
class UserSacramentalsNewPage extends StatefulWidget {
  const UserSacramentalsNewPage({super.key});

  @override
  State<UserSacramentalsNewPage> createState() =>
      _UserSacramentalsNewPageState();
}
class _UserSacramentalsNewPageState extends State<UserSacramentalsNewPage> {
  @override
  Widget build(BuildContext context) {
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
      body:Container(
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
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Select a Sacrament',
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
             
              //Sacrament details box is used to show the all navigator pages of sacramentals
              Container(
                      height: 220,
                    width: 370,
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 176, 240, 249),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child:Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children:[
                        Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => BaptisumRequestPage(),));
                                  },
                                  child:
                                     _buildIconButton('assets/sac1.png', 'Baptism'),
                                
                                ),
                               GestureDetector(
                                  onTap: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (context) => UserTextUploading(),));
                                        },
                              child: _buildIconButton('assets/sac2.png', 'Confirmation'),
                                             ),
                               GestureDetector(
                                 onTap: () {
                         
                              //  Navigator.push(context, MaterialPageRoute(builder:(context) => MyLivePage(),));
                                        },
                                child: _buildIconButton('assets/sac3.png', 'Penance/\nReconciliation')),
                                GestureDetector(
                                   onTap: () {
                             //Navigator.push(context,MaterialPageRoute(builder: (context) => CalenderDatesDetails(),));
                                        },
                                  child: _buildIconButton('assets/sac4.png', 'Eucharist')),
                              ],
                            ),
                              Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                  //  Navigator.push(context, MaterialPageRoute(builder: (context) => BiblePage(),));
                                  },
                                  child:
                                     _buildIconButton('assets/sac5.png', 'Ordination'),
                                
                                ),
                               GestureDetector(
                                  onTap: () {
                                 // Navigator.push(context, MaterialPageRoute(builder: (context) => HolyMassDetails(),));
                                        },
                              child: _buildIconButton('assets/sac6.png', 'Matrimony/\nMarriage'),
                                             ),
                               GestureDetector(
                                 onTap: () {
                               // Navigator.push(context, MaterialPageRoute(builder:(context) => MyLivePage(),));
                                        },
                                child: _buildIconButton('assets/sac7.png', 'Anointing of\nthe Sick')),
                              
                              ],
                            ),
                        ]
                      ),
                    )
              )
              ]))
      ),
    );
  }
}

 Widget _buildIconButton(String assetPath, String label) 
 {
    return Column(
           children: [
           CircleAvatar(
                        radius: 30,
                        backgroundColor: const Color.fromARGB(255, 176, 240, 249),
                        child: Image.asset(assetPath, scale: 2),
                       ),
                        Text(label, style: GoogleFonts.lexend(fontSize: 12)),
      ],
    );
  }





  


    