import 'package:test/test.dart';
import 'package:shelf/shelf.dart';
import 'package:zeytin/logic/gatekeeper.dart';
import 'package:zeytin/config.dart';

void main() {
  group('Gatekeeper', () {
    setUp(() {
      Gatekeeper.ipRegistry.clear();
      Gatekeeper.globalRequestCount = 0;
      Gatekeeper.sleepModeUntil = 0;
      ZeytinConfig.sleepModeEnabled = true;
      ZeytinConfig.blackList = [];
      ZeytinConfig.whiteList = ['127.0.0.1'];
    });

    Request createRequest(String path, {String? ip}) {
      final headers = <String, String>{};
      if (ip != null) {
        headers['x-forwarded-for'] = ip;
      }
      return Request(
        'GET',
        Uri.parse('http://localhost/$path'),
        headers: headers,
      );
    }

    test('allows whitelisted IP without restrictions', () async {
      final request = createRequest('test', ip: '127.0.0.1');
      final response = await Gatekeeper.check(request);
      expect(response, isNull);
    });

    test('blocks blacklisted IP', () async {
      ZeytinConfig.blackList = ['192.168.1.100'];
      final request = createRequest('test', ip: '192.168.1.100');
      final response = await Gatekeeper.check(request);
      expect(response, isNotNull);
      expect(response!.statusCode, equals(403));
    });

    test('allows normal request from new IP', () async {
      final request = createRequest('test', ip: '192.168.1.1');
      final response = await Gatekeeper.check(request);
      expect(response, isNull);
    });

    test('tracks IP activity', () async {
      final request = createRequest('test', ip: '192.168.1.1');
      await Gatekeeper.check(request);
      expect(Gatekeeper.ipRegistry.containsKey('192.168.1.1'), isTrue);
    });

    test('rate limits excessive requests from same IP', () async {
      final ip = '192.168.1.2';
      for (var i = 0; i < ZeytinConfig.generalIpRateLimit5Sec; i++) {
        final request = createRequest('test', ip: ip);
        await Gatekeeper.check(request);
      }
      
      final request = createRequest('test', ip: ip);
      final response = await Gatekeeper.check(request);
      expect(response, isNotNull);
      expect(response!.statusCode, equals(429));
    });

    test('cleans old request timestamps', () async {
      final ip = '192.168.1.3';
      final activity = IpActivity();
      final now = DateTime.now().millisecondsSinceEpoch;
      activity.requestTimestamps.add(now - 6000);
      activity.requestTimestamps.add(now - 4000);
      activity.requestTimestamps.add(now - 1000);
      Gatekeeper.ipRegistry[ip] = activity;
      
      final request = createRequest('test', ip: ip);
      await Gatekeeper.check(request);
      
      final updatedActivity = Gatekeeper.ipRegistry[ip]!;
      expect(
        updatedActivity.requestTimestamps.where((t) => now - t > 5000).isEmpty,
        isTrue,
      );
    });

    test('rate limits token creation endpoint', () async {
      final ip = '192.168.1.4';
      final request1 = createRequest('token/create', ip: ip);
      final response1 = await Gatekeeper.check(request1);
      expect(response1, isNull);
      
      final request2 = createRequest('token/create', ip: ip);
      final response2 = await Gatekeeper.check(request2);
      expect(response2, isNotNull);
      expect(response2!.statusCode, equals(429));
    });

    test('allows token creation after cooldown', () async {
      final ip = '192.168.1.5';
      final activity = IpActivity();
      activity.lastTokenRequest = DateTime.now().millisecondsSinceEpoch - 2000;
      Gatekeeper.ipRegistry[ip] = activity;
      
      final request = createRequest('token/create', ip: ip);
      final response = await Gatekeeper.check(request);
      expect(response, isNull);
    });

    test('enters sleep mode on global DoS threshold', () async {
      Gatekeeper.globalRequestCount = ZeytinConfig.globalDosThreshold + 1;
      final request = createRequest('test', ip: '192.168.1.6');
      final response = await Gatekeeper.check(request);
      expect(response, isNotNull);
      expect(response!.statusCode, equals(503));
      expect(Gatekeeper.sleepModeUntil, greaterThan(0));
    });

    test('blocks requests during sleep mode', () async {
      Gatekeeper.sleepModeUntil = DateTime.now().millisecondsSinceEpoch + 10000;
      final request = createRequest('test', ip: '192.168.1.7');
      final response = await Gatekeeper.check(request);
      expect(response, isNotNull);
      expect(response!.statusCode, equals(503));
    });

    test('allows requests after sleep mode expires', () async {
      Gatekeeper.sleepModeUntil = DateTime.now().millisecondsSinceEpoch - 1000;
      final request = createRequest('test', ip: '192.168.1.8');
      final response = await Gatekeeper.check(request);
      expect(response, isNull);
    });

    test('respects sleep mode disabled setting', () async {
      ZeytinConfig.sleepModeEnabled = false;
      Gatekeeper.sleepModeUntil = DateTime.now().millisecondsSinceEpoch + 10000;
      final request = createRequest('test', ip: '192.168.1.9');
      final response = await Gatekeeper.check(request);
      expect(response, isNull);
    });

    test('blocks banned IP', () async {
      final ip = '192.168.1.10';
      final activity = IpActivity();
      activity.isBanned = true;
      Gatekeeper.ipRegistry[ip] = activity;
      
      final request = createRequest('test', ip: ip);
      final response = await Gatekeeper.check(request);
      expect(response, isNotNull);
      expect(response!.statusCode, equals(403));
    });

    test('handles multiple IPs independently', () async {
      final ip1 = '192.168.1.11';
      final ip2 = '192.168.1.12';
      
      final request1 = createRequest('test', ip: ip1);
      final request2 = createRequest('test', ip: ip2);
      
      await Gatekeeper.check(request1);
      await Gatekeeper.check(request2);
      
      expect(Gatekeeper.ipRegistry.containsKey(ip1), isTrue);
      expect(Gatekeeper.ipRegistry.containsKey(ip2), isTrue);
      expect(Gatekeeper.ipRegistry[ip1], isNot(same(Gatekeeper.ipRegistry[ip2])));
    });

    test('increments global request count', () async {
      final initialCount = Gatekeeper.globalRequestCount;
      final request = createRequest('test', ip: '192.168.1.13');
      await Gatekeeper.check(request);
      expect(Gatekeeper.globalRequestCount, greaterThan(initialCount));
    });

    test('handles request without IP header', () async {
      final request = createRequest('test');
      final response = await Gatekeeper.check(request);
      expect(response, isNull);
    });

    test('extracts IP from x-forwarded-for header', () async {
      final request = createRequest('test', ip: '192.168.1.14, 10.0.0.1');
      await Gatekeeper.check(request);
      expect(Gatekeeper.ipRegistry.containsKey('192.168.1.14'), isTrue);
    });

    test('different endpoints share same IP rate limit', () async {
      final ip = '192.168.1.15';
      for (var i = 0; i < 50; i++) {
        await Gatekeeper.check(createRequest('endpoint1', ip: ip));
      }
      for (var i = 0; i < 50; i++) {
        await Gatekeeper.check(createRequest('endpoint2', ip: ip));
      }
      
      final request = createRequest('endpoint3', ip: ip);
      final response = await Gatekeeper.check(request);
      expect(response, isNotNull);
      expect(response!.statusCode, equals(429));
    });

    test('token endpoint has separate rate limit', () async {
      final ip = '192.168.1.16';
      for (var i = 0; i < 10; i++) {
        await Gatekeeper.check(createRequest('other/endpoint', ip: ip));
      }
      
      final tokenRequest = createRequest('token/create', ip: ip);
      final response = await Gatekeeper.check(tokenRequest);
      expect(response, isNull);
    });

    test('IpActivity tracks truck creation', () {
      final activity = IpActivity();
      expect(activity.lastTruckCreated, equals(0));
      expect(activity.truckCount, equals(0));
      
      activity.lastTruckCreated = DateTime.now().millisecondsSinceEpoch;
      activity.truckCount = 1;
      
      expect(activity.lastTruckCreated, greaterThan(0));
      expect(activity.truckCount, equals(1));
    });

    test('IpActivity initializes with default values', () {
      final activity = IpActivity();
      expect(activity.lastTruckCreated, equals(0));
      expect(activity.truckCount, equals(0));
      expect(activity.requestTimestamps, isEmpty);
      expect(activity.lastTokenRequest, equals(0));
      expect(activity.isBanned, isFalse);
    });

    test('multiple whitelisted IPs are allowed', () async {
      ZeytinConfig.whiteList = ['127.0.0.1', '192.168.1.100', '10.0.0.1'];
      
      final response1 = await Gatekeeper.check(createRequest('test', ip: '127.0.0.1'));
      final response2 = await Gatekeeper.check(createRequest('test', ip: '192.168.1.100'));
      final response3 = await Gatekeeper.check(createRequest('test', ip: '10.0.0.1'));
      
      expect(response1, isNull);
      expect(response2, isNull);
      expect(response3, isNull);
    });

    test('multiple blacklisted IPs are blocked', () async {
      ZeytinConfig.blackList = ['192.168.1.50', '192.168.1.51', '192.168.1.52'];
      
      final response1 = await Gatekeeper.check(createRequest('test', ip: '192.168.1.50'));
      final response2 = await Gatekeeper.check(createRequest('test', ip: '192.168.1.51'));
      final response3 = await Gatekeeper.check(createRequest('test', ip: '192.168.1.52'));
      
      expect(response1, isNotNull);
      expect(response2, isNotNull);
      expect(response3, isNotNull);
      expect(response1!.statusCode, equals(403));
      expect(response2!.statusCode, equals(403));
      expect(response3!.statusCode, equals(403));
    });

    test('blacklist takes precedence over whitelist', () async {
      final ip = '192.168.1.100';
      ZeytinConfig.whiteList = [ip];
      ZeytinConfig.blackList = [ip];
      
      final request = createRequest('test', ip: ip);
      final response = await Gatekeeper.check(request);
      expect(response, isNotNull);
      expect(response!.statusCode, equals(403));
    });

    test('rate limit resets after time window', () async {
      final ip = '192.168.1.17';
      final activity = IpActivity();
      final oldTimestamp = DateTime.now().millisecondsSinceEpoch - 6000;
      for (var i = 0; i < 100; i++) {
        activity.requestTimestamps.add(oldTimestamp);
      }
      Gatekeeper.ipRegistry[ip] = activity;
      
      final request = createRequest('test', ip: ip);
      final response = await Gatekeeper.check(request);
      expect(response, isNull);
    });
  });
}
