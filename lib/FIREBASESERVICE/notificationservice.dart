import 'dart:convert';
import 'package:Koottaayma/FIREBASESERVICE/notificationpopup.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  GlobalKey<NavigatorState>? navigatorKey;
  bool _initialized = false;
  static const String topicName = "all_members";

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    try {
      NotificationSettings settings =
          await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus != AuthorizationStatus.authorized) {
        print("Notification permission denied");
        return;
      }

      await FirebaseMessaging.instance.subscribeToTopic(topicName);
      print("Subscribed to topic: $topicName");

      String? token = await FirebaseMessaging.instance.getToken();
      print("FCM Token: $token");
      // if (token != null) {
      //  // await _sendTokenToServer(token);
      // }

      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        print("FCM Token refreshed: $newToken");
        
        await FirebaseMessaging.instance.subscribeToTopic(topicName);
      //  await _sendTokenToServer(newToken);
      });

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print("Foreground message received: ${message.data}");
        if (message.data['type'] == 'priest_message') {
          _showPopup(message.data);
        }
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print("App opened from notification: ${message.data}");
        if (message.data['type'] == 'priest_message') {
          _showPopup(message.data);
        }
      });

      //  _checkPendingMessages() removed — handled by checkPendingAfterLogin()

    } catch (e) {
      print("FCM INIT ERROR: $e");
    }
  }

  // Future<void> _sendTokenToServer(String token) async {
  //    print('old fcmtoken sending API Called ');
  //   try {
      
  //     final response = await http.post(
  //       Uri.parse(
  //           "https://lv4hfxvb-7000.inc1.devtunnels.ms/notifications/priestapprovalnotifications/"),
  //       headers: {
  //         "Content-Type": "application/json",
  //        // 'Authorization':'$savedToken',
  //       },
  //       body: jsonEncode({
  //         "cfcmToken": token,
  //          "cDeviceType":'android',
  //         }),
  //     );
  //     print("Token sent — Status: ${response.statusCode} | Body: ${response.body}");
  //   } catch (e) {
  //     print("Token registration error: $e");
  //   }
  // }

  // Add this constant near the top of the class
static const String _mediaBaseUrl = "https://lv4hfxvb-7000.inc1.devtunnels.ms/"; 

void _showPopup(Map<String, dynamic> data) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final context = navigatorKey?.currentContext;

    print("Showing popup...");
    print("Navigator context: $context");
    print("Data: $data");

    if (context == null) {
      print("Navigator context is null — retrying in 2 seconds");
      Future.delayed(const Duration(seconds: 2), () {
        _showPopup(data);
      });
      return;
    }

    final String uploadedPath = data['uploaded_path'] ?? '';

    // Build full URL only if uploadedPath is a non-empty relative filename
    final bool hasImage = uploadedPath.endsWith('.jpg') ||
        uploadedPath.endsWith('.jpeg') ||
        uploadedPath.endsWith('.png');
    final bool hasAudio = uploadedPath.endsWith('.mp3') ||
        uploadedPath.endsWith('.wav');

    // Build absolute URL from relative path
    String resolvedUrl = '';
    if (uploadedPath.isNotEmpty) {
      resolvedUrl = uploadedPath.startsWith('http')
          ? uploadedPath                          // already a full URL
          : '$_mediaBaseUrl$uploadedPath';        // prepend base URL
    }

    // Don't show body text if it's just the filename
    final String rawBody = data['body'] ?? '';
    final String displayBody = (rawBody == uploadedPath) ? '' : rawBody;

    final mappedData = {
      'title':     data['title'] ?? 'Message from Priest',
      'body':      displayBody,
      'date':      data['date'] ?? '',
      'image_url': hasImage ? resolvedUrl : '',
      'audio_url': hasAudio ? resolvedUrl : '',
    };

    print("Resolved image URL: ${mappedData['image_url']}");
    print("Resolved audio URL: ${mappedData['audio_url']}");

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => NotificationPopup(data: mappedData),
    );
  });
}

  //  Called from HomeScreen initState after login
  Future<void> checkPendingAfterLogin() async {
    await Future.delayed(const Duration(seconds: 2));

    final prefs = await SharedPreferences.getInstance();
    final pendingData = prefs.getString('pendingPriestMessage');

    print("Checking pending messages...");
    print("Pending data: $pendingData");

    if (pendingData != null) {
      print("Pending message found: $pendingData ");
      final data = jsonDecode(pendingData) as Map<String, dynamic>;
      await prefs.remove('pendingPriestMessage');
      _showPopup(data);
    } else {
      print("No pending messages found ");
    }
  }

  Future<void> unsubscribeFromAllMembers() async {
    await FirebaseMessaging.instance.unsubscribeFromTopic(topicName);
    print("Unsubscribed from topic: $topicName");
  }
}