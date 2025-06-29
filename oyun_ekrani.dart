import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart'; // Konfeti paketi
import 'dart:async';
import 'dart:math';
import 'gecis_ekrani.dart';

void main() {
  runApp(MaterialApp(
    home: GameScreen(),
  ));
}

class GameScreen extends StatefulWidget {
  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  String randomWord = '';
  String wordDefinition = '';
  List<String> wordLetters = [];
  List<String> guessedLetters = [];
  int score = 0;
  String userInput = '';
  List<String> passedWords = [];
  List<String> skippedWords = [];
  int currentLevel = 1;
  TextEditingController _controller = TextEditingController();
  FocusNode _focusNode = FocusNode();

  Timer? _timer;
  int _remainingTime = 30;
  int _remainingAttempts = 3;

  int _hintCount = 0;
  bool _isHintUsed = false;
  ConfettiController _confettiController =
      ConfettiController(duration: Duration(seconds: 20));

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
        duration: Duration(seconds: 20)); // Konfeti controller'ı başlat
    _loadUserProgress().then((_) {
      // Progress yüklendikten sonra kelime al
      _getRandomWord();
    });
  }

  void _startTimer() {
    _timer?.cancel();
    _remainingTime = 30;
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingTime > 0) {
          _remainingTime--;
        } else {
          _timer?.cancel();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Süre doldu! Yeni kelimeye geçiliyor.')),
          );
          // Burada kelimeyi geçmek için _getRandomWord çağrılmalı
          _getRandomWord();
        }
      });
    });
  }

  Future<void> _getRandomWord() async {
    try {
      // Kullanıcının mevcut seviyesine ait kelimeleri getir
      QuerySnapshot wordQuery = await FirebaseFirestore.instance
          .collection('words')
          .where('level', isEqualTo: currentLevel.toString())
          .get(); // Verileri al

      List<QueryDocumentSnapshot> words = wordQuery.docs.where((doc) {
        return !passedWords.contains(doc['word']) &&
            !skippedWords.contains(doc['word']);
      }).toList();

      if (words.isNotEmpty) {
        var selectedWord; // Seçilen kelimeyi saklayacak değişken
        bool wordFound = false;

        while (!wordFound) {
          // Geçmemiş kelime bulunana kadar döngüyü sürdür
          var randomIndex =
              Random().nextInt(words.length); // Rastgele bir indeks seç
          selectedWord = words[randomIndex]; // Seçilen kelimeyi al

          // Eğer seçilen kelime daha önce kullanılmadıysa, bu kelimeyi seç
          if (!passedWords.contains(selectedWord['word']) &&
              !skippedWords.contains(selectedWord['word'])) {
            // Atlanan kelimelerde değilse
            wordFound = true;
          }
        }

        setState(() {
          // UI'yi güncellemek için setState kullanıyoruz
          randomWord = selectedWord[
              'word']; // Seçilen kelimeyi 'randomWord' olarak ayarla
          wordDefinition = selectedWord['definition'] ?? '';
          wordLetters = randomWord.split('');
          guessedLetters = List.generate(wordLetters.length, (_) => '');
          _hintCount = (wordLetters.length / 2).floor();
          _isHintUsed = false; // İpucu kullanılmadı olarak başlat
        });

        _startTimer();

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_focusNode.hasFocus) {
            // Eğer odaklanılmamışsa
            FocusScope.of(context)
                .requestFocus(_focusNode); // FocusNode ile odaklan
          }
        });
      } else {
        if (currentLevel < 5) {
          passedWords.clear();
          skippedWords.clear();

          setState(() {
            currentLevel++;
          });
          _getRandomWord();
        } else {
          _showCompletionMessage();
        }
      }
    } catch (e) {
      print('Hata: $e');
    }
  }

  void _showCompletionMessage() {
    setState(() {
      _confettiController.play(); // Konfeti başlat
    });
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Tebrikler!'),
        content: Text('Tüm seviyeleri tamamladınız!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('Tamam'),
          ),
          TextButton(
            onPressed: _resetGame,
            child: Text('Yeniden Oynamak İçin'),
          ),
        ],
      ),
    );
  }

  void _resetGame() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String userId = user.uid;

      await FirebaseFirestore.instance.collection('scores').doc(userId).set({
        'userId': userId,
        'score': 0, // Firestore'daki puanı sıfırla
      }, SetOptions(merge: true));
    }
    // Konfeti durdur
    _confettiController.stop();
    setState(() {
      score = 0; // Uygulamadaki puanı sıfırla
      currentLevel = 1;
      passedWords.clear();
      skippedWords.clear();
      userInput = '';
      _remainingAttempts = 3; // Hakları sıfırla
    });

    Navigator.pop(context);
    _getRandomWord();
  }

  void _checkAnswer() {
    if (userInput.toLowerCase() == randomWord.toLowerCase()) {
      setState(() {
        // UI güncelleniyor
        guessedLetters = wordLetters; // Doğru harfler gösteriliyor
        score += wordLetters.length * 10;
        userInput = '';
      });
      // Doğru cevap verildiğinde SnackBar göster
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Doğru! Puan: $score')),
      );
      passedWords.add(randomWord); // Geçmiş kelimelere doğru cevabı ekle
      _getRandomWord(); // Yeni kelime al
    } else {
      // Eğer cevap yanlışsa
      setState(() {
        if (userInput.length != randomWord.length) {
          // Eğer girilen kelime uzunluğu yanlışsa

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text('Kelime ${randomWord.length} harften oluşmaktadır!')),
          );
        } else if (_remainingAttempts > 1) {
          _remainingAttempts--;
          userInput = ''; // Kullanıcı girişini temizle
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Yanlış! Kalan hak: $_remainingAttempts')),
          );
        } else {
          _getRandomWord(); // Yeni kelimeyi al
          _remainingAttempts = 3; // Hakları sıfırla
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Haklarınız bitti! Yeni kelimeye geçiliyor.')),
          );
        }
      });
    }

    _controller.clear(); // Kullanıcı girdisini temizle
  }

  Future<void> _saveScoreToFirestore() async {
    try {
      // Mevcut kullanıcıyı al
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String userId = user.uid;
        DocumentReference scoreDoc =
            FirebaseFirestore.instance.collection('scores').doc(userId);

        DocumentSnapshot snapshot = await scoreDoc.get();
        int currentFirestoreScore = 0; // Mevcut Firestore puanı

        if (snapshot.exists && snapshot.data() != null) {
          // Eğer belge mevcut ve veri varsa
          Map<String, dynamic>? data =
              snapshot.data() as Map<String, dynamic>?; // Veriyi Map olarak al
          if (data != null && data.containsKey('score')) {
            // Veride 'score' anahtarı varsa
            currentFirestoreScore = data['score'] as int; // Mevcut puanı al
          }
        } else {
          await scoreDoc.set({
            'userId': userId, // Kullanıcı ID'sini kaydet
            'score': 0, // Varsayılan olarak skoru sıfır yap
          });
          currentFirestoreScore = 0; // Mevcut skoru sıfır olarak başlat
        }

        // Yeni skoru hesapla
        int newScore = currentFirestoreScore + score;

        await scoreDoc.set({
          'userId': userId,
          'score': newScore,
        }, SetOptions(merge: true));
      }
    } catch (e) {
      print("Hata Firestore'a kaydederken: $e");
    }
  }

  void _exitGame() async {
    await _saveScoreToFirestore();
    await _saveUserProgress();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => TransitionScreen()),
    );
  }

  void _useHint() {
    if (_hintCount > 0) {
      setState(() {
        int randomIndex =
            Random().nextInt(wordLetters.length); // Rastgele bir harfi seç
        while (guessedLetters[randomIndex].isNotEmpty) {
          // Eğer seçilen harf zaten tahmin edilmişse, başka bir harf seç
          randomIndex = Random().nextInt(wordLetters.length);
        }
        guessedLetters[randomIndex] = wordLetters[randomIndex];
        _hintCount--;
        score -= 10;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('İpucu kullanıldı! Puan -10')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('İpucu hakkınız kalmadı!')),
      );
    }
  }

  Future<void> _saveUserProgress() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentReference userDoc =
          FirebaseFirestore.instance.collection('users').doc(user.uid);

      await userDoc.set({
        'currentLevel': currentLevel.toString(),
        'passedWords': passedWords,
        'skippedWords': skippedWords,
        'currentWord': randomWord, // O anki kelimeyi kaydet
        'currentDefinition': wordDefinition, // Kelimenin tanımını kaydet
        'guessedLetters': guessedLetters, // Tahmin edilen harfler
        'remainingTime': _remainingTime, // Kalan süre
      }, SetOptions(merge: true));
    }
  }

  Future<void> _loadUserProgress() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
        setState(() {
          currentLevel = int.parse(data['currentLevel'] ?? '1');
          passedWords = List<String>.from(data['passedWords'] ?? []);
          skippedWords = List<String>.from(data['skippedWords'] ?? []);
          randomWord = data['currentWord'] ?? ''; // Kaydedilen kelimeyi yükle
          wordDefinition = data['currentDefinition'] ?? ''; // Tanımı yükle
          guessedLetters = List<String>.from(data['guessedLetters'] ?? []);
          _remainingTime = data['remainingTime'] ?? 30; // Kalan süreyi yükle
          wordLetters = randomWord.split('');
          _isHintUsed =
              false; // Yeni oyun başladığında ipucu kullanılmadı olarak ayarla
          _hintCount =
              (wordLetters.length / 2).floor(); // İpucu sayısını ayarla
        });

        if (randomWord.isNotEmpty) {
          _startTimer();
        } else {
          _getRandomWord(); // Eğer kelime yoksa yeni bir kelime seç
        }
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Oyun Ekranı'), // Uygulama başlığı
      ),
      body: Center(
        child: Stack(
          children: [
            // Konfeti efekti
            ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality:
                  BlastDirectionality.explosive, // Patlama yönü
              blastDirection: pi / 3, // 60 derece açı
              gravity: 0.3,
              emissionFrequency: 0.1,
              shouldLoop: true,
              colors: [
                Colors.red,
                Colors.green,
                Colors.blue,
                Colors.purple,
                Colors.cyan,
                Colors.lime,
                Colors.indigo
              ], // Konfeti renkleri
            ),

            Column(
              mainAxisAlignment: MainAxisAlignment.center, // Dikeyde ortalama
              children: [
                Align(
                  alignment: Alignment.topRight, // Sağ üst köşeye hizalama
                  child: Padding(
                    padding: EdgeInsets.all(16), // Padding ile alan yaratma
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.end, // Sağdan hizalama
                      children: [
                        // Puan ve haklar
                        Text(
                          'Puan: $score', // Puanı gösterir
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Haklar: $_remainingAttempts', // Kalan hakları gösterir
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        // İpucu hakkı göstergesi
                        Stack(
                          alignment: Alignment.center, // Ortada hizalama
                          children: [
                            // Daire şekli
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle, // Daire şekli
                                border: Border.all(
                                    color: Colors.blue,
                                    width: 2), // Kenarlık rengi
                              ),
                            ),

                            GestureDetector(
                              onTap: _useHint, // İpucu kullanıldığında çağrılır
                              child: Icon(
                                Icons.star,
                                color: _hintCount > 0 && !_isHintUsed
                                    ? Colors.yellow
                                    : Colors.grey,
                                size: 30,
                              ),
                            ),
                          ],
                        ),
                        // İpucu hakkı gösterimi
                        Text(
                          'İpucu Hakkı: $_hintCount', // Kalan ipucu hakkını gösterir
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'Kalan Süre: $_remainingTime saniye', // Kalan süreyi gösterir
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 20),
                Text(
                  'Seviye: $currentLevel', // Mevcut seviyeyi gösterir
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.blue,
                  child: Text(
                    currentLevel.toString(), // Seviye numarasını gösterir
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
                SizedBox(height: 20),
                Container(
                  margin: EdgeInsets.symmetric(vertical: 20),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent
                        .withOpacity(0.1), // Tanım arka plan rengi
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    wordDefinition.isEmpty
                        ? 'Tanım yükleniyor...'
                        : wordDefinition, // Tanımı göster
                    style: TextStyle(fontSize: 18, fontStyle: FontStyle.italic),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.center, // Ortada hizalama
                  children: guessedLetters.map((letter) {
                    return Container(
                      margin: EdgeInsets.symmetric(horizontal: 4),
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        letter.isEmpty
                            ? '_'
                            : letter, // Boş harf yerine alt çizgi göster
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    );
                  }).toList(),
                ),
                SizedBox(height: 20),
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 50),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode, // FocusNode'u burada kullanıyoruz
                    onChanged: (value) {
                      userInput = value; // Kullanıcı girdisini günceller
                    },
                    onSubmitted: (value) {
                      userInput = value.trim();
                      _checkAnswer();
                      _controller.clear(); // TextField'i temizle
                      _startTimer();
                    },
                    decoration: InputDecoration.collapsed(
                        hintText: 'Cevabınızı yazın'), // Giriş metni
                    textAlign: TextAlign.center, // Giriş alanını ortala
                  ),
                ),
                SizedBox(height: 20),
                // Butonları yan yana yerleştir
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.center, // Ortada hizalama
                  children: [
                    ElevatedButton(
                      onPressed: _checkAnswer, // Cevabı kontrol et
                      child: Text('Onayla'),
                    ),
                    SizedBox(width: 20),
                    ElevatedButton(
                      onPressed: _exitGame, // Oyundan çık
                      child: Text('Çıkış Yap'),
                    ),
                    SizedBox(width: 20),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          skippedWords.add(randomWord); // Kelimeyi atla
                        });
                        _getRandomWord(); // Yeni kelimeye geç
                      },
                      child: Text('Pas'),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
