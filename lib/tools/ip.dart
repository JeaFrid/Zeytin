import 'package:shelf/shelf.dart';

 String getClientIp(Request request) {
  final xForwardedFor = request.headers['x-forwarded-for'];
  if (xForwardedFor != null && xForwardedFor.isNotEmpty) {
    return xForwardedFor.split(',').first.trim();
  }

  final xRealIp = request.headers['x-real-ip'];
  if (xRealIp != null && xRealIp.isNotEmpty) {
    return xRealIp;
  }
  final connInfo = request.context['shelf.io.connection_info'];
  if (connInfo != null) {
    return (connInfo as dynamic).remoteAddress.address;
  }

  return 'unknown';
}