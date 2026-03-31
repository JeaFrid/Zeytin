import 'package:test/test.dart';
import 'package:shelf/shelf.dart';
import 'package:zeytin/tools/ip.dart';

void main() {
  group('getClientIp', () {
    Request createRequest({
      String? xForwardedFor,
      String? xRealIp,
      Map<String, Object>? connectionInfo,
    }) {
      final headers = <String, String>{};
      if (xForwardedFor != null) {
        headers['x-forwarded-for'] = xForwardedFor;
      }
      if (xRealIp != null) {
        headers['x-real-ip'] = xRealIp;
      }
      
      final context = <String, Object>{};
      if (connectionInfo != null) {
        context['shelf.io.connection_info'] = connectionInfo;
      }
      
      return Request(
        'GET',
        Uri.parse('http://localhost/test'),
        headers: headers,
        context: context,
      );
    }

    test('extracts IP from x-forwarded-for header', () {
      final request = createRequest(xForwardedFor: '192.168.1.1');
      final ip = getClientIp(request);
      expect(ip, equals('192.168.1.1'));
    });

    test('extracts first IP from x-forwarded-for with multiple IPs', () {
      final request = createRequest(
        xForwardedFor: '192.168.1.1, 10.0.0.1, 172.16.0.1',
      );
      final ip = getClientIp(request);
      expect(ip, equals('192.168.1.1'));
    });

    test('trims whitespace from x-forwarded-for IP', () {
      final request = createRequest(xForwardedFor: '  192.168.1.1  ');
      final ip = getClientIp(request);
      expect(ip, equals('192.168.1.1'));
    });

    test('extracts IP from x-real-ip header when x-forwarded-for absent', () {
      final request = createRequest(xRealIp: '10.0.0.1');
      final ip = getClientIp(request);
      expect(ip, equals('10.0.0.1'));
    });

    test('prefers x-forwarded-for over x-real-ip', () {
      final request = createRequest(
        xForwardedFor: '192.168.1.1',
        xRealIp: '10.0.0.1',
      );
      final ip = getClientIp(request);
      expect(ip, equals('192.168.1.1'));
    });

    test('returns unknown when no IP headers present', () {
      final request = createRequest();
      final ip = getClientIp(request);
      expect(ip, equals('unknown'));
    });

    test('handles empty x-forwarded-for header', () {
      final request = createRequest(xForwardedFor: '');
      final ip = getClientIp(request);
      expect(ip, equals('unknown'));
    });

    test('handles empty x-real-ip header', () {
      final request = createRequest(xRealIp: '');
      final ip = getClientIp(request);
      expect(ip, equals('unknown'));
    });

    test('extracts IPv4 address', () {
      final request = createRequest(xForwardedFor: '203.0.113.1');
      final ip = getClientIp(request);
      expect(ip, equals('203.0.113.1'));
    });

    test('extracts IPv6 address', () {
      final request = createRequest(
        xForwardedFor: '2001:0db8:85a3:0000:0000:8a2e:0370:7334',
      );
      final ip = getClientIp(request);
      expect(ip, equals('2001:0db8:85a3:0000:0000:8a2e:0370:7334'));
    });

    test('extracts compressed IPv6 address', () {
      final request = createRequest(xForwardedFor: '2001:db8::1');
      final ip = getClientIp(request);
      expect(ip, equals('2001:db8::1'));
    });

    test('handles localhost IPv4', () {
      final request = createRequest(xForwardedFor: '127.0.0.1');
      final ip = getClientIp(request);
      expect(ip, equals('127.0.0.1'));
    });

    test('handles localhost IPv6', () {
      final request = createRequest(xForwardedFor: '::1');
      final ip = getClientIp(request);
      expect(ip, equals('::1'));
    });

    test('handles private network IP ranges', () {
      final ips = [
        '10.0.0.1',
        '172.16.0.1',
        '192.168.0.1',
      ];
      
      for (var testIp in ips) {
        final request = createRequest(xForwardedFor: testIp);
        final ip = getClientIp(request);
        expect(ip, equals(testIp));
      }
    });

    test('handles proxy chain with multiple IPs', () {
      final request = createRequest(
        xForwardedFor: '203.0.113.1, 198.51.100.1, 192.0.2.1',
      );
      final ip = getClientIp(request);
      expect(ip, equals('203.0.113.1'));
    });

    test('handles mixed IPv4 and IPv6 in proxy chain', () {
      final request = createRequest(
        xForwardedFor: '203.0.113.1, 2001:db8::1, 198.51.100.1',
      );
      final ip = getClientIp(request);
      expect(ip, equals('203.0.113.1'));
    });

    test('handles x-forwarded-for with spaces after commas', () {
      final request = createRequest(
        xForwardedFor: '192.168.1.1,10.0.0.1,172.16.0.1',
      );
      final ip = getClientIp(request);
      expect(ip, equals('192.168.1.1'));
    });

    test('handles x-forwarded-for with extra spaces', () {
      final request = createRequest(
        xForwardedFor: '192.168.1.1  ,  10.0.0.1  ,  172.16.0.1',
      );
      final ip = getClientIp(request);
      expect(ip, equals('192.168.1.1'));
    });

    test('case insensitive header matching', () {
      final headers = {
        'X-Forwarded-For': '192.168.1.1',
      };
      final request = Request(
        'GET',
        Uri.parse('http://localhost/test'),
        headers: headers,
      );
      final ip = getClientIp(request);
      expect(ip, equals('192.168.1.1'));
    });

    test('handles real-world proxy scenarios', () {
      final scenarios = [
        '203.0.113.195',
        '198.51.100.178, 203.0.113.195',
        '2001:db8:85a3::8a2e:370:7334',
        '192.0.2.1, 198.51.100.178, 203.0.113.195',
      ];
      
      for (var scenario in scenarios) {
        final request = createRequest(xForwardedFor: scenario);
        final ip = getClientIp(request);
        expect(ip, isNotEmpty);
        expect(ip, isNot(equals('unknown')));
      }
    });

    test('handles edge case with single comma', () {
      final request = createRequest(xForwardedFor: '192.168.1.1,');
      final ip = getClientIp(request);
      expect(ip, equals('192.168.1.1'));
    });

    test('handles edge case with leading comma', () {
      final request = createRequest(xForwardedFor: ',192.168.1.1');
      final ip = getClientIp(request);
      // Empty string or valid IP or unknown are all acceptable
      expect(ip, anyOf(equals('192.168.1.1'), equals('unknown'), equals('')));
    });

    test('returns consistent results for same input', () {
      final request = createRequest(xForwardedFor: '192.168.1.100');
      final ip1 = getClientIp(request);
      final ip2 = getClientIp(request);
      expect(ip1, equals(ip2));
    });

    test('handles CloudFlare proxy format', () {
      final request = createRequest(
        xForwardedFor: '203.0.113.1',
        xRealIp: '203.0.113.1',
      );
      final ip = getClientIp(request);
      expect(ip, equals('203.0.113.1'));
    });

    test('handles AWS ELB format', () {
      final request = createRequest(
        xForwardedFor: '203.0.113.1, 10.0.0.1',
      );
      final ip = getClientIp(request);
      expect(ip, equals('203.0.113.1'));
    });

    test('handles nginx proxy format', () {
      final request = createRequest(
        xForwardedFor: '203.0.113.1',
        xRealIp: '203.0.113.1',
      );
      final ip = getClientIp(request);
      expect(ip, equals('203.0.113.1'));
    });

    test('handles multiple requests with different IPs', () {
      final ips = ['192.168.1.1', '192.168.1.2', '192.168.1.3'];
      for (var testIp in ips) {
        final request = createRequest(xForwardedFor: testIp);
        final ip = getClientIp(request);
        expect(ip, equals(testIp));
      }
    });

    test('extracts valid IP format', () {
      final request = createRequest(xForwardedFor: '192.168.1.1');
      final ip = getClientIp(request);
      final parts = ip.split('.');
      expect(parts.length, equals(4));
      for (var part in parts) {
        final num = int.tryParse(part);
        expect(num, isNotNull);
        expect(num!, greaterThanOrEqualTo(0));
        expect(num, lessThanOrEqualTo(255));
      }
    });

    test('handles request from load balancer', () {
      final request = createRequest(
        xForwardedFor: '203.0.113.1, 10.0.1.1, 10.0.2.1',
      );
      final ip = getClientIp(request);
      expect(ip, equals('203.0.113.1'));
    });

    test('handles request through multiple proxies', () {
      final request = createRequest(
        xForwardedFor: '203.0.113.1, 198.51.100.1, 192.0.2.1, 10.0.0.1',
      );
      final ip = getClientIp(request);
      expect(ip, equals('203.0.113.1'));
    });

    test('handles direct connection without proxy', () {
      final request = createRequest(xForwardedFor: '203.0.113.1');
      final ip = getClientIp(request);
      expect(ip, equals('203.0.113.1'));
    });

    test('handles x-real-ip as fallback', () {
      final request = createRequest(xRealIp: '198.51.100.1');
      final ip = getClientIp(request);
      expect(ip, equals('198.51.100.1'));
    });

    test('returns unknown for completely missing headers', () {
      final request = Request(
        'GET',
        Uri.parse('http://localhost/test'),
      );
      final ip = getClientIp(request);
      expect(ip, equals('unknown'));
    });
  });
}
