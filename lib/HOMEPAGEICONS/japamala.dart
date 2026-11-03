
import 'package:Koottaayma/SQFLITEVERSION1/DataBaseHelper.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';



class PrayerItem {
  final int nJMID;
  final int nDayID;
  final String cHeading;
  final String cPrayer;
  final int nPrayedBy;  // 0 = leader, 1 = all
  final int nEchoedBy;
  final int nNoofTimes; // how many times this prayer must be counted

  PrayerItem({
    required this.nJMID,
    required this.nDayID,
    required this.cHeading,
    required this.cPrayer,
    required this.nPrayedBy,
    required this.nEchoedBy,
    required this.nNoofTimes,
  });

  factory PrayerItem.fromJson(Map<String, dynamic> json) {
    return PrayerItem(
      nJMID:      (json['nJMID']      ?? 0) as int,
      nDayID:     (json['nDayID']     ?? 0) as int,
      cHeading:   (json['cHeading']   ?? '') as String,
      cPrayer:    (json['cPrayer']    ?? '') as String,
      nPrayedBy:  (json['nPrayedBy']  ?? 0) as int,
      nEchoedBy:  (json['nEchoedBy']  ?? 0) as int,
      nNoofTimes: (json['nNoofTimes'] ?? 1) as int,
    );
  }
}



class MyJapamalaPage extends StatefulWidget {
  const MyJapamalaPage({super.key});

  @override
  State<MyJapamalaPage> createState() => _MyJapamalaPageState();
}

class _MyJapamalaPageState extends State<MyJapamalaPage> {
  // ── Helpers 
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final AudioPlayer _audioPlayer = AudioPlayer();
/// Maps DateTime.weekday (Mon=1…Sun=7) → app dayID (Sun=1…Sat=7)
  int get _todayDayID => DateTime.now().weekday % 7 + 1;
  // ── State 
  int? _userPhoneNumber;
  bool _isLoading = true;
  String? _error;

  /// All prayer items from cache
  List<PrayerItem> _allItems = [];

  /// Items grouped by nDayID  {dayID → [PrayerItem]}
  Map<int, List<PrayerItem>> _grouped = {};

  /// Sorted day IDs
  List<int> _dayIDs = [];

  /// Count map  { nJMID → currentCount }
  Map<int, int> _counts = {};

  // ── Audio 
  bool _isPlaying = false;
  bool _isAudioLoading = false;
  int? _playingJMID;
  int? _loadingJMID;
// ── Expanded prayer text state ──
final Set<int> _expandedPrayers = {};
  

  @override
  void initState() {
    super.initState();
    _fetchData();

    _audioPlayer.onPlayerStateChanged.listen((PlayerState state) {
      if (!mounted) return;
      setState(() {
        _isPlaying = state == PlayerState.playing;
        if (state != PlayerState.playing) {
          _playingJMID = null;
        }
      });
    });

    _audioPlayer.onPlayerComplete.listen((_) {
      if (!mounted) return;
      setState(() {
        _isPlaying = false;
        _playingJMID = null;
        _isAudioLoading = false;
        _loadingJMID = null;
      });
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  

  Future<void> _getUserPhoneNumber() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final phone = prefs.getString('userPhone');
      if (phone != null) _userPhoneNumber = int.tryParse(phone);
    } catch (e) {
      debugPrint('Error getting user phone: $e');
    }
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    if (_userPhoneNumber == null) await _getUserPhoneNumber();

    if (_userPhoneNumber == null) {
      setState(() {
        _error = 'User phone number not found. Please login again.';
        _isLoading = false;
      });
      return;
    }

    try {
      final cached =
          await _dbHelper.getCachedJapamalaDetails(_userPhoneNumber!);

      if (cached == null || cached.isEmpty) {
        setState(() {
          _error = 'No cached data found. Please sync your data first.';
          _isLoading = false;
        });
        return;
      }

      // ── Parse every row as a PrayerItem ──────────
      final List<PrayerItem> items = (cached as List)
          .whereType<Map<String, dynamic>>()
          .map(PrayerItem.fromJson)
          .toList();

      // ── Group by nDayID 
      final Map<int, List<PrayerItem>> grouped = {};
      for (final item in items) {
        grouped.putIfAbsent(item.nDayID, () => []).add(item);
      }

      // ── Sort day IDs (0 = intro, then 1-7) ───────
      final List<int> dayIDs = grouped.keys.toList()..sort();

      // ── Initialize counts 
      final Map<int, int> counts = {
        for (final item in items) item.nJMID: 0,
      };

      setState(() {
        _allItems = items;
        _grouped = grouped;
        _dayIDs = dayIDs;
        _counts = counts;
        _isLoading = false;
      });
    } catch (e, stack) {
      debugPrint('Cache read error: $e\n$stack');
      setState(() {
        _error = 'Failed to load cached data: $e';
        _isLoading = false;
      });
    }
  }

  

  /// Tap the counter button for a prayer item
  void _onTapCount(PrayerItem item) {
    final current = _counts[item.nJMID] ?? 0;
    if (current >= item.nNoofTimes) return; // already complete
    setState(() => _counts[item.nJMID] = current + 1);
  }

  /// Reset all counts for a specific day
  void _resetDay(int dayID) {
    setState(() {
      for (final item in _grouped[dayID]!) {
        _counts[item.nJMID] = 0;
      }
    });
  }

  /// Check if all prayers in a day are complete
  bool _isDayComplete(int dayID) {
    final items = _grouped[dayID] ?? [];
    return items.every((item) => (_counts[item.nJMID] ?? 0) >= item.nNoofTimes);
  }


  Future<void> _toggleAudio(String audioUrl, int jmID) async {
    if (audioUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Audio not available'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    if (_isAudioLoading) return;

    try {
      if (_playingJMID == jmID && _isPlaying) {
        // Same audio → pause
        setState(() {
          _isAudioLoading = true;
          _loadingJMID = jmID;
        });
        await _audioPlayer.pause();
        setState(() {
          _isPlaying = false;
          _playingJMID = null;
          _isAudioLoading = false;
          _loadingJMID = null;
        });
        return;
      }

      // New audio
      setState(() {
        _isAudioLoading = true;
        _loadingJMID = jmID;
      });
      await _audioPlayer.stop();
      await _audioPlayer.play(UrlSource(audioUrl));
      setState(() {
        _playingJMID = jmID;
        _isPlaying = true;
        _isAudioLoading = false;
        _loadingJMID = null;
      });
    } catch (e) {
      setState(() {
        _isAudioLoading = false;
        _loadingJMID = null;
        _playingJMID = null;
        _isPlaying = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error playing audio: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  String _dayLabel(int dayID) {
    const labels = {
      0: 'ആമുഖ ജപങ്ങൾ',  
      1: 'ഞായർ',
      2: 'തിങ്കൾ',
      3: 'ചൊവ്വ',
      4: 'ബുധൻ',
      5: 'വ്യാഴം',
      6: 'വെള്ളി',
      7: 'ശനി',
    };
    return labels[dayID] ?? 'ദിവസം $dayID';
  }

 
  // Build
 

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
          'ജപമാല',
          style: GoogleFonts.roboto(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.cyan, Color(0xFF9EDAE4), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.cyan))
            : _error != null
                ? _buildError()
                : _buildBody(),
      ),
    );
  }

  // ── Error state 
  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 12),
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: SingleChildScrollView(
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _fetchData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan),
            ),
          ],
        ),
      ),
    );
  }
//////////////////////////////////////////athira
  // ── Main body 
  // Widget _buildBody() {
  //   return Column(
  //     children: [
  //       // Date header
  //       // Container(
  //       //   margin: const EdgeInsets.fromLTRB(8, 8, 8, 0),
  //       //   height: 45,
  //       //   width: double.infinity,
  //       //   alignment: Alignment.center,
  //       //   decoration: BoxDecoration(
  //       //     color: Colors.white,
  //       //     borderRadius: BorderRadius.circular(8),
  //       //   ),
  //       //   child: Text(
  //       //     DateFormat('dd MMM yyyy, EEEE').format(DateTime.now()),
  //       //     style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
  //       //   ),
  //       // ),

  //       const SizedBox(height: 8),

  //       // Scrollable list of day sections
  //       Expanded(
  //         child: ListView.builder(
  //           padding: const EdgeInsets.fromLTRB(8, 0, 8, 20),
  //           itemCount: _dayIDs.length,
  //           itemBuilder: (context, i) => _buildDaySection(_dayIDs[i]),
  //         ),
  //       ),
  //     ],
  //   );
  // }

 Widget _buildBody() {
  final List<PrayerItem> mergedItems = _allItems
      .where((item) => item.nDayID == 0 || item.nDayID == _todayDayID)
      .toList()
    ..sort((a, b) => a.nJMID.compareTo(b.nJMID));

  // Build a mixed list of headers + items
  final List<dynamic> listItems = [];
  int? lastDayID;

  for (final item in mergedItems) {
    if (item.nDayID != lastDayID) {
      listItems.add(item.nDayID); // insert day header
      lastDayID = item.nDayID;
    }
    listItems.add(item);
  }

  return Column(
    children: [
      const SizedBox(height: 8),
      Expanded(
        child: mergedItems.isEmpty
            ? Center(
                child: Text(
                  'ഇന്നത്തെ ജപം ലഭ്യമല്ല',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 20),
                itemCount: listItems.length,
                itemBuilder: (context, i) {
                  final entry = listItems[i];

                  // ── Day header ──
                  if (entry is int) {
                    return _buildDayHeader(entry);
                  }

                  // ── Prayer card ──
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _buildPrayerCard(entry as PrayerItem),
                  );
                },
              ),
      ),
    ],
  );
}

Widget _buildDayHeader(int dayID) {
  final bool isIntro = dayID == 0;
  return Container(
    margin: const EdgeInsets.only(top: 8, bottom: 6),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: isIntro ? Colors.cyan[100] : Colors.blue[100],
      borderRadius: BorderRadius.circular(10),
      border: Border.all(
        color: isIntro
            ? Colors.cyan.withOpacity(0.5)
            : Colors.blue.withOpacity(0.4),
        width: 1.5,
      ),
    ),
    child: Row(
      children: [
        Icon(
          isIntro ? Icons.menu_book_rounded : Icons.today_rounded,
          color: isIntro ? Colors.cyan[800] : Colors.blue[800],
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          _dayLabel(dayID),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: isIntro ? Colors.cyan[900] : Colors.blue[900],
          ),
        ),
      ],
    ),
  );
}

  // ── Day section 
  Widget _buildDaySection(int dayID) {
    final items = _grouped[dayID]!;
    final isDayDone = _isDayComplete(dayID);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDayDone ? Colors.blue : Colors.cyan.withOpacity(0.4),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Day header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDayDone ? Colors.blue[100] : Colors.cyan[100],
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(11)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      isDayDone ? Icons.check_circle : Icons.circle_outlined,
                      color: isDayDone ? Colors.blue[700] : Colors.cyan[700],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _dayLabel(dayID),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: isDayDone ? Colors.blue[800] : Colors.cyan[900],
                      ),
                    ),
                  ],
                ),
                // Reset button for the day
                if (isDayDone)
                  GestureDetector(
                    onTap: () => _resetDay(dayID),
                    child: const Icon(Icons.replay,
                        size: 20, color: Colors.blueGrey),
                  ),
              ],
            ),
          ),

          // Prayer items
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(10),
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 14),
            itemBuilder: (context, i) => _buildPrayerCard(items[i]),
          ),
        ],
      ),
    );
  }

Widget _buildPrayerCard(PrayerItem item) {
  final count = _counts[item.nJMID] ?? 0;
  final isDone = count >= item.nNoofTimes;
  final showHeading = item.cHeading.isNotEmpty && item.cHeading != '-';
  final showPrayer = item.cPrayer.isNotEmpty && item.cPrayer != '-';
  final isOnce = item.nNoofTimes == 1;
  final reciterColor = item.nPrayedBy == 0 ? Colors.orange : Colors.green;

  // Read more logic
  const int maxLines = 3;
  final bool isExpanded = _expandedPrayers.contains(item.nJMID);

  final cardContent = Container(
    decoration: BoxDecoration(
      color: isDone ? Colors.blue[50] : Colors.grey[50],
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: isDone
            ? Colors.blue.withOpacity(0.3)
            : Colors.grey.withOpacity(0.2),
      ),
    ),
    padding: const EdgeInsets.all(10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Top row: heading + prayer text 
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showHeading)
                    Text(
                      item.cHeading,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isDone ? Colors.blue[800] : Colors.black87,
                      ),
                    ),
                  if (showPrayer) ...[
                    if (showHeading) const SizedBox(height: 6),

                    // ── Collapsible prayer text ──
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final textSpan = TextSpan(
                          text: item.cPrayer.trim(),
                          style: TextStyle(
                            fontSize: 13,
                            color: isDone ? Colors.blue[700] : Colors.black54,
                            height: 1.5,
                          ),
                        );
                       final textPainter = TextPainter(
                            text: textSpan,
                          maxLines: maxLines,
                          textDirection: Directionality.of(context),
                            )..layout(maxWidth: constraints.maxWidth);

                        final isOverflowing = textPainter.didExceedMaxLines;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.cPrayer.trim(),
                              maxLines: isExpanded ? null : maxLines,
                              overflow: isExpanded
                                  ? TextOverflow.visible
                                  : TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                color:
                                    isDone ? Colors.blue[700] : Colors.black54,
                                height: 1.5,
                              ),
                            ),
                            if (isOverflowing) ...[
                              const SizedBox(height: 4),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    if (isExpanded) {
                                      _expandedPrayers.remove(item.nJMID);
                                    } else {
                                      _expandedPrayers.add(item.nJMID);
                                    }
                                  });
                                },
                                child: Text(
                                  isExpanded ? 'Read Less ▲' : 'Read More ▼',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isDone
                                        ? Colors.blue[600]
                                        : Colors.cyan[700],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // ── Progress bar 
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: item.nNoofTimes > 0 ? count / item.nNoofTimes : 1,
            minHeight: 6,
            backgroundColor: Colors.cyan[50],
            valueColor: AlwaysStoppedAnimation<Color>(
              isDone ? Colors.blue : Colors.cyan,
            ),
          ),
        ),

        const SizedBox(height: 8),

        //  Bottom row: count label + tap button 
        if (!isOnce)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$count / ${item.nNoofTimes}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDone ? Colors.blue[700] : Colors.grey[600],
                ),
              ),
              GestureDetector(
                onTap: isDone ? null : () => _onTapCount(item),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDone ? Colors.blue[200] : Colors.cyan[400],
                    boxShadow: isDone
                        ? []
                        : [
                            BoxShadow(
                              color: Colors.cyan.withOpacity(0.4),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            )
                          ],
                  ),
                  child: Center(
                    child: Text(
                      isDone ? '✓' : '+',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isDone ? Colors.blue[800] : Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
      ],
    ),
  );

  if (isOnce) {
    return GestureDetector(
      onTap: isDone ? null : () => _onTapCount(item),
      child: cardContent,
    );
  }

  return cardContent;
}
}