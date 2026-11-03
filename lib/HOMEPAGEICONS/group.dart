
import 'package:Koottaayma/HTTPURL/httpurl.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Model Class for Group
class GroupModel {
  final int nGroupID;
  final String cGroupName;
  final int? nDioceseID;
  final int? nForaneID;
  final int? nParishID;

  GroupModel({
    required this.nGroupID,
    required this.cGroupName,
    this.nDioceseID,
    this.nForaneID,
    this.nParishID,
  });

  factory GroupModel.fromJson(Map<String, dynamic> json) {
    return GroupModel(
      nGroupID: (json['nGroupID'] as int?) ?? 0,
      cGroupName: (json['cGroupName'] as String?) ?? '',
      nDioceseID: json['nDioceseID'] as int?,
      nForaneID: json['nForaneID'] as int?,
      nParishID: json['nParishID'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nGroupID': nGroupID,
      'cGroupName': cGroupName,
      'nDioceseID': nDioceseID,
      'nForaneID': nForaneID,
      'nParishID': nParishID,
    };
  }

  // Get initials from group name
  String getInitials() {
    List<String> words = cGroupName.trim().split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return cGroupName
        .substring(0, cGroupName.length >= 2 ? 2 : 1)
        .toUpperCase();
  }

  // Generate color based on group ID
  Color getColor() {
    List<Color> colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
      Colors.cyan,
      Colors.amber,
    ];
    return colors[nGroupID % colors.length];
  }
}

// Model Class for Group Programme/Event
class GroupProgrammeModel {
  final int nGroupProgrammeeID;
  final String cGroupProgrammeeName;
  final String dStartDate;
  final String dEndDate;
   final String dStartTime;
  final String dEndTime;
  final String cDioceseName;
  final String cParishName;
  final String cForaneName;

  GroupProgrammeModel({
    required this.nGroupProgrammeeID,
    required this.cGroupProgrammeeName,
    required this.dStartDate,
    required this.dEndDate,
    required this.dStartTime,
    required this.dEndTime,
    required this.cDioceseName,
    required this.cParishName,
    required this.cForaneName,
  });

  factory GroupProgrammeModel.fromJson(Map<String, dynamic> json) {
    return GroupProgrammeModel(
      nGroupProgrammeeID: (json['nGroupProgrammeeID'] as int?) ?? 0,
      cGroupProgrammeeName: (json['cGroupProgrammeeName'] as String?) ?? '',
      dStartDate: (json['dStartDate'] as String?) ?? '',
      dEndDate: (json['dEndDate'] as String?) ?? '',
        dStartTime: (json['dStartTime'] as String?) ?? '',
      dEndTime: (json['dEndTime'] as String?) ?? '',
      cDioceseName: (json['cDioceseName'] as String?) ?? '',
      cParishName: (json['cParishName'] as String?) ?? '',
      cForaneName: (json['cForaneName'] as String?) ?? '',
    );
  }

  // Format date for display
String getFormattedStartDate() {
  try {
    DateTime date = DateTime.parse(dStartDate);
    return DateFormat('d-MMM-yyyy').format(date);
  } catch (e) {
    return dStartDate;
  }
}

  String getFormattedEndDate() {
    try {
      DateTime date = DateTime.parse(dEndDate);
         return DateFormat('d-MMM-yyyy').format(date);
    } catch (e) {
      return dEndDate;
    }
  }
String formatTimeWithAmPm(String time) {
  try {
    print('Input time: $time'); 
    
    final parts = time.split(':');
    if (parts.length < 2) return time;

    int hour = int.parse(parts[0]);
    int minute = int.parse(parts[1]);
    
    print('Parsed hour: $hour');

    final String period = hour >= 12 ? 'PM' : 'AM';

    hour = hour % 12;
    if (hour == 0) hour = 12;

    return '$hour:${minute.toString().padLeft(2, '0')} $period';
  } catch (e) {
    return time;
  }
}
  // Get duration in days
  int getDuration() {
    try {
      DateTime start = DateTime.parse(dStartDate);
      DateTime end = DateTime.parse(dEndDate);
      return end.difference(start).inDays + 1;
    } catch (e) {
      return 0;
    }
  }
}

// Main Page
class MyGroups extends StatefulWidget {
  const MyGroups({super.key});

  @override
  State<MyGroups> createState() => _MyGroupsState();
}

class _MyGroupsState extends State<MyGroups> {
  List<GroupModel> groups = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    loadGroups();
  }

  // Load groups from API
  Future<void> loadGroups() async {
    setState(() {
      isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? savedToken = prefs.getString('jwt');
      final response = await http.get(
        Uri.parse(GroupAPI),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "$savedToken",
        },
      );

      print('Status Code: ${response.statusCode}'); // Debug
      print('Response Body: ${response.body}'); // Debug

      // Check for successful status codes (200 or 201)
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Check if response body is not empty
        if (response.body.isEmpty) {
          throw Exception('Empty response from server');
        }

        List<dynamic> jsonData = jsonDecode(response.body);

        print('Parsed Groups: ${jsonData.length}'); // Debug

        setState(() {
          groups = jsonData.map((json) => GroupModel.fromJson(json)).toList();
          isLoading = false;
        });

        // Show success message
        if (mounted && groups.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${groups.length} groups loaded successfully'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        throw Exception(
            'Failed to load groups. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e'); // Debug

      setState(() {
        isLoading = false;
        groups = []; // Clear groups on error
      });

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading groups: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 1),
            // action: SnackBarAction(
            //   label: 'Retry',
            //   textColor: Colors.white,
            //   onPressed: loadGroups,
            // ),
          ),
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
          'My Groups',
          style: GoogleFonts.roboto(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.refresh,
              color: Colors.white,
            ),
            onPressed: loadGroups,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : groups.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.group_off,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No groups found',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: loadGroups,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: groups.length,
                    itemBuilder: (context, index) {
                      return GroupCircle(
                        group: groups[index],
                        onTap: () {
                          _onGroupTap(groups[index]);
                        },
                      );
                    },
                  ),
                ),
    );
  }

  void _onGroupTap(GroupModel group) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GroupEventsPage(group: group),
      ),
    );
  }
}

// Group Circle Widget
class GroupCircle extends StatelessWidget {
  final GroupModel group;
  final VoidCallback? onTap;

  const GroupCircle({
    super.key,
    required this.group,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(60),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Hero(
            tag: 'group_${group.nGroupID}',
            child: CircleAvatar(
              radius: 40,
              backgroundColor: group.getColor(),
              child: Text(
                group.getInitials(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            group.cGroupName,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// Group Events/Programmes Page
class GroupEventsPage extends StatefulWidget {
  final GroupModel group;

  const GroupEventsPage({
    super.key,
    required this.group,
  });

  @override
  State<GroupEventsPage> createState() => _GroupEventsPageState();
}

class _GroupEventsPageState extends State<GroupEventsPage> {
  List<GroupProgrammeModel> programmes = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    loadProgrammes();
  }

  Future<void> loadProgrammes() async {
    setState(() {
      isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? savedToken = prefs.getString('jwt');

      // Prepare request body
      Map<String, dynamic> requestBody = {
        'nGroupMasterID': widget.group.nGroupID,
      };
      if (widget.group.nDioceseID != null) {
        requestBody['nDioceseID'] = widget.group.nDioceseID;
      }
      if (widget.group.nForaneID != null) {
        requestBody['nForaneID'] = widget.group.nForaneID;
      }
      if (widget.group.nParishID != null) {
        requestBody['nParishID'] = widget.group.nParishID;
      }

      print('API URL: ${GroupProgrammeAPI}'); 
      print('Request Body: ${jsonEncode(requestBody)}'); 

      final response = await http.post(
        Uri.parse(GroupProgrammeAPI), 
        headers: {
          "Content-Type": "application/json",
          "Authorization": "$savedToken",
        },
        body: jsonEncode(requestBody),
      );

      print('Status Code: ${response.statusCode}'); // Debug
      print('Response Body: ${response.body}'); // Debug

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.body.isEmpty) {
          setState(() {
            programmes = [];
            isLoading = false;
          });
          return;
        }

        List<dynamic> jsonData = jsonDecode(response.body);
        print('Total items received: ${jsonData.length}');

        List<GroupProgrammeModel> parsedList = [];

        for (int i = 0; i < jsonData.length; i++) {
          try {
            print('Parsing item[$i]: ${jsonData[i]}');
            parsedList.add(GroupProgrammeModel.fromJson(jsonData[i]));
            print('Successfully parsed item[$i]');
          } catch (e) {
            print('ERROR parsing item[$i]: $e');
            print('Item[$i] data: ${jsonData[i]}');
          }
        }

        print('Total parsed successfully: ${parsedList.length}');

        setState(() {
          programmes = parsedList;
          isLoading = false;
        });

        if (mounted) {
          if (programmes.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${programmes.length} events loaded'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          } 
          // else {
          //   ScaffoldMessenger.of(context).showSnackBar(
          //     SnackBar(
          //       content: const Text(''),
          //      // backgroundColor: Colors.orange,
          //       duration: const Duration(seconds: 3),
          //     ),
          //   );
          // }
        }
      } else {
        throw Exception(
            'Failed to load events. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e'); // Debug

      setState(() {
        isLoading = false;
        // Do NOT clear programmes here — keep whatever was already parsed
      });

      // if (mounted) {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     SnackBar(
      //       content: Text('Error loading events: $e'),
      //       backgroundColor: Colors.red,
      //       duration: const Duration(seconds: 1),
      //       // action: SnackBarAction(
      //       //   //label: 'Retry',
      //       //   textColor: Colors.white,
      //       //   onPressed: loadProgrammes,
      //       // ),
      //     ),
      //   );
      // }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: widget.group.getColor(),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.group.cGroupName,
          style: GoogleFonts.roboto(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.refresh,
              color: Colors.white,
            ),
            onPressed: loadProgrammes,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : programmes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.event_busy,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No events found',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'for ${widget.group.cGroupName}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: loadProgrammes,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.group.getColor(),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: programmes.length,
                  itemBuilder: (context, index) {
                    return EventCard(
                      programme: programmes[index],
                      groupColor: widget.group.getColor(),
                    );
                  },
                ),
    );
  }
}

// Event Card Widget
class EventCard extends StatelessWidget {
  final GroupProgrammeModel programme;
  final Color groupColor;

  const EventCard({
    super.key,
    required this.programme,
    required this.groupColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Icon + Title
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: groupColor.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.event, color: groupColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    programme.cGroupProgrammeeName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            
            // Date & Time Info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: groupColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  _infoRow(
                    Icons.calendar_today,
                    'Date',
                    '${programme.getFormattedStartDate()}  To  ${programme.getFormattedEndDate()}',
                    groupColor,
                  ),
                  const SizedBox(height: 10),
                  _infoRow(
                    Icons.access_time,
                    'Time',
                    '${programme.formatTimeWithAmPm(programme.dStartTime)}  To  ${programme.formatTimeWithAmPm(programme.dEndTime)}',
                    groupColor,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}