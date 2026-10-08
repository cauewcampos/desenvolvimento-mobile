import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const MeuApp());
}

class MeuApp extends StatelessWidget {
  const MeuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: PaginaMarkdown(),
    );
  }
}

class PaginaMarkdown extends StatefulWidget {
  const PaginaMarkdown({super.key});

  @override
  State<PaginaMarkdown> createState() => _PaginaMarkdownState();
}

class _PaginaMarkdownState extends State<PaginaMarkdown> {
  final textoController = TextEditingController();
  String mensagem = '';

  @override
  void initState() {
    super.initState();
    carregarTexto();
  }

  Future<File> obterArquivo() async {
    final pastaDocumentos = await getApplicationDocumentsDirectory();
    return File('${pastaDocumentos.path}/organiza.md');
  }

  Future<void> salvarTexto() async {
    final arquivo = await obterArquivo();

    await arquivo.writeAsString(textoController.text);

    if (!mounted) return;

    setState(() {
      mensagem = 'Texto salvo com sucesso!';
    });
  }

  Future<void> carregarTexto() async {
    final arquivo = await obterArquivo();

    if (await arquivo.exists()) {
      String conteudo = await arquivo.readAsString();

      if (!mounted) return;

      setState(() {
        textoController.text = conteudo;
      });
    }
  }

  Future<void> apagarTexto() async {
    final arquivo = await obterArquivo();

    if (await arquivo.exists()) {
      await arquivo.delete();
    }

    if (!mounted) return;

    setState(() {
      textoController.clear();
      mensagem = 'Texto apagado!';
    });
  }

  @override
  void dispose() {
    textoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editor Markdown'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text('Arquivo: organiza.md'),
            const SizedBox(height: 20),
            Expanded(
              child: TextField(
                controller: textoController,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: const InputDecoration(
                  hintText: 'Digite seu texto aqui...',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                ElevatedButton(
                  onPressed: salvarTexto,
                  child: const Text('Salvar'),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: apagarTexto,
                  child: const Text('Apagar'),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Text(mensagem),
          ],
        ),
      ),
    );
  }
}
