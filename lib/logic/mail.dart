import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:zeytin/config.dart';

class EmailService {
  static Future<bool> sendCustomEmail({
    required String toEmail,
    required String subject,
    required String htmlContent,
  }) async {
    try {
      final smtpServer = SmtpServer(
        ZeytinConfig.smtpHost,
        port: ZeytinConfig.smtpPort,
        username: ZeytinConfig.smtpUsername,
        password: ZeytinConfig.smtpPassword,
        ssl: ZeytinConfig.smtpPort == 465,
      );

      final message = Message()
        ..from = Address(ZeytinConfig.smtpUsername, ZeytinConfig.senderName)
        ..recipients.add(toEmail)
        ..subject = subject
        ..html = htmlContent;

      final sendReport = await send(message, smtpServer);
      print('Email sent successfully: ${sendReport.toString()}');
      return true;
    } on MailerException catch (e) {
      print('Email could not be sent.');
      for (var p in e.problems) {
        print('Problem: ${p.code}: ${p.msg}');
      }
      return false;
    } catch (e) {
      print('Unexpected email error: $e');
      return false;
    }
  }
}
