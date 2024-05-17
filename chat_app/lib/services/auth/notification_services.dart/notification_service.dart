import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:shared_preferences/shared_preferences.dart';

//instance of auth
final FirebaseAuth _auth = FirebaseAuth.instance;

class LocalNotificationService {
  static String serverKey =
      "AAAAqR7ocpU:APA91bEftNeeAB9anYEaEchQ2knFbzJZApJomaLzalUUEd_5KXdHMJr3PsYpgLXLiatqFNzB54WCnBSN0_6ek0RwF2qDzJcNAoR4220WUHhHUtcmy-A-IhPXH2q6T-0w4bkaKKnMkFtG";

  static final FlutterLocalNotificationsPlugin
      _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool notificationsEnabled =
        prefs.getBool('notificationsEnabled') ?? true;

    if (notificationsEnabled) {
      final InitializationSettings initializationSettings =
          InitializationSettings(
              android: AndroidInitializationSettings("@mipmap/ic_launcher"));
      _flutterLocalNotificationsPlugin.initialize(initializationSettings);

      FirebaseMessaging.instance
          .requestPermission(
        alert: true,
        badge: true,
        sound: true,
      )
          .then((settings) {
        if (settings.authorizationStatus == AuthorizationStatus.authorized) {
          print('User granted permission');
        } else if (settings.authorizationStatus ==
            AuthorizationStatus.provisional) {
          print('User granted provisional permission');
        } else {
          print('User declined or has not accepted permission');
        }
      });
    }
  }

  static void display(RemoteMessage message) async {
    try {
      print("In Notification method");
      // int id = DateTime.now().microsecondsSinceEpoch ~/1000000;
      Random random = new Random();
      int id = random.nextInt(1000);
      final NotificationDetails notificationDetails = NotificationDetails(
          android: AndroidNotificationDetails(
        "birdy_mate",
        "birdy mate",
        importance: Importance.max,
        priority: Priority.high,
      ));
      print("my id is ${id.toString()}");
      await _flutterLocalNotificationsPlugin.show(
        id,
        message.notification!.title,
        message.notification!.title,
        notificationDetails,
      );
    } on Exception catch (e) {
      print('Error>>>$e');
    }
  }

  sendNotification(String title, String? message, String token, [String? imageUrl]) async {
    print('token is $token');
    final data = {
      'click_action': 'FLUTTER_NOTIFICATION_CLICK',
      'id': '1',
      'status': 'done',
      'message': message,
      'image': imageUrl
    };

    try {
      http.Response res = await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'key=$serverKey'
        },
        body: jsonEncode(
          <String, dynamic>{
            'notification': <String, dynamic>{'body': message, 'title': title},
            'priority': 'high',
            'data': data,
            'to': '$token'
          },
        ),
      );

      print(res.body);
      if (res.statusCode == 200) {
        print('notification sent');
      } else {
        print(res.statusCode);
      }
    } catch (e) {
      print('exception $e');
    }
  }

  static storeToken() async {
    try {
      String? token = await FirebaseMessaging.instance.getToken();
      print(token);
      FirebaseFirestore.instance
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .set({'token': token}, SetOptions(merge: true));
    } catch (e) {
      print('exception $e');
    }
  }
}
