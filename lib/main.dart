import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'services/fcm_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  debugPrint('Background message received: ${message.messageId}');
  debugPrint('Background message data: ${message.data}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FCM Activity 14',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FCMService _fcmService = FCMService();

  String statusText = 'Waiting for a cloud message...';
  String bodyText = 'No notification received yet.';
  String assetName = 'default';
  String actionText = 'No action yet.';
  String tokenText = 'Loading token...';

  @override
  void initState() {
    super.initState();
    _initializeFCM();
  }

  Future<void> _initializeFCM() async {
    await _fcmService.initialize(
      onData: (RemoteMessage message) {
        final notificationTitle =
            message.notification?.title ?? 'Payload received';
        final notificationBody =
            message.notification?.body ?? 'No body provided';
        final incomingAsset = message.data['asset'] ?? 'default';
        final incomingAction = message.data['action'] ?? 'none';

        debugPrint('Message received in UI: ${message.messageId}');
        debugPrint('Notification title: $notificationTitle');
        debugPrint('Notification body: $notificationBody');
        debugPrint('Data payload: ${message.data}');

        if (!mounted) return;

        setState(() {
          statusText = notificationTitle;
          bodyText = notificationBody;
          assetName = incomingAsset;
          actionText = incomingAction;
        });
      },
    );

    final token = await _fcmService.getToken();
    if (!mounted) return;

    setState(() {
      tokenText = token ?? 'Token unavailable';
    });
  }

  String _assetPath() {
    return 'assets/images/$assetName.png';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase Cloud Messaging'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      'Current FCM Token',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SelectableText(
                      tokenText,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () async {
                        final token = await _fcmService.getToken();
                        if (!mounted) return;
                        setState(() {
                          tokenText = token ?? 'Token unavailable';
                        });
                      },
                      child: const Text('Refresh Token'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      'Notification Status',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      statusText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      bodyText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Action: $actionText',
                      style: const TextStyle(
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 220,
                      child: Image.asset(
                        _assetPath(),
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(
                                Icons.image_not_supported,
                                size: 60,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Image not found.\nCheck assets/images/ folder.',
                                textAlign: TextAlign.center,
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              color: Colors.blue.shade50,
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'Test Payload Example',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    SelectableText(
                      '{\n'
                      '  "notification": {\n'
                      '    "title": "New promotion",\n'
                      '    "body": "Switch the screen to the promo asset"\n'
                      '  },\n'
                      '  "data": {\n'
                      '    "asset": "promo",\n'
                      '    "action": "show_animation"\n'
                      '  }\n'
                      '}',
                      textAlign: TextAlign.left,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}