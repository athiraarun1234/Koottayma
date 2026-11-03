// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';

// class ApprovalDetail {
//   final String cUploadedPath;
//   final String dDate;

//   bool get isImage =>
//       cUploadedPath.startsWith('http') &&
//       (cUploadedPath.contains('.jpg') ||
//           cUploadedPath.contains('.jpeg') ||
//           cUploadedPath.contains('.png') ||
//           cUploadedPath.contains('.webp'));

//   ApprovalDetail({required this.cUploadedPath, required this.dDate});

//   factory ApprovalDetail.fromJson(Map<String, dynamic> json) {
//     return ApprovalDetail(
//       cUploadedPath: json['cUploadedPath'] ?? '',
//       dDate: json['dDate'] ?? '',
//     );
//   }

//   String get uniqueKey => '${cUploadedPath}_$dDate';
// }

// class MessageService {
//   final String apiUrl = 'https://lv4hfxvb-7000.inc1.devtunnels.ms/notifications/priestapprovalnotifications/';

//   final Set<String> _seenKeys = {};
//   static const _prefKey = 'seen_approval_keys';

//   //  REMOVED: bool _isFirstLoad = true;

//   Future<void> init() async {
//     final prefs = await SharedPreferences.getInstance();
//     final saved = prefs.getStringList(_prefKey) ?? [];
//     _seenKeys.addAll(saved);
//     print(' Loaded ${saved.length} previously seen keys');
//   }

//   Future<List<ApprovalDetail>> fetchNewMessages() async {
//     try {
//       final response = await http
//           .get(Uri.parse(apiUrl))
//           .timeout(const Duration(seconds: 10));

//       if (response.statusCode == 200) {
//         final decoded = jsonDecode(response.body);

//         if (decoded['Success'] == true) {
//           final List list = decoded['lstapprovalrequestdetails'] ?? [];
//           final allMessages = list.map((e) => ApprovalDetail.fromJson(e)).toList();

//           //  Show anything not seen before — works on first open AND after restart
//           final newMessages =
//               allMessages.where((m) => !_seenKeys.contains(m.uniqueKey)).toList();

//           if (newMessages.isNotEmpty) {
//             _seenKeys.addAll(newMessages.map((m) => m.uniqueKey));
//             await _persist();
//           }

//           return newMessages;
//         }
//       }
//     } catch (e) {
//       print(' API error: $e');
//     }
//     return [];
//   }

//   Future<void> _persist() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setStringList(_prefKey, _seenKeys.toList());
//   }

//   Future<void> reset() async {
//     _seenKeys.clear();
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.remove(_prefKey);
//   }
// }
