import 'package:flutter/material.dart';
import 'dart:math';

void main() {
  runApp(const MeuApp());
}

class MeuApp extends StatelessWidget {
  const MeuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Treinar tabuada',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.orange,
        ),
        useMaterial3: true,
      ),
      home: const DesafioPage(),
    );
  }
}

class DesafioPage extends StatefulWidget {
  const DesafioPage({super.key});

  @override
  State<DesafioPage> createState() => _DesafioPageState();
}

class _DesafioPageState extends State<DesafioPage> {
  int numero1 = 1;
  int numero2 = 1;

  int acertos = 0;
  int erros = 0;

  String mensagem = '';

  final TextEditingController respostaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    gerarConta();
  }

  void gerarConta() {
    final random = Random();

    setState(() {
      numero1 = random.nextInt(10) + 1;
      numero2 = random.nextInt(10) + 1;

      mensagem = '';
      respostaController.clear();
    });
  }

  void verificarResposta() {
    final resposta = int.tryParse(respostaController.text);

    if (resposta == null) {
      setState(() {
        mensagem = 'Digite um número!';
      });

      return;
    }

    final resultadoCorreto = numero1 * numero2;

    if (resposta == resultadoCorreto) {
      setState(() {
        acertos++;
        mensagem = '✅ Resposta correta!';
      });
    } else {
      setState(() {
        erros++;
        mensagem = '❌ Errado! A resposta era $resultadoCorreto.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange.shade50,

      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        title: const Text(
          'Desafio da Multiplicação',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            const Text(
              'Quanto é?',
              style: TextStyle(
                fontSize: 24,
              ),
            ),

            const SizedBox(height: 15),

            Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$numero1 × $numero2',
                style: const TextStyle(
                  fontSize: 50,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 30),

            TextField(
              controller: respostaController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 25,
              ),
              decoration: const InputDecoration(
                labelText: 'Digite sua resposta',
                prefixIcon: Icon(Icons.calculate),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: verificarResposta,
              icon: const Icon(Icons.check),
              label: const Text(
                'Responder',
                style: TextStyle(
                  fontSize: 18,
                ),
              ),
            ),

            const SizedBox(height: 15),

            Text(
              mensagem,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 30),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '✅ Acertos: $acertos',
                  style: const TextStyle(
                    fontSize: 17,
                  ),
                ),

                const SizedBox(width: 30),

                Text(
                  '❌ Erros: $erros',
                  style: const TextStyle(
                    fontSize: 17,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            OutlinedButton.icon(
              onPressed: gerarConta,
              icon: const Icon(Icons.refresh),
              label: const Text(
                'Nova Conta',
              ),
            ),
          ],
        ),
      ),
    );
  }
}