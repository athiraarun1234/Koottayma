import 'package:Koottaayma/BETSEIDHA/betpriestgetguestapproval.dart';
import 'package:Koottaayma/HOMEPAGEICONS/bible.dart';
import 'package:Koottaayma/HOMEPAGEICONS/calender.dart';
import 'package:Koottaayma/HOMEPAGEICONS/connect.dart';
import 'package:Koottaayma/HOMEPAGEICONS/events.dart';
import 'package:Koottaayma/HOMEPAGEICONS/group.dart';
import 'package:Koottaayma/HOMEPAGEICONS/holymass.dart';
import 'package:Koottaayma/HOMEPAGEICONS/notepad.dart';
import 'package:Koottaayma/HTTPURL/httpurl.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';


class NotificationIconWithBadges extends StatefulWidget {
  final VoidCallback? onTap;
  final Color iconColor;
  final double iconSize;
  final Map<String, dynamic>? userData; // Add this parameter

  const NotificationIconWithBadges({
    Key? key,
    this.onTap,
    this.iconColor = const Color.fromARGB(255, 40, 141, 161),
    this.iconSize = 28,
    this.userData, // Add this
  }) : super(key: key);

  @override
  State<NotificationIconWithBadges> createState() =>
      _NotificationIconWithBadgesState();
}

class _NotificationIconWithBadgesState
    extends State<NotificationIconWithBadges> {
  int baptismCount = 0;
  int guestCount = 0;
  int totalCount = 0;

  @override
  void initState() {
    super.initState();
    _loadCounts();
    // If userData is provided, update counts from it
    if (widget.userData != null) {
      _updateCountsFromUserData();
    }
  }

  @override
  void didUpdateWidget(NotificationIconWithBadges oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update counts when userData changes
    if (widget.userData != null && widget.userData != oldWidget.userData) {
      _updateCountsFromUserData();
    }
  }

  Future<void> _updateCountsFromUserData() async {
    try {
      final userData = widget.userData;
      if (userData != null && userData.containsKey('Priest')) {
        final priestList = userData['Priest'] as List;
        if (priestList.isNotEmpty) {
          final priestData = priestList[0] as Map<String, dynamic>;
          final newBaptismCount = priestData['nBaptismCount'] as int? ?? 0;
          final newGuestCount = priestData['nGuestCount'] as int? ?? 0;

          // Update SharedPreferences with server values
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setInt('baptismCount', newBaptismCount);
          await prefs.setInt('guestCount', newGuestCount);

          // Load the updated counts
          await _loadCounts();

          print('Updated from userData - Baptism: $newBaptismCount, Guest: $newGuestCount');
        }
      }
    } catch (e) {
      print('Error updating counts from userData: $e');
    }
  }

  ///  UPDATED: made public for external refresh
  Future<void> refreshCounts() async {
    await _loadCounts();
  }

  Future<void> _loadCounts() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      // UPDATED: always read fresh values
      final bCount = prefs.getInt('baptismCount') ?? 0;
      final gCount = prefs.getInt('guestCount') ?? 0;

      setState(() {
        baptismCount = bCount;
        guestCount = gCount;
        totalCount =  guestCount;
      });

      print('Loaded baptism count: $baptismCount');
      print('Loaded guest count: $guestCount');
      print('Total count: $totalCount');
    } catch (e) {
      print('Error loading counts: $e');
    }
  }

  // New method to update counts directly from API response
  Future<void> updateCountsFromServerResponse(Map<String, dynamic> responseData) async {
    try {
      if (responseData.containsKey('Priest')) {
        final priestList = responseData['Priest'] as List;
        if (priestList.isNotEmpty) {
          final priestData = priestList[0] as Map<String, dynamic>;
          final newBaptismCount = priestData['nBaptismCount'] as int? ?? 0;
          final newGuestCount = priestData['nGuestCount'] as int? ?? 0;

          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setInt('baptismCount', newBaptismCount);
          await prefs.setInt('guestCount', newGuestCount);

          setState(() {
            baptismCount = newBaptismCount;
            guestCount = newGuestCount;
            totalCount = guestCount;
          });

          print('Updated from server - Baptism: $baptismCount, Guest: $guestCount');
        }
      }
    } catch (e) {
      print('Error updating counts from server: $e');
    }
  }

  // Keep the old method name for backward compatibility
  Future<void> updateCount(int newCount) async {
    await updateBaptismCount(newCount);
  }

  Future<void> updateBaptismCount(int newCount) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setInt('baptismCount', newCount);

      // 🔹 UPDATED: reload both counts
      await _loadCounts();

      print('Updated baptism count to: $newCount');
    } catch (e) {
      print('Error updating baptism count: $e');
    }
  }

  Future<void> updateGuestCount(int newCount) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setInt('guestCount', newCount);

      // 🔹 UPDATED: reload both counts
      await _loadCounts();

      print('Updated guest count to: $newCount');
    } catch (e) {
      print('Error updating guest count: $e');
    }
  }

  Future<void> updateBothCounts(
      int newBaptismCount, int newGuestCount) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setInt('baptismCount', newBaptismCount);
      await prefs.setInt('guestCount', newGuestCount);

      // 🔹 UPDATED: reload
      await _loadCounts();

      print('Updated baptism count to: $newBaptismCount');
      print('Updated guest count to: $newGuestCount');
    } catch (e) {
      print('Error updating counts: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(
            Icons.notifications,
            color: widget.iconColor,
            size: widget.iconSize,
          ),
          if (totalCount > 0)
            Positioned(
              right: -6,
              top: -4,
              child: Container(
                padding: EdgeInsets.all(totalCount > 9 ? 4 : 5),
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                constraints: BoxConstraints(
                  minWidth: totalCount > 9 ? 20 : 18,
                  minHeight: totalCount > 9 ? 20 : 18,
                ),
                child: Center(
                  child: Text(
                    totalCount > 99 ? '99+' : totalCount.toString(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: totalCount > 9 ? 9 : 10,
                      fontWeight: FontWeight.bold,
                      height: 1,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class AudioModel {
  int? nGospelReadingMasterID;
  String? dDate;
  int? nWeekDayID;
  String? cUploadedPath;
  String? cChapterSummary;
  String? cChapterNo;
  String? cChapterDetails;
  String? cGospelReadingText;

  AudioModel({
    this.nGospelReadingMasterID,
    this.dDate,
    this.nWeekDayID,
    this.cUploadedPath,
    this.cChapterSummary,
    this.cChapterNo,
    this.cChapterDetails,
    this.cGospelReadingText,
  });

  factory AudioModel.fromJson(Map<String, dynamic> json) {
    return AudioModel(
      nGospelReadingMasterID: json['nGospelReadingMasterID'],
      dDate: json['dDate'],
      nWeekDayID: json['nWeekDayID'],
      cUploadedPath: json['cAudioFilePath'],
      cChapterSummary: json['cChapterSummary'],
      cChapterNo: json['cChapterNo'],
      cChapterDetails: json['cChapterDetails'],
      cGospelReadingText: json['cGospelReadingText'],
    );
  }
}


class BetseidhaPriestHome extends StatefulWidget {
  int? languageId;
  int? phoneNumber;
  int? nUserTypeID;
  BetseidhaPriestHome({super.key, this.languageId, this.nUserTypeID, this.phoneNumber});

  @override
  State<BetseidhaPriestHome> createState() => _BetseidhaPriestHomeState();
}

class _BetseidhaPriestHomeState extends State<BetseidhaPriestHome> with SingleTickerProviderStateMixin {
  final AudioPlayer _audioPlayer = AudioPlayer();
  AudioModel? _audioData;
  bool _isPlaying = false;
  bool _isLoading = true;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  late AnimationController _waveController;
  bool _isVisible = true;
  bool isLoading = true;
  String errorMessage = '';
  List<dynamic> baptismProfiles = [];
  bool isLoadingFromBackend = false;
  String dataSource = ''; 
  List<dynamic> baptismNotifications = [];
  List<String>Names=['St Marys','Vizhinjam Old Portuguese Church','St Josephs Shrine','St ','St Marys'];
  List<String>images=['assets/poster5.jpg','assets/poster6.jpg','assets/poster.jpg','assets/poster2.jpg','assets/poster4.jpg',];
   List<String>Times=['10:00 AM -12:00 PM','8:00 AM -10:00 PM','6:00 AM -9:00 AM','10:00 AM -12:30 PM ','10:00 AM -12:00 PM'];
  final GlobalKey<_NotificationIconWithBadgesState> _notificationKey = 
      GlobalKey<_NotificationIconWithBadgesState>();

  @override
  void initState() {
    super.initState();
    _loadVisibility();
    
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    
    _loadAudioData();
    
    _audioPlayer.onDurationChanged.listen((duration) {
      setState(() {
        _duration = duration;
      });
    });

    _audioPlayer.onPositionChanged.listen((position) {
      setState(() {
        _position = position;
      });
    });

    _audioPlayer.onPlayerComplete.listen((event) {
      setState(() {
        _isPlaying = false;
        _position = Duration.zero;
      });
    });
  }

  String _formatDateWithDay(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'N/A';
    try {
      DateTime date = DateTime.parse(dateStr);
      String formattedDate = DateFormat('dd-MM-yyyy').format(date);
      String dayName = DateFormat('EEEE').format(date);
      return '$formattedDate ($dayName)';
    } catch (e) {
      return 'Invalid date';
    }
  }

  Future<void> _checkFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    final lastPlayedDate = prefs.getString('last_audio_played_date');
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    
    print('Last played date: $lastPlayedDate');
    print('Today: $today');
    print('Will auto-play? ${lastPlayedDate != today}');
    
    if (lastPlayedDate != today) {
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (_audioData != null && _audioData!.cUploadedPath != null) {
        print('Auto-playing audio...');
        _playAudio();
        await prefs.setString('last_audio_played_date', today);
      } else {
        print('Cannot auto-play: audioData or path is null');
      }
    }
  }

  Future<void> _loadVisibility() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isVisible = prefs.getBool('isVisible') ?? true;
    });
  }

  Future<void> _hideContainer() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isVisible', false);
    setState(() {
      _isVisible = false;
    });
  }

Future<void> _loadAudioData() async {
    setState(() => _isLoading = true);

    try {
         SharedPreferences prefs = await SharedPreferences.getInstance();
         String? savedToken = prefs.getString('jwt');
         final response = await http.get(
         Uri.parse(AudioDetails),
         headers: {
        'Content-Type': 'application/json',
      },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = response.body.trim();

        if (body.isEmpty) {
          print('Empty response body.');
          setState(() => _isLoading = false);
          return;
        }

        final List<dynamic> jsonData = json.decode(body);
        print('JSON data length: ${jsonData.length}');

        if (jsonData.isNotEmpty) {
          setState(() {
            _audioData = AudioModel.fromJson(jsonData.first);
            _isLoading = false;
          });
          
          print('Audio data loaded: ${_audioData?.cUploadedPath}');
          print('Audio data null? ${_audioData == null}');
          print('Audio path null? ${_audioData?.cUploadedPath == null}');
          
          await _checkFirstTime();
        } else {
          print('Have a nice day — no audio notifications found.');
          setState(() => _isLoading = false);
        }
      } else {
        print('Server returned status code: ${response.statusCode}');
        setState(() => _isLoading = false);
      }
    } catch (e, stackTrace) {
      print('Error loading audio: $e');
      print('StackTrace: $stackTrace');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _playAudio() async {
    print('_playAudio called');
    print('Audio path: ${_audioData?.cUploadedPath}');
    
    if (_audioData?.cUploadedPath != null) {
      try {
        String audioUrl = _audioData!.cUploadedPath!;
        print('Attempting to play: $audioUrl');
        
        await _audioPlayer.play(UrlSource(audioUrl));
        setState(() {
          _isPlaying = true;
        });
        print('Audio playing successfully');
      } catch (e) {
        print('Error playing audio: $e');
      }
    } else {
      print('Audio path is null, cannot play');
    }
  }

  Future<void> _pauseAudio() async {
    await _audioPlayer.pause();
    setState(() {
      _isPlaying = false;
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _waveController.dispose();
    super.dispose();
  }

  Future<void> fetchBaptismDetails() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? phoneNumber = prefs.getString('userPhone');
      String? savedToken = prefs.getString('jwt');
      if (phoneNumber == null) {
        setState(() {
          isLoading = false;
          errorMessage = 'Phone number not found. Please login again.';
        });
        return;
      }
      if (savedToken == null) {
        setState(() {
          isLoading = false;
          errorMessage = 'Authentication token not found. Please login again.';
        });
        return;
      }
      
      print(' Checking SQLite for family members...');
      final hasCachedData = false;
      
      if (hasCachedData) {
        // Load from SQLite
      } else {
        print(' No cached data, fetching from backend...');
        await _fetchFromBackend(phoneNumber, savedToken);
      }
    } catch (e) {
      print('Error in fetchUserProfile: $e');
      setState(() {
        isLoading = false;
        errorMessage = 'Error: ${e.toString()}';
      });
    }
  }

  Future<void> _fetchFromBackend(String phoneNumber, String? savedToken) async {
    setState(() {
      isLoadingFromBackend = true;
    });

    try {
      var response = await http.get(
        Uri.parse('https://lv4hfxvb-7000.inc1.devtunnels.ms/churchdetails/guestapproval/'),
        headers: {
          'Content-Type': 'application/json',
          if (savedToken != null) 'Authorization': ' $savedToken', 
        },
        // body: jsonEncode({
        //   'nPhoneNo': phoneNumber,
        //   'jwt': savedToken,
        // }),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Connection timeout');
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        var responseData = jsonDecode(response.body);
        List<dynamic> members = [];

        if (responseData is List) {
          members = responseData;
        } else if (responseData is Map) {
          members = [responseData];
        }

        if (members.isNotEmpty) {
          print('Saving ${members.length} members to SQLite...');
          print('Would save to SQLite here');
        }

        setState(() {
          baptismProfiles = members;
          baptismNotifications = members; 
          isLoading = false;
          isLoadingFromBackend = false;
          dataSource = 'backend';
        });

        //  NEW - Update the badge count based on actual notifications
        _notificationKey.currentState?.updateCount(members.length);
        
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } on http.ClientException catch (e) {
      setState(() {
        isLoading = false;
        isLoadingFromBackend = false;
        errorMessage = 'Network error. Check your connection.';
      });
      print('Network error: $e');
    } catch (e) {
      setState(() {
        isLoading = false;
        isLoadingFromBackend = false;
        errorMessage = 'Failed to load data: ${e.toString()}';
      });
      print('Error fetching from backend: $e');
    }
  }

  void _showBaptismNotificationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 340,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.cyan.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.notifications_active, color: Colors.cyan[700], size: 24),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Guest Requests',
                        style: GoogleFonts.roboto(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    splashRadius: 10,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              baptismNotifications.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'No requests found',
                        style: GoogleFonts.roboto(fontSize: 14, color: Colors.grey),
                      ),
                    )
                  : SizedBox(
                      height: 300,
                      child: SingleChildScrollView(
                        child: Column(
                          children: baptismNotifications.map((notification) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.cyan.withOpacity(0.1),
                                      Colors.blue.withOpacity(0.05)
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.cyan.withOpacity(0.2)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                      
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                notification['cMemberName'] ?? 'N/A',
                                                style: GoogleFonts.roboto(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.cyan[800],
                                                ),
                                              ),
                                              Text(
                                                "Address: ${notification['cAddress'] ?? 'N/A'}",
                                                style: GoogleFonts.roboto(fontSize: 12),
                                              ),
                                              Text(
                                                "Phone No: ${notification['nPhoneNo'] ?? 'N/A'}",
                                                style: GoogleFonts.roboto(fontSize: 12),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            //Icon(Icons.calendar_today, size: 12, color: Colors.grey[600]),
                                           // const SizedBox(width: 4),
                                            // Text(
                                            //   notification['dBaptismDate'] ?? 'N/A',
                                            //   style: GoogleFonts.roboto(
                                            //     fontSize: 11,
                                            //     color: Colors.grey[600],
                                            //   ),
                                            // ),
                                          ],
                                        ),
                                        GestureDetector(
                                          onTap: () async {
                                            Navigator.pop(context);
                                            final result = await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => BetseidhaPriestBaptismApproval(
                                                  baptismData: notification,
                                                ),
                                              ),
                                            );
                                            if (result == true) {
                                              await fetchBaptismDetails();
                                            }
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.cyan[700],
                                              borderRadius: BorderRadius.circular(20),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.cyan.withOpacity(0.3),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: Text(
                                              'View Details',
                                              style: GoogleFonts.roboto(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
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
      backgroundColor: const Color.fromARGB(255, 248, 254, 255),
      body: SizedBox.expand(
        child: SingleChildScrollView(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.cyan,
                  Color.fromARGB(255, 158, 218, 228),
                  Colors.white,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              children: [
                SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: SearchBar(
                    leading: Icon(Icons.menu),
                    hintText: 'Search...',
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.search,
                    trailing: [
                      IconButton(
                        onPressed: () {},
                        icon: Icon(Icons.search),
                      ),
                      
                     
                      NotificationIconWithBadges(
                        key: _notificationKey,
                        iconColor: const Color.fromARGB(255, 40, 141, 161),
                        iconSize: 28,
                        onTap: () async {
                          print(' Notification icon pressed');
                          print(' Current notifications count: ${baptismNotifications.length}');
                          
                          await fetchBaptismDetails();
                          
                          if (mounted) {
                            _showBaptismNotificationDialog(context);
                          }
                        },
                      ),
                      SizedBox(width: 8),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: 20),
                    _buildAudioPlayer(),
                    SizedBox(height: 40),
                    Container(
                      height: 230,
                      width: 330,
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 176, 240, 249),
                        borderRadius: BorderRadius.circular(10),
                      ),
                        child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => BiblePage(),));
                                  },
                                  child:
                                     _buildIconButton('assets/icon1.png', 'Bible'),
                                
                                ),
                               GestureDetector(
                                  onTap: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (context) => HolyMassDetails(),));
                                        },
                              child: _buildIconButton('assets/icon2.png', 'Holymass'),
                                             ),
                               GestureDetector(
                                 onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Please contact your church')),
                                     );
                                        },
                                child: _buildIconButton('assets/icon3.png', 'Live')),
                                 GestureDetector(
                                   onTap: () {
                             Navigator.push(context,MaterialPageRoute(builder: (context) => CalenderDatesDetails(),));
                                        },
                                  child: _buildIconButton('assets/icon4.png', 'Calender')),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                   GestureDetector(
                                   onTap: () {
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => Churchnotification(),));
                                        },
                                  child: _buildIconButton('assets/icon5.png', 'Events')),
                                                            GestureDetector(
                                   onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => MyGroups(),));
                                        },
                                  child: _buildIconButton('assets/icon6.png', 'Group')),
                              GestureDetector(
                                   onTap: () {
                                 Navigator.push(context, MaterialPageRoute(builder:(context) => ConnectPage(),));
                                     
                                        },
                                  child: _buildIconButton('assets/icon7.png', 'Connect')),
                                GestureDetector(
                                   onTap: () {
                                     Navigator.push(context, MaterialPageRoute(builder: (context) => WritingNotes(),));
                                  // ScaffoldMessenger.of(context).showSnackBar(
                                  // SnackBar(content: Text('Please contact your church')),
                                  //    );
                                        },
                                  child: _buildIconButton('assets/icon8.png', 'Notes')),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 40),
                 Container(
  height: 175,
  child: ListView.builder(
    scrollDirection: Axis.horizontal,
    itemCount: 5,
    itemBuilder: (context, index) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          width: 175,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            image: DecorationImage(
              image: AssetImage(images[index]),
              fit: BoxFit.cover,
            ),
          ),

          child: Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.black.withOpacity(0.3), // overlay for readability
            ),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,

              children: [
                Text(
                  Names[index],  
                  style: GoogleFonts.roboto(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                SizedBox(height: 4),

                Text(
                  "Sunday Service",
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),

                Text(
                 Times[index],
                  style: GoogleFonts.roboto(
                    fontSize: 13,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  ),
       ),

                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton(String assetPath, String label) {
    return Column(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: Colors.white,
          child: Image.asset(assetPath, scale: 2),
        ),
        Text(label, style: GoogleFonts.lexend(fontSize: 12)),
      ],
    );
  }

 Widget _buildAudioPlayer() {
  if (_isLoading) {
    return Container(
      height: 135,
      width: 330,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.cyan.withOpacity(0.3),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Center(
        child: CircularProgressIndicator(
          color: Colors.cyan,
        ),
      ),
    );
  }

  // Check if audio file path exists and is not empty
  if (_audioData != null && 
      _audioData!.cUploadedPath != null && 
      _audioData!.cUploadedPath!.isNotEmpty) {
    // Show audio player
    return _isVisible
        ? Container(
            height: 120,
            width: 330,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF00BCD4),
                  Color(0xFF00ACC1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.cyan.withOpacity(0.4),
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.campaign,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Today Verse',
                                  style: GoogleFonts.roboto(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(width: 15),
                                Text(
                                  _formatDateWithDay(_audioData?.dDate),
                                  style: GoogleFonts.roboto(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Row(
                        children: [
                          Text(
                            _formatDuration(_position),
                            style: GoogleFonts.roboto(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                          Expanded(
                            child: SliderTheme(
                              data: SliderThemeData(
                                trackHeight: 2,
                                thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
                                overlayShape: RoundSliderOverlayShape(overlayRadius: 12),
                              ),
                              child: Slider(
                                value: _position.inSeconds.toDouble(),
                                max: _duration.inSeconds.toDouble() > 0
                                    ? _duration.inSeconds.toDouble()
                                    : 1,
                                activeColor: Colors.white,
                                inactiveColor: Colors.white.withOpacity(0.3),
                                onChanged: (value) async {
                                  await _audioPlayer.seek(Duration(seconds: value.toInt()));
                                },
                              ),
                            ),
                          ),
                          Text(
                            _formatDuration(_duration),
                            style: GoogleFonts.roboto(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                          SizedBox(width: 10),
                          GestureDetector(
                            onTap: () {
                              if (_isPlaying) {
                                _pauseAudio();
                              } else {
                                _playAudio();
                              }
                            },
                            child: Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 8,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Icon(
                                _isPlaying ? Icons.pause : Icons.play_arrow,
                                color: Color(0xFF00BCD4),
                                size: 15,
                              ),
                            ),
                          ),
                          SizedBox(width: 10),
                          CircleAvatar(
                            radius: 17,
                            backgroundColor: Colors.white,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              constraints: BoxConstraints(),
                              icon: Icon(Icons.check, color: Colors.red),
                              onPressed: _hideContainer,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          )
        : SizedBox.shrink(); 
  }
  
  // Check if gospel reading text exists and is not empty
  if (_audioData != null && 
      _audioData!.cGospelReadingText != null && 
      _audioData!.cGospelReadingText!.isNotEmpty) {
    // Show gospel reading text
    return Container(
      height: 135,
      width: 330,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // if (_audioData!.cChapterNo != null && _audioData!.cChapterNo!.isNotEmpty)
              //   Text(
              //     _audioData!.cChapterNo!,
              //     style: GoogleFonts.roboto(
              //       color: Colors.black87,
              //       fontWeight: FontWeight.bold,
              //       fontSize: 13,
              //     ),
              //   ),
              // if (_audioData!.cChapterDetails != null && _audioData!.cChapterDetails!.isNotEmpty)
              //   Padding(
              //     padding: const EdgeInsets.only(top: 4.0),
              //     child: Text(
              //       _audioData!.cChapterDetails!,
              //       style: GoogleFonts.roboto(
              //         color: Colors.black54,
              //         fontSize: 11,
              //         fontStyle: FontStyle.normal,
              //       ),
              //     ),
              //   ),
              SizedBox(height: 8),
              Text(
                _audioData!.cGospelReadingText!,
                style: GoogleFonts.roboto(
                  color: Colors.black,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  height: 1.5,
                ),
                textAlign: TextAlign.justify,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Both are null/empty - show default Bible verse
  return Container(
    height: 135,
    width: 330,
    decoration: BoxDecoration(
      color: Colors.grey[100],
      borderRadius: BorderRadius.circular(20),
    ),
    child: Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          '"And we know that in all things God works for the good of those who love him, who have been called according to his purpose."\n(Romans 8:28)',
          style: GoogleFonts.roboto(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    ),
  );
}
}