import 'dart:ui';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.dark);
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

// إعداد الإشعارات في الخلفية
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
  
  // إعداد الإشعارات المحلية والرسمية للأندرويد
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
  
  // تصحيح الخطأ هنا (initializationSettings)
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel', 
    'إشعارات الحجوزات', 
    description: 'هذه القناة مخصصة لإشعارات الحجوزات والتنبيهات المهمة.',
    importance: Importance.max,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true, badge: true, sound: true,
  );
  
  FirebaseMessaging.instance.requestPermission();

  runApp(const HallaqDZApp());
}

class HallaqDZApp extends StatelessWidget {
  const HallaqDZApp({super.key});
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, ThemeMode currentMode, __) {
        return MaterialApp(
          title: 'Hallaq DZ',
          debugShowCheckedModeBanner: false,
          themeMode: currentMode,
          theme: ThemeData(
            brightness: Brightness.light,
            primaryColor: const Color(0xFFD4AF37),
            scaffoldBackgroundColor: const Color(0xFFF5F5F5),
            appBarTheme: const AppBarTheme(backgroundColor: Colors.white, elevation: 1, iconTheme: IconThemeData(color: Colors.black)),
            colorScheme: const ColorScheme.light(primary: Color(0xFFD4AF37), secondary: Color(0xFFB5952F), surface: Colors.white),
            cardColor: Colors.white,
            textTheme: const TextTheme(bodyMedium: TextStyle(color: Colors.black87), titleLarge: TextStyle(color: Colors.black)),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primaryColor: const Color(0xFFD4AF37),
            scaffoldBackgroundColor: const Color(0xFF0D0D0D),
            appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF0D0D0D), elevation: 0),
            colorScheme: const ColorScheme.dark(primary: Color(0xFFD4AF37), secondary: Color(0xFFF3E5AB), surface: Color(0xFF1A1A1A)),
            cardColor: const Color(0xFF1A1A1A),
          ),
          home: const SplashScreen(),
        );
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const MainWrapper()));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/splash.png', fit: BoxFit.cover),
          Container(color: Colors.black.withOpacity(0.85)),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFD4AF37).withOpacity(0.1),
                  border: Border.all(color: const Color(0xFFD4AF37), width: 3),
                  boxShadow: [BoxShadow(color: const Color(0xFFD4AF37).withOpacity(0.5), blurRadius: 20)]
                ),
                child: const Icon(Icons.content_cut, size: 70, color: Color(0xFFD4AF37)),
              ),
              const SizedBox(height: 30),
              const Text('Hallaq DZ',
                  style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: Color(0xFFD4AF37), letterSpacing: 2.0, shadows: [Shadow(color: Colors.black, blurRadius: 10)])),
              const SizedBox(height: 30),
              const Text('التطبيق رقم واحد للحلاقة في الجزائر', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 8),
              const Text('L\'application N°1 de coiffure en Algérie', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white70)),
              const SizedBox(height: 50),
              const CircularProgressIndicator(color: Color(0xFFD4AF37)),
            ],
          ),
        ],
      ),
    );
  }
}

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});
  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  bool isArabic = true;
  void toggleLanguage() => setState(() => isArabic = !isArabic);

  @override
  void initState() {
    super.initState();
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;
      if (notification != null && android != null) {
        flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'high_importance_channel',
              'إشعارات الحجوزات',
              importance: Importance.max,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37))));
        if (snapshot.hasData) {
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('users').doc(snapshot.data!.uid).get(),
            builder: (context, userSnap) {
              if (!userSnap.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37))));
              if (!userSnap.data!.exists) return AuthScreen(isArabic: isArabic, onLanguageToggle: toggleLanguage);
              String role = userSnap.data!.get('role');
              
              FirebaseMessaging.instance.getToken().then((token) {
                if (token != null) FirebaseFirestore.instance.collection('users').doc(snapshot.data!.uid).update({'fcmToken': token});
              });

              return role == 'Barber'
                  ? BarberDashboard(isArabic: isArabic, uid: snapshot.data!.uid, onLanguageToggle: toggleLanguage)
                  : CustomerDashboard(isArabic: isArabic, onLanguageToggle: toggleLanguage);
            },
          );
        }
        return AuthScreen(isArabic: isArabic, onLanguageToggle: toggleLanguage);
      },
    );
  }
}

class AppDrawer extends StatelessWidget {
  final bool isArabic;
  final VoidCallback onLanguageToggle;
  final String uid;

  const AppDrawer({super.key, required this.isArabic, required this.onLanguageToggle, required this.uid});

  void _changeAvatar(BuildContext context) async {
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37))));
    try {
      String? url = await pickAndUploadImage();
      if (url != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).update({'avatarUrl': url});
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
    if (context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Drawer(child: Center(child: CircularProgressIndicator()));
        var userData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
        String name = userData['name'] ?? 'User';
        String email = userData['email'] ?? '';
        String avatarUrl = userData['avatarUrl'] ?? '';

        return Drawer(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          child: Column(
            children: [
              UserAccountsDrawerHeader(
                decoration: const BoxDecoration(color: Color(0xFFD4AF37)),
                currentAccountPicture: GestureDetector(
                  onTap: () => _changeAvatar(context),
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 36, backgroundColor: Colors.white,
                        backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                        child: avatarUrl.isEmpty ? const Icon(Icons.person, size: 40, color: Colors.black) : null,
                      ),
                      const Positioned(bottom: 0, right: 0, child: CircleAvatar(radius: 12, backgroundColor: Colors.black87, child: Icon(Icons.camera_alt, size: 14, color: Color(0xFFD4AF37))))
                    ],
                  )
                ),
                accountName: Row(
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black)),
                    const SizedBox(width: 5),
                    GestureDetector(
                      onTap: () {
                        TextEditingController nameCtrl = TextEditingController(text: name);
                        showDialog(context: context, builder: (_) => AlertDialog(
                          backgroundColor: Theme.of(context).cardColor,
                          title: Text(isArabic ? 'تغيير اسم المستخدم' : 'Changer le nom', style: const TextStyle(color: Color(0xFFD4AF37))),
                          content: TextField(controller: nameCtrl, decoration: InputDecoration(hintText: isArabic ? 'الاسم الجديد' : 'Nouveau nom')),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context), child: Text(isArabic ? 'إلغاء' : 'Annuler')),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37)),
                              onPressed: () {
                                if (nameCtrl.text.isNotEmpty) {
                                  FirebaseFirestore.instance.collection('users').doc(uid).update({'name': nameCtrl.text});
                                  Navigator.pop(context);
                                }
                              },
                              child: Text(isArabic ? 'حفظ' : 'Enregistrer', style: const TextStyle(color: Colors.black)),
                            )
                          ]
                        ));
                      },
                      child: const Icon(Icons.edit, size: 16, color: Colors.black54),
                    )
                  ],
                ),
                accountEmail: Text(email, style: const TextStyle(color: Colors.black87)),
              ),
              ListTile(leading: const Icon(Icons.language, color: Color(0xFFD4AF37)), title: Text(isArabic ? 'لغة التطبيق (Français)' : 'Langue (العربية)'), onTap: onLanguageToggle),
              ListTile(leading: const Icon(Icons.photo_camera, color: Color(0xFFD4AF37)), title: Text(isArabic ? 'تغيير صورة الحساب من المعرض' : 'Changer la photo (Galerie)'), onTap: () { Navigator.pop(context); _changeAvatar(context); }),
              ListTile(leading: const Icon(Icons.brightness_6, color: Color(0xFFD4AF37)), title: Text(isArabic ? 'تغيير المظهر (ليلي/نهاري)' : 'Changer le thème'), onTap: () { themeNotifier.value = themeNotifier.value == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark; }),
              const Spacer(), const Divider(),
              ListTile(leading: const Icon(Icons.logout, color: Colors.redAccent), title: Text(isArabic ? 'تسجيل الخروج' : 'Déconnexion', style: const TextStyle(color: Colors.redAccent)), onTap: () => FirebaseAuth.instance.signOut()),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}

class AuthScreen extends StatefulWidget {
  final bool isArabic;
  final VoidCallback onLanguageToggle;
  const AuthScreen({super.key, required this.isArabic, required this.onLanguageToggle});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  bool isLogin = true;
  String role = 'Customer';
  String barberType = 'Fixed';
  bool isLoading = false;

  final Map<String, bool> defaultWorkingHours = {
    '08:00': true, '09:00': true, '10:00': true, '11:00': true, '12:00': true, '13:00': true, '14:00': true, '15:00': true,
    '16:00': true, '17:00': true, '18:00': true, '19:00': true, '20:00': true, '21:00': true, '22:00': true,
  };

  void _submit() async {
    if (_emailCtrl.text.isEmpty || _passCtrl.text.isEmpty) return;
    setState(() => isLoading = true);
    try {
      if (isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(email: _emailCtrl.text.trim(), password: _passCtrl.text.trim());
      } else {
        UserCredential c = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: _emailCtrl.text.trim(), password: _passCtrl.text.trim());
        await FirebaseFirestore.instance.collection('users').doc(c.user!.uid).set({
          'uid': c.user!.uid, 'name': _nameCtrl.text.trim(), 'email': _emailCtrl.text.trim(), 'phone': _phoneCtrl.text.trim(),
          'role': role, 'avatarUrl': '', 'barberType': role == 'Barber' ? barberType : null,
          'rating': 5.0, 'totalRatings': 1, 'earnings': 0, 'totalBookings': 0, 'available': true, 'favorites': [], 'gallery': [],
          'createdAt': FieldValue.serverTimestamp(),
          'address': (role == 'Barber' && barberType == 'Fixed') ? _addressCtrl.text.trim() : null,
          'working_hours': role == 'Barber' ? defaultWorkingHours : null,
          'services': [{'name': 'قصة شعر', 'nameF': 'Coupe', 'price': 300}, {'name': 'لحية', 'nameF': 'Barbe', 'price': 200}]
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.redAccent));
    }
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(decoration: const BoxDecoration(image: DecorationImage(image: AssetImage('assets/splash.png'), fit: BoxFit.cover))),
          BackdropFilter(filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0), child: Container(color: Colors.black.withOpacity(0.7))),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFFD4AF37).withOpacity(0.1), border: Border.all(color: const Color(0xFFD4AF37), width: 2)), child: const Icon(Icons.content_cut, size: 45, color: Color(0xFFD4AF37))),
                    const SizedBox(height: 12),
                    const Text('Hallaq DZ', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFFD4AF37), letterSpacing: 2.0, shadows: [Shadow(color: Colors.black, blurRadius: 10)])),
                    const SizedBox(height: 30),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20)]),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Container(
                          height: 46, decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(14)),
                          child: Row(children: [
                            Expanded(child: _toggleBtn(widget.isArabic ? 'دخول' : 'Connexion', isLogin, () => setState(() => isLogin = true))),
                            Expanded(child: _toggleBtn(widget.isArabic ? 'تسجيل' : 'Inscription', !isLogin, () => setState(() => isLogin = false))),
                          ]),
                        ),
                        const SizedBox(height: 20),
                        if (!isLogin) ...[
                          _input(_nameCtrl, widget.isArabic ? 'الاسم الكامل' : 'Nom complet', Icons.person),
                          const SizedBox(height: 12),
                          _input(_phoneCtrl, widget.isArabic ? 'رقم الهاتف' : 'Téléphone', Icons.phone, type: TextInputType.phone),
                          const SizedBox(height: 16),
                          Row(children: [
                            Expanded(child: _roleSelector('Customer', widget.isArabic ? 'زبون' : 'Client', Icons.person)),
                            const SizedBox(width: 10),
                            Expanded(child: _roleSelector('Barber', widget.isArabic ? 'حلاق' : 'Coiffeur', Icons.content_cut)),
                          ]),
                          const SizedBox(height: 16),
                          if (role == 'Barber') ...[
                            Text(widget.isArabic ? 'طبيعة عملك كحلاق:' : 'Type de service:', style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 13, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Row(children: [
                              Expanded(child: _barberTypeSelector('Fixed', widget.isArabic ? 'حلاق ثابت' : 'Salon Fixe', Icons.store)),
                              const SizedBox(width: 10),
                              Expanded(child: _barberTypeSelector('Mobile', widget.isArabic ? 'حلاق متنقل' : 'Mobile', Icons.drive_eta)),
                            ]),
                            const SizedBox(height: 12),
                            if (barberType == 'Fixed') ...[
                              Row(
                                children: [
                                  Expanded(child: _input(_addressCtrl, widget.isArabic ? 'عنوان الصالون' : 'Adresse du salon', Icons.location_on)),
                                  const SizedBox(width: 8),
                                  Container(
                                    decoration: BoxDecoration(color: const Color(0xFFD4AF37).withOpacity(0.2), borderRadius: BorderRadius.circular(14)),
                                    child: IconButton(
                                      onPressed: () async {
                                        setState(() => isLoading = true);
                                        try {
                                          LocationPermission permission = await Geolocator.checkPermission();
                                          if (permission == LocationPermission.denied) {
                                            permission = await Geolocator.requestPermission();
                                            if (permission == LocationPermission.denied) throw 'لم يتم إعطاء صلاحية الموقع';
                                          }
                                          if (permission == LocationPermission.deniedForever) throw 'الصلاحية مرفوضة نهائياً';
                                          
                                          Position? position = await Geolocator.getLastKnownPosition();
                                          position ??= await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium);
                                          
                                          _addressCtrl.text = "${position.latitude}, ${position.longitude}";
                                          if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(widget.isArabic ? '✅ تم تحديد الموقع بنجاح' : '✅ Position trouvée'), backgroundColor: Colors.green));
                                        } catch (e) {
                                          if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red));
                                        }
                                        setState(() => isLoading = false);
                                      },
                                      icon: const Icon(Icons.my_location, color: Color(0xFFD4AF37), size: 28),
                                    ),
                                  )
                                ],
                              ),
                              const SizedBox(height: 12),
                            ],
                          ],
                        ],
                        _input(_emailCtrl, widget.isArabic ? 'البريد الإلكتروني' : 'Email', Icons.email, type: TextInputType.emailAddress),
                        const SizedBox(height: 12),
                        _input(_passCtrl, widget.isArabic ? 'كلمة السر' : 'Mot de passe', Icons.lock, obscure: true),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37), minimumSize: const Size(double.infinity, 54), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 5, shadowColor: const Color(0xFFD4AF37).withOpacity(0.4)),
                          onPressed: isLoading ? null : _submit,
                          child: isLoading
                              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                              : Text(isLogin ? (widget.isArabic ? 'تسجيل الدخول' : 'Connexion') : (widget.isArabic ? 'إنشاء حساب جديد' : 'Créer le compte'), style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 30),
                    const Text('Developed & Designed by', style: TextStyle(color: Colors.white54, fontSize: 11)),
                    const SizedBox(height: 4),
                    const Text('ISKANDER KHANTOUCHE', style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1.2)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _toggleBtn(String title, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(decoration: BoxDecoration(color: active ? const Color(0xFFD4AF37) : Colors.transparent, borderRadius: BorderRadius.circular(12)), alignment: Alignment.center, child: Text(title, style: TextStyle(color: active ? Colors.black : Colors.white60, fontWeight: FontWeight.bold))),
    );
  }

  Widget _roleSelector(String r, String label, IconData icon) {
    bool active = role == r;
    return GestureDetector(
      onTap: () => setState(() => role = r),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: active ? const Color(0xFFD4AF37).withOpacity(0.15) : Colors.black.withOpacity(0.5), borderRadius: BorderRadius.circular(12), border: Border.all(color: active ? const Color(0xFFD4AF37) : Colors.white10)),
        alignment: Alignment.center,
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 18, color: active ? const Color(0xFFD4AF37) : Colors.white60), const SizedBox(width: 8), Text(label, style: TextStyle(color: active ? const Color(0xFFD4AF37) : Colors.white60, fontWeight: FontWeight.bold))]),
      ),
    );
  }

  Widget _barberTypeSelector(String t, String label, IconData icon) {
    bool active = barberType == t;
    return GestureDetector(
      onTap: () => setState(() => barberType = t),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(color: active ? Colors.white10 : Colors.transparent, borderRadius: BorderRadius.circular(10), border: Border.all(color: active ? const Color(0xFFD4AF37) : Colors.white10)),
        alignment: Alignment.center,
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 16, color: active ? Colors.white : Colors.white30), const SizedBox(width: 6), Text(label, style: TextStyle(color: active ? Colors.white : Colors.white30, fontSize: 12, fontWeight: FontWeight.bold))]),
      ),
    );
  }

  Widget _input(TextEditingController c, String hint, IconData icon, {bool obscure = false, TextInputType? type}) {
    return TextField(
      controller: c, obscureText: obscure, keyboardType: type, style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(prefixIcon: Icon(icon, color: const Color(0xFFD4AF37), size: 20), hintText: hint, hintStyle: const TextStyle(color: Colors.white30, fontSize: 13), filled: true, fillColor: Colors.black.withOpacity(0.5), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(vertical: 14)),
    );
  }
}

class CustomerDashboard extends StatefulWidget {
  final bool isArabic;
  final VoidCallback onLanguageToggle;
  const CustomerDashboard({super.key, required this.isArabic, required this.onLanguageToggle});
  @override
  State<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard> {
  String filter = 'AI_Recommended';
  int _tab = 0; 

  Future<void> _contactBarber(String phone) async {
    final url = Uri.parse("https://wa.me/$phone");
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      final telUrl = Uri.parse("tel:$phone");
      if (await canLaunchUrl(telUrl)) await launchUrl(telUrl);
    }
  }

  void _toggleFavorite(String barberId, List currentFavs) async {
    String myUid = FirebaseAuth.instance.currentUser!.uid;
    if (currentFavs.contains(barberId)) {
      currentFavs.remove(barberId);
    } else {
      currentFavs.add(barberId);
    }
    await FirebaseFirestore.instance.collection('users').doc(myUid).update({'favorites': currentFavs});
  }

  @override
  Widget build(BuildContext context) {
    String currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(currentUid).snapshots(),
      builder: (context, userSnap) {
        if (!userSnap.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        var myData = userSnap.data!.data() as Map<String, dynamic>? ?? {};
        List myFavorites = myData['favorites'] ?? [];

        return Scaffold(
          appBar: AppBar(
            title: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(_tab == 0 ? Icons.storefront : Icons.favorite, color: const Color(0xFFD4AF37)), 
              const SizedBox(width: 8), 
              Text(_tab == 0 ? (widget.isArabic ? 'الصالونات المتاحة' : 'Salons Disponibles') : (widget.isArabic ? 'صالوناتي المفضلة' : 'Mes Favoris'), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Color(0xFFD4AF37), letterSpacing: 1.2))
            ]),
            centerTitle: true,
          ),
          drawer: AppDrawer(isArabic: widget.isArabic, onLanguageToggle: widget.onLanguageToggle, uid: currentUid),
          body: _tab == 0 ? _buildHome(myFavorites) : _buildFavorites(myFavorites),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _tab,
            onTap: (i) => setState(() => _tab = i),
            backgroundColor: Theme.of(context).cardColor,
            selectedItemColor: const Color(0xFFD4AF37),
            unselectedItemColor: Colors.grey,
            items: [
              BottomNavigationBarItem(icon: const Icon(Icons.home_outlined), activeIcon: const Icon(Icons.home), label: widget.isArabic ? 'الرئيسية' : 'Accueil'),
              BottomNavigationBarItem(icon: const Icon(Icons.favorite_outline), activeIcon: const Icon(Icons.favorite), label: widget.isArabic ? 'المفضلة' : 'Favoris'),
            ],
          ),
        );
      }
    );
  }

  Widget _buildHome(List myFavorites) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.2))),
          child: Row(children: [
            Expanded(child: _filterOption('AI_Recommended', widget.isArabic ? 'الأفضل (AI)' : 'Top (AI)', Icons.local_fire_department)),
            Expanded(child: _filterOption('Fixed', widget.isArabic ? 'صالون' : 'Salon', Icons.storefront)),
            Expanded(child: _filterOption('Mobile', widget.isArabic ? 'متنقل' : 'Mobile', Icons.directions_car)),
          ]),
        ),
      ),
      Expanded(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'Barber').snapshots(),
          builder: (context, snap) {
            if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)));
            var barbers = snap.data!.docs.toList();
            if (filter == 'AI_Recommended') {
              barbers.sort((a, b) {
                var dataA = a.data() as Map<String, dynamic>;
                var dataB = b.data() as Map<String, dynamic>;
                bool availA = dataA['available'] ?? true;
                bool availB = dataB['available'] ?? true;
                double ratingA = (dataA['rating'] ?? 0.0).toDouble();
                double ratingB = (dataB['rating'] ?? 0.0).toDouble();
                if (availA && !availB) return -1;
                if (!availA && availB) return 1;
                return ratingB.compareTo(ratingA);
              });
            } else {
              barbers = barbers.where((d) => (d.data() as Map<String, dynamic>)['barberType'] == filter).toList();
            }

            if (barbers.isEmpty) return _emptyState(widget.isArabic ? 'لا يوجد حلاقين بهذه المواصفات حالياً' : 'Aucun coiffeur trouvé', Icons.search_off);

            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: barbers.length,
              itemBuilder: (context, i) => _buildBarberCard(barbers[i], myFavorites, isTop: filter == 'AI_Recommended' && i == 0),
            );
          },
        ),
      )
    ]);
  }

  Widget _buildFavorites(List myFavorites) {
    if (myFavorites.isEmpty) return _emptyState(widget.isArabic ? 'لا توجد صالونات مفضلة بعد' : 'Aucun salon favori', Icons.favorite_border);
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'Barber').snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        var barbers = snap.data!.docs.where((d) => myFavorites.contains(d.id)).toList();
        if (barbers.isEmpty) return _emptyState(widget.isArabic ? 'لا توجد صالونات مفضلة بعد' : 'Aucun salon favori', Icons.favorite_border);
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: barbers.length,
          itemBuilder: (context, i) => _buildBarberCard(barbers[i], myFavorites),
        );
      },
    );
  }

  Widget _emptyState(String msg, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 60, color: Colors.grey.withOpacity(0.4)),
          const SizedBox(height: 16),
          Text(msg, style: const TextStyle(color: Colors.grey, fontSize: 16)),
        ],
      ));
  }

  Widget _filterOption(String val, String label, IconData icon) {
    bool active = filter == val;
    return GestureDetector(
      onTap: () => setState(() => filter = val),
      child: Container(
        height: 42,
        decoration: BoxDecoration(color: active ? const Color(0xFFD4AF37) : Colors.transparent, borderRadius: BorderRadius.circular(14)),
        alignment: Alignment.center,
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 16, color: active ? Colors.black : Colors.grey), const SizedBox(width: 4), Text(label, style: TextStyle(color: active ? Colors.black : Colors.grey, fontWeight: FontWeight.bold, fontSize: 13))]),
      ),
    );
  }

  Widget _buildBarberCard(DocumentSnapshot doc, List myFavorites, {bool isTop = false}) {
    var b = doc.data() as Map<String, dynamic>;
    String avatar = b['avatarUrl'] ?? '';
    bool available = b['available'] ?? true;
    bool isFav = myFavorites.contains(doc.id);
    
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => BarberProfileScreen(barberDoc: doc, isArabic: widget.isArabic, customerUid: FirebaseAuth.instance.currentUser!.uid)));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF1E1E1E), Color(0xFF121212)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.15)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 8))]
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFFD4AF37), width: 2)),
                child: CircleAvatar(
                  radius: 28, backgroundColor: const Color(0xFFD4AF37).withOpacity(0.2),
                  backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
                  child: avatar.isEmpty ? const Icon(Icons.person, color: Color(0xFFD4AF37), size: 30) : null,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(
                      children: [
                        Expanded(child: Text(b['name'] ?? 'Barber', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Theme.of(context).textTheme.titleLarge!.color), maxLines: 1, overflow: TextOverflow.ellipsis)),
                        if (isTop) Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(color: const Color(0xFFD4AF37), borderRadius: BorderRadius.circular(8)),
                          child: Text(widget.isArabic ? 'الأفضل' : 'Top', style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                        GestureDetector(
                          onTap: () => _toggleFavorite(doc.id, myFavorites),
                          child: Icon(isFav ? Icons.favorite : Icons.favorite_border, color: isFav ? Colors.redAccent : Colors.grey, size: 24),
                        )
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 14, color: Colors.grey), const SizedBox(width: 4),
                        Expanded(child: Text(b['address'] ?? (widget.isArabic ? 'حلاق متنقل' : 'Coiffeur Mobile'), style: const TextStyle(color: Colors.grey, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                  ])),
            ]),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.star, color: Color(0xFFD4AF37), size: 16), const SizedBox(width: 4),
                    Text('${(b['rating'] ?? 0.0).toStringAsFixed(1)}', style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: available ? Colors.green.withOpacity(0.15) : Colors.red.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                  child: Text(available ? (widget.isArabic ? 'متاح' : 'Dispo') : (widget.isArabic ? 'مشغول' : 'Occupé'), style: TextStyle(color: available ? Colors.green : Colors.red, fontSize: 11, fontWeight: FontWeight.bold)),
                )
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37).withOpacity(0.1), elevation: 0, minimumSize: const Size(double.infinity, 40), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFFD4AF37)))),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => BarberProfileScreen(barberDoc: doc, isArabic: widget.isArabic, customerUid: FirebaseAuth.instance.currentUser!.uid)));
              },
              child: Text(widget.isArabic ? 'عرض البروفايل والحجز' : 'Voir Profil & Réserver', style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold)),
            )
          ]),
        ),
      ),
    );
  }port 'dart:ui';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.dark);
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

// إعداد الإشعارات في الخلفية
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
  
  // إعداد الإشعارات المحلية والرسمية للأندرويد
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
  
  // تصحيح الخطأ هنا (initializationSettings)
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel', 
    'إشعارات الحجوزات', 
    description: 'هذه القناة مخصصة لإشعارات الحجوزات والتنبيهات المهمة.',
    importance: Importance.max,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true, badge: true, sound: true,
  );
  
  FirebaseMessaging.instance.requestPermission();

  runApp(const HallaqDZApp());
}

class HallaqDZApp extends StatelessWidget {
  const HallaqDZApp({super.key});
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, ThemeMode currentMode, __) {
        return MaterialApp(
          title: 'Hallaq DZ',
          debugShowCheckedModeBanner: false,
          themeMode: currentMode,
          theme: ThemeData(
            brightness: Brightness.light,
            primaryColor: const Color(0xFFD4AF37),
            scaffoldBackgroundColor: const Color(0xFFF5F5F5),
            appBarTheme: const AppBarTheme(backgroundColor: Colors.white, elevation: 1, iconTheme: IconThemeData(color: Colors.black)),
            colorScheme: const ColorScheme.light(primary: Color(0xFFD4AF37), secondary: Color(0xFFB5952F), surface: Colors.white),
            cardColor: Colors.white,
            textTheme: const TextTheme(bodyMedium: TextStyle(color: Colors.black87), titleLarge: TextStyle(color: Colors.black)),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primaryColor: const Color(0xFFD4AF37),
            scaffoldBackgroundColor: const Color(0xFF0D0D0D),
            appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF0D0D0D), elevation: 0),
            colorScheme: const ColorScheme.dark(primary: Color(0xFFD4AF37), secondary: Color(0xFFF3E5AB), surface: Color(0xFF1A1A1A)),
            cardColor: const Color(0xFF1A1A1A),
          ),
          home: const SplashScreen(),
        );
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const MainWrapper()));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/splash.png', fit: BoxFit.cover),
          Container(color: Colors.black.withOpacity(0.85)),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFD4AF37).withOpacity(0.1),
                  border: Border.all(color: const Color(0xFFD4AF37), width: 3),
                  boxShadow: [BoxShadow(color: const Color(0xFFD4AF37).withOpacity(0.5), blurRadius: 20)]
                ),
                child: const Icon(Icons.content_cut, size: 70, color: Color(0xFFD4AF37)),
              ),
              const SizedBox(height: 30),
              const Text('Hallaq DZ',
                  style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: Color(0xFFD4AF37), letterSpacing: 2.0, shadows: [Shadow(color: Colors.black, blurRadius: 10)])),
              const SizedBox(height: 30),
              const Text('التطبيق رقم واحد للحلاقة في الجزائر', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 8),
              const Text('L\'application N°1 de coiffure en Algérie', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white70)),
              const SizedBox(height: 50),
              const CircularProgressIndicator(color: Color(0xFFD4AF37)),
            ],
          ),
        ],
      ),
    );
  }
}

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});
  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  bool isArabic = true;
  void toggleLanguage() => setState(() => isArabic = !isArabic);

  @override
  void initState() {
    super.initState();
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;
      if (notification != null && android != null) {
        flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'high_importance_channel',
              'إشعارات الحجوزات',
              importance: Importance.max,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37))));
        if (snapshot.hasData) {
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('users').doc(snapshot.data!.uid).get(),
            builder: (context, userSnap) {
              if (!userSnap.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37))));
              if (!userSnap.data!.exists) return AuthScreen(isArabic: isArabic, onLanguageToggle: toggleLanguage);
              String role = userSnap.data!.get('role');
              
              FirebaseMessaging.instance.getToken().then((token) {
                if (token != null) FirebaseFirestore.instance.collection('users').doc(snapshot.data!.uid).update({'fcmToken': token});
              });

              return role == 'Barber'
                  ? BarberDashboard(isArabic: isArabic, uid: snapshot.data!.uid, onLanguageToggle: toggleLanguage)
                  : CustomerDashboard(isArabic: isArabic, onLanguageToggle: toggleLanguage);
            },
          );
        }
        return AuthScreen(isArabic: isArabic, onLanguageToggle: toggleLanguage);
      },
    );
  }
}

class AppDrawer extends StatelessWidget {
  final bool isArabic;
  final VoidCallback onLanguageToggle;
  final String uid;

  const AppDrawer({super.key, required this.isArabic, required this.onLanguageToggle, required this.uid});

  void _changeAvatar(BuildContext context) async {
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37))));
    try {
      String? url = await pickAndUploadImage();
      if (url != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).update({'avatarUrl': url});
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
    if (context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Drawer(child: Center(child: CircularProgressIndicator()));
        var userData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
        String name = userData['name'] ?? 'User';
        String email = userData['email'] ?? '';
        String avatarUrl = userData['avatarUrl'] ?? '';

        return Drawer(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          child: Column(
            children: [
              UserAccountsDrawerHeader(
                decoration: const BoxDecoration(color: Color(0xFFD4AF37)),
                currentAccountPicture: GestureDetector(
                  onTap: () => _changeAvatar(context),
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 36, backgroundColor: Colors.white,
                        backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                        child: avatarUrl.isEmpty ? const Icon(Icons.person, size: 40, color: Colors.black) : null,
                      ),
                      const Positioned(bottom: 0, right: 0, child: CircleAvatar(radius: 12, backgroundColor: Colors.black87, child: Icon(Icons.camera_alt, size: 14, color: Color(0xFFD4AF37))))
                    ],
                  )
                ),
                accountName: Row(
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black)),
                    const SizedBox(width: 5),
                    GestureDetector(
                      onTap: () {
                        TextEditingController nameCtrl = TextEditingController(text: name);
                        showDialog(context: context, builder: (_) => AlertDialog(
                          backgroundColor: Theme.of(context).cardColor,
                          title: Text(isArabic ? 'تغيير اسم المستخدم' : 'Changer le nom', style: const TextStyle(color: Color(0xFFD4AF37))),
                          content: TextField(controller: nameCtrl, decoration: InputDecoration(hintText: isArabic ? 'الاسم الجديد' : 'Nouveau nom')),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context), child: Text(isArabic ? 'إلغاء' : 'Annuler')),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37)),
                              onPressed: () {
                                if (nameCtrl.text.isNotEmpty) {
                                  FirebaseFirestore.instance.collection('users').doc(uid).update({'name': nameCtrl.text});
                                  Navigator.pop(context);
                                }
                              },
                              child: Text(isArabic ? 'حفظ' : 'Enregistrer', style: const TextStyle(color: Colors.black)),
                            )
                          ]
                        ));
                      },
                      child: const Icon(Icons.edit, size: 16, color: Colors.black54),
                    )
                  ],
                ),
                accountEmail: Text(email, style: const TextStyle(color: Colors.black87)),
              ),
              ListTile(leading: const Icon(Icons.language, color: Color(0xFFD4AF37)), title: Text(isArabic ? 'لغة التطبيق (Français)' : 'Langue (العربية)'), onTap: onLanguageToggle),
              ListTile(leading: const Icon(Icons.photo_camera, color: Color(0xFFD4AF37)), title: Text(isArabic ? 'تغيير صورة الحساب من المعرض' : 'Changer la photo (Galerie)'), onTap: () { Navigator.pop(context); _changeAvatar(context); }),
              ListTile(leading: const Icon(Icons.brightness_6, color: Color(0xFFD4AF37)), title: Text(isArabic ? 'تغيير المظهر (ليلي/نهاري)' : 'Changer le thème'), onTap: () { themeNotifier.value = themeNotifier.value == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark; }),
              const Spacer(), const Divider(),
              ListTile(leading: const Icon(Icons.logout, color: Colors.redAccent), title: Text(isArabic ? 'تسجيل الخروج' : 'Déconnexion', style: const TextStyle(color: Colors.redAccent)), onTap: () => FirebaseAuth.instance.signOut()),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}

class AuthScreen extends StatefulWidget {
  final bool isArabic;
  final VoidCallback onLanguageToggle;
  const AuthScreen({super.key, required this.isArabic, required this.onLanguageToggle});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  bool isLogin = true;
  String role = 'Customer';
  String barberType = 'Fixed';
  bool isLoading = false;

  final Map<String, bool> defaultWorkingHours = {
    '08:00': true, '09:00': true, '10:00': true, '11:00': true, '12:00': true, '13:00': true, '14:00': true, '15:00': true,
    '16:00': true, '17:00': true, '18:00': true, '19:00': true, '20:00': true, '21:00': true, '22:00': true,
  };

  void _submit() async {
    if (_emailCtrl.text.isEmpty || _passCtrl.text.isEmpty) return;
    setState(() => isLoading = true);
    try {
      if (isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(email: _emailCtrl.text.trim(), password: _passCtrl.text.trim());
      } else {
        UserCredential c = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: _emailCtrl.text.trim(), password: _passCtrl.text.trim());
        await FirebaseFirestore.instance.collection('users').doc(c.user!.uid).set({
          'uid': c.user!.uid, 'name': _nameCtrl.text.trim(), 'email': _emailCtrl.text.trim(), 'phone': _phoneCtrl.text.trim(),
          'role': role, 'avatarUrl': '', 'barberType': role == 'Barber' ? barberType : null,
          'rating': 5.0, 'totalRatings': 1, 'earnings': 0, 'totalBookings': 0, 'available': true, 'favorites': [], 'gallery': [],
          'createdAt': FieldValue.serverTimestamp(),
          'address': (role == 'Barber' && barberType == 'Fixed') ? _addressCtrl.text.trim() : null,
          'working_hours': role == 'Barber' ? defaultWorkingHours : null,
          'services': [{'name': 'قصة شعر', 'nameF': 'Coupe', 'price': 300}, {'name': 'لحية', 'nameF': 'Barbe', 'price': 200}]
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.redAccent));
    }
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(decoration: const BoxDecoration(image: DecorationImage(image: AssetImage('assets/splash.png'), fit: BoxFit.cover))),
          BackdropFilter(filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0), child: Container(color: Colors.black.withOpacity(0.7))),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFFD4AF37).withOpacity(0.1), border: Border.all(color: const Color(0xFFD4AF37), width: 2)), child: const Icon(Icons.content_cut, size: 45, color: Color(0xFFD4AF37))),
                    const SizedBox(height: 12),
                    const Text('Hallaq DZ', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFFD4AF37), letterSpacing: 2.0, shadows: [Shadow(color: Colors.black, blurRadius: 10)])),
                    const SizedBox(height: 30),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20)]),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Container(
                          height: 46, decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(14)),
                          child: Row(children: [
                            Expanded(child: _toggleBtn(widget.isArabic ? 'دخول' : 'Connexion', isLogin, () => setState(() => isLogin = true))),
                            Expanded(child: _toggleBtn(widget.isArabic ? 'تسجيل' : 'Inscription', !isLogin, () => setState(() => isLogin = false))),
                          ]),
                        ),
                        const SizedBox(height: 20),
                        if (!isLogin) ...[
                          _input(_nameCtrl, widget.isArabic ? 'الاسم الكامل' : 'Nom complet', Icons.person),
                          const SizedBox(height: 12),
                          _input(_phoneCtrl, widget.isArabic ? 'رقم الهاتف' : 'Téléphone', Icons.phone, type: TextInputType.phone),
                          const SizedBox(height: 16),
                          Row(children: [
                            Expanded(child: _roleSelector('Customer', widget.isArabic ? 'زبون' : 'Client', Icons.person)),
                            const SizedBox(width: 10),
                            Expanded(child: _roleSelector('Barber', widget.isArabic ? 'حلاق' : 'Coiffeur', Icons.content_cut)),
                          ]),
                          const SizedBox(height: 16),
                          if (role == 'Barber') ...[
                            Text(widget.isArabic ? 'طبيعة عملك كحلاق:' : 'Type de service:', style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 13, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Row(children: [
                              Expanded(child: _barberTypeSelector('Fixed', widget.isArabic ? 'حلاق ثابت' : 'Salon Fixe', Icons.store)),
                              const SizedBox(width: 10),
                              Expanded(child: _barberTypeSelector('Mobile', widget.isArabic ? 'حلاق متنقل' : 'Mobile', Icons.drive_eta)),
                            ]),
                            const SizedBox(height: 12),
                            if (barberType == 'Fixed') ...[
                              Row(
                                children: [
                                  Expanded(child: _input(_addressCtrl, widget.isArabic ? 'عنوان الصالون' : 'Adresse du salon', Icons.location_on)),
                                  const SizedBox(width: 8),
                                  Container(
                                    decoration: BoxDecoration(color: const Color(0xFFD4AF37).withOpacity(0.2), borderRadius: BorderRadius.circular(14)),
                                    child: IconButton(
                                      onPressed: () async {
                                        setState(() => isLoading = true);
                                        try {
                                          LocationPermission permission = await Geolocator.checkPermission();
                                          if (permission == LocationPermission.denied) {
                                            permission = await Geolocator.requestPermission();
                                            if (permission == LocationPermission.denied) throw 'لم يتم إعطاء صلاحية الموقع';
                                          }
                                          if (permission == LocationPermission.deniedForever) throw 'الصلاحية مرفوضة نهائياً';
                                          
                                          Position? position = await Geolocator.getLastKnownPosition();
                                          position ??= await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium);
                                          
                                          _addressCtrl.text = "${position.latitude}, ${position.longitude}";
                                          if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(widget.isArabic ? '✅ تم تحديد الموقع بنجاح' : '✅ Position trouvée'), backgroundColor: Colors.green));
                                        } catch (e) {
                                          if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red));
                                        }
                                        setState(() => isLoading = false);
                                      },
                                      icon: const Icon(Icons.my_location, color: Color(0xFFD4AF37), size: 28),
                                    ),
                                  )
                                ],
                              ),
                              const SizedBox(height: 12),
                            ],
                          ],
                        ],
                        _input(_emailCtrl, widget.isArabic ? 'البريد الإلكتروني' : 'Email', Icons.email, type: TextInputType.emailAddress),
                        const SizedBox(height: 12),
                        _input(_passCtrl, widget.isArabic ? 'كلمة السر' : 'Mot de passe', Icons.lock, obscure: true),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37), minimumSize: const Size(double.infinity, 54), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 5, shadowColor: const Color(0xFFD4AF37).withOpacity(0.4)),
                          onPressed: isLoading ? null : _submit,
                          child: isLoading
                              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                              : Text(isLogin ? (widget.isArabic ? 'تسجيل الدخول' : 'Connexion') : (widget.isArabic ? 'إنشاء حساب جديد' : 'Créer le compte'), style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 30),
                    const Text('Developed & Designed by', style: TextStyle(color: Colors.white54, fontSize: 11)),
                    const SizedBox(height: 4),
                    const Text('ISKANDER KHANTOUCHE', style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1.2)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _toggleBtn(String title, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(decoration: BoxDecoration(color: active ? const Color(0xFFD4AF37) : Colors.transparent, borderRadius: BorderRadius.circular(12)), alignment: Alignment.center, child: Text(title, style: TextStyle(color: active ? Colors.black : Colors.white60, fontWeight: FontWeight.bold))),
    );
  }

  Widget _roleSelector(String r, String label, IconData icon) {
    bool active = role == r;
    return GestureDetector(
      onTap: () => setState(() => role = r),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: active ? const Color(0xFFD4AF37).withOpacity(0.15) : Colors.black.withOpacity(0.5), borderRadius: BorderRadius.circular(12), border: Border.all(color: active ? const Color(0xFFD4AF37) : Colors.white10)),
        alignment: Alignment.center,
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 18, color: active ? const Color(0xFFD4AF37) : Colors.white60), const SizedBox(width: 8), Text(label, style: TextStyle(color: active ? const Color(0xFFD4AF37) : Colors.white60, fontWeight: FontWeight.bold))]),
      ),
    );
  }

  Widget _barberTypeSelector(String t, String label, IconData icon) {
    bool active = barberType == t;
    return GestureDetector(
      onTap: () => setState(() => barberType = t),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(color: active ? Colors.white10 : Colors.transparent, borderRadius: BorderRadius.circular(10), border: Border.all(color: active ? const Color(0xFFD4AF37) : Colors.white10)),
        alignment: Alignment.center,
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 16, color: active ? Colors.white : Colors.white30), const SizedBox(width: 6), Text(label, style: TextStyle(color: active ? Colors.white : Colors.white30, fontSize: 12, fontWeight: FontWeight.bold))]),
      ),
    );
  }

  Widget _input(TextEditingController c, String hint, IconData icon, {bool obscure = false, TextInputType? type}) {
    return TextField(
      controller: c, obscureText: obscure, keyboardType: type, style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(prefixIcon: Icon(icon, color: const Color(0xFFD4AF37), size: 20), hintText: hint, hintStyle: const TextStyle(color: Colors.white30, fontSize: 13), filled: true, fillColor: Colors.black.withOpacity(0.5), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(vertical: 14)),
    );
  }
}

