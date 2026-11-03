import 'dart:convert';
import 'package:Koottaayma/HTTPURL/formatdate.dart';
import 'package:Koottaayma/HTTPURL/httpurl.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// ── Model 

class MessageItem {
  final String uploadedPath;
  final String date;

  const MessageItem({required this.uploadedPath, required this.date});

  factory MessageItem.fromJson(Map<String, dynamic> json) => MessageItem(
        uploadedPath: json['cUploadedPath'] as String? ?? '',
        date: json['dDate'] as String? ?? '',
      );

  /// Detect what kind of content this item carries.
  ContentType get contentType {
    final p = uploadedPath.toLowerCase();
    if (p.startsWith('http://') || p.startsWith('https://')) {
      // Image extensions
      if (p.endsWith('.jpg') ||
          p.endsWith('.jpeg') ||
          p.endsWith('.png') ||
          p.endsWith('.gif') ||
          p.endsWith('.webp')) {
        return ContentType.image;
      }
      // Audio extensions
      if (p.endsWith('.mp3') ||
          p.endsWith('.m4a') ||
          p.endsWith('.wav') ||
          p.endsWith('.ogg') ||
          p.endsWith('.aac')) {
        return ContentType.audio;
      }
      return ContentType.link;
    }
    // Local audio files
    if (p.endsWith('.mp3') ||
        p.endsWith('.m4a') ||
        p.endsWith('.wav') ||
        p.endsWith('.ogg') ||
        p.endsWith('.aac')) {
      return ContentType.audio;
    }
    return ContentType.text;
  }
}

enum ContentType { text, image, audio, link }

// ── API Service ────────────────────────────────────────────────────────────

class PriestMessagesService {
  // 🔧 Replace with your actual endpoint
 // static const String _baseUrl =
      //'https://lv4hfxvb-7000.inc1.devtunnels.ms/notifications/priestapprovalnotifications/';

  static Future<List<MessageItem>> fetchMessages() async {
    final response = await http
        .get(Uri.parse(PriestMessageShows))
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final Map<String, dynamic> body = jsonDecode(response.body);

      if (body['Success'] == true) {
        final List<dynamic> raw = body['lstapprovalrequestdetails'] ?? [];
        return raw.map((e) => MessageItem.fromJson(e)).toList();
      } else {
        throw Exception('Server returned Success: false');
      }
    } else {
      throw Exception('HTTP ${response.statusCode}: ${response.reasonPhrase}');
    }
  }
}

// ── Page ───────────────────────────────────────────────────────────────────

class PriestMessages extends StatefulWidget {
  const PriestMessages({super.key});

  @override
  State<PriestMessages> createState() => _PriestMessagesState();
}

class _PriestMessagesState extends State<PriestMessages> {
  late Future<List<MessageItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = PriestMessagesService.fetchMessages();
  }

  void _refresh() => setState(() {
        _future = PriestMessagesService.fetchMessages();
      });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF6F0),
      appBar: AppBar(
      backgroundColor: Colors.cyan,
        foregroundColor: Colors.white,
        title: const Text(
          'Priest Messages',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: FutureBuilder<List<MessageItem>>(
        future: _future,
        builder: (context, snapshot) {
          // ── Loading ──
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Color(0xFF8B3A2A)),
                  SizedBox(height: 12),
                  Text(
                    'Loading messages…',
                    style: TextStyle(color: Color(0xFF8B3A2A)),
                  ),
                ],
              ),
            );
          }

          // ── Error ──
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 60, color: Color(0xFFB00020)),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load messages',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _refresh,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try Again'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B3A2A),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // ── Empty ──
          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inbox_outlined, size: 64, color: Colors.black26),
                  SizedBox(height: 12),
                  Text('No messages yet',
                      style: TextStyle(color: Colors.black45)),
                ],
              ),
            );
          }

          // ── List ──
          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) =>
                _MessageCard(item: items[index]),
          );
        },
      ),
    );
  }
}

// ── Message Card 

class _MessageCard extends StatelessWidget {
  final MessageItem item;
  const _MessageCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Content area
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: _buildContent(context),
          ),

          // Date footer
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF5EDE8),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined,
                    size: 13, color: Color(0xFF8B3A2A)),
                const SizedBox(width: 6),
                Text(
                  DateFormatter.formatDateWithDay(item.date),
                 // item.date,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8B3A2A),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    switch (item.contentType) {
      // ── Text message 
      case ContentType.text:
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF5EDE8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.message_outlined,
                  color: Color(0xFF8B3A2A), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.uploadedPath,
                style: const TextStyle(fontSize: 15, height: 1.45),
              ),
            ),
          ],
        );

      // ── Image 
      case ContentType.image:
        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(
            item.uploadedPath,
            width: double.infinity,
            fit: BoxFit.cover,
            loadingBuilder: (_, child, progress) {
              if (progress == null) return child;
              return Container(
                height: 180,
                color: const Color(0xFFF5EDE8),
                child: Center(
                  child: CircularProgressIndicator(
                    value: progress.expectedTotalBytes != null
                        ? progress.cumulativeBytesLoaded /
                            progress.expectedTotalBytes!
                        : null,
                    color: const Color(0xFF8B3A2A),
                  ),
                ),
              );
            },
            errorBuilder: (_, __, ___) => Container(
              height: 120,
              color: const Color(0xFFF5EDE8),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.broken_image_outlined,
                        size: 36, color: Colors.black38),
                    SizedBox(height: 4),
                    Text('Image unavailable',
                        style: TextStyle(color: Colors.black38, fontSize: 12)),
                  ],
                ),
              ),
            ),
          ),
        );

      // ── Audio ─
      case ContentType.audio:
        final fileName = item.uploadedPath.split('/').last;
        return Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF8B3A2A),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.mic, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Voice Message',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(
                    fileName,
                    style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black45,
                        overflow: TextOverflow.ellipsis),
                    maxLines: 1,
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {
                // 🔧 Plug in just_audio / audioplayers here:
                // AudioPlayer().play(UrlSource(item.uploadedPath));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Add audioplayers package to play audio'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.play_circle_filled_rounded,
                  size: 36, color: Color(0xFF8B3A2A)),
            ),
          ],
        );

      // ── Generic link ──────────────────────────────────────────────────
      case ContentType.link:
        return Row(
          children: [
            const Icon(Icons.link, color: Color(0xFF8B3A2A)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                item.uploadedPath,
                style: const TextStyle(
                  color: Color(0xFF8B3A2A),
                  decoration: TextDecoration.underline,
                  fontSize: 13,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
    }
  }
}