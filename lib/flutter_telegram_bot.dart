library flutter_telegram_bot;

import 'package:dio/dio.dart';

/// TelegramService allows you to send error reports to a Telegram bot.
/// 
/// Example usage:
/// ```dart
/// final telegram = TelegramService(
///   botToken: "YOUR_BOT_TOKEN",
///   chatId: "@your_channel_or_user",
/// );
///
/// telegram.sendErrorReport(
///   username: "John",
///   serverName: "MyServer",
///   deviceInfo: {"Brand": "Samsung", "Model": "S24"},
///   requestData: {
///     "endpoint": "/api/login",
///     "method": "POST",
///     "body": {"username": "test"},
///     "messages": "Invalid credentials",
///   },
/// );
/// ```
class TelegramService {
  final Dio _dio = Dio();

  /// Your Telegram Bot API token
  final String botToken;

  /// Chat ID or channel username where the message will be sent
  final String chatId;

  TelegramService({
    required this.botToken,
    required this.chatId,
  });

  /// Sends an error report to Telegram with a formatted message.
  ///
  /// - [username]: The username of the reporter
  /// - [serverName]: The server or app name
  /// - [deviceInfo]: Device information map
  /// - [requestData]: Request data (endpoint, method, body, messages)
  Future<void> sendErrorReport({
    required String username,
    required String serverName,
    required Map<String, dynamic> deviceInfo,
    required Map<String, dynamic> requestData,
  }) async {
    final url = "https://api.telegram.org/bot$botToken/sendMessage";

    // Default message template (customize as needed)
    final String message = """
🚫 *ERROR 500* 🚫
${requestData['messages']}

➡➡➡ *GENERAL* ⬅⬅⬅
Server: $serverName
User: $username

➡➡➡ *DEVICE INFO* ⬅⬅⬅
${deviceInfo.entries.map((e) => "${e.key}: ${e.value}").join("\n")}

➡➡➡ *REQUEST* ⬅⬅⬅
End Point: ${requestData['endpoint']}
Method: ${requestData['method']}
Body Data: ${requestData['body']}
""";

    try {
      final response = await _dio.post(
        url,
        data: {
          "chat_id": chatId,
          "text": message,
          "parse_mode": "Markdown",
        },
      );
      print("Telegram OK: ${response.data}");
    } on DioException catch (e) {
      print("Telegram error: ${e.response?.statusCode} - ${e.response?.data}");
    }
  }
}
