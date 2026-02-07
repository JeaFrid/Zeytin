import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:zeytin/config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LiveEngine {
  static bool get isEnabled =>
      ZeytinConfig.liveKitUrl.isNotEmpty &&
      ZeytinConfig.liveKitApiKey.isNotEmpty;
  static String createToken({
    required String roomName,
    required String identity,
    required String name,
    bool isAdmin = false,
  }) {
    if (!isEnabled) {
      throw Exception("LiveKit is not configured on this server.");
    }

    final jwt = JWT({
      'sub': identity,
      'name': name,
      'video': {
        'room': roomName,
        'roomJoin': true,
        'canPublish': true,
        'canSubscribe': true,
        'canPublishData': true,
        'roomAdmin': isAdmin,
      },
    }, issuer: ZeytinConfig.liveKitApiKey);

    return jwt.sign(
      SecretKey(ZeytinConfig.liveKitSecretKey),
      expiresIn: Duration(hours: 6),
    );
  }

  static Future<bool> isRoomActive(String roomName) async {
    if (!isEnabled) return false;
    final jwt = JWT({
      'video': {
        'roomList': true,
        'roomRecord': false,
      },
    }, issuer: ZeytinConfig.liveKitApiKey);

    String adminToken = jwt.sign(
      SecretKey(ZeytinConfig.liveKitSecretKey),
      expiresIn: Duration(minutes: 1),
    );

    try {
      String baseUrl = ZeytinConfig.liveKitUrl;
      String httpUrl = baseUrl
          .replaceAll("ws://", "http://")
          .replaceAll("wss://", "https://");
      String targetUrl = "$httpUrl/twirp/livekit.RoomService/ListRooms";
      var response = await http.post(
        Uri.parse(targetUrl),
        headers: {
          "Authorization": "Bearer $adminToken",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "names": [roomName],
        }),
      );

      if (response.statusCode == 200) {
        var body = jsonDecode(response.body);
        List rooms = body['rooms'] ?? [];
        if (rooms.isNotEmpty) {
          var room = rooms.first;
          int numParticipants = room['num_participants'] ?? 0;
          return numParticipants > 0;
        }
      }
      return false;
    } catch (e) {
      print("LiveKit API Hatası: $e");
      return false;
    }
  }
}
