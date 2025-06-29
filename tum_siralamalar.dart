import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AllScoresScreen extends StatelessWidget {
  Future<List<Map<String, dynamic>>> _getAllScores() async {
    try {
      // Puanları Firestore'dan al
      QuerySnapshot scoreSnapshot = await FirebaseFirestore.instance
          .collection('scores') // 'scores' koleksiyonundaki verileri alıyoruz
          .orderBy('score', descending: true)
          .get(); // Veritabanından sorgu çekiyoruz

      List<Map<String, dynamic>> allScores =
          []; // Tüm sıralamaları tutacak liste

      for (var doc in scoreSnapshot.docs) {
        String userId = doc['userId']; // Kullanıcı ID'sini alıyoruz

        // Kullanıcı ID'sine göre email almak için users koleksiyonuna sorgu yapıyoruz
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection(
                'users') // 'users' koleksiyonundan kullanıcı bilgilerini alıyoruz
            .doc(userId) // Belirli bir kullanıcıyı seçiyoruz
            .get(); // Veriyi çekiyoruz

        if (userDoc.exists) {
          // Eğer kullanıcı mevcutsa
          String email =
              userDoc['email']; // Kullanıcının e-posta adresini alıyoruz
          int score = doc['score']; // Puanı alıyoruz

          // Tüm kullanıcıları listeye ekliyoruz
          allScores.add({'email': email, 'score': score, 'userId': userId});
        }
      }

      return allScores; // Tüm kullanıcıları içeren listeyi döndürüyoruz
    } catch (e) {
      print("Hata: $e"); // Hata durumunda hata mesajını yazdırıyoruz
      return []; // Hata durumunda boş liste döndürüyoruz
    }
  }

  @override
  Widget build(BuildContext context) {
    // build metoduyla ekranı oluşturuyoruz
    User? currentUser =
        FirebaseAuth.instance.currentUser; // Hesap sahibini alıyoruz

    return Scaffold(
      // Scaffold widget'ı ile ekran yapısını oluşturuyoruz
      appBar: AppBar(
        title: Text(
            'Tüm Sıralamalar'), // Başlık çubuğunda "Tüm Sıralamalar" yazısı
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        // Asenkron veri almak için FutureBuilder kullanıyoruz
        future: _getAllScores(), // _getAllScores fonksiyonunu çağırıyoruz
        builder: (context, snapshot) {
          // Snapshot ile veriyi işliyoruz
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator(); // Veriler yükleniyor ise loading göstergesi
          } else if (snapshot.hasError) {
            return Text(
                'Bir hata oluştu: ${snapshot.error}'); // Hata durumunda mesaj
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Text('Puan bilgisi bulunamadı'); // Veri bulunamadıysa mesaj
          } else {
            List<Map<String, dynamic>> allScores =
                snapshot.data!; // Verileri alıyoruz

            return ListView.builder(
              // Listeyi builder ile dinamik olarak oluşturuyoruz
              itemCount: allScores.length, // Liste uzunluğunu ayarlıyoruz
              itemBuilder: (context, index) {
                // Her bir öğe için widget oluşturuyoruz
                var scoreData = allScores[index]; // Şu anki öğeyi alıyoruz
                bool isCurrentUser = scoreData['userId'] ==
                    currentUser?.uid; // Şu anki kullanıcıyı kontrol ediyoruz

                String userIdSubstring = scoreData['userId']
                    .toString()
                    .substring(0, 4); // UID'nin ilk 4 hanesini alıyoruz

                return Container(
                  // Her bir öğeyi Container içinde düzenliyoruz
                  margin: EdgeInsets.symmetric(
                      vertical: 8), // Yatayda 8 piksel boşluk bırakıyoruz
                  padding:
                      EdgeInsets.all(16), // Container'a iç boşluk ekliyoruz
                  decoration: BoxDecoration(
                    color: isCurrentUser
                        ? Colors.yellow.shade200 // Hesap sahibine açık sarı
                        : Colors.purple[100], // Diğerlerine açık mor
                    borderRadius:
                        BorderRadius.circular(8), // Container köşe yuvarlama
                  ),
                  child: Row(
                    // Satır içinde düzenliyoruz
                    mainAxisAlignment:
                        MainAxisAlignment.start, // Satırı soldan başlatıyoruz
                    children: [
                      // Sıralama numarasını göstermek için CircleAvatar kullanıyoruz
                      CircleAvatar(
                        backgroundColor: const Color.fromARGB(255, 137, 169,
                            223), // Yuvarlak kutunun arka plan rengi
                        radius: 15, // Yuvarlak kutunun yarıçapı
                        child: Text(
                          (index + 1)
                              .toString(), // Sıra numarasını yazdırıyoruz
                          style: TextStyle(
                            color: Colors.white, // Metin rengi beyaz
                            fontWeight: FontWeight.bold, // Kalın font
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
                          // Yatayda düzenliyoruz
                          mainAxisAlignment: MainAxisAlignment
                              .spaceBetween, // Elemanları aralarına boşluk koyarak hizalıyoruz
                          children: [
                            // UID'nin ilk 4 hanesini ve e-posta kısmını yazdırıyoruz
                            Text(
                              '$userIdSubstring ${scoreData['email'].toString().split('@')[0]}', // UID'nin ilk 4 hanesi + e-posta kısmı
                              style: TextStyle(
                                fontSize: 18, // Font boyutu
                                fontWeight: FontWeight.bold, // Kalın font
                              ),
                            ),
                            Text(
                              'Puan: ${scoreData['score']}', // Kullanıcının puanını yazdırıyoruz
                              style: TextStyle(fontSize: 18), // Font boyutu
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
