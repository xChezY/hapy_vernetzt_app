import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:hapy_vernetzt_app/core/firebase_options.dart';
import 'package:hapy_vernetzt_app/core/firebase.dart'; // For initToken/initOnTokenRefresh
import 'package:hapy_vernetzt_app/core/services/notification_service.dart';

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

  Future<void> initialize() async {
    // Initialize Firebase
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);

    // Initialize token handling
    initToken();
    initOnTokenRefresh();

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      await NotificationService().showNotifications();
    });

    // Register background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }
}
