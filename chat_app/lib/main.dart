// import 'package:chat_app/api/firebase_api.dart';
// import 'dart:convert';
// import 'dart:html';

import 'package:chat_app/firebase_options.dart';
import 'package:chat_app/language/locale_notifier.dart';
// import 'package:chat_app/pages/notification_page.dart';
// import 'package:chat_app/pages/notification_provider.dart';
// import 'package:chat_app/pages/notification_page.dart';
import 'package:chat_app/pages/splash_screen.dart';
// import 'package:chat_app/services/auth/auth_gate.dart';
import 'package:chat_app/services/auth/auth_services.dart';
import 'package:chat_app/services/auth/notification_services.dart/notification_service.dart';
// import 'package:chat_app/services/auth/notification_services.dart/notification_service.dart';
// import 'package:chat_app/services/auth/notification_services.dart/notification_service.dart';
// import 'package:chat_app/services/auth/notification_services.dart/notification_service.dart';
import 'package:chat_app/theme/theme_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_locales/flutter_locales.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';



//this will help navigate to other screens easily
// final navigatorKey = GlobalKey<NavigatorState>();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // print('Handling a background message ${message.messageId}');
  //on click listener
  print(message.data.toString());
  print(message.notification!.toString());
}

// LocalNotificationService localNotificationService = LocalNotificationService();

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  //initialize the shared preference
  await Locales.init(['en', 'es']);
  LocalNotificationService.initialize();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  //lock the orientation to portrait
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  //get the preferred language
  SharedPreferences prefs = await SharedPreferences.getInstance();
  //get the selected language from shared preference or default to 'en'
  String preferredLang = prefs.getString('language') ?? 'en';

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LanguageNotifier(preferredLang)),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // LocalNotificationService localNotificationService = LocalNotificationService();
  
  @override
  void initState() {
    super.initState();
    // localNotificationService.requestNotificationPermission();
    setUserStatusOnline();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    super.dispose();
    setUserStatusOffline();
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setUserStatusOnline();
    } else {
      setUserStatusOffline();
    }
  }

    void setUserStatusOnline() async {
    if (_auth.currentUser != null) {
      await FirebaseFirestore.instance
        .collection('users')
        .doc(_auth.currentUser!.uid)
        .update({'status': 'online'});
    }
  }

  void setUserStatusOffline() async {
    if (_auth.currentUser != null) {
      await FirebaseFirestore.instance
        .collection('users')
        .doc(_auth.currentUser!.uid)
        .update({'status': 'offline'});
    }
  }

  @override
Widget build(BuildContext context) {
  final themeProvider = Provider.of<ThemeProvider>(context);
  final localeNotifier = Provider.of<LanguageNotifier>(context);
  return LocaleBuilder(
    builder: (locale) => MaterialApp(
        localizationsDelegates: Locales.delegates,
        supportedLocales: Locales.supportedLocales,
        locale: Locale(localeNotifier.currentLocale ?? 'en'),
        debugShowCheckedModeBanner: false,
        theme: themeProvider.themeData,
        home: const SplashScreen(),
      )
    );
  }
}

