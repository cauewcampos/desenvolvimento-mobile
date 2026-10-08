import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MeuApp());
}

class MeuApp extends StatelessWidget {
  const MeuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: PaginaCep(),
    );
  }
}

class PaginaCep extends StatefulWidget {
  const PaginaCep({super.key});

  @override
  State<PaginaCep> createState() => _PaginaCepState();
}

class _PaginaCepState extends State<PaginaCep> {
  final cepController = TextEditingController();
  final numeroController = TextEditingController();

  String rua = '';
  String bairro = '';
  String cidade = '';
  String estado = '';
  String mensagem = '';

  @override
  void initState() {
    super.initState();
    carregarDados();
  }

  Future<void> buscarCep() async {
    String cep = cepController.text.replaceAll(RegExp(r'\D'), '');

    if (cep.length != 8 || numeroController.text.trim().isEmpty) {
      setState(() {
        mensagem = 'Informe o CEP e o número da casa.';
      });
      return;
    }

    try {
      final resposta = await http.get(
        Uri.parse('https://viacep.com.br/ws/$cep/json/'),
      );

      if (resposta.statusCode == 200) {
        final dados = jsonDecode(resposta.body);

        if (dados['erro'] == true) {
          setState(() {
            mensagem = 'CEP não encontrado.';
          });
          return;
        }

        setState(() {
          rua = dados['logradouro'] ?? '';
          bairro = dados['bairro'] ?? '';
          cidade = dados['localidade'] ?? '';
          estado = dados['uf'] ?? '';
          mensagem = 'Endereço encontrado!';
        });

        await salvarDados();
      } else {
        setState(() {
          mensagem = 'Erro ao consultar o CEP.';
        });
      }
    } catch (e) {
      setState(() {
        mensagem = 'Erro de conexão.';
      });
    }
  }

  Future<void> salvarDados() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('cep', cepController.text);
    await prefs.setString('numero', numeroController.text);
    await prefs.setString('rua', rua);
    await prefs.setString('bairro', bairro);
    await prefs.setString('cidade', cidade);
    await prefs.setString('estado', estado);
  }

  Future<void> carregarDados() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      cepController.text = prefs.getString('cep') ?? '';
      numeroController.text = prefs.getString('numero') ?? '';
      rua = prefs.getString('rua') ?? '';
      bairro = prefs.getString('bairro') ?? '';
      cidade = prefs.getString('cidade') ?? '';
      estado = prefs.getString('estado') ?? '';
    });
  }

  Future<void> apagarDados() async {
    final prefs = await SharedPreferences.getInstance();

    for (String chave in [
      'cep',
      'numero',
      'rua',
      'bairro',
      'cidade',
      'estado'
    ]) {
      await prefs.remove(chave);
    }

    if (!mounted) return;

    setState(() {
      cepController.clear();
      numeroController.clear();
      rua = '';
      bairro = '';
      cidade = '';
      estado = '';
      mensagem = 'Dados apagados!';
    });
  }

  @override
  void dispose() {
    cepController.dispose();
    numeroController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Consulta de CEP'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: cepController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'CEP',
              ),
            ),
            TextField(
              controller: numeroController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Número da casa',
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: buscarCep,
              child: const Text('Buscar CEP'),
            ),
            const SizedBox(height: 20),
            Text('Rua: $rua'),
            Text('Número: ${numeroController.text}'),
            Text('Bairro: $bairro'),
            Text('Cidade: $cidade'),
            Text('Estado: $estado'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: apagarDados,
              child: const Text('Apagar dados'),
            ),
            const SizedBox(height: 15),
            Text(mensagem),
          ],
        ),
      ),
    );
  }
}
