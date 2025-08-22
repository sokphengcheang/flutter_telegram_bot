# Changelog

All notable changes to this project will be documented in this file.

## [1.0.0] - 2025-08-23
### Added
- Initial release of `flutter_telegram_bot` demo.
- Flutter app integrated with Telegram bot using `TelegramNotifier`.
- Simple UI with `IconButton` to send messages to Telegram.
- Support for sending messages to default chat/channel.
- Full example with `MaterialApp`, `Scaffold`, and `AppBar`.

### Fixed
- Ensured proper initialization of Flutter engine with `WidgetsFlutterBinding.ensureInitialized()`.

### Notes
- Replace `botToken` and `defaultChatId` with your own Telegram bot credentials.
- Demo sends a static message ("Hi, Telegram!") to the specified chat.
- Recommended to secure bot token for production use.
