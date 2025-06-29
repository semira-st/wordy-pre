import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'gecis_ekrani.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WORDY',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[200],
      ),
      home: AuthPage(),
    );
  }
}

// Giriş ve kayıt ekranı için stateful widget
class AuthPage extends StatefulWidget {
  @override
  _AuthPageState createState() => _AuthPageState(); // State'i oluşturuyoruz
}

// AuthPage için state sınıfı
class _AuthPageState extends State<AuthPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController =
      TextEditingController(); // Şifre alanı kontrolcüsü

  // Kullanıcı kaydetme işlemi
  Future<void> _signUp() async {
    try {
      final UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text, // Şifre alanından alınan değer
      );
      print(
          'Kullanıcı oluşturuldu: ${userCredential.user?.email}'); // Başarı durumunda konsola yazdırılır

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user?.uid)
          .set({
        'email': userCredential.user?.email, // Kullanıcının e-posta adresi
        'uid': userCredential.user?.uid, // Kullanıcının UID'si
      });

      _showMessage('Kayıt Başarılı!',
          'Kullanıcı oluşturuldu: ${userCredential.user?.email}');
    } catch (e) {
      print('Hata: $e'); // Hata durumunda konsola yazdırılır
      _showMessage('Hata',
          'Kayıt işlemi başarısız: $e'); // Kullanıcıya hata mesajı gösterilir
    }
  }

  Future<void> _signIn() async {
    try {
      final UserCredential userCredential =
          await _auth.signInWithEmailAndPassword(
        email: _emailController.text, // E-posta alanından alınan değer
        password: _passwordController.text, // Şifre alanından alınan değer
      );
      print(
          'Giriş yapıldı: ${userCredential.user?.email}'); // Başarı durumunda konsola yazdırılır

      _showMessage(
          'Giriş Başarılı!', 'Hoş geldiniz: ${userCredential.user?.email}');

      Navigator.pushReplacement(
        context, // Mevcut bağlam
        MaterialPageRoute(
            builder: (context) => TransitionScreen()), // Geçiş ekranına geçiş
      );
    } catch (e) {
      print('Hata: $e'); // Hata durumunda konsola yazdırılır
      _showMessage('Hata',
          'Giriş işlemi başarısız: $e'); // Kullanıcıya hata mesajı gösterilir
    }
  }

  // Uyarı mesajı göstermek için yardımcı fonksiyon
  void _showMessage(String title, String message) {
    showDialog(
      context: context, // Mevcut bağlam
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title), // Mesaj başlığı
          content: Text(message), // Mesaj içeriği
          actions: <Widget>[
            TextButton(
              child: Text('Tamam'), // Kapatma düğmesi
              onPressed: () {
                Navigator.of(context).pop(); // Uyarı penceresini kapatır
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'WORDY', // Uygulama adı
          style: TextStyle(
            color: const Color.fromARGB(255, 132, 200, 98), // Yeşil yazı rengi
            fontWeight: FontWeight.bold, // Kalın yazı
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(50.0), // Sayfanın içeriği çevresindeki boşluk
        child: Column(
          children: <Widget>[
            SizedBox(height: 100), // Üstte boşluk
            TextField(
              controller: _emailController, // E-posta alanı kontrolcüsü
              decoration:
                  InputDecoration(labelText: 'Email'), // E-posta etiketi
            ),
            TextField(
              controller: _passwordController, // Şifre alanı kontrolcüsü
              decoration:
                  InputDecoration(labelText: 'Password'), // Şifre etiketi
              obscureText: true, // Şifreyi gizli yazma
            ),
            SizedBox(height: 20), // Butonlar arasına boşluk
            ElevatedButton(
              onPressed: _signUp, // Kayıt olma işlevini çağırır
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    Colors.blueAccent.withOpacity(0.1), // Buton arka plan rengi
                foregroundColor:
                    const Color.fromARGB(255, 8, 1, 43), // Yazı rengi
                fixedSize: Size(120, 40), // Buton boyutu
              ),
              child: Text('Kayıt Ol'), // Buton metni
            ),
            SizedBox(height: 20), // Butonlar arasına boşluk
            ElevatedButton(
              onPressed: _signIn, // Giriş yapma işlevini çağırır
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    Colors.blueAccent.withOpacity(0.1), // Buton arka plan rengi
                foregroundColor:
                    const Color.fromARGB(255, 8, 1, 43), // Yazı rengi
                fixedSize: Size(120, 40), // Buton boyutu
              ),
              child: Text('Giriş Yap'), // Buton metni
            ),
          ],
        ),
      ),
    );
  }
}
