import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MessageSendPage extends StatefulWidget {
  const MessageSendPage({super.key});

  @override
  State<MessageSendPage> createState() => _MessageSendPageState();
}

class _MessageSendPageState extends State<MessageSendPage> {
  
  // Shared data that will be used for all three categories
  final List<Map<String, dynamic>> wardList = [
    {"id": 1001, "name": "Ward 1", "department": "Kalluvettankuzhy"},
    {"id": 1002, "name": "Ward 2", "department": "Vizhinjam"},
    {"id": 1003, "name": "Ward 3", "department": "Mukkola"},
  ];

  final List<Map<String, dynamic>> familyunitList = [
    {"id": 1101, "name": "ST Thomas 1", "department": "Kalluvettankuzhy"},
    {"id": 1102, "name": "ST Thomas 2", "department": "Kalluvettankuzhy"},
    {"id": 1103, "name": "ST Thomas 3", "department": "Vizhinjam"},
    {"id": 1104, "name": "ST Thomas 4", "department": "Vizhinjam"},
    {"id": 1105, "name": "ST Thomas 5", "department": "Mukkola"},
  ];

  final List<Map<String, dynamic>> familymemberList = [
    {"id": 1201, "name": "Alice Cooper", "year": "Final Year", "department": "Kalluvettankuzhy", "familyunit": "ST Thomas 1"},
    {"id": 1202, "name": "Bob Martin", "year": "Third Year", "department": "Kalluvettankuzhy", "familyunit": "ST Thomas 2"},
    {"id": 1203, "name": "Charlie White", "year": "Final Year", "department": "Vizhinjam", "familyunit": "ST Thomas 3"},
    {"id": 1204, "name": "Diana Green", "year": "Second Year", "department": "Vizhinjam", "familyunit": "ST Thomas 4"},
    {"id": 1205, "name": "Edward Black", "year": "Third Year", "department": "Mukkola", "familyunit": "ST Thomas 5"},
    {"id": 1206, "name": "Fiona Gray", "year": "First Year", "department": "Mukkola", "familyunit": "ST Thomas 5"},
  ];

  final Set<int> selectedMembers = {};

  void toggleMember(int memberId) {
    setState(() {
      if (selectedMembers.contains(memberId)) {
        selectedMembers.remove(memberId);
      } else {
        selectedMembers.add(memberId);
      }
    });
  }

  void selectAllByCategory() {
    final allMembers = <int>[];
    
    
    for (var ward in wardList) {
      allMembers.add(ward['id']);
    }
    
   
    for (var familyunit in familyunitList) {
      allMembers.add(familyunit['id']);
    }
    
   
    for (var familymember in familymemberList) {
      allMembers.add(familymember['id']);
    }

    final allSelected = allMembers.every((id) => selectedMembers.contains(id));
    
    setState(() {
      if (allSelected) {
        selectedMembers.removeAll(allMembers);
      } else {
        selectedMembers.addAll(allMembers);
      }
    });
  }

  void sendMessage() {
    if (selectedMembers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select at least one person.")),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Verification',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'The message will first be validated by the Admin. '
                  'Once the admin sends a verification message, you can send this message.',
                ),
                const SizedBox(height: 20),
                Container(
                  height: 50,
                  width: 150,
                  decoration: BoxDecoration(
                    color: Colors.cyan,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Verify ',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Icon(
                        Icons.verified,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget buildCategorySection(String categoryName, IconData icon, Color color) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: Icon(icon, color: color, size: 28),
        title: Text(
          categoryName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        children: wardList.map<Widget>((ward) {
          final wardDept = ward['department'];
          final familyunits = familyunitList.where((t) => t['department'] == wardDept).toList();

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: ExpansionTile(
              leading: const Icon(Icons.supervisor_account, color: Colors.blueAccent),
              title: Text('${ward['name']} ($wardDept)'),
              trailing: Checkbox(
                value: selectedMembers.contains(ward['id']),
                onChanged: (_) => toggleMember(ward['id']),
              ),
              children: familyunits.map<Widget>((familyunit) {
                final familyunitName = familyunit['name'];
                final familymembers = familymemberList.where((s) => s['familyunit'] == familyunitName).toList();

                return ExpansionTile(
                  leading: const Icon(Icons.school, color: Colors.green),
                  title: Text(familyunit['name']),
                  trailing: Checkbox(
                    value: selectedMembers.contains(familyunit['id']),
                    onChanged: (_) => toggleMember(familyunit['id']),
                  ),
                  children: familymembers.map<Widget>((familymember) {
                    return CheckboxListTile(
                      title: Text('${familymember['name']} (${familymember['year']})'),
                      value: selectedMembers.contains(familymember['id']),
                      onChanged: (_) => toggleMember(familymember['id']),
                    );
                  }).toList(),
                );
              }).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          "Send Message",
          style: GoogleFonts.roboto(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 13, 191, 215),
      ),
      body: SizedBox.expand(
        child: SingleChildScrollView(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.cyan,
                  Color.fromARGB(255, 202, 236, 241),
                  Colors.white
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                 
                  const SizedBox(height: 16),
                  buildCategorySection("President", Icons.account_balance, const Color.fromARGB(255, 33, 150, 243)),
                  buildCategorySection("Secretary", Icons.business_center, const Color.fromARGB(255, 76, 175, 80)),
                  buildCategorySection("Tresurer", Icons.school, const Color.fromARGB(255, 255, 152, 0)),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyan[400],
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.send, color: Colors.white),
                    label: Text(
                      "Send Message (${selectedMembers.length} selected)",
                      style: const TextStyle(fontSize: 18, color: Colors.white),
                    ),
                    onPressed: sendMessage,
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}