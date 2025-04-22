import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:hapy_vernetzt_app/core/firebase_options.dart';
import 'package:hapy_vernetzt_app/core/services/notification_service.dart';
import 'package:hapy_vernetzt_app/main.dart' show storage;
import 'package:hapy_vernetzt_app/core/services/notification_backend_api_service.dart';

// Top-level function for background message handling (required by Firebase)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase essential for background handling
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Initialize notifications and show them using NotificationService
  // We need to initialize notifications here too for the background isolate
  await NotificationService().initialize();
  await NotificationService().showNotifications();
}

class FirebaseService {
  // Singleton pattern
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() {
    return _instance;
  }
  FirebaseService._internal();

  // Moved from core/firebase.dart
  Future<void> _initToken() async {
    String token = await FirebaseMessaging.instance.getToken() ?? '';
    if (token.isNotEmpty) {
      // Use NotificationBackendApiService directly
      await NotificationBackendApiService().sendDeviceToken(token);
      // Use storage from main.dart
      await storage.write(key: 'token', value: token);
    }
  }

  // Moved from core/firebase.dart
  void _initOnTokenRefresh() {
    FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
      // Use NotificationBackendApiService directly
      await NotificationBackendApiService().sendDeviceToken(token);
      // Use storage from main.dart
      await storage.write(key: 'token', value: token);
    });
  }

  Future<void> initialize() async {
    // Initialize Firebase
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);

    // Initialize token handling using internal methods
    await _initToken(); // Use await here as it's async now
    _initOnTokenRefresh();

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      await NotificationService().showNotifications();
    });

    // Register background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  }
}
