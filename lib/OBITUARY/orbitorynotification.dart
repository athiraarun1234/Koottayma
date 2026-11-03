import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

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