import 'package:flutter/material.dart';
import 'package:flutter_telegram_bot/flutter_telegram_bot.dart';

void main() async {
  // Ensures Flutter engine is fully initialized before running the app
  WidgetsFlutterBinding.ensureInitialized();

  // Launch the app
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Create an instance of TelegramNotifier
    // Replace with your bot token and chat ID
    final telegram = TelegramNotifier(
      botToken:
          "8383153727:AAG6Iq-E8LYmR-nt02KT5X-ljPmf7B1LCB4", // Bot token from BotFather
      defaultChatId: "@nmflutterbot", // Default chat/channel to send messages
    );

    return MaterialApp(
      // Root of the app
      home: Scaffold(
        // Basic page structure with AppBar and Body
        appBar: AppBar(
          title: Text("Flutter Telegram Bot Example"),
        ), // Top bar title
        body: Center(
          // Center the child widget
          child: IconButton(
            // Clickable icon button
            onPressed: () async {
              // When button is pressed, send a message to Telegram
              await telegram.sendMessage(
                text: "Hi, Telegram!",
              ); // Sends message to default chat
            },
            icon: Icon(Icons.send), // Display send icon
          ),
        ),
      ),
    );
  }
}
