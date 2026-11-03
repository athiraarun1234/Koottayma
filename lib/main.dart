
import 'dart:convert';
import 'package:Koottaayma/FIREBASESERVICE/notificationservice.dart';
import 'package:Koottaayma/SQFLITEVERSION1/1splshscreen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Global navigatorKey
final GlobalKey<NavigatorState> navigatorKey =
    GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(
    RemoteMessage message) async {

  await Firebase.initializeApp();

  print("Background message received: ${message.data}");

  if (message.data['type'] == 'priest_message') {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      'pendingPriestMessage',
      jsonEncode(message.data),
    );

    print("Background message saved");
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  FirebaseMessaging.onBackgroundMessage(
    firebaseMessagingBackgroundHandler,
  );

  runApp(const MyApp());

  // Run AFTER UI loads
  Future.microtask(() async {
    NotificationService().navigatorKey = navigatorKey;
    await NotificationService().init();
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'കൂട്ടായ്മ',

      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
        ),
        useMaterial3: true,
      ),

      home: SplashScreen(),
    );
  }
}

// import 'dart:convert';
// import 'package:MyCommunity/FIREBASESERVICE/notificationservice.dart';
// import 'package:MyCommunity/SQFLITEVERSION1/1splshscreen.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// //  Global navigatorKey — outside any class
// final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// @pragma('vm:entry-point')
// Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//   //  Must initialize Firebase in background handler
//   await Firebase.initializeApp();
  
//   print("Background message received: ${message.data}");
  
//   if (message.data['type'] == 'priest_message') {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setString('pendingPriestMessage', jsonEncode(message.data));
//     print("Background message saved to SharedPreferences ");
//   }
// }

// Future<void> main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp();
  
//   FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

//   //  Attach navigatorKey BEFORE init()
//   NotificationService().navigatorKey = navigatorKey;
//   await NotificationService().init();

//   runApp(MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       navigatorKey: navigatorKey,  //  Pass navigatorKey here
//       debugShowCheckedModeBanner: false,
//       title: 'കൂട്ടായ്മ',
//       theme: ThemeData(
//         colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
//         useMaterial3: true,
//       ),
//       home: SplashScreen(),
//     );
//   }
// }