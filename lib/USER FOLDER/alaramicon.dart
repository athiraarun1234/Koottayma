// import 'package:alarm/alarm.dart'; 
// import 'package:flutter/material.dart';

// class AlarmRingingScreen extends StatefulWidget {
//   final int alarmId;

//   const AlarmRingingScreen({super.key, required this.alarmId});

//   @override
//   State<AlarmRingingScreen> createState() => _AlarmRingingScreenState();
// }

// class _AlarmRingingScreenState extends State<AlarmRingingScreen> {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const Icon(
//               Icons.alarm,
//               size: 100,
//               color: Colors.white,
//             ),
//             const SizedBox(height: 32),
//             const Text(
//               'WAKE UP!',
//               style: TextStyle(
//                 fontSize: 48,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.white,
//               ),
//             ),
//             const SizedBox(height: 48),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//               children: [
//                 ElevatedButton(
//                   onPressed: () async {
//                     await Alarm.stop(widget.alarmId);
//                     if (mounted) Navigator.pop(context);
//                   },
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.green,
//                     minimumSize: const Size(120, 50),
//                   ),
//                   child: const Text(
//                     'STOP',
//                     style: TextStyle(fontSize: 18),
//                   ),
//                 ),
//                 ElevatedButton(
//                   onPressed: () async {
//                     await _snoozeAlarm();
//                     if (mounted) Navigator.pop(context);
//                   },
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.orange,
//                     minimumSize: const Size(120, 50),
//                   ),
//                   child: const Text(
//                     'SNOOZE',
//                     style: TextStyle(fontSize: 18),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Future<void> _snoozeAlarm() async {
//     await Alarm.stop(widget.alarmId);

//     final snoozeTime = DateTime.now().add(const Duration(minutes: 5));

//     // final alarmSettings = AlarmSettings(
//     //   id: widget.alarmId,
//     //   dateTime: snoozeTime,
//     //   assetAudioPath: 'assets/alarm.mp3',
//     //   loopAudio: true,
//     //   vibrate: true,
//     //   androidFullScreenIntent: true,
//     //   notificationTitle: 'Snoozed Alarm',
//     //   notificationBody: 'Alarm ringing again!',
//     // );

//    // await Alarm.set(alarmSettings: alarmSettings);
//   }
// } // ✅ missing closing brace for the class added