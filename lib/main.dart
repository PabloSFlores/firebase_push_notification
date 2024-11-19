import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'firebase_options.dart';

/// Handler para mensajes en segundo plano
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Mensaje en segundo plano recibido: ${message.notification?.title}");
}

/// Inicialización de notificaciones locales
final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> _initializeNotifications() async {
  const AndroidInitializationSettings androidInitializationSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  final DarwinInitializationSettings iosInitializationSettings =
      DarwinInitializationSettings();
  final InitializationSettings initializationSettings = InitializationSettings(
    android: androidInitializationSettings,
    iOS: iosInitializationSettings,
  );

  await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
}

/// Configuración del canal de notificaciones
const AndroidNotificationChannel _channel = AndroidNotificationChannel(
  "test_channel",
  "Test Notifications",
  description: "Canal de notificaciones para pruebas",
  importance: Importance.max,
);

Future<void> _setupNotificationChannel() async {
  final android =
      _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
  if (android != null) {
    await android.createNotificationChannel(_channel);
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa Firebase y configura el canal de notificaciones
  try {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
    await _initializeNotifications();
    await _setupNotificationChannel();

    // Configura el handler de mensajes en segundo plano
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } catch (e) {
    print("Error durante la inicialización: $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _setupFirebaseMessaging();
  }

  /// Configura Firebase Messaging
  Future<void> _setupFirebaseMessaging() async {
    final FirebaseMessaging messaging = FirebaseMessaging.instance;

    // Solicitar permisos para notificaciones en dispositivos iOS
    try {
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (e) {
      print("Error al solicitar permisos de notificación: $e");
    }

    // Escucha mensajes en primer plano
    FirebaseMessaging.onMessage.listen((RemoteMessage remoteMessage) {
      print("Notificación recibida: ${remoteMessage.notification?.title}");
      _showLocalNotification(remoteMessage);
    });

    // Obtén el token del dispositivo
    try {
      final String? token = await messaging.getToken();
      print("Token del dispositivo: $token");
    } catch (e) {
      print("Error al obtener el token: $e");
    }
  }

  /// Muestra una notificación local cuando se recibe un mensaje en primer plano
  Future<void> _showLocalNotification(RemoteMessage remoteMessage) async {
    final notification = remoteMessage.notification;
    if (notification != null) {
      NotificationDetails notificationDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.max,
          priority: Priority.high,
        ),
      );

      await _flutterLocalNotificationsPlugin.show(
        remoteMessage.hashCode,
        notification.title,
        notification.body,
        notificationDetails,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text("Notificaciones Push"),
        ),
        body: const Center(
          child: Text("Esperando Notificaciones"),
        ),
      ),
    );
  }
}
