import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:hex/hex.dart';
import 'package:mnemonic_generator/colors.dart';
import 'package:mnemonic_generator/wordlists/english.dart';
import 'package:mnemonic_generator/wordlists/korean.dart';
import 'package:window_manager/window_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  if (Platform.isWindows) {
    WindowManager.instance.setSize(const Size(1100, 710));
    WindowManager.instance.setMinimumSize(const Size(1100, 710));
    WindowManager.instance.setMaximumSize(const Size(1100, 710));
  } else if (Platform.isMacOS) {
    WindowManager.instance.setSize(const Size(1080, 690));
    WindowManager.instance.setMinimumSize(const Size(1080, 690));
    WindowManager.instance.setMaximumSize(const Size(1080, 690));
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '니모닉 생성기 MNEMONIC GENERATOR',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.orange,
      ),
      home: const MyHomePage(title: '당신의 니모닉을 만들어보세요!'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  TextEditingController editingController = TextEditingController();

  late StreamSubscription<ConnectivityResult> subscription;
  late ValueNotifier networkStatus = ValueNotifier(false);

  final allMnemonicList = List.generate(listEN.length, (i) => [i + 1, listEN[i], listKR[i]]);
  var mnemonicList = [];
  var wordsList = List.filled(23, -1);
  final total2Suffix = ['000', '001', '010', '011', '100', '101', '110', '111'];
  int focusIdx = 1;
  var lastWords = [];

  var coinList = List.filled(11, -1);
  final coinImg = ['assets/coin_head.png', 'assets/coin_tail.png', 'assets/coin_toss.png'];

  @override
  void initState() {
    mnemonicList.addAll(allMnemonicList);

    super.initState();
    subscription = Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      if (result == ConnectivityResult.none) {
        networkStatus.value = true;
      } else {
        networkStatus.value = false;
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    subscription.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Image.asset(
              'assets/bitcong_mini.png',
              width: 50,
            ),
            const SizedBox(
              width: 10,
            ),
            Text(widget.title),
            const Spacer(),
          ],
        ),
      ),
      body: Stack(
        children: [
          SizedBox(
            width: 1080,
            height: 600,
            child: Row(
              children: [
                Column(
                  children: [
                    Container(
                      width: 800,
                      height: 400,
                      color: color2,
                      padding: const EdgeInsets.all(10),
                      child: GridView.builder(
                        itemCount: 24,
                        scrollDirection: Axis.horizontal,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 6,
                          childAspectRatio: 1 / 3,
                        ),
                        itemBuilder: (BuildContext context, int index) {
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                if (index == 23) return;
                                focusIdx = index + 1;
                              });
                            },
                            child: Stack(
                              children: [
                                Positioned(
                                  top: 0,
                                  left: 30,
                                  child: Offstage(
                                    offstage: focusIdx != (index + 1),
                                    child: Image.asset(
                                      'assets/bitcong.png',
                                      height: 30,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 16),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Text((index + 1).toString()),
                                      Container(
                                        width: 160,
                                        height: 30,
                                        decoration: BoxDecoration(
                                          color: index != 23 ? Colors.white : Colors.grey.shade500,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: index < 23 && wordsList[index] != -1
                                            ? Center(
                                                child: Text(
                                                    "${listEN[wordsList[index]]} ${listKR[wordsList[index]]}"))
                                            : null,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    Row(
                      children: [
                        Stack(
                          children: [
                            Column(
                              children: [
                                Container(
                                  width: 600,
                                  height: 40,
                                  padding: const EdgeInsets.all(10),
                                  color: color4,
                                  child: const Text(
                                    '동전 던지기',
                                    style: TextStyle(fontSize: 15),
                                  ),
                                ),
                                Container(
                                  width: 600,
                                  height: 80,
                                  color: color4,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: 11,
                                    itemBuilder: (context, index) {
                                      return GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            coinList[index] == 1 ? coinList[index] = 0 : coinList[index] = 1;
                                            if (!coinList.contains(-1)) {
                                              var resCoin = '';
                                              for (var i = 0; i < coinList.length; i++) {
                                                resCoin += coinList[i].toString();
                                              }
                                              var resIdx = (int.parse(resCoin, radix: 2) + 1).toString();
                                              editingController.text = resIdx;
                                              filterSearchResults(resIdx);
                                            }
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(10),
                                          width: 55,
                                          height: 55,
                                          child: Image.asset(
                                            coinList[index] == -1
                                                ? coinImg[2]
                                                : coinList[index] == 1
                                                    ? coinImg[1]
                                                    : coinImg[0],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                Container(
                                  width: 600,
                                  height: 80,
                                  color: color3,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      const SizedBox(
                                        width: 20,
                                      ),
                                      SizedBox(
                                        width: 30,
                                        child: Image.asset('assets/youtube.png'),
                                      ),
                                      const SizedBox(
                                        width: 10,
                                      ),
                                      const Text(
                                        '유튜브\n - 1분 비트코인',
                                        style: TextStyle(fontSize: 15),
                                      ),
                                      const SizedBox(
                                        width: 50,
                                      ),
                                      const Text(
                                        '문의 및 제안\n - 5959song@naver.com',
                                        style: TextStyle(fontSize: 15),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            Positioned(
                              top: 5,
                              left: 550,
                              child: FloatingActionButton(
                                mini: true,
                                onPressed: () {
                                  setState(() {
                                    coinList = List.filled(11, -1);
                                    editingController.text = '';
                                    filterSearchResults('');
                                  });
                                },
                                tooltip: 'Clear',
                                child: const Icon(Icons.refresh),
                              ),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            Container(
                              width: 200,
                              height: 40,
                              padding: const EdgeInsets.all(10),
                              color: color1,
                              child: const Text('24번째 니모닉은..'),
                            ),
                            Stack(
                              children: [
                                Container(
                                  width: 200,
                                  height: 160,
                                  padding: const EdgeInsets.symmetric(horizontal: 30),
                                  color: color1,
                                  child: ListView.builder(
                                    itemCount: lastWords.length,
                                    itemBuilder: (context, index) {
                                      return Text('${listEN[lastWords[index]]} ${listKR[lastWords[index]]}');
                                    },
                                  ),
                                ),
                                Positioned(
                                  top: 100,
                                  left: 150,
                                  child: FloatingActionButton(
                                    mini: true,
                                    onPressed: () {
                                      setState(() {
                                        wordsList = List.filled(23, -1);
                                        lastWords = [];
                                      });
                                    },
                                    tooltip: 'Clear',
                                    child: const Icon(Icons.clear),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    )
                  ],
                ),
                Column(
                  children: [
                    Container(
                      width: 280,
                      height: 60,
                      color: color3,
                      child: Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: TextField(
                          controller: editingController,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: IconButton(
                              onPressed: () {
                                editingController.text = '';
                                filterSearchResults('');
                              },
                              icon: const Icon(Icons.cancel, color: Color.fromARGB(255, 199, 193, 193)),
                            ),
                            border: const OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(15.0),
                              ),
                            ),
                          ),
                          onChanged: (value) {
                            filterSearchResults(value);
                          },
                        ),
                      ),
                    ),
                    Container(
                      width: 280,
                      height: 540,
                      color: color3,
                      child: ListView.builder(
                        itemCount: mnemonicList.length,
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                wordsList[focusIdx - 1] = mnemonicList[index][0] - 1;
                                generateLastWords();

                                if (wordsList.sublist(focusIdx).contains(-1)) {
                                  focusIdx = wordsList.sublist(focusIdx).indexOf(-1) + focusIdx + 1;
                                } else if (wordsList.contains(-1)) {
                                  focusIdx = wordsList.indexOf(-1) + 1;
                                } else {
                                  return;
                                }
                              });
                            },
                            child: Card(
                              color: Colors.grey.shade200,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 5,
                                ),
                                child: Row(
                                  children: [
                                    SizedBox(width: 80, child: Text(mnemonicList[index][0].toString())),
                                    SizedBox(width: 80, child: Text(mnemonicList[index][1])),
                                    SizedBox(width: 80, child: Text(mnemonicList[index][2])),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          ValueListenableBuilder(
            valueListenable: networkStatus,
            builder: (context, value, child) {
              return !value
                  ? Container(
                      width: 1080,
                      height: 600,
                      color: Colors.orange.shade50,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/bitcong.png',
                            width: 300,
                          ),
                          const SizedBox(
                            width: 30,
                          ),
                          const Text(
                            '블루투스/인터넷/와이파이를 끊고\n다시 실행해 주세요!',
                            style: TextStyle(fontSize: 40),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : const SizedBox();
            },
          )
        ],
      ),
    );
  }

  // Calc 24th Mnemonic
  void generateLastWords() {
    if (wordsList.contains(-1)) {
      lastWords = [];
      return;
    }

    var binaryEntropy = [];
    var hexEntropy = [];
    var checksumEntropy = [];
    lastWords = [];

    // Convert 23 mnemonic to 11-digit binary string
    var twoRadixStr = '';
    for (var element in wordsList) {
      twoRadixStr += element.toRadixString(2).padLeft(11, '0');
    }

    // Add 8 Entropy Cases
    for (int i = 0; i < 8; i++) {
      binaryEntropy.add(twoRadixStr + total2Suffix[i]);
    }

    // Convert binary entropy to original entropy
    for (int i = 0; i < 8; i++) {
      var tmp = '';
      for (int j = 0; j < binaryEntropy[i].length / 4; j++) {
        tmp += int.parse(binaryEntropy[i].substring(4 * j, 4 * (j + 1)), radix: 2).toRadixString(16);
      }
      hexEntropy.add(tmp);
    }

    // Calc sha256 and CheckSum
    for (int i = 0; i < 8; i++) {
      // sha256
      var hash = sha256.convert(Uint8List.fromList(HEX.decode(hexEntropy[i])));

      // Add checksum, 24th mnemonic calculation of binary completed
      checksumEntropy.add(total2Suffix[i] +
          int.parse(hash.toString()[0], radix: 16).toRadixString(2).padLeft(4, '0') +
          int.parse(hash.toString()[1], radix: 16).toRadixString(2).padLeft(4, '0'));
    }

    // Convert 24th mnemonic to decimal, Add 'lastWords' List
    for (int i = 0; i < 8; i++) {
      lastWords.add(int.parse(checksumEntropy[i], radix: 2));
    }

    setState(() {});
  }

  // Mnemonic Search Filter
  filterSearchResults(String query) {
    List dummySearchList = [];
    dummySearchList.addAll(allMnemonicList);

    if (query.isNotEmpty) {
      List dummyListData = [];
      for (var item in dummySearchList) {
        if (item[0].toString().contains(query) || item[1].contains(query) || item[2].contains(query)) {
          dummyListData.add(item);
        }
      }

      setState(() {
        mnemonicList.clear();
        mnemonicList.addAll(dummyListData);
      });
      return;
    } else {
      setState(() {
        mnemonicList.clear();
        mnemonicList.addAll(allMnemonicList);
      });
    }
  }
}
