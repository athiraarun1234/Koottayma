import 'dart:convert';
import 'package:Koottaayma/HTTPURL/httpurl.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:table_calendar/table_calendar.dart';
import 'package:http/http.dart' as http;
//athira arun flutter

// Model for Calendar Events
class CalendarEventModel {
  final int nCalendarEventsID;
  final String dDate;
  final String cEventName;

  CalendarEventModel({
    required this.nCalendarEventsID,
    required this.dDate,
    required this.cEventName,
  });

  factory CalendarEventModel.fromJson(Map<String, dynamic> json) {
    return CalendarEventModel(
      nCalendarEventsID: json['nCalendarEventsID'] ?? 0,
      dDate: json['dDate'] ?? '',
      cEventName: json['cEventName'] ?? '',
    );
  }

  DateTime get eventDate {
    try {
      return DateTime.parse(dDate);
    } catch (e) {
      return DateTime.now();
    }
  }
}

// Model for Timings
class TimingModel {
  final int nHolyMassMasterID;
  final String dStartTime;
  final String dDate;
  final String cChurchName;
  final String cProgrammeeName;

  TimingModel({
    required this.nHolyMassMasterID,
    required this.dStartTime,
    required this.dDate,
    required this.cChurchName,
    required this.cProgrammeeName,
  });

  factory TimingModel.fromJson(Map<String, dynamic> json) {
    return TimingModel(
      nHolyMassMasterID: json['nHolyMassMasterID'] ?? 0,
      dStartTime: json['dStartTime'] ?? '',
      dDate: json['dDate'] ?? '',
      cChurchName: json['cChurchName'] ?? '',
      cProgrammeeName: json['cProgrammeeName'] ?? '',
    );
  }

  DateTime get eventDate {
    try {
      return DateTime.parse(dDate);
    } catch (e) {
      return DateTime.now();
    }
  }
}

// Model for Special Programs
class SpecialProgramModel {
  final int nSpecialProgramID;
  final String dStartDate;
  final String dEndDate;
  final String cImagePath;
  final String cMessageText;

  SpecialProgramModel({
    required this.nSpecialProgramID,
    required this.dStartDate,
    required this.dEndDate,
    required this.cImagePath,
    required this.cMessageText,
  });

  factory SpecialProgramModel.fromJson(Map<String, dynamic> json) {
    return SpecialProgramModel(
      nSpecialProgramID: json['nSpecialProgramID'] ?? 0,
      dStartDate: json['dStartDate'] ?? '',
      dEndDate: json['dEndDate'] ?? '',
      cImagePath: json['cImagePath'] ?? '',
      cMessageText: json['cMessageText'] ?? '',
    );
  }
  
 DateTime get startDate {
    try {
      // Parse DD-MM-YYYY format
      return _parseCustomDate(dStartDate);
    } catch (e) {
      return DateTime.now();
    }
  }
  
  DateTime get endDate {
    try {
      // Parse DD-MM-YYYY format
      return _parseCustomDate(dEndDate);
    } catch (e) {
      return DateTime.now();
    }
  }
  
  // Helper method to parse DD-MM-YYYY format
  static DateTime _parseCustomDate(String dateStr) {
    try {
      final parts = dateStr.split('-');
      if (parts.length == 3) {
        final day = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        return DateTime(year, month, day);
      }
    } catch (e) {
      // If custom parsing fails, try standard parsing
    }
    return DateTime.parse(dateStr);
  }
}

class CalenderDatesDetails extends StatefulWidget {
  @override
  State<CalenderDatesDetails> createState() => _CalenderDatesDetailsState();
}

class _CalenderDatesDetailsState extends State<CalenderDatesDetails> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  bool isLoading = false;
  String? errorMessage;

  // Store events mapped by date
  Map<DateTime, List<CalendarEventModel>> _calendarEvents = {};
  Map<DateTime, List<TimingModel>> _timings = {};
  Map<DateTime, List<SpecialProgramModel>> _specialPrograms = {};

  List<SpecialProgramModel> _allspecialPrograms = [];
  List<CalendarEventModel> _allCalendarEvents = [];
  List<TimingModel> _allTimings = [];

  @override
  void initState() {
    super.initState();
    _fetchCalendarEvents();
  }

  

Future<void> _fetchCalendarEvents() async {
  setState(() {
    isLoading = true;
    errorMessage = null;
  });

  try {
    final response = await http.get(
      Uri.parse(CalenderEventsAPI),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      
      // Extract calendar events
      final List<dynamic> calendarEventsJson = responseData['lstCalendarEvents'] ?? [];
      // Extract timings
      final List<dynamic> timingsJson = responseData['lstTimings'] ?? [];
      // Extract special programs
      final List<dynamic> specialProgramsJson = responseData['lstSpecialPrograms'] ?? [];
      
      print('=== API Response Debug ===');
      print('Calendar Events: ${calendarEventsJson.length}');
      print('Timings: ${timingsJson.length}');
      print('Special Programs: ${specialProgramsJson.length}');
      
      setState(() {
        _allCalendarEvents = calendarEventsJson
            .map((json) => CalendarEventModel.fromJson(json))
            .toList();
        
        _allTimings = timingsJson
            .map((json) => TimingModel.fromJson(json))
            .toList();
        
        _allspecialPrograms = specialProgramsJson
            .map((json) => SpecialProgramModel.fromJson(json))
            .toList();
        
        print('=== Special Programs Details ===');
        for (var sp in _allspecialPrograms) {
          print('Program: "${sp.cMessageText}"');
          print('  Start: ${sp.dStartDate}');
          print('  End: ${sp.dEndDate}');
          print('  Normalized End: ${_normalizeDate(sp.endDate)}');
        }
        
        // Map calendar events by normalized date
        _calendarEvents = {};
        for (var event in _allCalendarEvents) {
          final normalizedDate = _normalizeDate(event.eventDate);
          if (_calendarEvents[normalizedDate] == null) {
            _calendarEvents[normalizedDate] = [];
          }
          _calendarEvents[normalizedDate]!.add(event);
        }
        
        // Map timings by normalized date
        _timings = {};
        for (var timing in _allTimings) {
          final normalizedDate = _normalizeDate(timing.eventDate);
          if (_timings[normalizedDate] == null) {
            _timings[normalizedDate] = [];
          }
          _timings[normalizedDate]!.add(timing);
        }
        
        // Map special programs by END DATE only
        _specialPrograms = {};
        print('=== Mapping Special Programs ===');
        for (var special in _allspecialPrograms) {
          final endDate = _normalizeDate(special.endDate);
          print('Mapping "${special.cMessageText}" to END DATE: $endDate');
          
          // Add the special program only to the end date
          if (_specialPrograms[endDate] == null) {
            _specialPrograms[endDate] = [];
          }
          _specialPrograms[endDate]!.add(special);
        }
        
        print('=== Special Programs Map Contents ===');
        _specialPrograms.forEach((date, programs) {
          print('Date: $date has ${programs.length} program(s)');
          for (var p in programs) {
            print('  - ${p.cMessageText}');
          }
        });
        
        isLoading = false;
      });
    } else {
      setState(() {
        errorMessage = 'Failed to load events: ${response.statusCode}';
        isLoading = false;
      });
    }
  } catch (e) {
    print('=== ERROR ===');
    print(e);
    setState(() {
      errorMessage = 'Error loading events: $e';
      isLoading = false;
    });
  }
}

  /// Normalize date (remove time)
  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Get events for a specific day (combines calendar events, timings, and special programs)
  List<dynamic> _getEventsForDay(DateTime day) {
    final normalizedDay = _normalizeDate(day);
    List<dynamic> allEvents = [];
    
    // Add calendar events
    if (_calendarEvents[normalizedDay] != null) {
      allEvents.addAll(_calendarEvents[normalizedDay]!);
    }
    
    // Add timings
    if (_timings[normalizedDay] != null) {
      allEvents.addAll(_timings[normalizedDay]!);
    }
    
    // Add special programs
    if (_specialPrograms[normalizedDay] != null) {
      allEvents.addAll(_specialPrograms[normalizedDay]!);
    }
    
    return allEvents;
  }

  /// Show detailed modal for special program
  void _showProgramDetailModal(SpecialProgramModel program) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: EdgeInsets.only(top: 12, bottom: 20),
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            
            // Close button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: EdgeInsets.only(right: 16),
                child: IconButton(
                  icon: Icon(Icons.close, color: Colors.grey[600]),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            
            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Image at the top
                          if (program.cImagePath.isNotEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(16),
                                topRight: Radius.circular(16),
                              ),
                              child: Image.network(
                                program.cImagePath,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: 400,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    height: 400,
                                    color: Colors.grey[300],
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        color: Colors.cyan,
                                        value: loadingProgress.expectedTotalBytes != null
                                            ? loadingProgress.cumulativeBytesLoaded /
                                                loadingProgress.expectedTotalBytes!
                                            : null,
                                      ),
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    height: 400,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(16),
                                        topRight: Radius.circular(16),
                                      ),
                                    ),
                                    child: Center(
                                      child: Icon(
                                        Icons.image_not_supported,
                                        size: 40,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),

                          // Content Section
                          Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Title
                                Text(
                                  program.cMessageText,
                                  style: GoogleFonts.poppins(
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                    height: 1.3,
                                  ),
                                ),
                                SizedBox(height: 12),
                                
                                // Date Information
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'START DATE',
                                            style: GoogleFonts.roboto(
                                              color: Colors.grey[600],
                                              fontWeight: FontWeight.w500,
                                              fontSize: 10,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            program.dStartDate,
                                            style: GoogleFonts.roboto(
                                              color: Colors.black87,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'END DATE',
                                            style: GoogleFonts.roboto(
                                              color: Colors.grey[600],
                                              fontWeight: FontWeight.w500,
                                              fontSize: 10,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            program.dEndDate,
                                            style: GoogleFonts.roboto(
                                              color: Colors.black87,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
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
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            
            // Bottom close button
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyan,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline),
                      SizedBox(width: 8),
                      Text(
                        "Close",
                        style: GoogleFonts.roboto(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Show detailed modal for calendar event
  void _showEventDetailModal(CalendarEventModel event) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.5,
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
              margin: EdgeInsets.only(top: 12, bottom: 20),
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.purple[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.celebration, color: Colors.purple, size: 32),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            event.cEventName,
                            style: GoogleFonts.roboto(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: Colors.grey[600]),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    SizedBox(height: 24),
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.purple[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, color: Colors.purple),
                          SizedBox(width: 12),
                          Text(
                            _formatDate(event.dDate),
                            style: GoogleFonts.roboto(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline),
                      SizedBox(width: 8),
                      Text(
                        "Close",
                        style: GoogleFonts.roboto(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Show detailed modal for timing
  void _showTimingDetailModal(TimingModel timing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
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
              margin: EdgeInsets.only(top: 12, bottom: 20),
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.schedule, color: Colors.blue, size: 32),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            timing.cProgrammeeName,
                            style: GoogleFonts.roboto(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: Colors.grey[600]),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    SizedBox(height: 24),
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(Icons.access_time, color: Colors.blue),
                              SizedBox(width: 12),
                              Text(
                                'Time',
                                style: GoogleFonts.roboto(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Spacer(),
                              Text(
                                _formatTime(timing.dStartTime),
                                style: GoogleFonts.roboto(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          Row(
                            children: [
                              Icon(Icons.calendar_today, color: Colors.blue),
                              SizedBox(width: 12),
                              Text(
                                'Date',
                                style: GoogleFonts.roboto(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Spacer(),
                              Text(
                                _formatDate(timing.dDate),
                                style: GoogleFonts.roboto(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.location_on, color: Colors.blue),
                              SizedBox(width: 12),
                              Text(
                                'Location',
                                style: GoogleFonts.roboto(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  timing.cChurchName,
                                  style: GoogleFonts.roboto(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                  textAlign: TextAlign.right,
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
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline),
                      SizedBox(width: 8),
                      Text(
                        "Close",
                        style: GoogleFonts.roboto(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        SizedBox(width: 12),
        Text(
          title,
          style: GoogleFonts.roboto(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildSpecialProgramCard(SpecialProgramModel program) {
    return InkWell(
      onTap: () => _showProgramDetailModal(program),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.cyan[50]!, Colors.cyan[50]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.cyan[100]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.cyan,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.star, color: Colors.white, size: 24),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        program.cMessageText,
                        style: GoogleFonts.roboto(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 4),
                    
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, size: 16, color: Colors.cyan),
              ],
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  _buildInfoRow(Icons.calendar_today, "Start Date", _formatDate(program.dStartDate)),
                  SizedBox(height: 8),
                  _buildInfoRow(Icons.event_available, "End Date", _formatDate(program.dEndDate)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarEventCard(CalendarEventModel event) {
    return SafeArea(
      child: InkWell(
        onTap: () => _showEventDetailModal(event),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: EdgeInsets.only(bottom: 12),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.purple[50]!, Colors.pink[50]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.purple[100]!),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purple,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.celebration, color: Colors.white, size: 24),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.cEventName,
                      style: GoogleFonts.roboto(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 4),
                    
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.purple),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimingCard(TimingModel timing) {
    return SafeArea(
      child: InkWell(
        onTap: () => _showTimingDetailModal(timing),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: EdgeInsets.only(bottom: 12),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue[100]!),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.access_time, color: Colors.blue, size: 20),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      timing.cProgrammeeName,
                      style: GoogleFonts.roboto(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, size: 16, color: Colors.blue),
                ],
              ),
              SizedBox(height: 12),
              _buildInfoRow(Icons.schedule, "Time", _formatTime(timing.dStartTime)),
              SizedBox(height: 8),
              _buildInfoRow(Icons.location_on, "Location", timing.cChurchName),
            
             
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        SizedBox(width: 8),
        Text(
          "$label: ",
          style: GoogleFonts.roboto(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.roboto(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  String _formatTime(String timeStr) {
    try {
      final parts = timeStr.split(':');
      if (parts.length >= 2) {
        int hour = int.parse(parts[0]);
        int minute = int.parse(parts[1]);
        String period = hour >= 12 ? 'PM' : 'AM';
        if (hour > 12) hour -= 12;
        if (hour == 0) hour = 12;
        return "${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period";
      }
    } catch (e) {
      return timeStr;
    }
    return timeStr;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.cyan,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Special Programs",
          style: GoogleFonts.roboto(fontWeight: FontWeight.bold,color: Colors.white),
        ),
        centerTitle: true,
       
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          errorMessage!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.roboto(color: Colors.red),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _fetchCalendarEvents,
                          child: Text(
                            "Retry",
                            style: GoogleFonts.roboto(),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    // Calendar Section
                    TableCalendar<dynamic>(
                      firstDay: DateTime.utc(2020, 1, 1),
                      lastDay: DateTime.utc(2030, 12, 31),
                      focusedDay: _focusedDay,
                      calendarFormat: _calendarFormat,
                      selectedDayPredicate: (day) =>
                          isSameDay(_selectedDay, day),
                      eventLoader: _getEventsForDay,
                      onDaySelected: (selectedDay, focusedDay) {
                        setState(() {
                          _selectedDay = selectedDay;
                          _focusedDay = focusedDay;
                        });
                      },
                      onFormatChanged: (format) {
                        setState(() {
                          _calendarFormat = format;
                        });
                      },
                      onPageChanged: (focusedDay) {
                        setState(() {
                          _focusedDay = focusedDay;
                        });
                      },
                      calendarStyle: CalendarStyle(
                        defaultTextStyle:
                            GoogleFonts.roboto(color: Colors.black),
                        weekendTextStyle:
                            GoogleFonts.roboto(color: Colors.blue),
                        selectedTextStyle: GoogleFonts.roboto(
                            color: Colors.white, fontWeight: FontWeight.bold),
                        todayTextStyle: GoogleFonts.roboto(
                            color: Colors.white, fontWeight: FontWeight.bold),
                        todayDecoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                        selectedDecoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                        markerDecoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        markerSize: 6.0,
                        markerMargin: const EdgeInsets.symmetric(horizontal: 1),
                        markersMaxCount: 1
                      ),
                      headerStyle: HeaderStyle(
                        formatButtonVisible: true,
                        titleCentered: true,
                        formatButtonShowsNext: false,
                        titleTextStyle: GoogleFonts.roboto(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      daysOfWeekStyle: DaysOfWeekStyle(
                        weekdayStyle: GoogleFonts.roboto(
                          fontWeight: FontWeight.bold,
                        ),
                        weekendStyle: GoogleFonts.roboto(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Events Section - DIRECTLY SHOWING ALL EVENTS
                    Expanded(
                      child: _selectedDay == null
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 64,
                                    color: Colors.grey[300],
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    "Select a date to view events",
                                    style: GoogleFonts.roboto(
                                      color: Colors.grey,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : _getEventsForDay(_selectedDay!).isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.event_busy,
                                        size: 64,
                                        color: Colors.grey[300],
                                      ),
                                      SizedBox(height: 16),
                                      Text(
                                        "No events on this date",
                                        style: GoogleFonts.roboto(
                                          color: Colors.grey,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView(
                                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  children: [
                                    // Date Header
                                    Container(
                                      padding: EdgeInsets.all(16),
                                      margin: EdgeInsets.only(bottom: 16),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [Colors.cyan, Colors.cyan[700]!],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.event, color: Colors.white, size: 28),
                                          SizedBox(width: 12),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                _formatDate(_selectedDay.toString()),
                                                style: GoogleFonts.roboto(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              Text(
                                                "${_getEventsForDay(_selectedDay!).length} Event(s)",
                                                style: GoogleFonts.roboto(
                                                  fontSize: 14,
                                                  color: Colors.white.withOpacity(0.9),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    
                                    // Special Programs Section
                                    if ((_specialPrograms[_normalizeDate(_selectedDay!)] ?? []).isNotEmpty) ...[
                                      _buildSectionHeader("Special Programs", Icons.star, Colors.cyan),
                                      SizedBox(height: 12),
                                      ...(_specialPrograms[_normalizeDate(_selectedDay!)] ?? [])
                                          .map((program) => _buildSpecialProgramCard(program))
                                          .toList(),
                                      SizedBox(height: 24),
                                    ],
                                    
                                    // Calendar Events Section
                                    if ((_calendarEvents[_normalizeDate(_selectedDay!)] ?? []).isNotEmpty) ...[
                                      _buildSectionHeader("Special Events", Icons.celebration, Colors.purple),
                                      SizedBox(height: 12),
                                      ...(_calendarEvents[_normalizeDate(_selectedDay!)] ?? [])
                                          .map((event) => _buildCalendarEventCard(event))
                                          .toList(),
                                      SizedBox(height: 24),
                                    ],
                                    
                                    // Timings Section
                                    if ((_timings[_normalizeDate(_selectedDay!)] ?? []).isNotEmpty) ...[
                                      _buildSectionHeader("Holy Mass", Icons.schedule, Colors.blue),
                                      SizedBox(height: 12),
                                      ...(_timings[_normalizeDate(_selectedDay!)] ?? [])
                                          .map((timing) => _buildTimingCard(timing))
                                          .toList(),
                                      SizedBox(height: 16),
                                    ],
                                  ],
                                ),
                    ),
                  ],
                ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }
  
  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'N/A';

    try {
      DateTime date = DateTime.parse(dateStr);
      return "${date.day} ${_getMonthName(date.month)} ${date.year}";
    } catch (e) {
      return dateStr;
    }
  }
}