import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';

void main() => runApp(const BingoClientApp());

class BingoClientApp extends StatelessWidget {
  const BingoClientApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.teal,
        scaffoldBackgroundColor: const Color(0xFF121212),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
          ),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontFamily: 'Poppins', color: Colors.white),
          bodyMedium: TextStyle(fontFamily: 'Poppins', color: Colors.white70),
        ),
      ),
      theme: ThemeData(
        fontFamily: 'Poppins',
      ),
      home: const BingoCardScreen(),
    );
  }
}

class BingoCardScreen extends StatefulWidget {
  const BingoCardScreen({super.key});

  @override
  State<BingoCardScreen> createState() => _BingoCardScreenState();
}

class _BingoCardScreenState extends State<BingoCardScreen> {
  WebSocket? socket;
  List<int> drawnNumbers = [];
  late List<List<int?>> myCard;
  Set<int> marked = {};
  String serverIp = '';
  final ipController = TextEditingController();

  final headers = ['B', 'I', 'N', 'G', 'O'];

  @override
  void initState() {
    super.initState();
    myCard = generateCard();
  }

  void connect(String ip) async {
    try {
      final ws = await WebSocket.connect('ws://$ip:3000');
      setState(() {
        socket = ws;
        serverIp = ip;
        drawnNumbers.clear();
        marked.clear();
      });
      ws.listen((data) {
        final decoded = jsonDecode(data);

        if (decoded['type'] == 'DRAW') {
          final rawNumber = decoded['number'];
          final number = rawNumber is int ? rawNumber : int.tryParse(rawNumber.toString());
          if (number != null) {
            setState(() {
              drawnNumbers.add(number);
            });
          }
        } else if (decoded['type'] == 'BINGO_RESULT') {
          final result = decoded['result'];
          final message = result == 'WIN' ? '🎉 BINGO! Você ganhou!' : '❌ Ainda não foi dessa vez.';
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Resultado'),
              content: Text(message),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                )
              ],
            ),
          );
        }
      });
    } catch (e) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Erro de Conexão'),
          content: Text('Não foi possível conectar ao IP "$ip".\n\nErro: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            )
          ],
        ),
      );
    }
  }

  void callBingo() {
    if (socket != null && socket!.readyState == WebSocket.open) {
      final markedNumbers = marked.toList();
      socket!.add(jsonEncode({
        "type": "BINGO_REQUEST",
        "playerId": "Jogador 1",
        "numbers": markedNumbers,
      }));
    }
  }

  @override
  Widget build(BuildContext context) {
    final headerColors = [
      Colors.teal[300],
      Colors.teal[400],
      Colors.teal[500],
      Colors.teal[600],
      Colors.teal[700],
    ];

    return Scaffold(
      appBar: AppBar(title: const Text(
        'Bingo Family',
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 32,
          color: Colors.teal,
          fontWeight: FontWeight.bold,
        ),
      )),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: ipController,
                      decoration: const InputDecoration(labelText: 'IP da TV'),
                      enabled: socket == null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (socket == null)
                    ElevatedButton(
                      onPressed: () => connect(ipController.text),
                      child: const Text('Conectar'),
                    ),
                  if (socket != null)
                    const Text('✅ Conectado', style: TextStyle(fontFamily: 'Poppins', color: Colors.green)),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: headers.asMap().entries.map((entry) {
                  final i = entry.key;
                  final h = entry.value;

                  return Expanded(
                    child: Center(
                      child: Text(
                        h,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: headerColors[i % headerColors.length], // usa cor diferente por letra
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 8),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                children: List.generate(5, (row) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(5, (col) {
                      final int? n = myCard[col][row];
                      final isMarked = n != null && marked.contains(n);
                      final isDrawn = n != null && drawnNumbers.contains(n);
                      final isFree = n == null;

                      return Expanded(
                        child: GestureDetector(
                          onTap: isFree
                            ? null
                            : () {
                                setState(() {
                                  if (marked.contains(n)) {
                                    marked.remove(n);
                                  } else {
                                    marked.add(n);
                                  }
                                });
                              },
                          child: Container(
                            margin: const EdgeInsets.all(4),
                            height: 48,
                            decoration: BoxDecoration(
                              color: isFree
                                  ? Colors.amber[600]
                                  : isMarked
                                      ? Colors.teal
                                      : isDrawn
                                          ? Colors.red[600]
                                          : Colors.grey[700],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: Center(
                              child: isFree
                                  ? const Icon(
                                      Icons.star,
                                      size: 18,
                                      color: Colors.white,
                                    )
                                  : Text(
                                      '$n',
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      );
                    }),
                  );
                }),
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: callBingo,
              child: const Text('Bater'),
            )
          ],
        ),
      ),
    );
  }
}

class Range {
  final int start;
  final int end;
  Range(this.start, this.end);
}

List<List<int?>> generateCard() {
  final random = Random();
  List<List<int?>> card = [];

  List<Range> ranges = [
    Range(1, 15),
    Range(16, 30),
    Range(31, 45),
    Range(46, 60),
    Range(61, 75),
  ];

  for (var i = 0; i < 5; i++) {
    final numbers = <int?>{};
    while (numbers.length < 5) {
      numbers.add(ranges[i].start + random.nextInt(ranges[i].end - ranges[i].start + 1));
    }

    final column = numbers.toList();
    if (i == 2) column[2] = null;
    card.add(column);
  }

  return card;
}
