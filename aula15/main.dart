import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const Janela());
}

class Janela extends StatefulWidget {
  const Janela({super.key});

  @override
  State<Janela> createState() => _JanelaState();
}

class _JanelaState extends State<Janela> {
  TextEditingController controlaNome = TextEditingController();
  TextEditingController controlaSenha = TextEditingController();
  TextEditingController controlaEmail = TextEditingController();
  String mensagem = 'Aguardando...';
  void envia() async {
    setState(() {
      mensagem = 'Enviando dados...';
    });
    var resposta = await buscaPostagem();

    if (resposta.statusCode == 200) {
      var json = jsonDecode(resposta.body);
      if (json.containsKey('sucesso')) {
        setState(() {
          mensagem = json['sucesso'];
        });
      } else {
        setState(() {
          mensagem = json['erro'];
        });
      }
      //print(jsonDecode(resposta.body)['sucesso']);
    } else {
      throw Exception('Falha ao enviar!');
    }
  }

  Future<http.Response> buscaPostagem() {
    var nome = controlaNome.text;
    var senha = controlaSenha.text;
    var email = controlaEmail.text;

    if (nome == '' || senha == '' || email == '') {
      setState(() {
        mensagem = 'Preencha os dados!';
      });
    }
    return http.get(Uri.parse(
        'http://10.106.76.21/trufa/salva_usuario.php?nome=$nome&senha=$senha&email=$email'));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Column(children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: controlaNome,
            ),
          ),
          SizedBox(
            height: 10,
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: controlaSenha,
            ),
          ),
          SizedBox(
            height: 10,
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: controlaEmail,
            ),
          ),
          SizedBox(
            height: 10,
          ),
          ElevatedButton(
            onPressed: envia,
            child: Text('Cadastrar'),
          ),
          Text(mensagem),
        ]),
      ),
    );
  }
}
