import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'oyun_ekrani.dart';
import 'tum_siralamalar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main.dart';

class TransitionScreen extends StatelessWidget {
  Future<List<Map<String, dynamic>>> _getTopScores() async {
    try {
      QuerySnapshot scoreSnapshot = await FirebaseFirestore.instance
          .collection('scores')
          .orderBy('score', descending: true)
          .limit(3)
          .get();
      List<Map<String, dynamic>> topScores = [];

      for (var doc in scoreSnapshot.docs) {
        String userId = doc['userId'];

        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId) // Belirli bir kullanıcıyı seçiyoruz
            .get();

        if (userDoc.exists) {
          String email = userDoc['email'];
          String uid = userId;
          int score = doc['score'];

          topScores.add({'email': email, 'score': score, 'uid': uid});
        }
      }

      return topScores;
    } catch (e) {
      print("Hata: $e");
      return []; // Hata durumunda boş liste döndürüyoruz
    }
  }

  Future<void> _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance
          .signOut(); // Firebase üzerinden çıkış yapıyoruz
      // Giriş sayfasına yönlendiriyoruz
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              AuthPage(), // AuthPage sayfasına yönlendiriyoruz
        ),
      );
    } catch (e) {
      print(
          "Çıkış yaparken hata: $e"); // Çıkış yaparken hata olursa yazdırıyoruz
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Scaffold widget'ı ile ekranı yapılandırıyoruz
      appBar: AppBar(
        title: Text('Geçiş Ekranı'), // Başlık çubuğunda "Geçiş Ekranı" yazısı
      ),
      body: Padding(
        // Ekran içeriğine padding ekliyoruz
        padding: EdgeInsets.all(16.0),
        child: Column(
          // Dikey bir sütun yapısı kullanıyoruz
          mainAxisAlignment:
              MainAxisAlignment.center, // İçeriği dikeyde ortalıyoruz
          crossAxisAlignment:
              CrossAxisAlignment.center, // İçeriği yatayda ortalıyoruz
          children: <Widget>[
            // Puanları ve kullanıcı bilgilerini gösterecek alan
            FutureBuilder<List<Map<String, dynamic>>>(
              // Asenkron veri almak için FutureBuilder kullanıyoruz
              future: _getTopScores(), // _getTopScores fonksiyonunu çağırıyoruz
              builder: (context, snapshot) {
                // Snapshot ile veriyi işliyoruz
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator(); // Veriler yükleniyor ise loading göstergesi
                } else if (snapshot.hasError) {
                  return Text(
                      'Bir hata oluştu: ${snapshot.error}'); // Hata durumunda mesaj
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Text(
                      'Puan bilgisi bulunamadı'); // Veri bulunamadıysa mesaj
                } else {
                  List<Map<String, dynamic>> topScores =
                      snapshot.data!; // En yüksek puanları alıyoruz

                  return Column(
                    // Puanları sırasıyla göstereceğiz
                    children: topScores
                        .asMap() // Her bir öğeyi sırasıyla işliyoruz
                        .map((index, scoreData) {
                          // Her puan için bir Container widget'ı oluşturuyoruz
                          return MapEntry(
                            index,
                            Container(
                              margin: EdgeInsets.symmetric(
                                  vertical:
                                      8), // Container'a dikey boşluk ekliyoruz
                              padding: EdgeInsets.all(
                                  16), // Container'a iç boşluk ekliyoruz
                              decoration: BoxDecoration(
                                color: Colors.purple[
                                    100], // Container arka plan rengini ayarlıyoruz
                                borderRadius: BorderRadius.circular(
                                    8), // Container köşe yuvarlama
                              ),
                              child: Row(
                                // Satır içinde düzenliyoruz
                                mainAxisAlignment: MainAxisAlignment
                                    .start, // Satırı soldan başlatıyoruz
                                children: [
                                  // Sıralama numarasını yuvarlak kutu içinde gösteriyoruz
                                  CircleAvatar(
                                    backgroundColor: const Color.fromARGB(
                                        255, 137, 169, 223),
                                    radius: 15,
                                    child: Text(
                                      (index + 1)
                                          .toString(), // Sıra numarasını yazdırıyoruz
                                      style: TextStyle(
                                        color:
                                            Colors.white, // Metin rengi beyaz
                                        fontWeight:
                                            FontWeight.bold, // Kalın font
                                        fontSize: 15, // Font boyutu
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                      width:
                                          16), // Sıra numarası ile metin arasına boşluk ekliyoruz
                                  Expanded(
                                    // Metnin genişliğini ayarlıyoruz
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment
                                          .spaceBetween, // Satırdaki elemanları dağıtıyoruz
                                      children: [
                                        // Kullanıcının e-posta kısmı ve UID
                                        Text(
                                          '${scoreData['uid'].substring(0, 4)} - ${scoreData['email'].split('@')[0]}', // UID ve e-posta kısmı
                                          style: TextStyle(
                                            fontSize: 18, // Font boyutu
                                            fontWeight:
                                                FontWeight.bold, // Kalın font
                                          ),
                                        ),
                                        Text(
                                          'Puan: ${scoreData['score']}', // Kullanıcının puanını gösteriyoruz
                                          style: TextStyle(
                                              fontSize: 18), // Font boyutu
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        })
                        .values
                        .toList(),
                  );
                }
              },
            ),
            SizedBox(height: 20), // Elemanlar arasında boşluk bırakıyoruz
            // Oyun başlatma butonu
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  // Oyun ekranına geçiş yapıyoruz
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          GameScreen()), // GameScreen sayfasına yönlendiriyoruz
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(
                    255, 204, 248, 229), // Buton arka plan rengi
                foregroundColor:
                    const Color.fromARGB(255, 8, 1, 43), // Buton metin rengi
                fixedSize: Size(170, 40), // Buton boyutları
              ),
              child: Text('Oyna'), // Butonun üzerinde "Oyna" yazısı
            ),
            SizedBox(height: 20), // Butonlar arasına boşluk bırakıyoruz
            // Sıralamayı görmek için buton
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  // Tüm sıralamalar sayfasına geçiş yapıyoruz
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        AllScoresScreen(), // AllScoresScreen sayfasına yönlendiriyoruz
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(
                    255, 204, 248, 229), // Buton arka plan rengi
                foregroundColor:
                    const Color.fromARGB(255, 8, 1, 43), // Buton metin rengi
                fixedSize: Size(170, 40), // Buton boyutları
              ),
              child: Text(
                  'Sıralamanı Gör'), // Butonun üzerinde "Sıralamanı Gör" yazısı
            ),
            SizedBox(height: 20), // Butonlar arasına boşluk bırakıyoruz
            // Çıkış yap butonu
            ElevatedButton(
              onPressed: () =>
                  _logout(context), // Çıkış yapma fonksiyonu çağırılıyor
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(
                    255, 204, 248, 229), // Buton arka plan rengi
                foregroundColor:
                    const Color.fromARGB(255, 8, 1, 43), // Buton metin rengi
                fixedSize: Size(170, 40), // Buton boyutları
              ),
              child: Text('Çıkış Yap'), // Butonun üzerinde "Çıkış Yap" yazısı
            ),
          ],
        ),
      ),
    );
  }
}
