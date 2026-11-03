import 'dart:async';
import 'package:Koottaayma/FIREBASESERVICE/notificationservice.dart';
import 'package:Koottaayma/HOMEPAGEICONS/bible.dart';
import 'package:Koottaayma/HOMEPAGEICONS/calender.dart';
import 'package:Koottaayma/HOMEPAGEICONS/connect.dart';
import 'package:Koottaayma/HOMEPAGEICONS/events.dart';
import 'package:Koottaayma/HOMEPAGEICONS/group.dart';
import 'package:Koottaayma/HOMEPAGEICONS/holymass.dart';
import 'package:Koottaayma/HOMEPAGEICONS/japamala.dart';
import 'package:Koottaayma/HOMEPAGEICONS/karunayudekontha.dart';
import 'package:Koottaayma/HOMEPAGEICONS/kurishinttevazhi.dart';
import 'package:Koottaayma/HOMEPAGEICONS/live.dart';
import 'package:Koottaayma/HOMEPAGEICONS/madhyasthaprarthana.dart';
import 'package:Koottaayma/HOMEPAGEICONS/notepad.dart';
import 'package:Koottaayma/HTTPURL/formatdate.dart';
import 'package:Koottaayma/HTTPURL/httpurl.dart';
import 'package:Koottaayma/NOTABLEPERSONS/notablepersonwidget.dart';
import 'package:Koottaayma/SQFLITEVERSION1/DataBaseHelper.dart';
import 'package:Koottaayma/USER%20FOLDER/baptismnotificationdetails.dart';
import 'package:Koottaayma/USER%20FOLDER/notificationalerthomepage.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

class NotificationIconWithBadge extends StatefulWidget {
  final VoidCallback? onTap;
  final Color iconColor;
  final double iconSize;

  const NotificationIconWithBadge({
    Key? key,
    this.onTap,
    this.iconColor = const Color.fromARGB(255, 40, 141, 161),
    this.iconSize = 28,
  }) : super(key: key);

  @override
  State<NotificationIconWithBadge> createState() => _NotificationIconWithBadgeState();
}

class _NotificationIconWithBadgeState extends State<NotificationIconWithBadge> {
  int baptismCount = 0;

  @override
  void initState() {
    super.initState();
    _loadBaptismCount();
  }

  Future<void> _loadBaptismCount() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      setState(() {
        baptismCount = prefs.getInt('baptismCount') ?? 0;
      });
      print('Loaded baptism count: $baptismCount');
    } catch (e) {
      print('Error loading baptism count: $e');
    }
  }

  Future<void> updateCount(int newCount) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setInt('baptismCount', newCount);
      setState(() {
        baptismCount = newCount;
      });
      print('Updated baptism count to: $baptismCount');
    } catch (e) {
      print('Error updating baptism count: $e');
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
          if (baptismCount > 0)
            Positioned(
              right: -6,
              top: -4,
              child: Container(
                padding: EdgeInsets.all(baptismCount > 9 ? 4 : 5),
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 1.5,
                  ),
                ),
                constraints: BoxConstraints(
                  minWidth: baptismCount > 9 ? 20 : 18,
                  minHeight: baptismCount > 9 ? 20 : 18,
                ),
                child: Center(
                  child: Text(
                    baptismCount > 99 ? '99+' : baptismCount.toString(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: baptismCount > 9 ? 9 : 10,
                      fontWeight: FontWeight.bold,
                      height: 1,
                    ),
                    textAlign: TextAlign.center,
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

class HomePage extends StatefulWidget {
  int? languageId;
  int? phoneNumber;
  int? nUserTypeID;
  HomePage({super.key, this.languageId, this.nUserTypeID, this.phoneNumber});

  @override
  State<HomePage> createState() => _HomePageState();
  
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
   
  bool _expanded = false;
   bool _isLoading = true;
  bool _showUpdateButton = false;
  String _message = '';
  String _updateStatus = '';
  bool _isUpdating = false;
  final AudioPlayer _audioPlayer = AudioPlayer();
  AudioModel? _audioData;
  bool _isPlaying = false;
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
  String? logoPath;
    List<Map<String, dynamic>> readings = [];
 List<Map<String, dynamic>> specialPrograms = [];
List<Map<String, dynamic>> holyMassPrograms = [];
 final DatabaseHelper dbHelper = DatabaseHelper();
  List<String>Names=['St Marys','Vizhinjam Old Portuguese Church','St Josephs Shrine','St ','St Marys'];
 // List<String>images=['assets/poster5.jpg','assets/poster6.jpg','assets/poster.jpg','assets/poster2.jpg','assets/poster4.jpg',];
   List<String>Times=['10:00 AM -12:00 PM','8:00 AM -10:00 PM','6:00 AM -9:00 AM','10:00 AM -12:30 PM ','10:00 AM -12:00 PM'];
  final GlobalKey<_NotificationIconWithBadgeState> _notificationKey = 
      GlobalKey<_NotificationIconWithBadgeState>();
 int? userPhoneNumber;
  Map<String, String> churchLogoMap = {};
  final ScrollController _scrollController = ScrollController();
  // Timer? _timer;
  int _currentIndex = 0;
  final int _totalItems = 6; // 1 audio player + 5 other items
final List<String> videos = [
  'assets/video3.mp4',
  'assets/video2.mp4',
  'assets/video3.mp4',
  'assets/video4.mp4',
  'assets/video5.mp4',
];
 bool _showVideo = false;
 
 // Timer? _pollingTimer;

  // Track already-shown messages to avoid re-showing
 // final Set<String> _shownKeys = {};
 // final MessageService _messageService = MessageService();
  bool _isPopupVisible = false;
  @override
  void initState() {
  super.initState();
  
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(seconds: 2));
      NotificationService().checkPendingAfterLogin();
    });
    // Initial fetch of approved messages 
  
    // NotificationService().onPriestMessage = (data) {

    //   WidgetsBinding.instance.addPostFrameCallback((_) {

    //     if (mounted) {
    //       NotificationPopup.show(context, data);
    //     }

    //   });
    // };

    // // INIT FCM
    // NotificationService().init();
  
    
  
 // WidgetsBinding.instance.addObserver(this);
  
  // _messageService.init().then((_) {
  //   print(' init() completed, calling checkForNewMessages');
  //   checkForNewMessages();
  // }).catchError((e) {
  //   print(' init() FAILED: $e'); 
  // });
     // Start polling automatically when home page loads
   // _startPolling();
  _loadNotifications();
  // _fetchNotificationAlert(); 
    _loadVisibility();
      // _scrollController = ScrollController();
  //  _startAutoScroll();
    
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    
     _loadAudioData();
     _initializeSpecialPrograms();
     _initializeGospelReadings();
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


    // Show video after 5 seconds
     Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _showVideo = true;
        });
        
        // Auto-scroll to show the video after a brief delay
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted && _scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            );
          }
        });
      }
    }); 
  }


  // void _startAutoScroll() {
  //   _timer = Timer.periodic(Duration(seconds: 3), (timer) {
  //     if (_scrollController.hasClients) {
  //       double itemWidth = MediaQuery.of(context).size.width * 0.95;
        
  //       if (_currentIndex < _totalItems - 1) {
  //         _currentIndex++;
  //       } else {
  //         _currentIndex = 0;
  //       }
        
  //       _scrollController.animateTo(
  //         _currentIndex * itemWidth,
  //         duration: Duration(milliseconds: 500),
  //         curve: Curves.easeInOut,
  //       );
  //     }
  //   });
  // }
  

//load notifications functions import from the file notificationalerthomepage.dart page


  Future<void> _loadNotifications() async {
  await fetchNotificationAlert(
    dbHelper: dbHelper,
    onUpdateButton: (show) => setState(() => _showUpdateButton = show),
    onError: (msg) => setState(() => _message = msg),
    onFinally: () => setState(() => _isLoading = false),
  );
}

//toadyverse from sqlite fetching
Future<void> _initializeGospelReadings() async {
  await _getUserPhoneNumber();
  await  loadGospelReadings();
}



Future<void> loadGospelReadings() async {
  
  setState(() => _isLoading = true);

  try {
    // Get phone number from SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? phoneNumber = prefs.getInt('phone_number'); 
    
    if (phoneNumber == null) {
      print('No phone number found in SharedPreferences');
      setState(() => _isLoading = false);
      return;
    }

    // Fetch from SQLite instead of backend
     final db = await dbHelper.database;
      // Make sure you have access to your database instance
    
    final maps = await db.query(
      'today_verse_cache', 
      where: 'phone_number = ?',
      whereArgs: [phoneNumber],
    );

    print('SQLite query returned ${maps.length} rows');

    if (maps.isNotEmpty) {
      // Parse the cached JSON data
      final cachedData = jsonDecode(maps.first['audio_data'] as String);
      
      print('Cached data: $cachedData');
   
      setState(() {
        _audioData = AudioModel.fromJson(cachedData);
        _isLoading = false;
      });
      
      print('Audio data loaded: ${_audioData?.cUploadedPath}');
      print('Audio data null? ${_audioData == null}');
      print('Audio path null? ${_audioData?.cUploadedPath == null}');
      
      await _checkFirstTime();
    } else {
      print('No cached audio data found for phone number: $phoneNumber');
      setState(() => _isLoading = false);
    }
    
  } catch (e, stackTrace) {
    print('Error loading audio from SQLite: $e');
    print('StackTrace: $stackTrace');
    setState(() => _isLoading = false);
  }
}


 Future<void> _initializeSpecialPrograms() async {
  await _getUserPhoneNumber();
  await loadChurchData();
}

// Update your _getUserPhoneNumber method:
Future<void> _getUserPhoneNumber() async {
  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? phone = prefs.getString('userPhone');
    if (phone != null) {
      setState(() {
        userPhoneNumber = int.tryParse(phone);
      });
      print('User phone number: $userPhoneNumber');
    } else {
      print('No user phone number found in SharedPreferences');
    }
  } catch (e) {
    print('Error getting user phone: $e');
  }
}
//athira aaa aaaa aaaa aaa aaaaaaa
Future<void> loadChurchData({List<dynamic>? freshData}) async {
  try {
    setState(() => isLoading = true);

    final DatabaseHelper dbHelper = DatabaseHelper();
    List<dynamic>? cachedData;

    if (freshData != null && freshData.isNotEmpty) {
      cachedData = freshData;

      // Save with phone number if logged in, else guest key 0
      await dbHelper.saveChurchDetails(
        phoneNumber: userPhoneNumber ?? 0,
        churchData: jsonEncode(cachedData),
      );

    } else {
      // Try logged in user's data first
      if (userPhoneNumber != null) {
        cachedData = await dbHelper.getCachedChurchDetails(userPhoneNumber!);
      }

      // Not logged in or no data — try guest key
      if (cachedData == null || cachedData.isEmpty) {
        cachedData = await dbHelper.getCachedChurchDetails(0);
      }

      // Still nothing and logged in — fetch from API
      if ((cachedData == null || cachedData.isEmpty) && userPhoneNumber != null) {
        print('Cache miss — fetching from API...');
        cachedData = await _fetchHomeDataFromAPI();

        if (cachedData != null && cachedData.isNotEmpty) {
          await dbHelper.saveChurchDetails(
            phoneNumber: userPhoneNumber!,
            churchData: jsonEncode(cachedData),
          );
        }
      }
    }

    // ── Process and filter by today
    if (cachedData != null && cachedData.isNotEmpty) {
      List<Map<String, dynamic>> allSpecialPrograms = [];
      List<Map<String, dynamic>> allHolyMass = [];

      final today = DateTime.now();
      final todayStr = DateFormat('yyyy-MM-dd').format(today);

      for (var churchDetails in cachedData) {
        final List<dynamic> programs = churchDetails['SpecialPrograms'] ?? [];
        final List<dynamic> holyMass = churchDetails['HolyMass'] ?? [];
        final String churchLogo = churchDetails['cLogoPath'] ?? '';

        for (var program in programs) {
          final endDateStr = program['dEndDate'] ?? '';
          if (endDateStr.isNotEmpty) {
            final parts = endDateStr.split('-');
            if (parts.length == 3) {
              final converted = '${parts[2]}-${parts[1]}-${parts[0]}';
              if (converted == todayStr) {
                final programMap = Map<String, dynamic>.from(program);
                programMap['_churchLogo'] = churchLogo;
                allSpecialPrograms.add(programMap);
              }
            }
          }
        }

        for (var mass in holyMass) {
          final massDate = mass['dDate'] ?? '';
          if (massDate == todayStr) {
            final massMap = Map<String, dynamic>.from(mass);
            massMap['_churchLogo'] = churchLogo;
            allHolyMass.add(massMap);
          }
        }
      }

      allSpecialPrograms.sort((a, b) {
        try {
          return _parseSpecialProgramDate(a['dStartDate'])
              .compareTo(_parseSpecialProgramDate(b['dStartDate']));
        } catch (_) { return 0; }
      });

      allHolyMass.sort((a, b) {
        try {
          return _parseHolyMassDateTime(a['dDate'], a['dStartTime'])
              .compareTo(_parseHolyMassDateTime(b['dDate'], b['dStartTime']));
        } catch (_) { return 0; }
      });

      setState(() {
        specialPrograms = allSpecialPrograms;
        holyMassPrograms = allHolyMass;
        isLoading = false;
      });

      print('Loaded ${holyMassPrograms.length} holy mass, ${specialPrograms.length} special programs');
    } else {
      setState(() => isLoading = false);
    }
  } catch (e) {
    print('Error in loadChurchData: $e');
    setState(() => isLoading = false);
  }
}

Future<List<Map<String, dynamic>>?> _fetchHomeDataFromAPI() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt') ?? '';
    if (token.isEmpty) return null;

    final response = await http.get(
      Uri.parse(
       ConnectChurchSelectionAPI,),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': token,
      },
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    return null;
  } catch (e) {
    print(' API fallback failed: $e');
    return null;
  }
}

// Parse Special Program date format: "09-02-2026" (DD-MM-YYYY)
DateTime _parseSpecialProgramDate(String? dateStr) {
  if (dateStr == null || dateStr.isEmpty) return DateTime.now();
  
  final parts = dateStr.split('-');
  if (parts.length != 3) return DateTime.now();
  
  return DateTime(
    int.parse(parts[2]), // Year
    int.parse(parts[1]), // Month
    int.parse(parts[0]), // Day
  );
}

// Parse Holy Mass date and time: "2026-02-11" + "12:00:00"
DateTime _parseHolyMassDateTime(String? dateStr, String? timeStr) {
  if (dateStr == null || dateStr.isEmpty) return DateTime.now();
  
  final date = DateTime.parse(dateStr); // ISO format works directly
  
  if (timeStr != null && timeStr.isNotEmpty) {
    final timeParts = timeStr.split(':');
    if (timeParts.length >= 2) {
      return DateTime(
        date.year,
        date.month,
        date.day,
        int.parse(timeParts[0]), // Hour
        int.parse(timeParts[1]), // Minute
        timeParts.length > 2 ? int.parse(timeParts[2]) : 0, // Second
      );
    }
  }
  
  return date;
}

// Helper method to parse date/time combinations
DateTime _parseDateTime(Map<String, dynamic> mass) {
  // Adjust these field names to match your actual data structure
  final date = mass['date'] ?? mass['massDate'] ?? DateTime.now().toString();
  final time = mass['time'] ?? mass['massTime'] ?? '00:00';
  
  final dateObj = DateTime.parse(date);
  final timeParts = time.split(':');
  
  return DateTime(
    dateObj.year,
    dateObj.month,
    dateObj.day,
    int.parse(timeParts[0]),
    int.parse(timeParts[1]),
  );
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
    //  _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }


List<dynamic> meetingNotifications = [];
List<dynamic> deathNotifications = [];
List<dynamic> priestMessages = [];

Future<void> fetchBaptismDetails({bool showMeetingDialog = true}) async {
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
    
    print('Checking SQLite for family members...');
    final hasCachedData = false;
    
    if (hasCachedData) {
      // Load from SQLite
    } else {
      print('No cached data, fetching from backend...');
      await _fetchFromBackend(phoneNumber, savedToken, showMeetingDialog: showMeetingDialog);
    }
  } catch (e) {
    print('Error in fetchUserProfile: $e');
    setState(() {
      isLoading = false;
      errorMessage: 'Error: ${e.toString()}';
    });
  }
}

Future<void> _fetchFromBackend(String phoneNumber, String? savedToken, {bool showMeetingDialog = true}) async {
  setState(() {
    isLoadingFromBackend = true;
  });

  try {
    var response = await http.post(
      Uri.parse(NotificationsList),
      headers: {
        'Content-Type': 'application/json',
        if (savedToken != null) 'Authorization': ' $savedToken',
      },
      body: jsonEncode({
        'nPhoneNo': phoneNumber,
        'jwt': savedToken,
      }),
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
      List<dynamic> meetings = [];
      List<dynamic> deathDetails = [];
      List<dynamic> approvalRequestDetails = []; 

      if (responseData is Map) {
        if (responseData.containsKey('lstRequestDetails')) {
          members = responseData['lstRequestDetails'] ?? [];
        }
        if (responseData.containsKey('lstMeeting')) {
          meetings = responseData['lstMeeting'] ?? [];
        }
        if (responseData.containsKey('lstdeathdetails')) {
          deathDetails = responseData['lstdeathdetails'] ?? [];
        }
        if (responseData.containsKey('lstapprovalrequestdetails')) {
          approvalRequestDetails = responseData['lstapprovalrequestdetails'] ?? [];
        }

        // Only fallback if NONE of the known keys exist
        if (!responseData.containsKey('lstRequestDetails') &&
            !responseData.containsKey('lstMeeting') &&
            !responseData.containsKey('lstdeathdetails') &&
            !responseData.containsKey('lstapprovalrequestdetails')) { 
          members = [responseData];
        }
      } else if (responseData is List) {
        members = responseData;
      }

      if (members.isNotEmpty) {
        print('Saving ${members.length} members to SQLite...');
        print('Would save to SQLite here');
      }

      if (deathDetails.isNotEmpty) {
        print('Death details received: ${deathDetails.length} record(s)');
      }

      if (approvalRequestDetails.isNotEmpty) {
        print('Priest messages received: ${approvalRequestDetails.length} record(s)');
      }

      setState(() {
        baptismProfiles = members;
        baptismNotifications = members;
        meetingNotifications = meetings;
        deathNotifications = deathDetails;
        priestMessages = approvalRequestDetails; 
        isLoading = false;
        isLoadingFromBackend = false;
        dataSource = 'backend';
      });

      _notificationKey.currentState?.updateCount(
        members.length + meetings.length + deathDetails.length + approvalRequestDetails.length, 
      );

      // Show meeting notification dialog
      if (meetings.isNotEmpty && showMeetingDialog) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showMeetingNotificationDialog(context, meetings);
        });
      }

      // Show death notification dialog
      if (deathDetails.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showDeathNotificationDialog(context, deathDetails);
        });
      }

      //  Added — Show priest message dialog
      // if (approvalRequestDetails.isNotEmpty) {
      //   WidgetsBinding.instance.addPostFrameCallback((_) {
      //     _showPriestMessageDialog(context, approvalRequestDetails);
      //   });
      // }

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
// void _showPriestMessageDialog(BuildContext context, List<dynamic> messages) {
//   showDialog(
//     context: context,
//     builder: (context) => AlertDialog(
//       title: const Row(
//         children: [
//           Icon(Icons.message, color: Colors.deepPurple),
//           SizedBox(width: 8),
//           Text('Message from Priest'),
//         ],
//       ),
//       content: SizedBox(
//           width: double.maxFinite,
//           child: ListView.separated(
//             shrinkWrap: true,
//             itemCount: messages.length,
//             separatorBuilder: (_, __) => const Divider(height: 24),
//             itemBuilder: (context, index) {
//               final item = messages[index];
//               return _MessageItem(
//                 item: item['cUploadedPath'] ?? '',
//                 date: item['dDate'] ?? '',
//               );
//             },
//           ),
//         ),

//       actions: [
//         TextButton(
//           onPressed: () => Navigator.of(context).pop(),
//           child: const Text('OK'),
//         ),
//       ],
//     ),
//   );
// }
Future<void> _showDeathNotificationDialog(
  BuildContext context,
  List<dynamic> deathDetails,
) async {
  // 1. Get already-seen IDs from device storage
  final seenIds = await ObituarySeenHelper.getSeenIds();

  // 2. Filter out obituaries the user has already dismissed
  final unseen = deathDetails.where((detail) {
    final id = (detail['nDeathID'] ?? detail['cFullName'] ?? '').toString().trim();
    return id.isNotEmpty && !seenIds.contains(id);
  }).toList();

  // 3. Only show dialog if there are new unseen obituaries
  if (unseen.isEmpty) return;

  if (context.mounted) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      builder: (context) => _ObituaryDialog(deathDetails: unseen),
    );
  }
}


void _showMeetingNotificationDialog(BuildContext context, List<dynamic> meetings) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 340,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue[700]!, Colors.blue[500]!],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.event_available,
                      color: Colors.blue[700],
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Priest Meeting',
                          style: GoogleFonts.roboto(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'We are scheduled for a meeting concerning your baptism request.',
                          style: GoogleFonts.roboto(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Meeting details
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.2)),
              ),
              child: Column(
                children: meetings.map((meeting) {
                  String meetingDateTime = meeting['MeetingDateTime'] ?? 'N/A';
                    String applicationCode = meeting['cApplicationCode'] ?? 'N/A';
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.access_time,
                            color: Colors.blue[700],
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Meeting Time',
                                style: GoogleFonts.roboto(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                meetingDateTime,
                                style: GoogleFonts.roboto(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[900],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: Colors.blue[700]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Dismiss',
                      style: GoogleFonts.roboto(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      // You can add calendar integration here if needed
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: Colors.blue[700],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Got It',
                      style: GoogleFonts.roboto(
                        fontSize: 14,
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
    ),
  );
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
                      'Notifications',
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
            
            // Check if both are empty
            (baptismNotifications.isEmpty && meetingNotifications.isEmpty)
                ? Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'No notifications found',
                      style: GoogleFonts.roboto(fontSize: 14, color: Colors.grey),
                    ),
                  )
                : SizedBox(
                    height: 400,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Meeting Notifications Section
                          if (meetingNotifications.isNotEmpty) ...[
                            Text(
                              'Meeting Scheduled',
                              style: GoogleFonts.roboto(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[800],
                              ),
                            ),
                            const SizedBox(height: 12),
                            ...meetingNotifications.map((meeting) {
                              String meetingDateTime = meeting['MeetingDateTime'] ?? 'N/A';
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.pop(context);
                                    _showMeetingNotificationDialog(context, [meeting]);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.blue.withOpacity(0.1),
                                          Colors.blue.withOpacity(0.05)
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Icon(
                                            Icons.event_available,
                                            color: Colors.blue[700],
                                            size: 24,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Priest Meeting',
                                                style: GoogleFonts.roboto(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.blue[800],
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                                                  const SizedBox(width: 4),
                                                  Expanded(
                                                    child: Text(
                                                      meetingDateTime,
                                                      style: GoogleFonts.roboto(
                                                        fontSize: 12,
                                                        color: Colors.grey[700],
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        Icon(Icons.arrow_forward_ios, size: 16, color: Colors.blue[700]),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                            const SizedBox(height: 16),
                          ],
                          
                          // Baptism Notifications Section
                          if (baptismNotifications.isNotEmpty) ...[
                            Text(
                              'Baptism Requests',
                              style: GoogleFonts.roboto(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.cyan[800],
                              ),
                            ),
                            const SizedBox(height: 12),
                            ...baptismNotifications.map((notification) {
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
                                          Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Icon(
                                              Icons.child_care,
                                              color: Colors.cyan[700],
                                              size: 18,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Text(
                                                      notification['cName'] ?? 'N/A',
                                                      style: GoogleFonts.roboto(
                                                        fontSize: 14,
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.cyan[800],
                                                      ),
                                                    ),
                                                    Text(
                                                  "${notification['cApplicationCode'] ?? 'N/A'}",
                                                  style: GoogleFonts.roboto(fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black),
                                                ),
                                                  ],
                                                ),
                                                Text(
                                                  "Father: ${notification['cFatherName'] ?? 'N/A'}",
                                                  style: GoogleFonts.roboto(fontSize: 12),
                                                ),
                                                Text(
                                                  "Mother: ${notification['cMotherName'] ?? 'N/A'}",
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
                                          Container(
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
                                            child: Row(
                                              children: [
                                                Icon(Icons.calendar_today, size: 12, color: Colors.white),
                                                const SizedBox(width: 4),
                                              Text(
                                                                                 notification['dBaptismDate'] != null
                                            ? DateFormat('d MMM yyyy')
                                               .format(DateTime.parse(notification['dBaptismDate'])) : 'N/A',
                                              style: GoogleFonts.roboto(
                                                  fontSize: 12,
                                               color: Colors.white,
                                                           ),
                                            
                                                ),
                                              ],
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: () async {
                                              Navigator.pop(context);
                                              
                                              final result = await Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) => BaptismNotificationDetails(
                                                    baptismData: notification,
                                                  ),
                                                ),
                                              );
                                              
                                              if (result == true) {
                                                await fetchBaptismDetails(showMeetingDialog: false);
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
                          ],
                        ],
                      ),
                    ),
                  ),
          ],
        ),
      ),
    ),
  );
}

 Future<bool> _showExitDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Exit App'),
            content: const Text('Are you sure you want to exit the app?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Yes'),
              ),
            ],
          ),
        ) ??
        false;
  }
  @override
  Widget build(BuildContext context) {
     return PopScope(
      canPop: false, // BLOCK system back
      onPopInvoked: (didPop) async {
        if (didPop) return;

        final exit = await _showExitDialog(context);
        if (exit) {
          // Closes the app
          SystemNavigator.pop();
        }
      },
    child:  Scaffold(
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
                SizedBox(height: 25),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SearchBar(
                    leading: GestureDetector(
                      // onTap: () {
                      //   Navigator.push(context, MaterialPageRoute(builder:  (context) => AlarmRingingScreen(alarmId: 1,),));
                      // },
                      child: Icon(Icons.alarm_add,color: const Color.fromARGB(255, 25, 131, 145),)),
                    hintText: 'Search...',
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.search,
                    trailing: [
                      IconButton(
                        onPressed: () {},
                        icon: Icon(Icons.search),
                      ),
                    
                     NotificationIconWithBadge(
                    key: _notificationKey,
                     iconColor: const Color.fromARGB(255, 40, 141, 161),
                     iconSize: 28,
                     onTap: () async {
                     print('Notification icon pressed');
                     print('Current baptism notifications count: ${baptismNotifications.length}');
                     print('Current meeting notifications count: ${meetingNotifications.length}');
    
    // Fetch latest data without showing automatic meeting dialog
    await fetchBaptismDetails(showMeetingDialog: false);
    
    if (mounted) {
      // Show combined notification dialog with both baptism and meeting notifications
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
        SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      child: Row(
      children: [
        // Audio Player
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.95,
          child: _buildAudioPlayer(),
        ),
        
        // Video Player - shows after 5 seconds
        // if (_showVideo)
        //   ...List.generate(1, (index) {
        //     return Container(
        //       width: MediaQuery.of(context).size.width * 0.95,
        //       height: 135,
        //       margin: const EdgeInsets.all(8),
        //       decoration: BoxDecoration(
        //         color: Colors.white,
        //         borderRadius: BorderRadius.circular(20),
        //       ),
        //       child: ClipRRect(
        //         borderRadius: BorderRadius.circular(20),
        //         child: VideoPlayerItem(
        //           videoPath: videos[index],
        //         ),
        //       ),
        //     );
        //   }),


       // if (_showVideo)
 // const NotablePersonsWidget(),//notable person widget imported from another file
      ],
    ),
    ),
Padding(
  padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Text(
      //   'Select your choice',
      //    style: GoogleFonts.roboto(
      //             fontSize: 18,
      //             fontWeight: FontWeight.bold,
      //             color: Colors.black
      //           ),
      // ),
      SizedBox(height: 10),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 8),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 176, 240, 249), // same as homepage
          borderRadius: BorderRadius.circular(10),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
           
              GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => MyJapamalaPage(),));
                },
                child: _buildpreferenceButton('assets/van4.png', 'ജപമാല')),
                   GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => Padapooja(),));
                    },
                    child: _buildpreferenceButton('assets/prayer5.png', 'മധ്യസ്ത പ്രാർത്ഥന')),
             // SizedBox(width: 5),
                GestureDetector(
                onTap: () {
                  Navigator.push(context,MaterialPageRoute(builder: (context) => KurishintteVazhiPage(),));
                },
                child: _buildpreferenceButton('assets/cross4.png', 'കുരിശിന്റെ വഴി')),
              GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => Karunayudekontha(),));
                },
                child: _buildpreferenceButton('assets/karuna.png', 'കരുണയുടെ കൊന്ത')),
           //   SizedBox(width: 5),
            
            //  SizedBox(width: 5),
           
               
              //        GestureDetector(
              //   // onTap: () {
              //   //   Navigator.push(context, MaterialPageRoute(builder: (context) => SaintPage()));
              //   // },
              //   child: _buildpreferenceButton('assets/prayer5.png', 'ദിവ്യകാരുണ്യ പ്രാർത്ഥന'),
              // ),
          //    SizedBox(width: 5),

            ],
          ),
        ),
      ),
    ],
  ),
),
                    SizedBox(height: 7),

                    Container(
                      height: 200,
                      width: 370,
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 176, 240, 249),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(15.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Row(
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
                                Navigator.push(context, MaterialPageRoute(builder:(context) => MyLivePage(),));
                                        },
                                child: _buildIconButton('assets/icon3.png', 'Live')),
                                GestureDetector(
                                   onTap: () {
                             Navigator.push(context,MaterialPageRoute(builder: (context) => CalenderDatesDetails(),));
                                        },
                                  child: _buildIconButton('assets/icon4.png', 'Calender')),
                              ],
                            ),
                            Row(
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
                                onTap: () async {
                                final result = await Navigator.push(
                                   context,MaterialPageRoute(builder: (context) => ConnectPage()),);
                             print(' Result from ConnectPage: $result');
                             print(' Result type: ${result.runtimeType}');

                            if (result != null && result is List && result.isNotEmpty) {
                            print(' Calling loadChurchData with ${result.length} items');
                            await loadChurchData(freshData: result);
                            } else {
                              print(' Result is null/empty — data not passed correctly');
                                    }
                                       },
                              child: _buildIconButton('assets/icon7.png', 'Connect'),
                                 ),
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
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                buildCombinedPrograms(),

                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),);
  }
// Combined widget that shows both sections in one ListView
Widget buildCombinedPrograms() {
  print(' buildCombinedPrograms called — holyMass: ${holyMassPrograms.length}, special: ${specialPrograms.length}');
  if (holyMassPrograms.isEmpty && specialPrograms.isEmpty) {
    return SizedBox.shrink();
  }
  
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Title only if Holy Mass programs exist
     
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Today Programs',
                style: GoogleFonts.roboto(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(context,MaterialPageRoute(builder: (context) => CalenderDatesDetails(),));
                },
                child: Text(
                  'More',
                  style: GoogleFonts.roboto(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black
                
                  ),
                ),
              ),
            ],
          ),
        ),
      // Single horizontal ListView with all cards
      Container(
        height: 150,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.only(left: 8),
          itemCount: holyMassPrograms.length + specialPrograms.length,
          itemBuilder: (context, index) {
            // Holy Mass cards
            if (index < holyMassPrograms.length) {
              return buildHolyMassCard(holyMassPrograms[index]);
            }
            
            // Special Program cards
            int specialIndex = index - holyMassPrograms.length;
            return buildSpecialProgramCard(specialPrograms[specialIndex]);
          },
        ),
      ),
    ],
  );
}
// Extract card building logic
Widget buildHolyMassCard(Map<String, dynamic> holyMass) {
  final churchName = holyMass['cChurchName'] ?? '';
  final programmeName = holyMass['cProgrammeeName'] ?? '';
  final startTime = holyMass['dStartTime'] ?? '';
  final date = holyMass['dDate'] ?? '';
  final churchLogo = holyMass['_churchLogo'] ?? '';

  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: Container(
      width: 350,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.fromARGB(255, 6, 90, 186),
            Color.fromARGB(255, 157, 157, 234),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Church Logo
            if (churchLogo.isNotEmpty)
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.network(
                    churchLogo,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Icon(Icons.church, color: Colors.grey, size: 30),
                  ),
                ),
              ),

            SizedBox(width: 12),

            //  Expanded fixes the invisible text issue
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    churchName,
                    style: GoogleFonts.roboto(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    programmeName,
                    style: GoogleFonts.roboto(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          DateFormatter.formatDateWithDay(date),
                          style: GoogleFonts.roboto(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.access_time, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text(
                        DateFormatter.formatTimeWithAmPm(startTime),
                        style: GoogleFonts.roboto(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// 4. Update buildSpecialProgramCard - get logo from program data
Widget buildSpecialProgramCard(Map<String, dynamic> program) {
  final imageUrl = program['cImagePath'] ?? '';
  final message = program['cMessageText'] ?? 'Special Program';
  final startDate = program['dStartDate'] ?? '';
  final endDate = program['dEndDate'] ?? '';
  
  // Get logo attached to this specific program
  final churchLogo = program['_churchLogo'] ?? '';
  
  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: Container(
      width: 320,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.grey[300],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Background image
            if (imageUrl.isNotEmpty)
              Positioned.fill(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(color: Colors.grey[300]);
                  },
                ),
              ),
            
            // Gradient overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.3),
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
              ),
            ),
            
            // Content
            Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (churchLogo.isNotEmpty)
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 3,
                        ),
                        color: Colors.grey[200],
                        // boxShadow: [
                        //   BoxShadow(
                        //     color: Colors.black.withOpacity(0.3),
                        //     blurRadius: 8,
                        //     offset: Offset(0, 2),
                        //   ),
                        // ],
                      ),
                      child: ClipOval(
                        child: Image.network(
                          churchLogo,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(Icons.church, color: Colors.grey, size: 30);
                          },
                        ),
                      ),
                    ),
                  
                  Spacer(),
                  
                  Row(
                    children: [
                      Text(
                        message,
                        style: GoogleFonts.roboto(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                    ],
                  ),
                  SizedBox(height: 4),
                  
                  Row(
                    children: [
                      Icon(Icons.calendar_today, color: Colors.white70, size: 14),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '$startDate - $endDate',
                          style: GoogleFonts.roboto(
                            fontSize: 13,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
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
          backgroundColor: const Color.fromARGB(255, 176, 240, 249),
          child: Image.asset(assetPath, scale: 2),
        ),
        Text(label, style: GoogleFonts.lexend(fontSize: 12)),
      ],
    );
  }

Widget _buildpreferenceButton(String assetPaths, String labels) {
  return SizedBox(
    width: 70,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 25,
          backgroundColor: const Color.fromARGB(255, 176, 240, 249),
          child: Image.asset(assetPaths, scale: 2),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 36, 
          child: Text(
            labels,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.lexend(fontSize: 10),
          ),
        ),
      ],
    ),
  );
}
 Widget _buildAudioPlayer() {
  if (_isLoading) {
    return Container(
      height: 135,
      width: 350,
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
        ? Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
              height: 135,
              width: 370,
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
                                    DateFormatter.formatDateWithDay(_audioData?.dDate),
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
            ),
        )
        : SizedBox.shrink(); 
  }
  
  // Check if gospel reading text exists and is not empty
  if (_audioData != null && 
      _audioData!.cGospelReadingText != null && 
      _audioData!.cGospelReadingText!.isNotEmpty) {
    // Show gospel reading text
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        height: 135,
        width: 370,
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
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.justify,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  // Both are null/empty - show default Bible verse
  return Container(
    height: 135,
    width: 370,
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


class VideoPlayerItem extends StatefulWidget {
  final String videoPath;

  const VideoPlayerItem({required this.videoPath});

  @override
  _VideoPlayerItemState createState() => _VideoPlayerItemState();
}

class _VideoPlayerItemState extends State<VideoPlayerItem> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset(widget.videoPath)
      ..initialize().then((_) => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openFullscreenVideo() {
    _controller.play();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FullscreenVideoPlayer(controller: _controller),
      ),
    ).then((_) {
      // Pause video when returning from fullscreen
      _controller.pause();
    });
  }

  @override
  Widget build(BuildContext context) {
    return _controller.value.isInitialized
        ? GestureDetector(
            onTap: _openFullscreenVideo,
            child: Stack(
              alignment: Alignment.center,
              children: [
              SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(  
                    width: _controller.value.size.width,
                    height: _controller.value.size.height,
                    child: VideoPlayer(_controller),
                  ),
                ),
              ),
                Icon(
                  Icons.play_circle_outline,
                  size: 50,
                  color: Colors.white,
                ),
              ],
            ),
          )
        : Center(child: CircularProgressIndicator());
  }
}

// Fullscreen Video Player Widget
class FullscreenVideoPlayer extends StatefulWidget {
  final VideoPlayerController controller;

  const FullscreenVideoPlayer({required this.controller});

  @override
  _FullscreenVideoPlayerState createState() => _FullscreenVideoPlayerState();
}

class _FullscreenVideoPlayerState extends State<FullscreenVideoPlayer> {
 @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.black,
    body: Stack(
      children: [
        Center(
          child: AspectRatio(
            aspectRatio: widget.controller.value.aspectRatio,
            child: Stack(
              children: [
                VideoPlayer(widget.controller),
                // Play/Pause button - Bottom Right of video
              Positioned(
              bottom: 0,
              left: 0,
              right: 0,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        widget.controller.value.isPlaying
                            ? widget.controller.pause()
                            : widget.controller.play();
                      });
                    },
                    child: Icon(
                      widget.controller.value.isPlaying
                          ? Icons.pause_circle_outline
                          : Icons.play_circle_outline,
                      size: 30,
                      color: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Close button - Outside video
        Positioned(
          top: 40,
          left: 20,
          child: IconButton(
            icon: Icon(Icons.close, color: Colors.white, size: 30),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ],
    ),
  );
}
}

class ObituarySeenHelper {
  static const String _key = 'seen_obituary_ids';

  /// Returns the set of already-dismissed obituary IDs stored on device.
  static Future<Set<String>> getSeenIds() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_key) ?? []).toSet();
  }

  /// Persists [ids] so they are never shown again.
  static Future<void> markAsSeen(List<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = (prefs.getStringList(_key) ?? []).toSet();
    existing.addAll(ids);
    await prefs.setStringList(_key, existing.toList());
  }
}


Future<void> showObituaryIfNeeded(
  BuildContext context,
  List<dynamic> allDeathDetails,
) async {
  final seenIds = await ObituarySeenHelper.getSeenIds();

  final unseen = allDeathDetails.where((detail) {
  
    final id =
        (detail['nDeathID'] ?? detail['cFullName'] ?? '').toString().trim();
    return id.isNotEmpty && !seenIds.contains(id);
  }).toList();

  if (unseen.isEmpty) return; // Nothing new to show.

  if (context.mounted) {
    showDialog(
      context: context,
      builder: (_) => _ObituaryDialog(deathDetails: unseen),
    );
  }
}


class _ObituaryDialog extends StatefulWidget {
  final List<dynamic> deathDetails;
  const _ObituaryDialog({required this.deathDetails});

  @override
  State<_ObituaryDialog> createState() => _ObituaryDialogState();
}

class _ObituaryDialogState extends State<_ObituaryDialog> {
  int _currentIndex = 0;
  bool _showFamilyMembers = false;
  bool _showServices = false;
  static const String _imageBaseUrl =
      'https://lv4hfxvb-7000.inc1.devtunnels.ms/';

  
  Future<void> _markAllAndClose() async {
    final ids = widget.deathDetails
        .map((e) =>
            (e['nDeathID'] ?? e['cFullName'] ?? '').toString().trim())
        .where((id) => id.isNotEmpty)
        .toList();

    await ObituarySeenHelper.markAsSeen(ids);
    if (mounted) Navigator.pop(context);
  }

  

  /// Handles both "1953-03-16" and "2026-05-05T18:00:00"
  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    try {
      final dt = DateTime.parse(raw);
      const months = [
        '',
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December',
      ];
      if (raw.contains('T')) {
        final hour = dt.hour.toString().padLeft(2, '0');
        final minute = dt.minute.toString().padLeft(2, '0');
        return '${months[dt.month]} ${dt.day}, ${dt.year}  •  $hour:$minute';
      }
      return '${months[dt.month]} ${dt.day}, ${dt.year}';
    } catch (_) {
      return raw;
    }
  }

  String _formatChurchDateTime(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    try {
      final dt = DateTime.parse(raw).toLocal();
      final datePart = DateFormat('dd MMM yyyy').format(dt);
      final timePart = DateFormat('h:mm a').format(dt);
      return '$datePart  •  $timePart';
    } catch (_) {
      return raw;
    }
  }

  String _extractRelativePath(String? path) {
    if (path == null || path.isEmpty) return '';
    final normalized =
        path.replaceAll('\\', '/').replaceAll(RegExp(r'/+'), '/');
    const marker = 'uploads/';
    final idx = normalized.indexOf(marker);
    if (idx != -1) return normalized.substring(idx + marker.length);
    return normalized.split('/').last;
  }

  
  String _serviceCategoryLabel(String id) {
    const Map<String, String> categoryMap = {
      '1': 'Funeral',
      '2': 'Seventh Day',
    };
    return categoryMap[id] ?? id;
  }

  @override
  Widget build(BuildContext context) {
    final detail = widget.deathDetails[_currentIndex];

    final String name = detail['cFullName'] ?? '';
    final String dob = _formatDate(detail['dDoB'] as String?);
    final String deathDate = _formatDate(detail['DemiseDate'] as String?);

    final String relativePath = detail['cUploadedPathText'] ??
        _extractRelativePath(detail['cUploadedFile']);
    final String imageUrl = '$_imageBaseUrl$relativePath';
    final bool hasImage = relativePath.isNotEmpty;

    // Family members (nested list)
    final List<Map<String, dynamic>> familyMembers =
        (detail['familyMembers'] as List<dynamic>? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();

    // Services (flat fields on the detail object)
    final String cat = (detail['nServiceCategoryID'] ?? '').toString();
    final String church = (detail['cChurchName'] ?? '').toString();
    final String date = (detail['dDoFuneral'] ?? '').toString();

    final List<Map<String, dynamic>> services =
        (cat.isNotEmpty || church.isNotEmpty || date.isNotEmpty)
            ? [
                {
                  'nServiceCategoryID': cat,
                  'cServiceCategoryName': _serviceCategoryLabel(cat),
                  'cChurchName': church,
                  'dDoFuneral': date,
                }
              ]
            : [];

    final bool hasMultiple = widget.deathDetails.length > 1;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF4A4A6A), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.6),
              blurRadius: 24,
              spreadRadius: 4,
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
        
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: const BoxDecoration(
                  color: Color(0xFF1A1A2E),
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Centre title
                    Column(
                      children: [
                        const Icon(Icons.local_florist,
                            color: Color(0xFFB0A080), size: 22),
                        const SizedBox(height: 6),
                        const Text(
                          '✦  In Loving Memory  ✦',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFFD4C5A0),
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.8,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                            height: 1,
                            width: 120,
                            color: const Color(0xFF4A4A6A)),
                      ],
                    ),
                    // ✕ button – top right, always closes the dialog
                    Positioned(
                      top: 0,
                      right: 8,
                      child: GestureDetector(
                        onTap: _markAllAndClose, // ← saves + closes
                        child: const Icon(
                          Icons.close,
                          color: Color(0xFF8888AA),
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

           
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                child: Column(
                  children: [
                    // Photo
                    Container(
                      width: 140,
                      height: 160,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A2A3E),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: const Color(0xFFB0A080), width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: hasImage
                            ? Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                loadingBuilder:
                                    (context, child, progress) {
                                  if (progress == null) return child;
                                  return const Center(
                                    child: CircularProgressIndicator(
                                      color: Color(0xFFB0A080),
                                      strokeWidth: 2,
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stack) {
                                  debugPrint(
                                      'Image failed: $imageUrl — $error');
                                  return _photoPlaceholder();
                                },
                              )
                            : _photoPlaceholder(),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Name
                    Text(
                      name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFFE8D8B0),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Birth / Death dates
                    if (dob.isNotEmpty || deathDate.isNotEmpty)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (dob.isNotEmpty) ...[
                            const Icon(Icons.brightness_1,
                                color: Color(0xFF6A6A8A), size: 7),
                            const SizedBox(width: 6),
                            Text(dob,
                                style: const TextStyle(
                                    color: Color(0xFF9898B8),
                                    fontSize: 12.5)),
                          ],
                          if (dob.isNotEmpty && deathDate.isNotEmpty)
                            const Padding(
                              padding:
                                  EdgeInsets.symmetric(horizontal: 8),
                              child: Text('—',
                                  style: TextStyle(
                                      color: Color(0xFF6A6A8A),
                                      fontSize: 12)),
                            ),
                          if (deathDate.isNotEmpty) ...[
                            Text(deathDate,
                                style: const TextStyle(
                                    color: Color(0xFF9898B8),
                                    fontSize: 12.5)),
                            const SizedBox(width: 6),
                            const Icon(Icons.brightness_1,
                                color: Color(0xFF6A6A8A), size: 7),
                          ],
                        ],
                      ),

                    const SizedBox(height: 18),
                    _divider(),
                    const SizedBox(height: 16),

                    if (services.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      GestureDetector(
                        onTap: () => setState(
                            () => _showServices = !_showServices),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF252540),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: const Color(0xFF3A3A5A),
                                width: 1),
                          ),
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.church_outlined,
                                  color: Color(0xFFB0A080), size: 16),
                              const SizedBox(width: 6),
                              const Text(
                                'Services',
                                style: TextStyle(
                                  color: Color(0xFFD4C5A0),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.3,
                                ),
                              ),
                              const SizedBox(width: 6),
                              AnimatedRotation(
                                turns: _showServices ? 0.5 : 0.0,
                                duration: const Duration(
                                    milliseconds: 250),
                                child: const Icon(
                                  Icons.keyboard_arrow_down,
                                  color: Color(0xFFB0A080),
                                  size: 18,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      AnimatedCrossFade(
                        firstChild:
                            const SizedBox(width: double.infinity),
                        secondChild: Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Column(
                            children: services.map((service) {
                              final String category =
                                  service['cServiceCategoryName'] ??
                                      '';
                              final String churchName =
                                  service['cChurchName'] ?? '';
                              final String churchDate =
                                  _formatChurchDateTime(
                                      service['dDoFuneral']
                                          as String?);
                              return Container(
                                margin:
                                    const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E1E38),
                                  borderRadius:
                                      BorderRadius.circular(10),
                                  border: Border.all(
                                      color: const Color(0xFF3A3A5A),
                                      width: 1),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    if (category.isNotEmpty)
                                      Container(
                                        margin: const EdgeInsets.only(
                                            bottom: 8),
                                        padding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 4),
                                        decoration: BoxDecoration(
                                          color:
                                              const Color(0xFF2E2E50),
                                          borderRadius:
                                              BorderRadius.circular(
                                                  20),
                                          border: Border.all(
                                              color: const Color(
                                                      0xFFB0A080)
                                                  .withOpacity(0.4),
                                              width: 1),
                                        ),
                                        child: Text(
                                          category,
                                          style: const TextStyle(
                                            color: Color(0xFFD4C5A0),
                                            fontSize: 11.5,
                                            fontWeight:
                                                FontWeight.w600,
                                            letterSpacing: 0.8,
                                          ),
                                        ),
                                      ),
                                    if (churchName.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                            bottom: 6),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Icon(
                                                Icons.location_on,
                                                color:
                                                    Color(0xFF8888AA),
                                                size: 15),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                churchName,
                                                style: const TextStyle(
                                                  color:
                                                      Color(0xFFCCCCE8),
                                                  fontSize: 13,
                                                  fontWeight:
                                                      FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    if (churchDate.isNotEmpty)
                                      Row(
                                        children: [
                                          const Icon(
                                              Icons
                                                  .calendar_today_outlined,
                                              color:
                                                  Color(0xFF8888AA),
                                              size: 14),
                                          const SizedBox(width: 8),
                                          Text(
                                            _formatChurchDateTime(
                                                churchDate),
                                            style: const TextStyle(
                                              color:
                                                  Color(0xFF9898B8),
                                              fontSize: 12.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        crossFadeState: _showServices
                            ? CrossFadeState.showSecond
                            : CrossFadeState.showFirst,
                        duration: const Duration(milliseconds: 300),
                      ),
                    ],

                  
                    if (familyMembers.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _divider(),
                      const SizedBox(height: 14),
                      GestureDetector(
                        onTap: () => setState(() =>
                            _showFamilyMembers = !_showFamilyMembers),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF252540),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: const Color(0xFF3A3A5A),
                                width: 1),
                          ),
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.people_outline,
                                  color: Color(0xFFB0A080), size: 16),
                              const SizedBox(width: 6),
                              const Text(
                                'Survived By',
                                style: TextStyle(
                                  color: Color(0xFFD4C5A0),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.3,
                                ),
                              ),
                              const SizedBox(width: 6),
                              AnimatedRotation(
                                turns: _showFamilyMembers ? 0.5 : 0.0,
                                duration: const Duration(
                                    milliseconds: 250),
                                child: const Icon(
                                  Icons.keyboard_arrow_down,
                                  color: Color(0xFFB0A080),
                                  size: 18,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      AnimatedCrossFade(
                        firstChild:
                            const SizedBox(width: double.infinity),
                        secondChild: Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Column(
                            children: familyMembers.map((member) {
                              final String memberName =
                                  member['cFullName'] ?? '';
                              return Container(
                                margin:
                                    const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF252540),
                                  borderRadius:
                                      BorderRadius.circular(8),
                                  border: Border.all(
                                      color: const Color(0xFF3A3A5A),
                                      width: 1),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.person,
                                        color: Color(0xFF8888AA),
                                        size: 20),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        memberName,
                                        style: const TextStyle(
                                          color: Color(0xFFCCCCE8),
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        crossFadeState: _showFamilyMembers
                            ? CrossFadeState.showSecond
                            : CrossFadeState.showFirst,
                        duration: const Duration(milliseconds: 300),
                      ),
                    ],

                    const SizedBox(height: 12),
                    _divider(),
                    const SizedBox(height: 4),
                  ],
                ),
              ),

          
              if (hasMultiple)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      widget.deathDetails.length,
                      (i) => GestureDetector(
                        onTap: () => setState(() {
                          _currentIndex = i;
                          _showServices = false;
                          _showFamilyMembers = false;
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(
                              horizontal: 4),
                          width: _currentIndex == i ? 18 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _currentIndex == i
                                ? const Color(0xFFB0A080)
                                : const Color(0xFF4A4A6A),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

             
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    if (hasMultiple && _currentIndex > 0) ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => setState(() {
                            _currentIndex--;
                            _showServices = false;
                            _showFamilyMembers = false;
                          }),
                          icon: const Icon(Icons.arrow_back_ios,
                              size: 14),
                          label: const Text('Prev'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFB0A080),
                            side: const BorderSide(
                                color: Color(0xFF4A4A6A)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (hasMultiple &&
                              _currentIndex <
                                  widget.deathDetails.length - 1) {
                            // Go to next record
                            setState(() {
                              _currentIndex++;
                              _showServices = false;
                              _showFamilyMembers = false;
                            });
                          } else {
                            // Last record → save + close
                            _markAllAndClose();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3A3A5A),
                          foregroundColor: const Color(0xFFD4C5A0),
                          padding: const EdgeInsets.symmetric(
                              vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          (hasMultiple &&
                                  _currentIndex <
                                      widget.deathDetails.length - 1)
                              ? 'Next'
                              : 'Close',
                          style: const TextStyle(letterSpacing: 1.2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }



  Widget _photoPlaceholder() => const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person, color: Color(0xFF6A6A8A), size: 48),
          SizedBox(height: 6),
          Text(
            'Photo\nUnavailable',
            textAlign: TextAlign.center,
            style:
                TextStyle(color: Color(0xFF6A6A8A), fontSize: 11),
          ),
        ],
      );

  Widget _divider() => Row(
        children: [
          const Expanded(child: Divider(color: Color(0xFF4A4A6A))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text('✦',
                style: TextStyle(
                    color: Colors.grey.shade700, fontSize: 12)),
          ),
          const Expanded(child: Divider(color: Color(0xFF4A4A6A))),
        ],
      );


}

// Widget _buildPersonRow(NotablePerson person) {
//   return Padding(
//     padding: const EdgeInsets.symmetric(vertical: 4),
//     child: Row(
//       children: [
//         // ── Avatar ──
//         CircleAvatar(
//           radius: 22,
//           backgroundColor:
//               const Color.fromARGB(255, 68, 33, 212).withOpacity(0.7),
//           child: Text(
//             person.name[0],
//             style: const TextStyle(
//               color: Colors.white,
//               fontWeight: FontWeight.bold,
//               fontSize: 18,
//             ),
//           ),
//         ),
//         const SizedBox(width: 12),

//         // ── Name & Title ──
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 person.name,
//                 style: const TextStyle(
//                   fontWeight: FontWeight.bold,
//                   fontSize: 14,
//                   color: Colors.white,
//                 ),
//               ),
//               Text(
//                 person.title,
//                 style: const TextStyle(
//                   fontSize: 11,
//                   color: Colors.white70,
//                 ),
//                 maxLines: 1,
//                 overflow: TextOverflow.ellipsis,
//               ),
//               Text(
//                 person.years,
//                 style: const TextStyle(
//                   fontSize: 11,
//                   color: Colors.white60,
//                 ),
//               ),
//             ],
//           ),
//         ),

//         // ── Info Icon ──
//         const Icon(Icons.info_outline, color: Colors.white60, size: 20),
//       ],
//     ),
//   );
// }