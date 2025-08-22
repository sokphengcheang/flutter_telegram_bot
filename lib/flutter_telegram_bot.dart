/// An advanced, customizable, and flexible Telegram bot notification library.
/// Configure message formatting and the HTTP client as you wish.
library flutter_telegram_bot_pro;

import 'package:dio/dio.dart';
import 'dart:convert';

/// Defines the text formatting mode for messages sent to Telegram.
enum ParseMode { MarkdownV2, HTML }

/// An interface to convert a `Map<String, dynamic>` (JSON) into a readable
/// text message. You can implement this class to create your own custom
/// message formatters.
///
/// Example:
/// ```dart
/// class MyCustomFormatter implements MessageFormatter {
///   @override
///   String format(Map<String, dynamic> data, {ParseMode parseMode = ParseMode.MarkdownV2}) {
///     // Your custom formatting logic here.
///     return "Report: ${data['title']}";
///   }
/// }
/// ```
abstract class MessageFormatter {
  /// Converts the given map into a formatted string according to the specified parse mode.
  String format(Map<String, dynamic> data, {ParseMode parseMode});
}

/// Default formatter that converts JSON data into a hierarchical and readable
/// Markdown text.
class DefaultJsonFormatter implements MessageFormatter {
  const DefaultJsonFormatter();

  @override
  String format(
    Map<String, dynamic> data, {
    ParseMode parseMode = ParseMode.MarkdownV2,
  }) {
    final buffer = StringBuffer();
    _formatMap(data, buffer, 0, parseMode);
    return buffer.toString();
  }

  void _formatMap(
    Map<String, dynamic> map,
    StringBuffer buffer,
    int indentLevel,
    ParseMode parseMode,
  ) {
    final indent = '  ' * indentLevel;

    map.forEach((key, value) {
      final formattedKey = _formatKey(key, parseMode);
      buffer.write('$indent$formattedKey ');
      _formatValue(value, buffer, indentLevel + 1, parseMode);
    });
  }

  void _formatValue(
    dynamic value,
    StringBuffer buffer,
    int indentLevel,
    ParseMode parseMode,
  ) {
    final indent = '  ' * indentLevel;

    if (value is Map<String, dynamic>) {
      buffer.writeln();
      _formatMap(value, buffer, indentLevel, parseMode);
    } else if (value is List) {
      buffer.writeln();
      for (var item in value) {
        buffer.write('$indent- ');
        // Format each element inside the list
        _formatValue(item, buffer, indentLevel, parseMode);
      }
    } else {
      // If the value looks like a JSON string, try decoding it as well.
      if (value is String) {
        try {
          final decoded = jsonDecode(value);
          if (decoded is Map<String, dynamic>) {
            buffer.writeln();
            _formatMap(decoded, buffer, indentLevel, parseMode);
            return;
          }
        } catch (e) {
          // Not JSON, continue as a normal string
        }
      }
      buffer.writeln(_escapeText(value.toString(), parseMode));
    }
  }

  String _formatKey(String key, ParseMode parseMode) {
    final escapedKey = _escapeText(
      key.replaceAll('_', ' ').toUpperCase(),
      parseMode,
    );
    switch (parseMode) {
      case ParseMode.HTML:
        return '<b>$escapedKey:</b>';
      case ParseMode.MarkdownV2:
      default:
        return '*$escapedKey:*';
    }
  }

  /// Escapes special characters depending on Telegram API’s parse mode.
  String _escapeText(String text, ParseMode parseMode) {
    if (parseMode == ParseMode.MarkdownV2) {
      // Escape characters for MarkdownV2
      const charsToEscape = r'_*[]()~`>#+-=|{}.!';
      return text
          .split('')
          .map((char) {
            return charsToEscape.contains(char) ? '\\$char' : char;
          })
          .join('');
    }
    // Basic escape characters for HTML
    if (parseMode == ParseMode.HTML) {
      return text
          .replaceAll('&', '&amp;')
          .replaceAll('<', '&lt;')
          .replaceAll('>', '&gt;');
    }
    return text;
  }
}

/// The main service class that communicates with the Telegram API.
///
/// Example Usage:
/// ```dart
/// // 1. Simple Usage
/// final notifier = TelegramNotifier(
///   botToken: "YOUR_BOT_TOKEN",
///   defaultChatId: "@your_channel",
/// );
///
/// await notifier.sendJson(
///   data: {
///     "error_code": 500,
///     "message": "Invalid credentials",
///     "request": {
///       "endpoint": "/api/login",
///       "method": "POST",
///     }
///   },
/// );
///
/// // 2. Advanced Usage (with your own Dio and Formatter)
/// final myDio = Dio(BaseOptions(connectTimeout: Duration(seconds: 10)));
/// final myFormatter = MyCustomFormatter();
///
/// final advancedNotifier = TelegramNotifier(
///   botToken: "YOUR_BOT_TOKEN",
///   defaultChatId: "123456789",
///   dio: myDio,
///   formatter: myFormatter,
/// );
/// ```
class TelegramNotifier {
  final String _botToken;
  final String _defaultChatId;
  final Dio _dio;
  final MessageFormatter _formatter;

  /// Creates a service for sending notifications to Telegram.
  ///
  /// - [botToken]: Your Telegram Bot API token.
  /// - [defaultChatId]: The chat ID or channel/username where messages will be sent by default.
  /// - [dio]: (Optional) Your custom Dio client. If not provided, a default one will be created.
  /// - [formatter]: (Optional) Your custom message formatting strategy. If not provided, `DefaultJsonFormatter` will be used.
  TelegramNotifier({
    required String botToken,
    required String defaultChatId,
    Dio? dio,
    MessageFormatter? formatter,
  }) : _botToken = botToken,
       _defaultChatId = defaultChatId,
       _dio = dio ?? Dio(),
       _formatter = formatter ?? const DefaultJsonFormatter();

  /// Sends a given `Map` (JSON) to Telegram using the configured formatter.
  ///
  /// - [data]: The JSON data to be sent.
  /// - [overrideChatId]: (Optional) Overrides the default `chatId` for this single message.
  /// - [parseMode]: (Optional) How the message should be parsed. Defaults to `MarkdownV2`.
  Future<void> sendJson({
    required Map<String, dynamic> data,
    String? overrideChatId,
    ParseMode parseMode = ParseMode.MarkdownV2,
  }) async {
    try {
      final messageText = _formatter.format(data, parseMode: parseMode);
      await sendMessage(
        text: messageText,
        overrideChatId: overrideChatId,
        parseMode: parseMode,
      );
    } catch (e) {
      print("Error while formatting or sending JSON data: $e");
      // If formatting fails, attempt to send raw data
      try {
        await sendMessage(
          text: 'Could not format JSON. Raw data:\n${data.toString()}',
          overrideChatId: overrideChatId,
        );
      } catch (e2) {
        print("Failed to send raw data as well: $e2");
      }
    }
  }

  /// Sends a plain text message to Telegram.
  ///
  /// - [text]: The text to send.
  /// - [overrideChatId]: (Optional) Overrides the default `chatId` for this single message.
  /// - [parseMode]: (Optional) How the message should be parsed. Defaults to `MarkdownV2`.
  Future<void> sendMessage({
    required String text,
    String? overrideChatId,
    ParseMode parseMode = ParseMode.MarkdownV2,
  }) async {
    final targetChatId = overrideChatId ?? _defaultChatId;
    final url = "https://api.telegram.org/bot$_botToken/sendMessage";

    try {
      final response = await _dio.post(
        url,
        data: {"chat_id": targetChatId, "text": text, "parse_mode": 'Markdown'},
      );
      if (response.statusCode == 200) {
        print("Telegram message sent successfully to $targetChatId.");
      } else {
        print(
          "Telegram API returned a non-200 status code: ${response.statusCode}",
        );
        print("Response data: ${response.data}");
      }
    } on DioException catch (e) {
      print("Dio error sending Telegram message: ${e.message}");
      if (e.response != null) {
        print(
          "Error response: ${e.response?.statusCode} - ${e.response?.data}",
        );
      }
    } catch (e) {
      print("An unexpected error occurred: $e");
    }
  }
}
