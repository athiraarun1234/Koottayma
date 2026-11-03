import 'dart:convert';
import 'dart:io';

import 'package:Koottaayma/SQFLITEVERSION1/DataBaseHelper.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';

class KVItem {
  final int nKVID;
  final int nPlaceID;
  final String cPlaceName;
  final String cContextSummary;
  final String cContext;
  final String cEchoedContext;
  final int nContextType;
  final int cProclaimedBy;
  final String? cAudioPath;

  const KVItem({
    required this.nKVID,
    required this.nPlaceID,
    required this.cPlaceName,
    required this.cContextSummary,
    required this.cContext,
    required this.cEchoedContext,
    required this.nContextType,
    required this.cProclaimedBy,
    this.cAudioPath,
  });

  factory KVItem.fromJson(Map<String, dynamic> json) => KVItem(
        nKVID: json['nKVID'] as int? ?? 0,
        nPlaceID: json['nPlaceID'] as int? ?? 0,
        cPlaceName: json['cPlaceName'] as String? ?? '-',
        cContextSummary: json['cContextSummary'] as String? ?? '-',
        cContext: json['cContext'] as String? ?? '-',
        cEchoedContext: json['cEchoedContext'] as String? ?? '-',
        nContextType: json['nContextType'] as int? ?? 2,
        cProclaimedBy: json['cProclaimedBy'] is int
            ? json['cProclaimedBy'] as int
            : int.tryParse(json['cProclaimedBy'].toString()) ?? 1,
        //  Fixed typo: was 'cAduioPath'
        cAudioPath: json['cAudioPath'] as String?,
      );
}

String _stationLabel(int id) {
  const labels = {
    0: 'ആമുഖം',
    1: 'ഒന്നാം സ്ഥലം',
    2: 'രണ്ടാം സ്ഥലം',
    3: 'മൂന്നാം സ്ഥലം',
    4: 'നാലാം സ്ഥലം',
    5: 'അഞ്ചാം സ്ഥലം',
    6: 'ആറാം സ്ഥലം',
    7: 'ഏഴാം സ്ഥലം',
    8: 'എട്ടാം സ്ഥലം',
    9: 'ഒൻപതാം സ്ഥലം',
    10: 'പത്താം സ്ഥലം',
    11: 'പതിനൊന്നാം സ്ഥലം',
    12: 'പന്ത്രണ്ടാം സ്ഥലം',
    13: 'പതിമൂന്നാം സ്ഥലം',
    14: 'പതിനാലാം സ്ഥലം',
  };
  return labels[id] ?? 'സ്ഥലം $id';
}

class KurishintteVazhiPage extends StatefulWidget {
  const KurishintteVazhiPage({super.key});

  @override
  State<KurishintteVazhiPage> createState() => _KurishintteVazhiPageState();
}

class _KurishintteVazhiPageState extends State<KurishintteVazhiPage> {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  int? _userPhoneNumber;
  List<KVItem> _items = [];
  bool _isLoading = true;
  String? _errorMessage;

  final PageController _pageController = PageController();
  int _currentPage = 0;

  // ─── AUDIO STATE 
  final AudioPlayer _audioPlayer = AudioPlayer();
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  
  String? currentlyPlayingAudio;
  bool isPlaying = false;
 

  @override
  void initState() {
    super.initState();
    _loadKurishinttevazhiData();
    _setupAudioListeners();
  }

  // ── Audio listeners

  void _setupAudioListeners() {
    _audioPlayer.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
    });
    _audioPlayer.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });
    // Reset when audio completes
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _position = Duration.zero;
          isPlaying = false;
          currentlyPlayingAudio = null;
        });
      }
    });
  }

  // ── Play / Pause toggle 
 Future<String> _getCachedAudioPath(String audioUrl) async {
  final dir = await getApplicationDocumentsDirectory();
  
  // Use a hash of the URL as filename
  final fileName = audioUrl.hashCode.toString() + '.mp3';
  final localFile = File('${dir.path}/audio_cache/$fileName');

 print('Cache path: ${localFile.path}');           
  print('File exists: ${await localFile.exists()}'); 

  // Return cached file if it already exists
  if (await localFile.exists()) {
    return localFile.path; //  Play from disk
  }

  // Download and save
  await localFile.parent.create(recursive: true);
  final response = await http.get(Uri.parse(audioUrl));
  
  if (response.statusCode == 200) {
    await localFile.writeAsBytes(response.bodyBytes);
    return localFile.path;
  }
  
  throw Exception('Failed to download audio');
}


Future<void> _toggleAudio(String? audioUrl) async {
  if (audioUrl == null || audioUrl.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Audio not available for this reading')),
    );
    return;
  }

  try {
    if (currentlyPlayingAudio == audioUrl && isPlaying) {
      await _audioPlayer.pause();
      setState(() => isPlaying = false);
      return;
    }

    if (currentlyPlayingAudio == audioUrl && !isPlaying) {
      await _audioPlayer.resume();
      setState(() => isPlaying = true);
      return;
    }

    await _audioPlayer.stop();

    //  Download once, cache on disk, play from disk
    final localPath = await _getCachedAudioPath(audioUrl);
    await _audioPlayer.play(DeviceFileSource(localPath));

    setState(() {
      currentlyPlayingAudio = audioUrl;
      isPlaying = true;
      _position = Duration.zero;
    });
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error playing audio: $e'), backgroundColor: Colors.red),
    );
  }
}

  Future<void> _stopAudio() async {
    await _audioPlayer.stop();
    setState(() {
      _position = Duration.zero;
      isPlaying = false;
      currentlyPlayingAudio = null;
    });
  }

  // Stop audio when user swipes to a new page
  void _onPageChanged(int i) {
    setState(() => _currentPage = i);
    if (currentlyPlayingAudio != null) _stopAudio();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _pageController.dispose();
    super.dispose();
  }

  // ─── Data loading 

  Future<void> _getUserPhoneNumber() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? phone = prefs.getString('userPhone');
      if (phone != null) _userPhoneNumber = int.tryParse(phone);
    } catch (e) {
      print('Error getting user phone: $e');
    }
  }


 

  Future<void> _loadKurishinttevazhiData() async {
    if (_userPhoneNumber == null) await _getUserPhoneNumber();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    if (_userPhoneNumber == null) {
      setState(() {
        _errorMessage = 'User phone number not found. Please login again.';
        _isLoading = false;
      });
      return;
    }

    try {
      final cachedData =
          await _dbHelper.getCachedKurishinttevazhiDetails(_userPhoneNumber!);

      if (cachedData != null && cachedData.isNotEmpty) {
        _processAndSetItemsFromList(cachedData as List<dynamic>);
        return;
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading data: $e';
        _isLoading = false;
      });
    }
  }

  void _processAndSetItemsFromList(List<dynamic> decoded) {
    try {
      final items =
          decoded.map((e) => KVItem.fromJson(e as Map<String, dynamic>)).toList();
      setState(() {
        _items = items;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error parsing data: $e';
        _isLoading = false;
      });
    }
  }

  void _goTo(int index) => _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );

  // ─── Build 

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
          'കുരിശിന്റെ വഴി',
          style: GoogleFonts.notoSansMalayalam(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          if (!_isLoading && _items.isNotEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_currentPage + 1} / ${_items.length}',
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
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
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text('loading', style: TextStyle(color: Colors.white70)),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.white70, size: 48),
              const SizedBox(height: 12),
              Text(_errorMessage!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.notoSansMalayalam(
                      color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _loadKurishinttevazhiData,
                icon: const Icon(Icons.refresh),
                label: Text('Retry', style: GoogleFonts.notoSansMalayalam()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF006B7D),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_items.isEmpty) {
      return Center(
        child: Text('no data',
            style: GoogleFonts.notoSansMalayalam(
                color: Colors.white70, fontSize: 16)),
      );
    }

    return Column(
      children: [
        _buildStationDots(),
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: _items.length,
            onPageChanged: _onPageChanged,
            itemBuilder: (_, i) => _buildPage(_items[i]),
          ),
        ),
        _buildNavButtons(),
      ],
    );
  }

  Widget _buildStationDots() {
    final ids = _items.map((e) => e.nPlaceID).toSet().toList()..sort();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: ids.map((id) {
          final active = _items[_currentPage].nPlaceID == id;
          return GestureDetector(
            onTap: () {
              final idx = _items.indexWhere((e) => e.nPlaceID == id);
              if (idx != -1) _goTo(idx);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: active ? 36 : 10,
              height: 10,
              decoration: BoxDecoration(
                color: active ? Colors.white : Colors.white54,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── Single page 

  Widget _buildPage(KVItem item) {
    final bool hasEcho =
        item.cEchoedContext.isNotEmpty && item.cEchoedContext != '-';
    final bool hasContext = item.cContext.isNotEmpty && item.cContext != '-';
    final bool hasSummary =
        item.cContextSummary.isNotEmpty && item.cContextSummary != '-';
    final bool isHymn = item.nContextType == 1;
    final bool hasAudio =
        item.cAudioPath != null && item.cAudioPath!.isNotEmpty;

    //  Use URL string to determine play/pause state
    final bool isThisPlaying =
        currentlyPlayingAudio == item.cAudioPath && isPlaying;
    final bool isThisPaused = currentlyPlayingAudio == item.cAudioPath &&
        !isPlaying &&
        currentlyPlayingAudio != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Station chip ──
            if (item.cPlaceName != '-' || item.nPlaceID > 0)
              Center(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF006B7D),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    item.cPlaceName != '-'
                        ? item.cPlaceName
                        : _stationLabel(item.nPlaceID),
                    style: GoogleFonts.notoSansMalayalam(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),

            // ── AUDIO PLAYER CARD 
            if (hasAudio)
              _buildAudioCard(item, isThisPlaying, isThisPaused),

            if (hasSummary)
              _card(
                icon: Icons.info_outline,
                iconColor: const Color(0xFF006B7D),
                label: 'സംഗ്രഹം',
                content: item.cContextSummary,
                bgColor: const Color(0xFFE0F7FA),
                textStyle: GoogleFonts.notoSansMalayalam(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF004D5F),
                ),
              ),

            if (hasContext)
              _card(
                icon: isHymn ? Icons.music_note : Icons.menu_book_outlined,
                iconColor: isHymn
                    ? const Color(0xFF7B3F00)
                    : const Color(0xFF006B7D),
                label: isHymn ? 'ഗാനം' : 'പ്രാർത്ഥന',
                content: item.cContext,
                bgColor: isHymn ? const Color(0xFFFFF8E1) : Colors.white,
                textStyle: isHymn
                    ? GoogleFonts.notoSansMalayalam(
                        fontSize: 15.5,
                        fontWeight: FontWeight.bold,
                        height: 1.8,
                        color: const Color(0xFF4A2C00),
                      )
                    : GoogleFonts.notoSansMalayalam(
                        fontSize: 15.5,
                        height: 1.8,
                        color: const Color(0xFF1A1A2E),
                      ),
              ),

            if (hasEcho)
              _card(
                icon: Icons.record_voice_over_outlined,
                iconColor: const Color(0xFF5C0057),
                label: '',
                content: item.cEchoedContext,
                bgColor: const Color(0xFFF3E5F5),
                textStyle: GoogleFonts.notoSansMalayalam(
                  fontSize: 15.5,
                  height: 1.8,
                  color: const Color(0xFF4A005E),
                ),
              ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ─── Audio player card 

  Widget _buildAudioCard(KVItem item, bool isThisPlaying, bool isThisPaused) {
    final bool isActive = isThisPlaying || isThisPaused;
    final double progress = (isActive && _duration.inMilliseconds > 0)
        ? _position.inMilliseconds / _duration.inMilliseconds
        : 0.0;

    String fmt(Duration d) =>
        '${d.inMinutes.toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF006B7D),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        children: [
          Row(
            children: [
              //  Play / Pause button — passes URL directly
              GestureDetector(
                onTap: () => _toggleAudio(item.cAudioPath),
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  child: Icon(
                    isThisPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    color: const Color(0xFF006B7D),
                    size: 32,
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Progress + time
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isThisPlaying
                          ? 'Playing...'
                          : isThisPaused
                              ? 'Paused'
                              : 'Audio',
                      style: GoogleFonts.notoSansMalayalam(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress.clamp(0.0, 1.0),
                        minHeight: 5,
                        backgroundColor: Colors.white24,
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isActive ? fmt(_position) : '00:00',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 10),
                        ),
                        Text(
                          isActive ? fmt(_duration) : '--:--',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Stop button (only when active)
              if (isActive)
                IconButton(
                  onPressed: _stopAudio,
                  icon: const Icon(Icons.stop_rounded,
                      color: Colors.white70, size: 26),
                  tooltip: 'Stop',
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Card 

  Widget _card({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String content,
    required Color bgColor,
    required TextStyle textStyle,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Row(
              children: [
                Icon(icon, color: iconColor, size: 18),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: GoogleFonts.notoSansMalayalam(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: iconColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              content.replaceAll('\r\n', '\n').trim(),
              style: textStyle,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Navigation buttons 

  Widget _buildNavButtons() {
    final isFirst = _currentPage == 0;
    final isLast = _currentPage == _items.length - 1;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: AnimatedOpacity(
                opacity: isFirst ? 0.3 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: ElevatedButton.icon(
                  onPressed: isFirst ? null : () => _goTo(_currentPage - 1),
                  icon: const Icon(Icons.chevron_left),
                  label:
                      Text('Back', style: GoogleFonts.notoSansMalayalam()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF006B7D),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AnimatedOpacity(
                opacity: isLast ? 0.3 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: ElevatedButton.icon(
                  onPressed: isLast ? null : () => _goTo(_currentPage + 1),
                  icon: const Icon(Icons.chevron_right),
                  label:
                      Text('Next', style: GoogleFonts.notoSansMalayalam()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF006B7D),
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

