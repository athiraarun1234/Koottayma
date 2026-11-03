import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MessageSendPage extends StatefulWidget {
  const MessageSendPage({super.key});

  @override
  State<MessageSendPage> createState() => _MessageSendPageState();
}

class _MessageSendPageState extends State<MessageSendPage> {
  

  final List<Map<String, dynamic>> wardList = [
    {"id": 1001, "name": "Ward 1", "department": "Kalluvettankuzhy"},
    {"id": 1002, "name": "Ward 2", "department": "Vizhinjam"},
    {"id": 1003, "name": "Ward 3", "department": "Mukkola"},
  ];

  final List<Map<String, dynamic>> familyunitList = [
    {"id": 1101, "name": "Familyunit 1", "department": "Kalluvettankuzhy"},
    {"id": 1102, "name": "Familyunit 2", "department": "Kalluvettankuzhy"},
    {"id": 1103, "name": "Familyunit 3", "department": "Vizhinjam"},
    {"id": 1104, "name": "Familyunit 4", "department": "Vizhinjam"},
    {"id": 1105, "name": "Familyunit 5", "department": "Mukkola"},
  ];

  final List<Map<String, dynamic>> familymemberList = [
    {"id": 1201, "name": "RR Family",  "department": "Kalluvettankuzhy", "teacher": "Familyunit 1"}, 
    {"id": 1202, "name": "VV Family",  "department": "Kalluvettankuzhy", "teacher": "Familyunit 2"},
    {"id": 1203, "name": "BB Family",  "department": "Vizhinjam", "teacher": "Familyunit 3"},
    {"id": 1204, "name": "KK Family",  "department": "Vizhinjam", "teacher": "Familyunit 4"},
    {"id": 1205, "name": "DD Family ",  "department": "Mukkola", "teacher": "Familyunit 5"},
    {"id": 1206, "name": "TT Family", "department": "Mukkola", "teacher": "Familyunit 5"},
     {"id": 1207, "name": "JJ Family",  "department": "Kalluvettankuzhy", "teacher": "Familyunit 1"},
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

    for (var hod in wardList) {
      allMembers.add(hod['id']);
    }
    
 
    for (var teacher in familyunitList) {
      allMembers.add(teacher['id']);
    }
    
    
    for (var student in familymemberList) {
      allMembers.add(student['id']);
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
        children: wardList.map<Widget>((hod) {
          final hodDept = hod['department'];
          final teachers = familyunitList.where((t) => t['department'] == hodDept).toList();

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: ExpansionTile(
              leading: const Icon(Icons.supervisor_account, color: Colors.blueAccent),
              title: Text('${hod['name']} ($hodDept)'),
              trailing: Checkbox(
                value: selectedMembers.contains(hod['id']),
                onChanged: (_) => toggleMember(hod['id']),
              ),
              children: teachers.map<Widget>((teacher) {
                final teacherName = teacher['name'];
                final students = familymemberList.where((s) => s['teacher'] == teacherName).toList();

                return ExpansionTile(
                  leading: const Icon(Icons.school, color: Colors.green),
                  title: Text(teacher['name']),
                  trailing: Checkbox(
                    value: selectedMembers.contains(teacher['id']),
                    onChanged: (_) => toggleMember(teacher['id']),
                  ),
                  children: students.map<Widget>((student) {
                    return CheckboxListTile(
                      title: Text('${student['name']} '),
                      value: selectedMembers.contains(student['id']),
                      onChanged: (_) => toggleMember(student['id']),
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
Widget buildContainer(String name, IconData icon, Color color, bool isChecked, VoidCallback onTap) {
  return GestureDetector(
    onTap: onTap, // toggles the checkbox on tap
    child: Container(
      height: 55,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: const Color.fromARGB(255, 251, 247, 252),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 20),
            Text(
              name,
              style: GoogleFonts.roboto(
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
            const Spacer(),
            Icon(
              isChecked ? Icons.check_box : Icons.check_box_outline_blank, 
              color: isChecked ? Colors.green : Colors.grey,
            ),
          ],
        ),
      ),
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
                
                 buildContainer("All", Icons.select_all, Colors.blue, selectedMembers.length == (wardList.length + familyunitList.length + familymemberList.length), selectAllByCategory),
                 SizedBox(height: 20),
                 buildContainer("Students", Icons.person, Colors.blue, false, () {}),
                 SizedBox(height: 20),
                 buildContainer("Parents", Icons.person, Colors.blue, false, () {}),
                   SizedBox(height: 20),
                 buildContainer("Aged above 60", Icons.person, Colors.blue, false, () {}),
                  SizedBox(height: 20),
                 buildContainer("Parish Committee", Icons.person, Colors.blue, false, () {}),
                 SizedBox(height: 20),
                 buildContainer("Groups", Icons.person, Colors.blue, false, () {}),


     const SizedBox(height: 16),
    Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    // Dropdown Container
    Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 8.0),
        leading: const Icon(Icons.people, color: Colors.blue),
        title: Text(
          'Authorized Persons',
          style: GoogleFonts.roboto(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
          
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                Container(
                  height: 55,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: const Color.fromARGB(255, 251, 247, 252),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18.0),
                    child: Row(
                      children: [
                        const Icon(Icons.person, color: Colors.blue),
                        const SizedBox(width: 20),
                        Text(
                          'President',
                          style: GoogleFonts.roboto(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                        ),
                        const SizedBox(width: 130),
                        const Icon(Icons.check_box_outline_blank),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  height: 55,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: const Color.fromARGB(255, 251, 247, 252),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18.0),
                    child: Row(
                      children: [
                        const Icon(Icons.person, color: Colors.blue),
                        const SizedBox(width: 20),
                        Text(
                          'Secretary',
                          style: GoogleFonts.roboto(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                        ),
                        const SizedBox(width: 130),
                        const Icon(Icons.check_box_outline_blank),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  height: 55,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: const Color.fromARGB(255, 251, 247, 252),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18.0),
                    child: Row(
                      children: [
                        const Icon(Icons.person, color: Colors.blue),
                        const SizedBox(width: 20),
                        Text(
                          'Treasurer',
                          style: GoogleFonts.roboto(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                        ),
                        const SizedBox(width: 130),
                        const Icon(Icons.check_box_outline_blank),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  ],
),  const SizedBox(height: 20),
                  buildCategorySection("Ward", Icons.account_balance, const Color.fromARGB(255, 33, 150, 243)),
                  // buildCategorySection("Faminly Unit", Icons.business_center, const Color.fromARGB(255, 76, 175, 80)),
                  // buildCategorySection("Family Member", Icons.school, const Color.fromARGB(255, 255, 152, 0)),
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
                      "Send Message",
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