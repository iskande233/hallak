import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

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
            return const Scaffold(
                body: Center(
                    child:
                        CircularProgressIndicator(color: Color(0xFFD4AF37))));
          }
          if (snapshot.hasData) {
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(snapshot.data!.uid)
                  .get(),
              builder: (context, userSnap) {
                if (!userSnap.hasData)
                  return const Scaffold(
                      body: Center(child: CircularProgressIndicator()));
                if (!userSnap.data!.exists)
                  return AuthScreen(
                      isArabic: isArabic, onLanguageToggle: toggleLanguage);
                String role = userSnap.data!.get('role');
                return role == 'Barber'
                    ? BarberDashboard(
                        isArabic: isArabic,
                        uid: snapshot.data!.uid,
                        onLanguageToggle: toggleLanguage)
                    : CustomerDashboard(
                        isArabic: isArabic, onLanguageToggle: toggleLanguage);
              },
            );
          }
          return AuthScreen(
              isArabic: isArabic, onLanguageToggle: toggleLanguage);
        },
      ),
    );
  }
}

class AppDrawer extends StatelessWidget {
  final bool isArabic;
  final VoidCallback onLanguageToggle;
  final String uid;

  const AppDrawer(
      {super.key,
      required this.isArabic,
      required this.onLanguageToggle,
      required this.uid});

  void _showAvatarDialog(BuildContext context, String currentUrl) {
    final controller = TextEditingController(text: currentUrl);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isArabic ? 'تغيير صورة البروفايل' : 'Changer la photo',
            style: const TextStyle(color: Color(0xFFD4AF37))),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText:
                isArabic ? 'رابط الصورة (URL)' : 'Lien de l\'image (URL)',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(isArabic ? 'إلغاء' : 'Annuler',
                  style: const TextStyle(color: CustomColors.white24))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF37),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8))),
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .update({'avatarUrl': controller.text.trim()});
              Navigator.pop(context);
            },
            child: Text(isArabic ? 'حفظ' : 'Enregistrer',
                style: const TextStyle(
                    color: CustomColors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream:
          FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Drawer(
              child: Center(child: CircularProgressIndicator()));
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
                  gradient: LinearGradient(
                    colors: [Color(0xFF1E1E1E), Color(0xFF0D0D0D)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                currentAccountPicture: GestureDetector(
                  onTap: () => _showAvatarDialog(context, avatarUrl),
                  child: CircleAvatar(
                    radius: 36,
                    backgroundColor: const Color(0xFFD4AF37),
                    backgroundImage:
                        avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                    child: avatarUrl.isEmpty
                        ? const Icon(Icons.person,
                            size: 40, color: CustomColors.black)
                        : null,
                  ),
                ),
                accountName: Text(name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Color(0xFFD4AF37))),
                accountEmail: Text(email,
                    style: const TextStyle(color: CustomColors.white60)),
              ),
              ListTile(
                leading: const Icon(Icons.language, color: Color(0xFFD4AF37)),
                title: Text(
                    isArabic ? 'لغة التطبيق (Français)' : 'Langue (العربية)',
                    style: const TextStyle(
                        color: CustomColors.whiteBF, fontSize: 15)),
                onTap: onLanguageToggle,
              ),
              ListTile(
                leading:
                    const Icon(Icons.photo_camera, color: Color(0xFFD4AF37)),
                title: Text(isArabic ? 'تغيير صورة الحساب' : 'Changer la photo',
                    style: const TextStyle(
                        color: CustomColors.whiteBF, fontSize: 15)),
                onTap: () {
                  Navigator.pop(context);
                  _showAvatarDialog(context, avatarUrl);
                },
              ),
              const Spacer(),
              const Divider(color: CustomColors.white12),
              ListTile(
                leading:
                    const Icon(Icons.logout, color: CustomColors.redAccent),
                title: Text(isArabic ? 'تسجيل الخروج' : 'Déconnexion',
                    style: const TextStyle(
                        color: CustomColors.redAccent, fontSize: 15)),
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
  const AuthScreen(
      {super.key, required this.isArabic, required this.onLanguageToggle});
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
    '08:00': true,
    '09:00': true,
    '10:00': true,
    '11:00': true,
    '12:00': true,
    '13:00': true,
    '14:00': true,
    '15:00': true,
    '16:00': true,
    '17:00': true,
    '18:00': true,
    '19:00': true,
    '20:00': true,
    '21:00': true,
    '22:00': true,
  };

  void _submit() async {
    if (_emailCtrl.text.isEmpty || _passCtrl.text.isEmpty) return;
    setState(() => isLoading = true);
    try {
      if (isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: _emailCtrl.text.trim(), password: _passCtrl.text.trim());
      } else {
        UserCredential c = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
                email: _emailCtrl.text.trim(), password: _passCtrl.text.trim());
        await FirebaseFirestore.instance
            .collection('users')
            .doc(c.user!.uid)
            .set({
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
          'address': (role == 'Barber' && barberType == 'Fixed')
              ? _addressCtrl.text.trim()
              : null,
          'working_hours': role == 'Barber' ? defaultWorkingHours : null,
          'services': [
            {'name': 'قصة شعر', 'nameF': 'Coupe', 'price': 300},
            {'name': 'لحية', 'nameF': 'Barbe', 'price': 200},
          ]
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
            gradient: LinearGradient(
          colors: [Color(0xFF0D0D0D), Color(0xFF1A1A1A)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        )),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: const Color(0xFF161616),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                      color: const Color(0xFFD4AF37).withOpacity(0.15)),
                  boxShadow: [
                    BoxShadow(
                        color: CustomColors.black.withOpacity(0.5),
                        blurRadius: 20,
                        offset: const Offset(0, 10))
                  ]),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.content_cut,
                    size: 55, color: Color(0xFFD4AF37)),
                const SizedBox(height: 8),
                const Text('Hallaq DZ',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFD4AF37),
                        letterSpacing: 1.5)),
                const SizedBox(height: 20),
                Container(
                  height: 46,
                  decoration: BoxDecoration(
                      color: CustomColors.black,
                      borderRadius: BorderRadius.circular(14)),
                  child: Row(children: [
                    Expanded(
                        child: _toggleBtn(
                            widget.isArabic ? 'دخول' : 'Connexion',
                            isLogin,
                            () => setState(() => isLogin = true))),
                    Expanded(
                        child: _toggleBtn(
                            widget.isArabic ? 'تسجيل جديد' : 'Inscription',
                            !isLogin,
                            () => setState(() => isLogin = false))),
                  ]),
                ),
                const SizedBox(height: 18),
                if (!isLogin) ...[
                  _input(
                      _nameCtrl,
                      widget.isArabic ? 'الاسم الكامل' : 'Nom complet',
                      Icons.person),
                  const SizedBox(height: 12),
                  _input(_phoneCtrl,
                      widget.isArabic ? 'رقم الهاتف' : 'Téléphone', Icons.phone,
                      type: TextInputType.phone),
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(
                        child: _roleSelector('Customer',
                            '👤 ${widget.isArabic ? 'زبون' : 'Client'}')),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _roleSelector('Barber',
                            '✂️ ${widget.isArabic ? 'حلاق' : 'Coiffeur'}')),
                  ]),
                  const SizedBox(height: 16),
                  if (role == 'Barber') ...[
                    Text(widget.isArabic ? 'طبيعة عملك كحلاق:' : 'Type الخدمة:',
                        style: const TextStyle(
                            color: Color(0xFFD4AF37),
                            fontSize: 13,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(
                          child: _barberTypeSelector('Fixed',
                              '🏪 ${widget.isArabic ? 'حلاق ثابت (محل)' : 'Salon Fixe'}')),
                      const SizedBox(width: 10),
                      Expanded(
                          child: _barberTypeSelector('Mobile',
                              '🚗 ${widget.isArabic ? 'حلاق متنقل' : 'Coiffeur Mobile'}')),
                    ]),
                    const SizedBox(height: 12),
                    if (barberType == 'Fixed') ...[
                      _input(
                          _addressCtrl,
                          widget.isArabic
                              ? 'عنوان صالون الحلاقة بالتفصيل'
                              : 'Adresse du salon',
                          Icons.location_on),
                      const SizedBox(height: 12),
                    ],
                  ],
                ],
                _input(
                    _emailCtrl,
                    widget.isArabic ? 'البريد الإلكتروني' : 'Email',
                    Icons.email,
                    type: TextInputType.emailAddress),
                const SizedBox(height: 12),
                _input(_passCtrl,
                    widget.isArabic ? 'كلمة السر' : 'Mot de passe', Icons.lock,
                    obscure: true),
                const SizedBox(height: 22),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 5,
                    shadowColor: const Color(0xFFD4AF37).withOpacity(0.3),
                  ),
                  onPressed: isLoading ? null : _submit,
                  child: isLoading
                      ? const CircularProgressIndicator(
                          color: CustomColors.black)
                      : Text(
                          isLogin
                              ? (widget.isArabic ? 'تسجيل الدخول' : 'Connexion')
                              : (widget.isArabic
                                  ? 'إنشاء حساب جديد'
                                  : 'Créer le compte'),
                          style: const TextStyle(
                              color: CustomColors.black,
                              fontSize: 15,
                              fontWeight: FontWeight.bold)),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _toggleBtn(String title, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
            color: active ? const Color(0xFFD4AF37) : CustomColors.transparent,
            borderRadius: BorderRadius.circular(12)),
        alignment: Alignment.center,
        child: Text(title,
            style: TextStyle(
                color: active ? CustomColors.black : CustomColors.white60,
                fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _roleSelector(String r, String label) {
    bool active = role == r;
    return GestureDetector(
      onTap: () => setState(() => role = r),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
            color: active
                ? const Color(0xFFD4AF37).withOpacity(0.15)
                : CustomColors.black,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color:
                    active ? const Color(0xFFD4AF37) : CustomColors.white10)),
        alignment: Alignment.center,
        child: Text(label,
            style: TextStyle(
                color: active ? const Color(0xFFD4AF37) : CustomColors.white60,
                fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _barberTypeSelector(String t, String label) {
    bool active = barberType == t;
    return GestureDetector(
      onTap: () => setState(() => barberType = t),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
            color: active ? CustomColors.white10 : CustomColors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color:
                    active ? const Color(0xFFD4AF37) : CustomColors.white10)),
        alignment: Alignment.center,
        child: Text(label,
            style: TextStyle(
                color: active ? CustomColors.white : CustomColors.white30,
                fontSize: 12,
                fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _input(TextEditingController c, String hint, IconData icon,
      {bool obscure = false, TextInputType? type}) {
    return TextField(
      controller: c,
      obscureText: obscure,
      keyboardType: type,
      decoration: InputDecoration(
          prefixIcon: Icon(icon, color: const Color(0xFFD4AF37), size: 20),
          hintText: hint,
          hintStyle: const TextStyle(color: CustomColors.white30, fontSize: 13),
          filled: true,
          fillColor: CustomColors.black,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(vertical: 14)),
    );
  }
}

class CustomerDashboard extends StatefulWidget {
  final bool isArabic;
  final VoidCallback onLanguageToggle;
  const CustomerDashboard(
      {super.key, required this.isArabic, required this.onLanguageToggle});
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
        title: Text(
            widget.isArabic
                ? '💈 قائمة الصالونات الذكية'
                : '💈 Salons intelligents',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: const Color(0xFF0D0D0D),
        elevation: 0,
        centerTitle: true,
      ),
      drawer: AppDrawer(
          isArabic: widget.isArabic,
          onLanguageToggle: widget.onLanguageToggle,
          uid: currentUid),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
                color: const Color(0xFF161616),
                borderRadius: BorderRadius.circular(16)),
            child: Row(children: [
              Expanded(
                  child: _filterOption('AI_Recommended',
                      widget.isArabic ? '🔥 ترشيح الـ AI' : 'AI Best')),
              Expanded(
                  child: _filterOption(
                      'Fixed', '🏪 ${widget.isArabic ? 'محل' : 'Salon'}')),
              Expanded(
                  child: _filterOption(
                      'Mobile', '🚗 ${widget.isArabic ? 'متنقل' : 'Mobile'}')),
            ]),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .where('role', isEqualTo: 'Barber')
                .snapshots(),
            builder: (context, snap) {
              if (!snap.hasData)
                return const Center(
                    child: CircularProgressIndicator(color: Color(0xFFD4AF37)));

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

              if (barbers.isEmpty)
                return Center(
                    child: Text(
                        widget.isArabic
                            ? 'لا يوجد حلاقين حالياً'
                            : 'Aucun coiffeur trouvé',
                        style: const TextStyle(color: CustomColors.white30)));

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: barbers.length,
                itemBuilder: (context, i) {
                  var b = barbers[i].data() as Map<String, dynamic>;
                  String avatar = b['avatarUrl'] ?? '';
                  bool available = b['available'] ?? true;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF161616),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: const Color(0xFFD4AF37).withOpacity(0.1)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(children: [
                        Row(children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: const Color(0xFFD4AF37),
                            backgroundImage:
                                avatar.isNotEmpty ? NetworkImage(avatar) : null,
                            child: avatar.isEmpty
                                ? const Icon(Icons.person,
                                    color: CustomColors.black)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Row(
                                  children: [
                                    Text(b['name'] ?? 'Barber',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16)),
                                    if (filter == 'AI_Recommended' &&
                                        i == 0) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                            color: const Color(0xFFD4AF37)
                                                .withOpacity(0.2),
                                            borderRadius:
                                                BorderRadius.circular(6)),
                                        child: Text(
                                            widget.isArabic
                                                ? '💡 الأفضل'
                                                : 'Top',
                                            style: const TextStyle(
                                                color: Color(0xFFD4AF37),
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold)),
                                      )
                                    ]
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                    b['address'] ??
                                        (widget.isArabic
                                            ? 'حلاق متنقل (يأتي إليك)'
                                            : 'Coiffeur Mobile'),
                                    style: const TextStyle(
                                        color: CustomColors.white30,
                                        fontSize: 12),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                              ])),
                          Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                    '⭐ ${(b['rating'] ?? 0.0).toStringAsFixed(1)}',
                                    style: const TextStyle(
                                        color: Color(0xFFD4AF37),
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                      color: available
                                          ? CustomColors.green.withOpacity(0.15)
                                          : CustomColors.red.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(8)),
                                  child: Text(
                                      available
                                          ? (widget.isArabic ? 'متاح' : 'Dispo')
                                          : (widget.isArabic
                                              ? 'مشغول'
                                              : 'Occupé'),
                                      style: TextStyle(
                                          color: available
                                              ? CustomColors.green
                                              : CustomColors.red,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold)),
                                )
                              ])
                        ]),
                        const Divider(color: CustomColors.white10, height: 20),
                        Row(children: [
                          Expanded(
                              child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                    color: CustomColors.white10),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10)),
                            onPressed: () async {
                              final url =
                                  Uri.parse('https://www.google.com/maps');
                              await launchUrl(url,
                                  mode: LaunchMode.externalApplication);
                            },
                            icon: const Icon(Icons.map_outlined,
                                size: 16, color: CustomColors.white70),
                            label: Text(
                                widget.isArabic ? 'عرض الموقع' : 'Itinéraire',
                                style: const TextStyle(
                                    color: CustomColors.white70, fontSize: 13)),
                          )),
                          const SizedBox(width: 10),
                          Expanded(
                              child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFD4AF37),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10)),
                            onPressed: available
                                ? () => _showBookingSheet(barbers[i])
                                : null,
                            icon: const Icon(Icons.calendar_today,
                                size: 16, color: CustomColors.black),
                            label: Text(
                                widget.isArabic ? 'احجز الآن' : 'Réserver',
                                style: const TextStyle(
                                    color: CustomColors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13)),
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
    );
  }

  Widget _filterOption(String val, String label) {
    bool active = filter == val;
    return GestureDetector(
      onTap: () => setState(() => filter = val),
      child: Container(
        height: 38,
        decoration: BoxDecoration(
            color: active ? const Color(0xFFD4AF37) : CustomColors.transparent,
            borderRadius: BorderRadius.circular(12)),
        alignment: Alignment.center,
        child: Text(label,
            style: TextStyle(
                color: active ? CustomColors.black : CustomColors.white60,
                fontWeight: FontWeight.bold,
                fontSize: 13)),
      ),
    );
  }

  void _showBookingSheet(DocumentSnapshot doc) {
    var b = doc.data() as Map<String, dynamic>;
    List services = b['services'] ?? [];
    Map<String, dynamic> workingHours =
        b['working_hours'] as Map<String, dynamic>? ?? {};

    List<String> allowedSlots = workingHours.entries
        .where((e) => e.value == true)
        .map((e) => e.key)
        .toList()
      ..sort();

    String selSvc = services.isNotEmpty ? services[0]['name'] : '';
    String selTime = allowedSlots.isNotEmpty ? allowedSlots[0] : '';
    String today = DateTime.now().toString().split(' ')[0];

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161616),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('bookings')
              .where('barberId', isEqualTo: doc.id)
              .where('date', isEqualTo: today)
              .snapshots(),
          builder: (context, bookingSnap) {
            if (!bookingSnap.hasData)
              return const SizedBox(
                  height: 150,
                  child: Center(child: CircularProgressIndicator()));

            List<String> reservedSlots = bookingSnap.data!.docs
                .map((d) =>
                    (d.data() as Map<String, dynamic>)['timeSlot'].toString())
                .toList();

            return StatefulBuilder(
                builder: (context, setModalState) => Padding(
                      padding: EdgeInsets.only(
                          top: 20,
                          left: 20,
                          right: 20,
                          bottom:
                              MediaQuery.of(context).viewInsets.bottom + 20),
                      child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                '${widget.isArabic ? "احجز موعد عند" : "Réserver chez"} ${b['name']}',
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFD4AF37))),
                            const SizedBox(height: 16),
                            Text(
                                widget.isArabic
                                    ? 'الخدمة المطلوبة:'
                                    : 'Service demandé:',
                                style: const TextStyle(
                                    color: CustomColors.white60, fontSize: 13)),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              children: services.map<Widget>((s) {
                                bool a = selSvc == s['name'];
                                return ChoiceChip(
                                  label: Text('${s['name']} (${s['price']} DA)',
                                      style: TextStyle(
                                          color: a
                                              ? CustomColors.black
                                              : CustomColors.white,
                                          fontWeight: FontWeight.bold)),
                                  selected: a,
                                  selectedColor: const Color(0xFFD4AF37),
                                  backgroundColor: CustomColors.black,
                                  onSelected: (_) =>
                                      setModalState(() => selSvc = s['name']),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 16),
                            Text(
                                widget.isArabic
                                    ? 'الوقت المتاح المخصص:'
                                    : 'Créneau disponible:',
                                style: const TextStyle(
                                    color: CustomColors.white60, fontSize: 13)),
                            const SizedBox(height: 8),
                            allowedSlots.isEmpty
                                ? Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 10),
                                    child: Text(
                                        widget.isArabic
                                            ? 'الحلاق لم يحدد أي ساعات عمل اليوم!'
                                            : 'Aucun créneau disponible!',
                                        style: const TextStyle(
                                            color: CustomColors.redAccent)),
                                  )
                                : Wrap(
                                    spacing: 8,
                                    runSpacing: 4,
                                    children: allowedSlots.map<Widget>((t) {
                                      bool isReserved =
                                          reservedSlots.contains(t);
                                      bool a = selTime == t;

                                      return ChoiceChip(
                                        label: Text(
                                            isReserved
                                                ? "$t (${widget.isArabic ? 'محجوز' : 'Réservé'})"
                                                : t,
                                            style: TextStyle(
                                                color: isReserved
                                                    ? CustomColors.white30
                                                    : (a
                                                        ? CustomColors.black
                                                        : CustomColors.white),
                                                decoration: isReserved
                                                    ? TextDecoration.lineThrough
                                                    : null)),
                                        selected: !isReserved && a,
                                        selectedColor: const Color(0xFFD4AF37),
                                        backgroundColor: isReserved
                                            ? const Color(0xFF0A0A0A)
                                            : CustomColors.black,
                                        onSelected: isReserved
                                            ? null
                                            : (_) => setModalState(
                                                () => selTime = t),
                                      );
                                    }).toList(),
                                  ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFD4AF37),
                                  minimumSize: const Size(double.infinity, 50),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14))),
                              onPressed: (allowedSlots.isEmpty ||
                                      reservedSlots.contains(selTime))
                                  ? null
                                  : () async {
                                      await FirebaseFirestore.instance
                                          .collection('bookings')
                                          .add({
                                        'barberId': doc.id,
                                        'barberName': b['name'],
                                        'customerId': FirebaseAuth
                                            .instance.currentUser!.uid,
                                        'service': selSvc,
                                        'timeSlot': selTime,
                                        'status': 'pending',
                                        'date': today,
                                        'createdAt':
                                            FieldValue.serverTimestamp(),
                                      });
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(
                                              content: Text(widget.isArabic
                                                  ? '✅ تم إرسال طلب الحجز بنجاح!'
                                                  : '✅ Demande envoyée!'),
                                              backgroundColor:
                                                  CustomColors.green));
                                    },
                              child: Text(
                                  widget.isArabic
                                      ? 'تأكيد الحجز المسبق'
                                      : 'Confirmer la réservation',
                                  style: const TextStyle(
                                      color: CustomColors.black,
                                      fontWeight: FontWeight.bold)),
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
  const BarberDashboard(
      {super.key,
      required this.isArabic,
      required this.uid,
      required this.onLanguageToggle});
  @override
  State<BarberDashboard> createState() => _BarberDashboardState();
}

class _BarberDashboardState extends State<BarberDashboard> {
  int _tab = 0;
  bool isAiLoading = false;

  void _triggerSmartAiBooking(Map<String, dynamic> userData) async {
    setState(() => isAiLoading = true);
    String today = DateTime.now().toString().split(' ')[0];

    Map<String, dynamic> workingHours =
        userData['working_hours'] as Map<String, dynamic>? ?? {};
    List<String> allowedSlots = workingHours.entries
        .where((e) => e.value == true)
        .map((e) => e.key)
        .toList()
      ..sort();

    if (allowedSlots.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(widget.isArabic
              ? '❌ يجب تفعيل ساعات العمل في الإعدادات أولاً!'
              : '❌ Activez les heures d\'abord!'),
          backgroundColor: CustomColors.red));
      setState(() => isAiLoading = false);
      return;
    }

    try {
      var bookingsSnap = await FirebaseFirestore.instance
          .collection('bookings')
          .where('barberId', isEqualTo: widget.uid)
          .where('date', isEqualTo: today)
          .get();

      List<String> reservedSlots =
          bookingsSnap.docs.map((d) => d.get('timeSlot').toString()).toList();

      DateTime now = DateTime.now();
      String bestSlot = '';

      for (String slot in allowedSlots) {
        List<String> parts = slot.split(':');
        int slotHour = int.parse(parts[0]);
        int slotMin = int.parse(parts[1]);

        if ((slotHour > now.hour ||
                (slotHour == now.hour && slotMin >= now.minute)) &&
            !reservedSlots.contains(slot)) {
          bestSlot = slot;
          break;
        }
      }

      if (bestSlot.isEmpty) {
        for (String slot in allowedSlots) {
          if (!reservedSlots.contains(slot)) {
            bestSlot = slot;
            break;
          }
        }
      }

      if (bestSlot.isNotEmpty) {
        await FirebaseFirestore.instance.collection('bookings').add({
          'barberId': widget.uid,
          'barberName': userData['name'] ?? 'Barber',
          'customerId': 'walk_in_client',
          'service': widget.isArabic ? 'زبون محلي (AI)' : 'Client Local (AI)',
          'timeSlot': bestSlot,
          'status': 'accepted',
          'date': today,
          'createdAt': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(widget.isArabic
                ? '⚡ قام الـ AI بحجز خانة الـ $bestSlot بنجاح!'
                : '⚡ AI a réservé le créneau $bestSlot !'),
            backgroundColor: CustomColors.green));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(widget.isArabic
                ? '❌ جميع الساعات ممتلئة تماماً اليوم!'
                : '❌ Plus de créneaux libres!'),
            backgroundColor: CustomColors.orange));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
    setState(() => isAiLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.isArabic ? '✂️ لوحة التحكم للحلاق' : '✂️ Dashboard Coiffeur',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: const Color(0xFF0D0D0D),
        elevation: 0,
      ),
      drawer: AppDrawer(
          isArabic: widget.isArabic,
          onLanguageToggle: widget.onLanguageToggle,
          uid: widget.uid),
      body: _tab == 0 ? _buildRequests() : _buildSettings(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tab,
        onTap: (i) => setState(() => _tab = i),
        backgroundColor: const Color(0xFF161616),
        selectedItemColor: const Color(0xFFD4AF37),
        unselectedItemColor: CustomColors.white30,
        showUnselectedLabels: false,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
              icon: const Icon(Icons.analytics_outlined),
              activeIcon: const Icon(Icons.analytics),
              label: widget.isArabic ? 'الطلبات' : 'Demandes'),
          BottomNavigationBarItem(
              icon: const Icon(Icons.tune_outlined),
              activeIcon: const Icon(Icons.tune),
              label: widget.isArabic ? 'الإعدادات' : 'Paramètres'),
        ],
      ),
    );
  }

  Widget _buildRequests() {
    return StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(widget.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          var d = snapshot.data!.data() as Map<String, dynamic>? ?? {};

          return Column(children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF1E1E1E), Color(0xFF161616)]),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: const Color(0xFFD4AF37).withOpacity(0.2)),
                ),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _statWidget(
                          '⭐',
                          '${(d['rating'] ?? 0.0).toStringAsFixed(1)}',
                          widget.isArabic ? 'التقييم' : 'Note'),
                      _statWidget('💰', '${d['earnings'] ?? 0} DA',
                          widget.isArabic ? 'المداخيل' : 'Gains'),
                      _statWidget('📋', '${d['totalBookings'] ?? 0}',
                          widget.isArabic ? 'الحجوزات' : 'Total'),
                    ]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37),
                    minimumSize: const Size(double.infinity, 54),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                    shadowColor: const Color(0xFFD4AF37).withOpacity(0.2)),
                onPressed: isAiLoading ? null : () => _triggerSmartAiBooking(d),
                icon: isAiLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: CustomColors.black, strokeWidth: 2))
                    : const Icon(Icons.bolt,
                        color: CustomColors.black, size: 24),
                label: Text(
                    widget.isArabic
                        ? '⚡ حجز سريع بالذكاء الاصطناعي (للداخلين للمحل)'
                        : '⚡ Réservation Rapide AI (Walk-in)',
                    style: const TextStyle(
                        color: CustomColors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('bookings')
                    .where('barberId', isEqualTo: widget.uid)
                    .snapshots(),
                builder: (context, bs) {
                  if (!bs.hasData)
                    return const Center(child: CircularProgressIndicator());
                  var bks = bs.data!.docs;
                  if (bks.isEmpty)
                    return Center(
                        child: Text(
                            widget.isArabic
                                ? 'لا توجد طلبات حجز حالياً'
                                : 'Aucune demande',
                            style:
                                const TextStyle(color: CustomColors.white30)));
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: bks.length,
                    itemBuilder: (context, i) {
                      var bk = bks[i].data() as Map<String, dynamic>;
                      String st = bk['status'] ?? 'pending';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                            color: const Color(0xFF161616),
                            borderRadius: BorderRadius.circular(16)),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('✂️ ${bk['service']}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15)),
                                    _statusChip(st),
                                  ]),
                              const SizedBox(height: 6),
                              Text('🕐 ${bk['timeSlot']} - 📅 ${bk['date']}',
                                  style: const TextStyle(
                                      color: CustomColors.white30,
                                      fontSize: 13)),
                              if (st == 'pending') ...[
                                const SizedBox(height: 12),
                                Row(children: [
                                  Expanded(
                                      child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: CustomColors.green,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10))),
                                    onPressed: () => bks[i]
                                        .reference
                                        .update({'status': 'accepted'}),
                                    child: Text(
                                        widget.isArabic ? 'قبول' : 'Accepter',
                                        style: const TextStyle(
                                            color: CustomColors.white,
                                            fontWeight: FontWeight.bold)),
                                  )),
                                  const SizedBox(width: 10),
                                  Expanded(
                                      child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                        side: const BorderSide(
                                            color: CustomColors.red),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10))),
                                    onPressed: () => bks[i]
                                        .reference
                                        .update({'status': 'rejected'}),
                                    child: Text(
                                        widget.isArabic ? 'رفض' : 'Refuser',
                                        style: const TextStyle(
                                            color: CustomColors.red,
                                            fontWeight: FontWeight.bold)),
                                  )),
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
    Color c = status == 'pending'
        ? CustomColors.orange
        : status == 'accepted'
            ? CustomColors.green
            : CustomColors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: c.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
      child: Text(status.toUpperCase(),
          style:
              TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Widget _statWidget(String icon, String val, String title) {
    return Column(children: [
      Text(icon, style: const TextStyle(fontSize: 18)),
      const SizedBox(height: 4),
      Text(val,
          style: const TextStyle(
              color: Color(0xFFD4AF37),
              fontWeight: FontWeight.bold,
              fontSize: 16)),
      Text(title,
          style: const TextStyle(color: CustomColors.white30, fontSize: 11)),
    ]);
  }

  Widget _buildSettings() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData)
          return const Center(child: CircularProgressIndicator());
        var d = snap.data!.data() as Map<String, dynamic>? ?? {};
        bool available = d['available'] ?? true;
        List services = d['services'] ?? [];
        Map<String, dynamic> workingHours =
            Map<String, dynamic>.from(d['working_hours'] ?? {});

        List<String> sortedSlots = workingHours.keys.toList()..sort();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Card(
              color: const Color(0xFF161616),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: SwitchListTile(
                value: available,
                activeColor: const Color(0xFFD4AF37),
                title: Text(available
                    ? (widget.isArabic
                        ? '🟢 الصالون متاح لاستقبال الزبائن'
                        : '🟢 Salon Ouvert')
                    : (widget.isArabic ? '🔴 مغلق حالياً' : '🔴 Salon Fermé')),
                onChanged: (val) => FirebaseFirestore.instance
                    .collection('users')
                    .doc(widget.uid)
                    .update({'available': val}),
              ),
            ),
            const SizedBox(height: 20),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(
                  widget.isArabic
                      ? '⏰ تفعيل ساعات العمل:'
                      : '⏰ Heures de travail:',
                  style: const TextStyle(
                      color: Color(0xFFD4AF37), fontWeight: FontWeight.bold)),
              TextButton(
                  onPressed: () {
                    workingHours.updateAll((key, value) => true);
                    FirebaseFirestore.instance
                        .collection('users')
                        .doc(widget.uid)
                        .update({'working_hours': workingHours});
                  },
                  child: Text(widget.isArabic ? 'تشغيل الكل' : 'Tout Activer',
                      style: const TextStyle(color: Color(0xFFD4AF37))))
            ]),
            const SizedBox(height: 5),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: const Color(0xFF161616),
                  borderRadius: BorderRadius.circular(16)),
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: sortedSlots.length,
                itemBuilder: (context, idx) {
                  String slot = sortedSlots[idx];
                  bool isEnabled = workingHours[slot] ?? false;
                  return CheckboxListTile(
                    title: Text(slot, style: const TextStyle(fontSize: 14)),
                    activeColor: const Color(0xFFD4AF37),
                    value: isEnabled,
                    onChanged: (bool? value) {
                      workingHours[slot] = value ?? false;
                      FirebaseFirestore.instance
                          .collection('users')
                          .doc(widget.uid)
                          .update({'working_hours': workingHours});
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 25),
            Text(
                widget.isArabic
                    ? '✂️ إدارة الخدمات والأسعار:'
                    : '✂️ Services & Prix:',
                style: const TextStyle(
                    color: Color(0xFFD4AF37), fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ...services.asMap().entries.map((e) {
              int idx = e.key;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: const Color(0xFF161616),
                    borderRadius: BorderRadius.circular(12)),
                child: Row(children: [
                  Expanded(
                      child: Text(e.value['name'],
                          style: const TextStyle(fontWeight: FontWeight.bold))),
                  Text('${e.value['price']} DA',
                      style: const TextStyle(
                          color: Color(0xFFD4AF37),
                          fontWeight: FontWeight.bold)),
                  IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: CustomColors.redAccent),
                      onPressed: () {
                        services.removeAt(idx);
                        FirebaseFirestore.instance
                            .collection('users')
                            .doc(widget.uid)
                            .update({'services': services});
                      })
                ]),
              );
            }),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                  backgroundColor: CustomColors.white10,
                  minimumSize: const Size(double.infinity, 46),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
              onPressed: () {
                services.add({
                  'name': widget.isArabic ? 'خدمة جديدة' : 'Nouveau service',
                  'price': 300
                });
                FirebaseFirestore.instance
                    .collection('users')
                    .doc(widget.uid)
                    .update({'services': services});
              },
              icon: const Icon(Icons.add, color: Color(0xFFD4AF37)),
              label: Text(
                  widget.isArabic ? 'إضافة خدمة جديدة' : 'Ajouter un service',
                  style: const TextStyle(color: Color(0xFFD4AF37))),
            )
          ]),
        );
      },
    );
  }
}
