import 'package:Koottaayma/HOMEPAGEICONS/notepad.dart';
import 'package:Koottaayma/HTTPURL/httpurl.dart';
import 'package:Koottaayma/SQFLITEVERSION1/DataBaseHelper.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BiblePage extends StatefulWidget {
  const BiblePage({super.key});

  @override
  State<BiblePage> createState() => _BiblePageState();
}

class _BiblePageState extends State<BiblePage> {
  late ScrollController _scrollController;
  final int totalDays = 15;
  final int centerIndex = 7;
  int selectedDay = 7;
  
  // API data storage
  Map<String, dynamic>? readingsData;
  bool isLoading = false;
  String? errorMessage;
  
  // Audio player
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? currentlyPlayingAudio;
  bool isPlaying = false;

  // Database helper
  final DatabaseHelper _dbHelper = DatabaseHelper();
  int? userPhoneNumber;
 //for updation
// int _lastKnownBibleVersion = 0;
  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _initializeData();
    //for updation
   // _listenForBibleUpdates();
    
    // Listen to audio player state
    _audioPlayer.onPlayerStateChanged.listen((PlayerState state) {
      setState(() {
        isPlaying = state == PlayerState.playing;
      });
    });
    
    _audioPlayer.onPlayerComplete.listen((event) {
      setState(() {
        isPlaying = false;
        currentlyPlayingAudio = null;
      });
    });
  }

//updation alertnotification
// void _listenForBibleUpdates() {
//   Future.doWhile(() async {
//     await Future.delayed(const Duration(seconds: 10));
//     if (!mounted) return false;

//     final prefs = await SharedPreferences.getInstance();
//     final int latestVersion = prefs.getInt('bibleUpdate') ?? 0;

//     if (latestVersion != _lastKnownBibleVersion) {
//       print('Bible update detected — force reloading from API');
//       _lastKnownBibleVersion = latestVersion;
//       await _loadReadingsData(
//         getDateForIndex(selectedDay),
//         forceRefresh: true, // ← clears cache, fetches fresh API data
//       );
//     }

//     return mounted;
//   });
// }

 // Initialize data - fetch from SQLite first, then API if needed
Future<void> _initializeData() async {
  await _getUserPhoneNumber();
  await _loadReadingsData(getDateForIndex(selectedDay));
  //for updation
  //   final prefs = await SharedPreferences.getInstance();
  // _lastKnownBibleVersion = prefs.getInt('bibleUpdate') ?? 0;
}

// Get user phone number from SharedPreferences
Future<void> _getUserPhoneNumber() async {
  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? phone = prefs.getString('userPhone');
    if (phone != null) {
      userPhoneNumber = int.tryParse(phone);
      print(' User phone number: $userPhoneNumber');
    } else {
      print(' No user phone number found in SharedPreferences');
    }
  } catch (e) {
    print(' Error getting user phone: $e');
  }
}

// Load readings data - SQLite first, API only if empty
Future<void> _loadReadingsData(DateTime date) async {
  if (userPhoneNumber == null) {
    await _getUserPhoneNumber();
  }

  setState(() {
    isLoading = true;
    errorMessage = null;
  });

  if (userPhoneNumber == null) {
    setState(() {
      errorMessage = 'User phone number not found. Please login again.';
      isLoading = false;
    });
    return;
  }

  try {
    // Always try SQLite first
    print(' Checking SQLite for cached gospel readings...');
    final cachedData = await _dbHelper.getCachedGospelReadings(userPhoneNumber!);
    
    if (cachedData != null && cachedData.isNotEmpty) {
      print('Loading gospel readings from SQLite');
      _processAndSetReadings(cachedData, date);
      return;
    }
    // if (cachedData != null && cachedData.isNotEmpty) {
    //   // ✅ Safely convert map types from SQLite
    //   final Map<String, dynamic> safeMap = {};
    //   cachedData.forEach((key, value) {
    //     if (value is List) {
    //       safeMap[key] = value.map((item) {
    //         if (item is Map) {
    //           final Map<String, dynamic> safeItem = {};
    //           item.forEach((k, v) {
    //             safeItem[k.toString()] = v;
    //           });
    //           return safeItem;
    //         }
    //         return item;
    //       }).toList();
    //     } else {
    //       safeMap[key.toString()] = value;
    //     }
    //   });

    //   _processAndSetReadings(safeMap, date);
    //   return;
    // }

    // Only fetch from API if SQLite is empty
    print(' No cached data found. Attempting to fetch from API...');
    await _fetchReadingsFromAPI(date);
    
  } catch (e) {
    setState(() {
      errorMessage = 'Error loading readings: $e';
      isLoading = false;
    });
    print(' Error in _loadReadingsData: $e');
  }
}

// Process and filter readings data
void _processAndSetReadings(Map<String, dynamic> data, DateTime date) {
  final formattedDate = DateFormat('yyyy-MM-dd').format(date);
  
  print(' Filtering data for date: $formattedDate');

  final filteredData = {
    'FirstReadingDetails': (data['FirstReadingDetails'] as List?)
            ?.where((item) => item['dDate'] == formattedDate)
            .toList() ??
        [],
    'SecondReadingDetails': (data['SecondReadingDetails'] as List?)
            ?.where((item) => item['dDate'] == formattedDate)
            .toList() ??
        [],
    'GospelReadingDetails': (data['GospelReadingDetails'] as List?)
            ?.where((item) => item['dDate'] == formattedDate)
            .toList() ??
        [],
  };

  print(' Found ${filteredData['FirstReadingDetails']?.length ?? 0} first readings');
  print(' Found ${filteredData['SecondReadingDetails']?.length ?? 0} second readings');
  print(' Found ${filteredData['GospelReadingDetails']?.length ?? 0} gospel readings');

  setState(() {
    readingsData = filteredData;
    isLoading = false;
    errorMessage = null;
  });
}

// Fetch readings from API and save to SQLite (only when cache is empty)
Future<void> _fetchReadingsFromAPI(DateTime date) async {
  try {
    final url = Uri.parse(BibleReadingsAPI);

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
    ).timeout(
      Duration(seconds: 15),
      onTimeout: () {
        throw Exception('Connection timeout - server not responding');
      },
    );

    print(' Server response status: ${response.statusCode}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = json.decode(response.body);

      // Save to SQLite for future use
      if (userPhoneNumber != null) {
        await _dbHelper.saveGospelReadings(
          phoneNumber: userPhoneNumber!,
          gospelData: response.body,
        );
        print(' Gospel readings saved to SQLite successfully');
      }

      _processAndSetReadings(data, date);
    } else {
      setState(() {
        errorMessage = 'Server error (${response.statusCode}). Cannot load readings.';
        isLoading = false;
      });
      print(' Server returned error: ${response.statusCode}');
    }
  } catch (e) {
    setState(() {
      errorMessage = 'Cannot connect to server. Please check your internet connection.';
      isLoading = false;
    });
    print(' Error fetching readings from API: $e');
  }
}

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final double itemWidth = 80 + 12;
      final double screenWidth = MediaQuery.of(context).size.width;
      final double centerOffset = (itemWidth * centerIndex) - (screenWidth / 2) + (itemWidth / 2);

      _scrollController.animateTo(
        centerOffset,
        duration: Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  DateTime getDateForIndex(int index) {
    final today = DateTime.now();
    final daysOffset = index - centerIndex;
    return today.add(Duration(days: daysOffset));
  }

  bool isToday(int index) {
    return index == centerIndex;
  }

  // Play or pause audio
  Future<void> _toggleAudio(String? audioUrl) async {
    if (audioUrl == null || audioUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Audio not available for this reading'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // If same audio is playing, pause it
      if (currentlyPlayingAudio == audioUrl && isPlaying) {
        await _audioPlayer.pause();
        setState(() {
          isPlaying = false;
        });
        return;
      }

      // If different audio or paused, play new audio
      await _audioPlayer.stop();
      await _audioPlayer.play(UrlSource(audioUrl));
      setState(() {
        currentlyPlayingAudio = audioUrl;
        isPlaying = true;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error playing audio: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Show reading details in bottom sheet
  void _showReadingDetails(
    BuildContext context,
    String title,
    String content,
    String reference,
    String chapterSummary,
    String? audioUrl,
    {String? repeatingSentence,
    String? chapterDetails,
    List<String>? additionalParagraphs}
  ) { 
    final bool isThisAudioPlaying =
        currentlyPlayingAudio == audioUrl && isPlaying;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Container(
                margin: EdgeInsets.only(top: 12),
                width: 50,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Text(
                                title,
                                style: GoogleFonts.roboto(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              const Spacer(),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (context) =>WritingNotes()));
                                },
                                child: Icon(Icons.note_alt_outlined, color: Colors.blue),
                              ),
                              SizedBox(width: 30),
                              GestureDetector(
                                onTap: () => _toggleAudio(audioUrl),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isThisAudioPlaying
                                        ? Colors.cyan.withOpacity(0.2)
                                        : Colors.cyan.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isThisAudioPlaying
                                        ? Icons.pause
                                        : Icons.play_arrow,
                                    color: Colors.cyan,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 5),
                          Text(
                            reference,
                            style: GoogleFonts.roboto(
                              fontSize: 16,
                              color: Colors.blue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (chapterDetails != null && chapterDetails.isNotEmpty) ...[
                            Text(
                              chapterDetails,
                              style: GoogleFonts.roboto(
                                fontSize: 16,
                                color: Colors.grey[500],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 5),
                            Text(
                              chapterSummary,
                              style: GoogleFonts.roboto(
                                fontSize: 16,
                                color: const Color.fromARGB(255, 142, 38, 0),
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        content,
                        style: GoogleFonts.roboto(
                          fontSize: 16,
                          height: 1.6,
                          color: Colors.black87,
                        ),
                      ),
                      
                      if (repeatingSentence != null && repeatingSentence.isNotEmpty) ...[
                        SizedBox(height: 20),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.cyan.withOpacity(0.1),
                                Colors.cyan.withOpacity(0.05),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.cyan.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                             Text('പ്രതിവചന സംഗീർത്തനം',  style: GoogleFonts.roboto(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.cyan.shade800,
                                  height: 1.5,
                                ),),
                              SizedBox(width: 12),
                              Text(
                                repeatingSentence,
                                style: GoogleFonts.roboto(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.cyan.shade800,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      
          if (additionalParagraphs != null && additionalParagraphs.isNotEmpty) ...[
  SizedBox(height: 20),
  Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        height: 200,
        child: Stack(
          children: [
            ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: additionalParagraphs.length,
              itemBuilder: (context, index) {
                return Container(
                  width: MediaQuery.of(context).size.width * 0.8,
                  margin: EdgeInsets.only(
                    right: index < additionalParagraphs.length - 1 ? 12 : 0,
                  ),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.orange.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 8),
                      Expanded(
                        child: Text(
                          additionalParagraphs[index],
                          style: GoogleFonts.roboto(
                            fontSize: 15,
                            height: 1.6,
                            color: Colors.black87,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(height: 8),
                      GestureDetector(
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => Container(
                              height: MediaQuery.of(context).size.height * 0.7,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(25),
                                  topRight: Radius.circular(25),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    margin: EdgeInsets.only(top: 12, bottom: 8),
                                    width: 50,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 10),
                                    child: Row(
                                      children: [
                                        Spacer(),
                                        IconButton(
                                          icon: Icon(Icons.close,
                                              color: Colors.grey[600]),
                                          onPressed: () =>
                                              Navigator.pop(context),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Divider(height: 1),
                                  Expanded(
                                    child: SingleChildScrollView(
                                      padding: EdgeInsets.all(20),
                                      child: Text(
                                        additionalParagraphs[index],
                                        style: GoogleFonts.roboto(
                                          fontSize: 16,
                                          height: 1.8,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              'Read More',
                              style: GoogleFonts.roboto(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.orange.shade700,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 13,
                              color: Colors.orange.shade700,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            // ── Right-side scroll hint 
            if (additionalParagraphs.length > 1)
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: IgnorePointer(
                  child: Container(
                    width: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.white.withOpacity(0.0),
                          Colors.white.withOpacity(0.85),
                        ],
                      ),
                    ),
                    child: Center(
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.orange.shade700,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withOpacity(0.35),
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.chevron_right,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            
          ],
        ),
      ),
    ],
  ),
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
          'Daily Gospels',
          style: GoogleFonts.roboto(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
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
            // Date Selector
            Container(
              height: 110,
              child: ListView.builder(
                controller: _scrollController,
                physics: ClampingScrollPhysics(),
                scrollDirection: Axis.horizontal,
                itemCount: totalDays,
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                itemBuilder: (context, index) {
                  final date = getDateForIndex(index);
                  final bool isTodayDate = isToday(index);
                  final bool isSelected = selectedDay == index;
                  final String dayName = DateFormat('EEE').format(date);
                  final String dateNum = DateFormat('dd').format(date);
                  final String monthYear = DateFormat('MMM').format(date);

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedDay = index;
                      });
                      _loadReadingsData(date);
                    },
                    child: Container(
                      width: 80,
                      margin: EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? LinearGradient(
                                colors: [Colors.cyan, Colors.cyan.shade600],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: isSelected ? null : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: isTodayDate && !isSelected
                            ? Border.all(color: Colors.cyan, width: 2)
                            : null,
                        boxShadow: [
                          BoxShadow(
                            color: isSelected
                                ? Colors.cyan.withOpacity(0.3)
                                : Colors.black12,
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            dayName,
                            style: GoogleFonts.roboto(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white : Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            dateNum,
                            style: GoogleFonts.roboto(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : Colors.black87,
                            ),
                          ),
                          Text(
                            monthYear,
                            style: GoogleFonts.roboto(
                              fontSize: 12,
                              color: isSelected ? Colors.white : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            
            // Readings List
            Expanded(
              child: isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.cyan),
                      ),
                    )
                  : errorMessage != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline, size: 60, color: Colors.red),
                              SizedBox(height: 16),
                              Text(
                                errorMessage!,
                                style: GoogleFonts.roboto(
                                  fontSize: 16,
                                  color: Colors.red,
                                ),
                              ),
                              SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () => _loadReadingsData(getDateForIndex(selectedDay)),
                                child: Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : readingsData == null
                          ? Center(child: Text('No data available'))
                          : ListView(
                              padding: EdgeInsets.all(16),
                              children: [
                                // First Reading
                                if (readingsData!['FirstReadingDetails'] != null &&
                                    (readingsData!['FirstReadingDetails'] as List).isNotEmpty)
                                  ..._buildFirstReadingCards(),
                                
                                // Second Reading
                                if (readingsData!['SecondReadingDetails'] != null &&
                                    (readingsData!['SecondReadingDetails'] as List).isNotEmpty)
                                  ..._buildSecondReadingCards(),
                                
                                // Gospel Reading
                                if (readingsData!['GospelReadingDetails'] != null &&
                                    (readingsData!['GospelReadingDetails'] as List).isNotEmpty)
                                  ..._buildGospelReadingCards(),
                                
                                // Show message if no readings available
                                if (_hasNoReadings())
                                  Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(32),
                                      child: Text(
                                        'No readings available for this date',
                                        style: GoogleFonts.roboto(
                                          fontSize: 16,
                                          color: Colors.grey[600],
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
  }

  bool _hasNoReadings() {
    if (readingsData == null) return true;
    
    final firstReading = readingsData!['FirstReadingDetails'] as List?;
    final secondReading = readingsData!['SecondReadingDetails'] as List?;
    final gospelReading = readingsData!['GospelReadingDetails'] as List?;
    
    return (firstReading == null || firstReading.isEmpty) &&
           (secondReading == null || secondReading.isEmpty) &&
           (gospelReading == null || gospelReading.isEmpty);
  }

  List<Widget> _buildFirstReadingCards() {
    final firstReadings = readingsData!['FirstReadingDetails'] as List;
    List<Widget> cards = [];
    
    for (var reading in firstReadings) {
      String? repeatingSentence;
      if (reading['RepeatingSentence'] != null && 
          reading['RepeatingSentence'] is Map &&
          reading['RepeatingSentence']['cRepeatedSentence'] != null) {
        repeatingSentence = reading['RepeatingSentence']['cRepeatedSentence'];
      }
      
      List<String>? additionalParagraphs;
      if (reading['RepeatingParagraph'] != null && 
          reading['RepeatingParagraph'] is List &&
          (reading['RepeatingParagraph'] as List).isNotEmpty) {
        additionalParagraphs = (reading['RepeatingParagraph'] as List)
            .map((p) => p['cRepeatingParagraph'] ?? '')
            .where((text) => text.isNotEmpty)
            .cast<String>()
            .toList();
      }
      
      cards.add(_buildReadingCard(
        context,
        title: 'ഒന്നാം വായന',
        chapterNo: reading['nChapterNo'] ?? reading['cChapterNo'] ?? '',
        chapterDetails: reading['cChapterDetails'] ?? '',
        chapterSummary: reading['cChapterSummary'] ?? '',
        readingText: reading['cFirstReadingText'] ?? '',
        icon: Icons.menu_book,
        color: Colors.blue,
        repeatingSentence: repeatingSentence,
        additionalParagraphs: additionalParagraphs,
        audioUrl: reading['cAudioFilePath'],
      ));

      cards.add(SizedBox(height: 16));
    }
    
    return cards;
  }

  List<Widget> _buildSecondReadingCards() {
    final secondReadings = readingsData!['SecondReadingDetails'] as List;
    List<Widget> cards = [];
    
    for (var reading in secondReadings) {
      cards.add(_buildReadingCard(
        context,
        title: 'രണ്ടാം വായന',
        chapterNo: reading['nChapterNo'] ?? reading['cChapterNo'] ?? '',
        chapterDetails: reading['cChapterDetails'] ?? '',
        chapterSummary: reading['cChapterSummary'] ?? '',
        readingText: reading['cSecondReadingText'] ?? '',
        icon: Icons.menu_book,
        color: Colors.blue,
        audioUrl: reading['cAudioFilePath'],
      ));
      cards.add(SizedBox(height: 16));
    }
    
    return cards;
  }

  List<Widget> _buildGospelReadingCards() {
    final gospelReadings = readingsData!['GospelReadingDetails'] as List;
    List<Widget> cards = [];
    
    for (var reading in gospelReadings) {
      cards.add(_buildReadingCard(
        context,
        title: 'സുവിശേഷം',
        chapterNo: reading['nChapterNo'] ?? reading['cChapterNo'] ?? '',
        chapterDetails: reading['cChapterDetails'] ?? '',
        chapterSummary: reading['cChapterSummary'] ?? '',
        readingText: reading['cGospelReadingText'] ?? '',
        icon: Icons.menu_book,
        color: Colors.blue,
        audioUrl: reading['cAudioFilePath'],
      ));
      cards.add(SizedBox(height: 16));
    }
    
    return cards;
  }
///////////////////////////
//starting container
  Widget _buildReadingCard(
    BuildContext context, {
    required String title,
    required String chapterNo,
    required IconData icon,
    required Color color,
    required String chapterSummary,
    required String readingText,
    String? chapterDetails,
    String? repeatingSentence,
    List<String>? additionalParagraphs,
    String? audioUrl,
  }) {
    final bool isThisAudioPlaying =
        currentlyPlayingAudio == audioUrl && isPlaying;

    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showReadingDetails(
              context,
              title,
              readingText,
              chapterNo,
              chapterSummary,
              audioUrl,
              repeatingSentence: repeatingSentence,
              additionalParagraphs: additionalParagraphs,
              chapterDetails: chapterDetails,
            ),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.roboto(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => _toggleAudio(audioUrl),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isThisAudioPlaying
                                ? Colors.cyan.withOpacity(0.2)
                                : Colors.cyan.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isThisAudioPlaying
                                ? Icons.pause
                                : Icons.play_arrow,
                            color: Colors.cyan,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
      
                  const SizedBox(height: 6),
      
                  Text(
                    chapterNo,
                    style: GoogleFonts.roboto(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
      
                  if (chapterDetails != null && chapterDetails.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      chapterDetails,
                      style: GoogleFonts.roboto(
                        fontSize: 15,
                        color: Colors.grey[600],
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
      
                  const SizedBox(height: 8),
      
                  Text(
                    chapterSummary,
                    style: GoogleFonts.roboto(
                      fontSize: 15,
                     color: const Color.fromARGB(255, 142, 38, 0),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
      
                  const SizedBox(height: 12),
      
                  Text(
                    readingText,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.roboto(
                      fontSize: 15,
                      height: 1.5,
                      color: Colors.black87,
                    ),
                  ),
      
                  const SizedBox(height: 12),
      
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        'Read More',
                        style: GoogleFonts.roboto(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: color,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
