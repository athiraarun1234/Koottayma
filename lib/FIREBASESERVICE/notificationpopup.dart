import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:gal/gal.dart'; // for saving to gallery

class NotificationPopup extends StatefulWidget {
  final Map<String, dynamic> data;

  const NotificationPopup({
    super.key,
    required this.data,
  });

  @override
  State<NotificationPopup> createState() => _NotificationPopupState();
}

class _NotificationPopupState extends State<NotificationPopup> {
  bool _isDownloading = false;

  Future<void> _downloadImage(String imageUrl) async {
    setState(() => _isDownloading = true);

    try {
      // Request storage/photos permission
      final status = await Permission.photos.request();
      if (!status.isGranted && !status.isLimited) {
        _showSnackBar("Permission denied to save image");
        setState(() => _isDownloading = false);
        return;
      }

      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode != 200) {
        _showSnackBar("Failed to download image");
        setState(() => _isDownloading = false);
        return;
      }

      final bytes = response.bodyBytes;

      // Save directly to gallery (works for both Android & iOS)
      await Gal.putImageBytes(
        bytes,
        name: "priest_image_${DateTime.now().millisecondsSinceEpoch}",
      );

      _showSnackBar("Image saved to gallery");
    } catch (e) {
      _showSnackBar("Error downloading image: $e");
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String title = widget.data['title'] ?? 'Message from Priest';
    final String body = widget.data['body'] ?? '';
    final String imageUrl = widget.data['image_url'] ?? '';
    final String audioUrl = widget.data['audio_url'] ?? '';
    //final String date = widget.data['date'] ?? '';

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
       backgroundColor: const Color.fromARGB(255, 21, 134, 215),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
           crossAxisAlignment: CrossAxisAlignment.start, 
/////
          children: [
        
            Row(
                crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.notifications, color:Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                        color: Colors.white70,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close,color: Colors.white,),
                ),
              ],
            ),
            const Divider(),

            // Content
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Text message
                    if (body.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.shade50,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(body),
                      ),

                    // Image
                    if (imageUrl.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return SizedBox(
                                height: 150,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              debugPrint("Image load error: $error | URL: $imageUrl");
                              return Container(
                                height: 100,
                                color: Colors.grey.shade200,
                                child: const Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.broken_image, size: 48, color: Colors.grey),
                                      SizedBox(height: 4),
                                      Text("Could not load image",
                                          style: TextStyle(color: Colors.grey, fontSize: 12)),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                      // Download button — only shown when an image is present
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _isDownloading
                                ? null
                                : () => _downloadImage(imageUrl),
                            icon: _isDownloading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.download),
                            label: Text(
                              _isDownloading ? "Downloading..." : "Download Image",
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.deepPurple,
                              side: const BorderSide(color: Colors.deepPurple),
                            ),
                          ),
                        ),
                      ),
                    ],

                    // Audio indicator
                    if (audioUrl.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.audiotrack),
                              SizedBox(width: 8),
                              Text("Voice Message"),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 15),

            // OK button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                ),
                child: const Text("OK", style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}