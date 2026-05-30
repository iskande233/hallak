import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const HallaqDZApp());
}

class HallaqDZApp extends StatefulWidget {
  const HallaqDZApp({super.key});
  @override
  State<HallaqDZApp> createState() => _HallaqDZAppState();
}

class _HallaqDZAppState extends State<HallaqDZApp> {
  bool isArabic = true;
  void toggleLanguage() => setState(() => isArabic = !isArabic);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hallaq DZ',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFFD4AF37),
        scaffoldBackgroundColor: const Color(0xFF0D0D0D),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFD4AF37),
          secondary: Color(0xFFF3E5AB),
          surface: Color(0xFF161616),
        ),
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37))));
          }
          if (snapshot.hasData) {
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(snapshot.data!.uid).get(),
              builder: (context, userSnap) {
                if (!userSnap.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));
                if (!userSnap.data!.exists) return AuthScreen(isArabic: isArabic, onLanguageToggle: toggleLanguage);
                String role = userSnap.data!.get('role');
                return role == 'Barber'
                    ? BarberDashboard(isArabic: isArabic, uid: snapshot.data!.uid, onLanguageToggle: toggleLanguage)
                    : CustomerDashboard(isArabic: isArabic, onLanguageToggle: toggleLanguage);
              },
            );
          }
          return AuthScreen(isArabic: isArabic, onLanguageToggle: toggleLanguage);
        },
      ),
    );
  }
}

class AppDrawer extends StatelessWidget {
  final bool isArabic;
  final VoidCallback onLanguageToggle;
  final String uid;

  const AppDrawer({super.key, required this.isArabic, required this.onLanguageToggle, required this.uid});

  void _showAvatarDialog(BuildContext context, String currentUrl) {
    final controller = TextEditingController(text: currentUrl);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isArabic ? 'تغيير صورة البروفايل' : 'Changer la photo', style: const TextStyle(color: Color(0xFFD4AF37))),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: isArabic ? 'رابط الصورة (URL)' : 'Lien de l\'image (URL)',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(isArabic ? 'إلغاء' : 'Annuler', style: const TextStyle(color: CustomColors.white24))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: () async {
              await FirebaseFirestore.instance.collection('users').doc(uid).update({'avatarUrl': controller.text.trim()});
              Navigator.pop(context);
            },
            child: Text(isArabic ? 'حفظ' : 'Enregistrer', style: const TextStyle(color: CustomColors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
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
          backgroundColor: const Color(0xFF121212),
          child: Column(
            children: [
              UserAccountsDrawerHeader(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFF1E1E1E), Color(0xFF0D0D0D)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                ),
                currentAccountPicture: GestureDetector(
                  onTap: () => _showAvatarDialog(context, avatarUrl),
                  child: CircleAvatar(
                    radius: 36,
                    backgroundColor: const Color(0xFFD4AF37),
                    backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                    child: avatarUrl.isEmpty ? const Icon(Icons.person, size: 40, color: CustomColors.black) : null,
                  ),
                ),
                accountName: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFFD4AF37))),
                accountEmail: Text(email, style: const TextStyle(color: CustomColors.white60)),
              ),
              ListTile(
                leading: const Icon(Icons.language, color: Color(0xFFD4AF37)),
                title: Text(isArabic ? 'لغة التطبيق (Français)' : 'Langue (العربية)', style: const TextStyle(color: CustomColors.whiteBF, fontSize: 15)),
                onTap: onLanguageToggle,
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera, color: Color(0xFFD4AF37)),
                title: Text(isArabic ? 'تغيير صورة الحساب' : 'Changer la photo', style: const TextStyle(color: CustomColors.whiteBF, fontSize: 15)),
                onTap: () {
                  Navigator.pop(context);
                  _showAvatarDialog(context, avatarUrl);
                },
              ),
              const Spacer(),
              const Divider(color: CustomColors.white12),
              ListTile(
                leading: const Icon(Icons.logout, color: CustomColors.redAccent),
                title: Text(isArabic ? 'تسجيل الخروج' : 'Déconnexion', style: const TextStyle(color: CustomColors.redAccent, fontSize: 15)),
                onTap: () => FirebaseAuth.instance.signOut(),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}

class CustomColors {
  static const Color white24 = Color(0x3DFFFFFF);
  static const Color white60 = Color(0x99FFFFFF);
  static const Color white70 = Color(0xB3FFFFFF);
  static const Color white30 = Color(0x4DFFFFFF);
  static const Color white10 = Color(0x1AFFFFFF);
  static const Color white12 = Color(0x1FFFFFFF);
  static const Color whiteBF = Color(0xBFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);
  static const Color transparent = Color(0x00000000);
  static const Color grey = Color(0xFF9E9E9E);
  static const Color red = Color(0xFFF44336);
  static const Color redAccent = Color(0xFFFF5252);
  static const Color green = Color(0xFF4CAF50);
  static const Color orange = Color(0xFFFF9800);
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
    '08:00': true, '09:00': true, '10:00': true, '11:00': true,
    '12:00': true, '13:00': true, '14:00': true, '15:00': true,
    '16:00': true, '17:00': true, '18:00': true, '19:00': true,
    '20:00': true, '21:00': true, '22:00': true,
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
          'uid': c.user!.uid,
          'name': _nameCtrl.text.trim(),
          'email': _emailCtrl.text.trim(),
          'phone': _phoneCtrl.text.trim(),
          'role': role,
          'avatarUrl': '',
          'barberType': role == 'Barber' ? barberType : null,
          'rating': 4.5,
          'totalRatings': 1,
          'earnings': 0,
          'totalBookings': 0,
          'available': true,
          'createdAt': FieldValue.serverTimestamp(),
          'address': (role == 'Barber' && barberType == 'Fixed') ? _addressCtrl.text.trim() : null,
          'working_hours': role == 'Barber' ? defaultWorkingHours : null,
          'services': [
            {'name': 'قصة شعر', 'nameF': 'Coupe', 'price': 300},
            {'name': 'لحية', 'nameF': 'Barbe', 'price': 200},
          ]
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: NetworkImage('https://images.unsplash.com/photo-1585747860715-2ba37e788b70?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
            child: Container(color: Colors.black.withOpacity(0.65)),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFD4AF37).withOpacity(0.1),
                        border: Border.all(color: const Color(0xFFD4AF37), width: 2),
                      ),
                      child: const Icon(Icons.content_cut, size: 45, color: Color(0xFFD4AF37)),
                    ),
                    const SizedBox(height: 12),
                    const Text('Hallaq DZ',
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFFD4AF37), letterSpacing: 2.0, shadows: [Shadow(color: Colors.black, blurRadius: 10)])),
                    const SizedBox(height: 30),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3)),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))]),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Container(
                          height: 46,
                          decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), borderRadius: BorderRadius.circular(14)),
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
                            Expanded(child: _roleSelector('Customer', '👤 ${widget.isArabic ? 'زبون' : 'Client'}')),
                            const SizedBox(width: 10),
                            Expanded(child: _roleSelector('Barber', '✂️ ${widget.isArabic ? 'حلاق' : 'Coiffeur'}')),
                          ]),
                          const SizedBox(height: 16),
                          if (role == 'Barber') ...[
                            Text(widget.isArabic ? 'طبيعة عملك كحلاق:' : 'Type الخدمة:', style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 13, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Row(children: [
                              Expanded(child: _barberTypeSelector('Fixed', '🏪 ${widget.isArabic ? 'حلاق ثابت' : 'Salon Fixe'}')),
                              const SizedBox(width: 10),
                              Expanded(child: _barberTypeSelector('Mobile', '🚗 ${widget.isArabic ? 'حلاق متنقل' : 'Mobile'}')),
                            ]),
                            const SizedBox(height: 12),
                            if (barberType == 'Fixed') ...[
                              Row(
                                children: [
                                  Expanded(
                                    child: _input(_addressCtrl, widget.isArabic ? 'عنوان الصالون' : 'Adresse du salon', Icons.location_on),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    onPressed: () async {
                                      setState(() => isLoading = true);
                                      try {
                                        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
                                        if (!serviceEnabled) throw 'Location services are disabled.';
                                        LocationPermission permission = await Geolocator.checkPermission();
                                        if (permission == LocationPermission.denied) {
                                          permission = await Geolocator.requestPermission();
                                          if (permission == LocationPermission.denied) throw 'Location permissions are denied';
                                        }
                                        Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
                                        _addressCtrl.text = "${position.latitude}, ${position.longitude}";
                                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(widget.isArabic ? '✅ تم تحديد الموقع بنجاح' : '✅ Position trouvée'), backgroundColor: Colors.green));
                                      } catch (e) {
                                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red));
                                      }
                                      setState(() => isLoading = false);
                                    },
                                    icon: const Icon(Icons.my_location, color: Color(0xFFD4AF37), size: 28),
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
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD4AF37),
                            minimumSize: const Size(double.infinity, 54),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 5,
                            shadowColor: const Color(0xFFD4AF37).withOpacity(0.4),
                          ),
                          onPressed: isLoading ? null : _submit,
                          child: isLoading
                              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                              : Text(isLogin ? (widget.isArabic ? 'تسجيل الدخول' : 'Connexion') : (widget.isArabic ? 'إنشاء حساب جديد' : 'Créer le compte'),
                                  style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
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
      child: Container(
        decoration: BoxDecoration(color: active ? const Color(0xFFD4AF37) : Colors.transparent, borderRadius: BorderRadius.circular(12)),
        alignment: Alignment.center,
        child: Text(title, style: TextStyle(color: active ? Colors.black : Colors.white60, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _roleSelector(String r, String label) {
    bool active = role == r;
    return GestureDetector(
      onTap: () => setState(() => role = r),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: active ? const Color(0xFFD4AF37).withOpacity(0.15) : Colors.black.withOpacity(0.5), borderRadius: BorderRadius.circular(12), border: Border.all(color: active ? const Color(0xFFD4AF37) : Colors.white10)),
        alignment: Alignment.center,
        child: Text(label, style: TextStyle(color: active ? const Color(0xFFD4AF37) : Colors.white60, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _barberTypeSelector(String t, String label) {
    bool active = barberType == t;
    return GestureDetector(
      onTap: () => setState(() => barberType = t),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(color: active ? Colors.white10 : Colors.transparent, borderRadius: BorderRadius.circular(10), border: Border.all(color: active ? const Color(0xFFD4AF37) : Colors.white10)),
        alignment: Alignment.center,
        child: Text(label, style: TextStyle(color: active ? Colors.white : Colors.white30, fontSize: 12, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _input(TextEditingController c, String hint, IconData icon, {bool obscure = false, TextInputType? type}) {
    return TextField(
      controller: c, obscureText: obscure, keyboardType: type, style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
          prefixIcon: Icon(icon, color: const Color(0xFFD4AF37), size: 20),
          hintText: hint, hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
          filled: true, fillColor: Colors.black.withOpacity(0.5),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(vertical: 14)),
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

  @override
  Widget build(BuildContext context) {
    String currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isArabic ? '💈 الصالونات المتاحة' : '💈 Salons Disponibles', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Color(0xFFD4AF37), letterSpacing: 1.2)),
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.black, Colors.black.withOpacity(0.8)], begin: Alignment.topCenter, end: Alignment.bottomCenter))),
        elevation: 0, centerTitle: true,
      ),
      drawer: AppDrawer(isArabic: widget.isArabic, onLanguageToggle: widget.onLanguageToggle, uid: currentUid),
      body: Container(
        decoration: const BoxDecoration(color: Color(0xFF0D0D0D)),
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.2))),
              child: Row(children: [
                Expanded(child: _filterOption('AI_Recommended', widget.isArabic ? '🔥 الأفضل (AI)' : 'AI Top')),
                Expanded(child: _filterOption('Fixed', '🏪 ${widget.isArabic ? 'صالون' : 'Salon'}')),
                Expanded(child: _filterOption('Mobile', '🚗 ${widget.isArabic ? 'متنقل' : 'Mobile'}')),
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
                  barbers = barbers.where((d) {
                    var data = d.data() as Map<String, dynamic>;
                    return data['barberType'] == filter;
                  }).toList();
                }

                if (barbers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_off, size: 60, color: Colors.white24),
                        const SizedBox(height: 16),
                        Text(widget.isArabic ? 'لا يوجد حلاقين بهذه المواصفات حالياً' : 'Aucun coiffeur trouvé', style: const TextStyle(color: Colors.white60, fontSize: 16)),
                      ],
                    ));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: barbers.length,
                  itemBuilder: (context, i) {
                    var b = barbers[i].data() as Map<String, dynamic>;
                    String avatar = b['avatarUrl'] ?? '';
                    bool available = b['available'] ?? true;

                    return Container(
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
                          Row(children: [
                            Container(
                              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFFD4AF37), width: 2)),
                              child: CircleAvatar(
                                radius: 28,
                                backgroundColor: const Color(0xFFD4AF37).withOpacity(0.2),
                                backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
                                child: avatar.isEmpty ? const Icon(Icons.person, color: Color(0xFFD4AF37), size: 30) : null,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Row(
                                    children: [
                                      Text(b['name'] ?? 'Barber', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
                                      if (filter == 'AI_Recommended' && i == 0) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(color: const Color(0xFFD4AF37), borderRadius: BorderRadius.circular(8)),
                                          child: Text(widget.isArabic ? '💡 الأفضل' : 'Top', style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
                                        )
                                      ]
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on, size: 14, color: Colors.white30),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(b['address'] ?? (widget.isArabic ? 'حلاق متنقل (يأتي إليك)' : 'Coiffeur Mobile'), style: const TextStyle(color: Colors.white60, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                                      ),
                                    ],
                                  ),
                                ])),
                            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), borderRadius: BorderRadius.circular(12)),
                                child: Row(
                                  children: [
                                    const Icon(Icons.star, color: Color(0xFFD4AF37), size: 14),
                                    const SizedBox(width: 4),
                                    Text('${(b['rating'] ?? 0.0).toStringAsFixed(1)}', style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(color: available ? Colors.green.withOpacity(0.15) : Colors.red.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                                child: Text(available ? (widget.isArabic ? 'متاح' : 'Dispo') : (widget.isArabic ? 'مشغول' : 'Occupé'), style: TextStyle(color: available ? Colors.greenAccent : Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                              )
                            ])
                          ]),
                          const SizedBox(height: 16),
                          const Divider(color: Colors.white10, height: 1),
                          const SizedBox(height: 16),
                          Row(children: [
                            Expanded(
                                child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(side: BorderSide(color: const Color(0xFFD4AF37).withOpacity(0.5)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), padding: const EdgeInsets.symmetric(vertical: 12)),
                              onPressed: () async {
                                String q = b['address'] ?? '';
                                final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(q)}');
                                await launchUrl(url, mode: LaunchMode.externalApplication);
                              },
                              icon: const Icon(Icons.map_outlined, size: 18, color: Color(0xFFD4AF37)),
                              label: Text(widget.isArabic ? 'الخريطة' : 'Carte', style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 14, fontWeight: FontWeight.bold)),
                            )),
                            const SizedBox(width: 12),
                            Expanded(
                                child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), padding: const EdgeInsets.symmetric(vertical: 12), elevation: 5, shadowColor: const Color(0xFFD4AF37).withOpacity(0.4)),
                              onPressed: available ? () => _showBookingSheet(barbers[i]) : null,
                              icon: const Icon(Icons.calendar_month, size: 18, color: Colors.black),
                              label: Text(widget.isArabic ? 'احجز الآن' : 'Réserver', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14)),
                            )),
                          ])
                        ]),
                      ),
                    );
                  },
                );
              },
            ),
          )
        ]),
      ),
    );
  }

  Widget _filterOption(String val, String label) {
    bool active = filter == val;
    return GestureDetector(
      onTap: () => setState(() => filter = val),
      child: Container(
        height: 42,
        decoration: BoxDecoration(color: active ? const Color(0xFFD4AF37) : Colors.transparent, borderRadius: BorderRadius.circular(14)),
        alignment: Alignment.center,
        child: Text(label, style: TextStyle(color: active ? Colors.black : Colors.white60, fontWeight: FontWeight.bold, fontSize: 13)),
      ),
    );
  }

  void _showBookingSheet(DocumentSnapshot doc) {
    var b = doc.data() as Map<String, dynamic>;
    List services = b['services'] ?? [];
    Map<String, dynamic> workingHours = b['working_hours'] as Map<String, dynamic>? ?? {};
    List<String> allowedSlots = workingHours.entries.where((e) => e.value == true).map((e) => e.key).toList()..sort();
    String selSvc = services.isNotEmpty ? services[0]['name'] : '';
    String selTime = allowedSlots.isNotEmpty ? allowedSlots[0] : '';
    String today = DateTime.now().toString().split(' ')[0];

    showModalBottomSheet(
      context: context, backgroundColor: const Color(0xFF161616), isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('bookings').where('barberId', isEqualTo: doc.id).where('date', isEqualTo: today).snapshots(),
          builder: (context, bookingSnap) {
            if (!bookingSnap.hasData) return const SizedBox(height: 150, child: Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37))));
            List<String> reservedSlots = bookingSnap.data!.docs.map((d) => (d.data() as Map<String, dynamic>)['timeSlot'].toString()).toList();
            return StatefulBuilder(
                builder: (context, setModalState) => Padding(
                      padding: EdgeInsets.only(top: 24, left: 24, right: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
                      child: Column(
                          mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(child: Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10)))),
                            const SizedBox(height: 20),
                            Text('${widget.isArabic ? "تأكيد موعد عند" : "Réservation chez"} ${b['name']}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFFD4AF37))),
                            const SizedBox(height: 24),
                            Text(widget.isArabic ? '1. اختر الخدمة المطلوبة:' : '1. Choisissez le service:', style: const TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 10, runSpacing: 10,
                              children: services.map<Widget>((s) {
                                bool a = selSvc == s['name'];
                                return ChoiceChip(
                                  label: Text('${s['name']} - ${s['price']} DA', style: TextStyle(color: a ? Colors.black : Colors.white, fontWeight: FontWeight.bold)),
                                  selected: a, selectedColor: const Color(0xFFD4AF37), backgroundColor: Colors.black, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                  onSelected: (_) => setModalState(() => selSvc = s['name']),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 24),
                            Text(widget.isArabic ? '2. اختر الوقت المناسب:' : '2. Choisissez l\'heure:', style: const TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            allowedSlots.isEmpty
                                ? Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Text(widget.isArabic ? 'عذراً، الحلاق لم يحدد ساعات العمل اليوم.' : 'Aucun créneau disponible aujourd\'hui.', style: const TextStyle(color: Colors.redAccent)))
                                : Wrap(
                                    spacing: 10, runSpacing: 10,
                                    children: allowedSlots.map<Widget>((t) {
                                      bool isReserved = reservedSlots.contains(t);
                                      bool a = selTime == t;
                                      return ChoiceChip(
                                        label: Text(isReserved ? "$t (${widget.isArabic ? 'محجوز' : 'Réservé'})" : t, style: TextStyle(color: isReserved ? Colors.white30 : (a ? Colors.black : Colors.white), fontWeight: FontWeight.bold, decoration: isReserved ? TextDecoration.lineThrough : null)),
                                        selected: !isReserved && a, selectedColor: const Color(0xFFD4AF37), backgroundColor: isReserved ? const Color(0xFF0A0A0A) : Colors.black, padding: const EdgeInsets.all(12),
                                        onSelected: isReserved ? null : (_) => setModalState(() => selTime = t),
                                      );
                                    }).toList(),
                                  ),
                            const SizedBox(height: 32),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37), minimumSize: const Size(double.infinity, 56), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 5, shadowColor: const Color(0xFFD4AF37).withOpacity(0.4)),
                              onPressed: (allowedSlots.isEmpty || reservedSlots.contains(selTime)) ? null : () async {
                                      await FirebaseFirestore.instance.collection('bookings').add({'barberId': doc.id, 'barberName': b['name'], 'customerId': FirebaseAuth.instance.currentUser!.uid, 'service': selSvc, 'timeSlot': selTime, 'status': 'pending', 'date': today, 'createdAt': FieldValue.serverTimestamp()});
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(widget.isArabic ? '✅ تم إرسال طلب الحجز بنجاح!' : '✅ Demande envoyée avec succès!'), behavior: SnackBarBehavior.floating, margin: const EdgeInsets.only(bottom: 20, left: 20, right: 20), backgroundColor: Colors.green.shade800));
                                    },
                              child: Text(widget.isArabic ? 'تأكيد الحجز النهائي' : 'Confirmer la réservation', style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                            )
                          ]),
                    ));
          }),
    );
  }
}

class BarberDashboard extends StatefulWidget {
  final bool isArabic;
  final String uid;
  final VoidCallback onLanguageToggle;
  const BarberDashboard({super.key, required this.isArabic, required this.uid, required this.onLanguageToggle});
  @override
  State<BarberDashboard> createState() => _BarberDashboardState();
}

class _BarberDashboardState extends State<BarberDashboard> {
  int _tab = 0;
  bool isAiLoading = false;

  void _triggerSmartAiBooking(Map<String, dynamic> userData) async {
    setState(() => isAiLoading = true);
    String today = DateTime.now().toString().split(' ')[0];
    Map<String, dynamic> workingHours = userData['working_hours'] as Map<String, dynamic>? ?? {};
    List<String> allowedSlots = workingHours.entries.where((e) => e.value == true).map((e) => e.key).toList()..sort();

    if (allowedSlots.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(widget.isArabic ? '❌ يجب تفعيل ساعات العمل في الإعدادات أولاً!' : '❌ Activez les heures d\'abord!'), behavior: SnackBarBehavior.floating, backgroundColor: Colors.redAccent));
      setState(() => isAiLoading = false);
      return;
    }

    try {
      var bookingsSnap = await FirebaseFirestore.instance.collection('bookings').where('barberId', isEqualTo: widget.uid).where('date', isEqualTo: today).get();
      List<String> reservedSlots = bookingsSnap.docs.map((d) => d.get('timeSlot').toString()).toList();
      DateTime now = DateTime.now();
      String bestSlot = '';

      for (String slot in allowedSlots) {
        List<String> parts = slot.split(':');
        int slotHour = int.parse(parts[0]);
        int slotMin = int.parse(parts[1]);
        if ((slotHour > now.hour || (slotHour == now.hour && slotMin >= now.minute)) && !reservedSlots.contains(slot)) {
          bestSlot = slot;
          break;
        }
      }
      if (bestSlot.isEmpty) {
        for (String slot in allowedSlots) {
          if (!reservedSlots.contains(slot)) { bestSlot = slot; break; }
        }
      }
      if (bestSlot.isNotEmpty) {
        await FirebaseFirestore.instance.collection('bookings').add({'barberId': widget.uid, 'barberName': userData['name'] ?? 'Barber', 'customerId': 'walk_in_client', 'service': widget.isArabic ? 'زبون محلي مباشر' : 'Client sur place', 'timeSlot': bestSlot, 'status': 'accepted', 'date': today, 'createdAt': FieldValue.serverTimestamp()});
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(widget.isArabic ? '⚡ تم حجز وقت الـ $bestSlot لزبون محلي!' : '⚡ Créneau $bestSlot réservé sur place!'), behavior: SnackBarBehavior.floating, backgroundColor: Colors.green.shade800));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(widget.isArabic ? '❌ لا توجد أوقات فارغة متبقية اليوم!' : '❌ Aucun créneau libre aujourd\'hui!'), behavior: SnackBarBehavior.floating, backgroundColor: Colors.orange.shade800));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    }
    setState(() => isAiLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isArabic ? '✂️ لوحة تحكم الصالون' : '✂️ Gestion du Salon', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Color(0xFFD4AF37), letterSpacing: 1.0)),
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.black, Colors.black.withOpacity(0.8)], begin: Alignment.topCenter, end: Alignment.bottomCenter))),
        elevation: 0,
      ),
      drawer: AppDrawer(isArabic: widget.isArabic, onLanguageToggle: widget.onLanguageToggle, uid: widget.uid),
      body: Container(color: const Color(0xFF0D0D0D), child: _tab == 0 ? _buildRequests() : _buildSettings()),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, -5))]),
        child: BottomNavigationBar(
          currentIndex: _tab, onTap: (i) => setState(() => _tab = i),
          backgroundColor: const Color(0xFF121212), selectedItemColor: const Color(0xFFD4AF37), unselectedItemColor: Colors.white30, selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold), type: BottomNavigationBarType.fixed,
          items: [
            BottomNavigationBarItem(icon: const Icon(Icons.receipt_long_outlined), activeIcon: const Icon(Icons.receipt_long), label: widget.isArabic ? 'حجوزاتي' : 'Réservations'),
            BottomNavigationBarItem(icon: const Icon(Icons.settings_outlined), activeIcon: const Icon(Icons.settings), label: widget.isArabic ? 'الإعدادات' : 'Paramètres'),
          ],
        ),
      ),
    );
  }

  Widget _buildRequests() {
    return StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(widget.uid).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)));
          var d = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          return Column(children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF232323), Color(0xFF141414)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3), width: 1.5),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))]
                ),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _statWidget(Icons.star_rounded, '${(d['rating'] ?? 0.0).toStringAsFixed(1)}', widget.isArabic ? 'التقييم' : 'Note'),
                      Container(width: 1, height: 40, color: Colors.white10),
                      _statWidget(Icons.account_balance_wallet_rounded, '${d['earnings'] ?? 0} DA', widget.isArabic ? 'المداخيل' : 'Gains'),
                      Container(width: 1, height: 40, color: Colors.white10),
                      _statWidget(Icons.people_alt_rounded, '${d['totalBookings'] ?? 0}', widget.isArabic ? 'الزبائن' : 'Clients'),
                    ]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37), minimumSize: const Size(double.infinity, 58), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)), elevation: 6, shadowColor: const Color(0xFFD4AF37).withOpacity(0.4)),
                onPressed: isAiLoading ? null : () => _triggerSmartAiBooking(d),
                icon: isAiLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5)) : const Icon(Icons.flash_on_rounded, color: Colors.black, size: 28),
                label: Text(widget.isArabic ? 'إضافة زبون محلي الآن (سريع)' : 'Ajouter client sur place', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('bookings').where('barberId', isEqualTo: widget.uid).snapshots(),
                builder: (context, bs) {
                  if (!bs.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)));
                  var bks = bs.data!.docs;
                  if (bks.isEmpty) {
                    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.inbox_outlined, size: 60, color: Colors.white24), const SizedBox(height: 16),
                      Text(widget.isArabic ? 'لا توجد أي حجوزات حالياً' : 'Aucune réservation', style: const TextStyle(color: Colors.white60, fontSize: 16)),
                    ]));
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16), itemCount: bks.length,
                    itemBuilder: (context, i) {
                      var bk = bks[i].data() as Map<String, dynamic>;
                      String st = bk['status'] ?? 'pending';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16), padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFF1E1E1E), Color(0xFF141414)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                            borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))]
                        ),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(children: [const Icon(Icons.cut_rounded, color: Color(0xFFD4AF37), size: 20), const SizedBox(width: 8), Text('${bk['service']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white))]),
                                    _statusChip(st),
                                  ]),
                              const SizedBox(height: 12),
                              Row(children: [const Icon(Icons.access_time_filled, size: 16, color: Colors.white54), const SizedBox(width: 6), Text('${bk['timeSlot']}  |  ${bk['date']}', style: const TextStyle(color: Colors.white70, fontSize: 14))]),
                              if (st == 'pending') ...[
                                const SizedBox(height: 20),
                                Row(children: [
                                  Expanded(child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), onPressed: () => bks[i].reference.update({'status': 'accepted'}), child: Text(widget.isArabic ? '✅ قبول' : 'Accepter', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)))),
                                  const SizedBox(width: 12),
                                  Expanded(child: OutlinedButton(style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.red.shade400, width: 1.5), padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), onPressed: () => bks[i].reference.update({'status': 'rejected'}), child: Text(widget.isArabic ? '❌ رفض' : 'Refuser', style: TextStyle(color: Colors.red.shade400, fontWeight: FontWeight.bold, fontSize: 15)))),
                                ])
                              ]
                            ]),
                      );
                    },
                  );
                },
              ),
            )
          ]);
        });
  }

  Widget _statusChip(String status) {
    Color c = status == 'pending' ? Colors.orangeAccent : status == 'accepted' ? Colors.greenAccent : Colors.redAccent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: c.withOpacity(0.15), borderRadius: BorderRadius.circular(10), border: Border.all(color: c.withOpacity(0.5))),
      child: Text(status.toUpperCase(), style: TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
    );
  }

  Widget _statWidget(IconData icon, String val, String title) {
    return Column(children: [
      Icon(icon, color: const Color(0xFFD4AF37), size: 28), const SizedBox(height: 8),
      Text(val, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)), const SizedBox(height: 4),
      Text(title, style: const TextStyle(color: Colors.white60, fontSize: 12)),
    ]);
  }

  Widget _buildSettings() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(widget.uid).snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)));
        var d = snap.data!.data() as Map<String, dynamic>? ?? {};
        bool available = d['available'] ?? true;
        List services = d['services'] ?? [];
        Map<String, dynamic> workingHours = Map<String, dynamic>.from(d['working_hours'] ?? {});
        List<String> sortedSlots = workingHours.keys.toList()..sort();

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF1A1A1A), Color(0xFF121212)]), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10)]),
              child: SwitchListTile(
                value: available, activeColor: Colors.black, activeTrackColor: const Color(0xFFD4AF37), inactiveThumbColor: Colors.white54, contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                title: Text(available ? (widget.isArabic ? '🟢 الصالون مفتوح ومتاح للزبائن' : '🟢 Salon Ouvert') : (widget.isArabic ? '🔴 الصالون مغلق حالياً' : '🔴 Salon Fermé'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                onChanged: (val) => FirebaseFirestore.instance.collection('users').doc(widget.uid).update({'available': val}),
              ),
            ),
            const SizedBox(height: 32),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(widget.isArabic ? '⏰ تحديد ساعات العمل:' : '⏰ Heures de travail:', style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.w900, fontSize: 16)),
              TextButton.icon(
                  onPressed: () { workingHours.updateAll((key, value) => true); FirebaseFirestore.instance.collection('users').doc(widget.uid).update({'working_hours': workingHours}); },
                  icon: const Icon(Icons.done_all, color: Color(0xFFD4AF37), size: 18), label: Text(widget.isArabic ? 'تفعيل الكل' : 'Tout Activer', style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold)))
            ]),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFF141414), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10)),
              child: GridView.builder(
                shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, childAspectRatio: 2.2, crossAxisSpacing: 10, mainAxisSpacing: 10),
                itemCount: sortedSlots.length,
                itemBuilder: (context, idx) {
                  String slot = sortedSlots[idx]; bool isEnabled = workingHours[slot] ?? false;
                  return GestureDetector(
                    onTap: () { workingHours[slot] = !isEnabled; FirebaseFirestore.instance.collection('users').doc(widget.uid).update({'working_hours': workingHours}); },
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: isEnabled ? const Color(0xFFD4AF37).withOpacity(0.2) : Colors.black, border: Border.all(color: isEnabled ? const Color(0xFFD4AF37) : Colors.white10), borderRadius: BorderRadius.circular(10)),
                      child: Text(slot, style: TextStyle(color: isEnabled ? const Color(0xFFD4AF37) : Colors.white54, fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 36),
            Text(widget.isArabic ? '✂️ قائمة الخدمات والأسعار:' : '✂️ Services & Prix:', style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.w900, fontSize: 16)),
            const SizedBox(height: 16),
            ...services.asMap().entries.map((e) {
              int idx = e.key;
              return Container(
                margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)),
                child: Row(children: [
                  const Icon(Icons.check_circle_outline, color: Color(0xFFD4AF37), size: 20), const SizedBox(width: 12),
                  Expanded(child: Text(e.value['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.5))),
                    child: Text('${e.value['price']} DA', style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.w900)),
                  ),
                  const SizedBox(width: 8),
                  IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent), onPressed: () { services.removeAt(idx); FirebaseFirestore.instance.collection('users').doc(widget.uid).update({'services': services}); })
                ]),
              );
            }),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, side: const BorderSide(color: Color(0xFFD4AF37), width: 1.5), minimumSize: const Size(double.infinity, 56), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              onPressed: () { services.add({'name': widget.isArabic ? 'خدمة جديدة (تعديل)' : 'Nouveau (Modifiez)', 'price': 300}); FirebaseFirestore.instance.collection('users').doc(widget.uid).update({'services': services}); },
              icon: const Icon(Icons.add_circle, color: Color(0xFFD4AF37), size: 24),
              label: Text(widget.isArabic ? 'إضافة خدمة جديدة' : 'Ajouter un service', style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold, fontSize: 15)),
            ),
            const SizedBox(height: 40),
          ]),
        );
      },
    );
  }
}
