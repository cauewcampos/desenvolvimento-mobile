import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const JogoMultiplicacaoApp());

class JogoMultiplicacaoApp extends StatelessWidget {
  const JogoMultiplicacaoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const JogoMultiplicacaoPage(),
    );
  }
}

class JogoMultiplicacaoPage extends StatefulWidget {
  const JogoMultiplicacaoPage({super.key});

  @override
  State<JogoMultiplicacaoPage> createState() => _JogoMultiplicacaoPageState();
}

class _JogoMultiplicacaoPageState extends State<JogoMultiplicacaoPage> {
  int fatorAtual = 2;
  int multiplicadorAtual = 1;
  String entradaUsuario = '';
  Timer? _timerErro;
  late Future<void> _inicializacaoDados;

  @override
  void initState() {
    super.initState();
    _inicializacaoDados = _carregarDados();
  }

  @override
  void dispose() {
    _timerErro?.cancel();
    super.dispose();
  }

  Future<void> _carregarDados() async {
    final prefs = await SharedPreferences.getInstance();
    fatorAtual = prefs.getInt('fatorAtual') ?? 2;
    multiplicadorAtual = prefs.getInt('multiplicadorAtual') ?? 1;
  }

  Future<void> _salvarDados() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('fatorAtual', fatorAtual);
    await prefs.setInt('multiplicadorAtual', multiplicadorAtual);
  }

  void _pressionarDigito(String digito) {
    if (entradaUsuario.length < 4) {
      setState(() {
        entradaUsuario += digito;
      });
    }
  }

  void _apagarDigito() {
    if (entradaUsuario.isNotEmpty) {
      setState(() {
        entradaUsuario = entradaUsuario.substring(0, entradaUsuario.length - 1);
      });
    }
  }

  void _verificarResposta() {
    if (entradaUsuario.isEmpty) return;

    int respostaCorreta = fatorAtual * multiplicadorAtual;
    int? respostaDigitada = int.tryParse(entradaUsuario);

    _timerErro?.cancel();
    setState(() {
      entradaUsuario = '';
    });

    if (respostaDigitada == respostaCorreta) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Acertou!'),
          backgroundColor: Colors.green,
          duration: Duration(milliseconds: 500),
        ),
      );

      setState(() {
        if (multiplicadorAtual == 10) {
          fatorAtual++;
          multiplicadorAtual = 1;
        } else {
          multiplicadorAtual++;
        }
        _salvarDados();
      });
    } else {
      final int fatorSalvo = fatorAtual;
      final int multiplicadorSalvo = multiplicadorAtual;

      setState(() {
        fatorAtual++;
        multiplicadorAtual = 1;
        _salvarDados();
      });

      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Errou!'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Clique aqui para continuar',
            textColor: Colors.white,
            onPressed: () {
              _timerErro?.cancel();
              setState(() {
                fatorAtual = fatorSalvo;
                multiplicadorAtual = multiplicadorSalvo;
                _salvarDados();
              });
            },
          ),
        ),
      );

      _timerErro = Timer(const Duration(seconds: 5), () {
        ScaffoldMessenger.of(context).clearSnackBars();
      });
    }
  }

  Widget _botaoTeclado(String texto, VoidCallback acao,
      {Color? corFundo, Color? corTexto}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: corFundo,
            padding: const EdgeInsets.symmetric(vertical: 18),
            textStyle:
                const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          onPressed: acao,
          child: Text(texto, style: TextStyle(color: corTexto)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _inicializacaoDados,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        double progresso = (multiplicadorAtual - 1) / 10.0;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Sequência de Multiplicação'),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.clear();
                  setState(() {
                    entradaUsuario = '';
                    _inicializacaoDados = _carregarDados();
                  });
                },
              )
            ],
          ),
          body: Column(
            children: [
              LinearProgressIndicator(
                value: progresso,
                backgroundColor: Colors.grey,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                minHeight: 10,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Fator Atual: $fatorAtual',
                        style:
                            const TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Progresso: ${(progresso * 100).toInt()}%',
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        '$fatorAtual x $multiplicadorAtual = ${entradaUsuario.isEmpty ? "?" : entradaUsuario}',
                        style: const TextStyle(
                            fontSize: 38, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 30),
                      Column(
                        children: [
                          Row(
                            children: [
                              _botaoTeclado('1', () => _pressionarDigito('1')),
                              _botaoTeclado('2', () => _pressionarDigito('2')),
                              _botaoTeclado('3', () => _pressionarDigito('3')),
                            ],
                          ),
                          Row(
                            children: [
                              _botaoTeclado('4', () => _pressionarDigito('4')),
                              _botaoTeclado('5', () => _pressionarDigito('5')),
                              _botaoTeclado('6', () => _pressionarDigito('6')),
                            ],
                          ),
                          Row(
                            children: [
                              _botaoTeclado('7', () => _pressionarDigito('7')),
                              _botaoTeclado('8', () => _pressionarDigito('8')),
                              _botaoTeclado('9', () => _pressionarDigito('9')),
                            ],
                          ),
                          Row(
                            children: [
                              _botaoTeclado('⌫', _apagarDigito,
                                  corFundo: Colors.orange,
                                  corTexto: Colors.white),
                              _botaoTeclado('0', () => _pressionarDigito('0')),
                              _botaoTeclado('OK', _verificarResposta,
                                  corFundo: Colors.blue,
                                  corTexto: Colors.white),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
