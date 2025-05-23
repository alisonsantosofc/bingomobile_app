import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';

void main() => runApp(const BingoClientApp());

class BingoClientApp extends StatelessWidget {
  const BingoClientApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: BingoCardScreen(),
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
  late List<List<int?>> myCard; // int? para permitir null no espaço livre
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
          setState(() {
            drawnNumbers.add(decoded['number']);
          });
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
      print('Erro ao conectar: $e');
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

  void _showBingoResult(bool success, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(success ? 'BINGO!' : 'Tentativa Inválida'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (success) {
                // Opcional: desconectar ou resetar o jogo
              }
            },
            child: const Text('OK'),
          )
        ],
      ),
    );
  }

  void _showGameOver(String winner) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Jogo Encerrado'),
        content: Text('O vencedor foi: $winner'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Opcional: desconectar ou resetar o jogo
            },
            child: const Text('OK'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Minha Cartela')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // IP input e botão conectar
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: ipController,
                      decoration: const InputDecoration(labelText: 'IP da TV'),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => connect(ipController.text),
                    child: const Text('Conectar'),
                  )
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Cabeçalhos B I N G O
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: headers.map((h) {
                  return Expanded(
                    child: Center(
                      child: Text(
                        h,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 8),

            // Grid 5x5 dos números
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
                          onTap: (isDrawn && !isFree)
                              ? () {
                                  setState(() {
                                    if (marked.contains(n)) {
                                      marked.remove(n);
                                    } else {
                                      marked.add(n!);
                                    }
                                  });
                                }
                              : null,
                          child: Container(
                            margin: const EdgeInsets.all(4),
                            height: 48,
                            decoration: BoxDecoration(
                              color: isFree
                                  ? Colors.blueGrey
                                  : isMarked
                                      ? Colors.green
                                      : isDrawn
                                          ? Colors.yellow
                                          : Colors.grey[300],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.black),
                            ),
                            child: Center(
                              child: Text(
                                isFree ? '★' : '$n',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
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
    if (i == 2) column[2] = null; // Espaço livre no centro da coluna N
    card.add(column);
  }

  return card;
}
