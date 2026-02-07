import 'dart:async';
import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:zeytin/models/response.dart';
import 'package:zeytin/tools/ip.dart';
import '../config.dart';

class IpActivity {
  int lastTruckCreated = 0;
  int truckCount = 0;
  List<int> requestTimestamps = [];
  int lastTokenRequest = 0;
  bool isBanned = false;
}

class Gatekeeper {
  static Map<String, IpActivity> ipRegistry = {};
  static int globalRequestCount = 0;
  static int sleepModeUntil = 0;

  static Future<Response?> check(Request request) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    if (ZeytinConfig.sleepModeEnabled && now < sleepModeUntil) {
      return Response(503, body: "Be quiet! I'm trying to sleep here.");
    }

    globalRequestCount++;
    if (globalRequestCount > ZeytinConfig.globalDosThreshold) {
      sleepModeUntil = now + ZeytinConfig.dosCooldownMs;
      globalRequestCount = 0;
      return Response(503, body: "Be quiet! I'm trying to sleep here.");
    }
    Timer(const Duration(seconds: 5), () => globalRequestCount = 0);

    final String ip = getClientIp(request);

    if (ZeytinConfig.blackList.contains(ip)) {
      return Response.forbidden(
        jsonEncode(
          ZeytinResponse(
            isSuccess: false,
            message: "Opss...",
            error: "I see I've banned your IP address. Get out!",
          ).toMap(),
        ),
      );
    }

    if (ZeytinConfig.whiteList.contains(ip)) {
      return null;
    }

    final activity = ipRegistry.putIfAbsent(ip, () => IpActivity());

    if (activity.isBanned) {
      return Response.forbidden(
        jsonEncode(
          ZeytinResponse(
            isSuccess: false,
            message: "Opss...",
            error: "I see I've banned your IP address. Get out!",
          ).toMap(),
        ),
      );
    }

    activity.requestTimestamps.add(now);
    activity.requestTimestamps.removeWhere((t) => now - t > 5000);

    if (activity.requestTimestamps.length >
        ZeytinConfig.generalIpRateLimit5Sec) {
      return Response(
        429,
        body: jsonEncode(
          ZeytinResponse(
            isSuccess: false,
            message: "Opss...",
            error: "Whoa, fast kid! Slow down, or...",
          ).toMap(),
        ),
      );
    }

    if (request.url.path == 'token/create') {
      if (now - activity.lastTokenRequest < ZeytinConfig.ipRateLimitMs) {
        return Response(
          429,
          body: jsonEncode(
            ZeytinResponse(
              isSuccess: false,
              message: "Opss...",
              error:
                  "I understand you need that token, but you need to slow down a bit. You can request it once every second.",
            ).toMap(),
          ),
        );
      }
      activity.lastTokenRequest = now;
    }

    return null;
  }
}
