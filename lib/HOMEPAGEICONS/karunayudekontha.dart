
import 'package:Koottaayma/SQFLITEVERSION1/DataBaseHelper.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';


class PrayerItem {
  final int nJMOthersID;
  final String cHeading;
  final String cPrayer;
  final int nPrayedBy;
  final int nEchoedBy;
  final int nNoofTimes;
  final int nPrayerTypeID; // 1 = song, 2 = prayer/article

  PrayerItem({
    required this.nJMOthersID,
    required this.cHeading,
    required this.cPrayer,
    required this.nPrayedBy,
    required this.nEchoedBy,
    required this.nNoofTimes,
    required this.nPrayerTypeID,
  });

  factory PrayerItem.fromJson(Map<String, dynamic> json) {
    return PrayerItem(
      nJMOthersID:    (json['nJMOthersID']    ?? 0)  as int,
      cHeading:       (json['cHeading']        ?? '') as String,  
      cPrayer:        (json['cPrayer']         ?? '') as String,  
      nPrayedBy:      (json['nPrayedBy']       ?? 0)  as int,    
      nEchoedBy:      (json['nEchoedBy']       ?? 0)  as int,
      nNoofTimes:     (json['nNoofTimes']      ?? 1)  as int,
      nPrayerTypeID:  (json['nPrayerTypeID']   ?? 0)  as int,     
    );
  }

  bool get isSong => nPrayerTypeID == 1;
}

class Karunayudekontha extends StatefulWidget {
  const Karunayudekontha({super.key});

  @override
  State<Karunayudekontha> createState() => _KarunayudekonthaState();
}

class _KarunayudekonthaState extends State<Karunayudekontha> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final AudioPlayer _audioPlayer = AudioPlayer();

  int? _userPhoneNumber;
  bool _isLoading = true;
  String? _error;

  List<PrayerItem> _allItems = [];
  Map<int, int> _counts = {};   // { nJMOthersID → currentCount }

  // ── Audio 
  bool _isPlaying = false;
  bool _isAudioLoading = false;
  int? _playingJMID;
  int? _loadingJMID;
final Set<int> _expandedPrayers = {};

  @override
  void initState() {
    super.initState();
    _fetchData();

    _audioPlayer.onPlayerStateChanged.listen((PlayerState state) {
      if (!mounted) return;
      setState(() {
        _isPlaying = state == PlayerState.playing;
        if (state != PlayerState.playing) _playingJMID = null;
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
          await _dbHelper.getCachedKarunayudeKonthaDetails(_userPhoneNumber!);

      if (cached == null || cached.isEmpty) {
        setState(() {
          _error = 'No cached data found. Please sync your data first.';
          _isLoading = false;
        });
        return;
      }

      // Parse all rows — no grouping needed
      final List<PrayerItem> items = (cached as List)
          .whereType<Map<String, dynamic>>()
          .map(PrayerItem.fromJson)
          .toList();

      final Map<int, int> counts = {
        for (final item in items) item.nJMOthersID: 0,
      };

      setState(() {
        _allItems  = items;
        _counts    = counts;
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

  // 

  void _onTapCount(PrayerItem item) {
    final current = _counts[item.nJMOthersID] ?? 0;
    if (current >= item.nNoofTimes) return;
    setState(() => _counts[item.nJMOthersID] = current + 1);
  }

  void _resetAll() {
    setState(() {
      for (final item in _allItems) {
        _counts[item.nJMOthersID] = 0;
      }
    });
  }

  bool _isAllComplete() => _allItems.every(
      (item) => (_counts[item.nJMOthersID] ?? 0) >= item.nNoofTimes);

  // 

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
        setState(() { _isAudioLoading = true; _loadingJMID = jmID; });
        await _audioPlayer.pause();
        setState(() {
          _isPlaying = false; _playingJMID = null;
          _isAudioLoading = false; _loadingJMID = null;
        });
        return;
      }
      setState(() { _isAudioLoading = true; _loadingJMID = jmID; });
      await _audioPlayer.stop();
      await _audioPlayer.play(UrlSource(audioUrl));
      setState(() {
        _playingJMID = jmID; _isPlaying = true;
        _isAudioLoading = false; _loadingJMID = null;
      });
    } catch (e) {
      setState(() {
        _isAudioLoading = false; _loadingJMID = null;
        _playingJMID = null; _isPlaying = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error playing audio: $e'),
            backgroundColor: Colors.red),
      );
    }
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
          'കരുണയുടെ കൊന്ത',
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
                child: Text(_error!,
                    style: const TextStyle(color: Colors.red, fontSize: 13)),
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

  // ── Main body 
  Widget _buildBody() {
    if (_allItems.isEmpty) {
      return const Center(
        child: Text('No prayer items found.',
            style: TextStyle(fontSize: 16, color: Colors.black54)),
      );
    }

    final allDone = _isAllComplete();

    return Column(
      children: [
        // Date header
        // Container(
        //   margin: const EdgeInsets.fromLTRB(8, 8, 8, 0),
        //   height: 45,
        //   width: double.infinity,
        //   alignment: Alignment.center,
        //   decoration: BoxDecoration(
        //     color: Colors.white,
        //     borderRadius: BorderRadius.circular(8),
        //   ),
        //   child: Text(
        //     DateFormat('dd MMM yyyy, EEEE').format(DateTime.now()),
        //     style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        //   ),
        // ),

        const SizedBox(height: 8),

        // "All complete" banner with reset button
        if (allDone)
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle,
                          color: Colors.blue[700], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Completed!',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800],
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: _resetAll,
                    child: const Icon(Icons.replay,
                        size: 20, color: Colors.blueGrey),
                  ),
                ],
              ),
            ),
          ),

        // ── Flat list of all prayer cards 
        Expanded(
          child: SafeArea(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 20),
              itemCount: _allItems.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) => _buildPrayerCard(_allItems[i]),
            ),
          ),
        ),
      ],
    );
  }

  // ── Single prayer card 
Widget _buildPrayerCard(PrayerItem item) {
  final count       = _counts[item.nJMOthersID] ?? 0;
  final isDone      = count >= item.nNoofTimes;
  final showHeading = item.cHeading.isNotEmpty && item.cHeading != '-';
  final showPrayer  = item.cPrayer.isNotEmpty  && item.cPrayer  != '-';
  final isOnce      = item.nNoofTimes == 1;
  final isSong      = item.nPrayerTypeID == 1; // ✅ song vs prayer

  const int maxLines    = 4;
  final bool isExpanded = _expandedPrayers.contains(item.nJMOthersID);

  // ── Theme colors based on type 
  final Color cardColor      = isDone
      ? (isSong ? Colors.purple[50]! : Colors.blue[50]!)
      : Colors.white.withOpacity(0.85);
  final Color borderColor    = isDone
      ? (isSong ? Colors.purple.withOpacity(0.4) : Colors.blue.withOpacity(0.4))
      : (isSong ? Colors.purple.withOpacity(0.3) : Colors.cyan.withOpacity(0.3));
  final Color headingColor   = isDone
      ? (isSong ? Colors.purple[800]! : Colors.blue[800]!)
      : (isSong ? Colors.deepPurple    : Colors.black87);
  final Color bodyColor      = isDone
      ? (isSong ? Colors.purple[700]! : Colors.blue[700]!)
      : (isSong ? Colors.purple[400]! : Colors.black54);
  final Color progressActive = isDone
      ? (isSong ? Colors.purple       : Colors.blue)
      : (isSong ? Colors.purple[300]! : Colors.cyan);
  final Color readMoreColor  = isDone
      ? (isSong ? Colors.purple[600]! : Colors.blue[600]!)
      : (isSong ? Colors.purple[400]! : Colors.cyan[700]!);
  final Color countColor     = isDone
      ? (isSong ? Colors.purple[700]! : Colors.blue[700]!)
      : Colors.grey[600]!;
  final Color btnColor       = isDone
      ? (isSong ? Colors.purple[200]! : Colors.blue[200]!)
      : (isSong ? Colors.purple[400]! : Colors.cyan[400]!);
  final Color btnTextColor   = isDone
      ? (isSong ? Colors.purple[800]! : Colors.blue[800]!)
      : Colors.white;

  final cardContent = Container(
    decoration: BoxDecoration(
      color: cardColor,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: borderColor, width: 1.2),
    ),
    padding: const EdgeInsets.all(12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        // ── Type badge + Heading row 
        if (showHeading)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Badge icon
              Container(
                margin: const EdgeInsets.only(top: 1, right: 6),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSong ? Colors.purple[100] : Colors.cyan[100],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isSong ? Icons.music_note : Icons.menu_book_rounded,
                      size: 12,
                      color: isSong ? Colors.purple[700] : Colors.cyan[700],
                    ),
                    const SizedBox(width: 3),
                    // Text(
                    //   isSong ? 'Song' : 'Prayer',
                    //   style: TextStyle(
                    //     fontSize: 10,
                    //     fontWeight: FontWeight.w600,
                    //     color: isSong ? Colors.purple[700] : Colors.cyan[700],
                    //   ),
                    // ),
                  ],
                ),
              ),
              // Heading text
              Expanded(
                child: Text(
                  item.cHeading,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: headingColor,
                  ),
                ),
              ),
            ],
          ),

        // ── Prayer / Song body with Read More 
        if (showPrayer) ...[
          if (showHeading) const SizedBox(height: 6),
          LayoutBuilder(
            builder: (context, constraints) {
              final textSpan = TextSpan(
                text: item.cPrayer.trim(),
                style: TextStyle(
                  fontSize: 13,
                  fontStyle: isSong ? FontStyle.italic : FontStyle.normal, //  songs italic
                  color: bodyColor,
                  height: 1.6,
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
                      fontStyle: isSong ? FontStyle.italic : FontStyle.normal,
                      color: bodyColor,
                      height: 1.6,
                    ),
                  ),
                  if (isOverflowing) ...[
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: () => setState(() {
                        isExpanded
                            ? _expandedPrayers.remove(item.nJMOthersID)
                            : _expandedPrayers.add(item.nJMOthersID);
                      }),
                      child: Text(
                        isExpanded ? 'Read Less ▲' : 'Read More ▼',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: readMoreColor,
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ],

        const SizedBox(height: 10),

        // ── Progress bar 
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: item.nNoofTimes > 0 ? count / item.nNoofTimes : 1,
            minHeight: 6,
            backgroundColor: isSong ? Colors.purple[50] : Colors.cyan[50],
            valueColor: AlwaysStoppedAnimation<Color>(progressActive),
          ),
        ),

        // ── Count label + tap button (only when nNoofTimes > 1) ──────────
        if (!isOnce) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$count / ${item.nNoofTimes}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: countColor,
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
                    color: btnColor,
                    boxShadow: isDone
                        ? []
                        : [
                            BoxShadow(
                              color: (isSong ? Colors.purple : Colors.cyan)
                                  .withOpacity(0.4),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                  ),
                  child: Center(
                    child: Text(
                      isDone ? '✓' : '+',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: btnTextColor,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    ),
  );

  // ── Tap whole card when nNoofTimes == 1 
  if (isOnce) {
    return GestureDetector(
      onTap: isDone ? null : () => _onTapCount(item),
      child: cardContent,
    );
  }

  return cardContent;
}
}