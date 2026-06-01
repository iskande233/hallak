import 'dart:ui';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.dark);
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

Future<String?> uploadImageToImgur(File imageFile) async {
  try {
    final uri = Uri.parse('https://api.imgur.com/3/image');
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Client-ID 546c25a59c58ad7'
      ..files.add(await http.MultipartFile.fromPath('image', imageFile.path));
    
    final response = await request.send();
    final responseData = await response.stream.bytesToString();
    final result = json.decode(responseData);
    
    if (result['success']) {
      return result['data']['link']; 
    }
  } catch (e) {
    debugPrint("Image Upload Error: $e");
  }
  return 'UPLOAD_FAILED';
}

Future<String?> pickAndUploadImage() async {
  final picker = ImagePicker();
  final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
  if (image == null) return null; 
  File file = File(image.path);
  return await uploadImageToImgur(file);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel', 'إشعارات الحجوزات', 
    description: 'هذه القناة مخصصة لإشعارات الحجوزات.',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  await flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(channel);
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(alert: true, badge: true, sound: true);
