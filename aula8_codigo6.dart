import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Galeria de Fotos',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
        ),
        useMaterial3: true,
      ),
      home: const Inicio(),
    );
  }
}

class Foto {
  final String titulo;
  final String url;

  const Foto({
    required this.titulo,
    required this.url,
  });
}

class Inicio extends StatefulWidget {
  const Inicio({super.key});

  @override
  State<Inicio> createState() => _InicioState();
}

class _InicioState extends State<Inicio> with SingleTickerProviderStateMixin {
  late TabController tabController;

  final List<Foto> fotos = [];
  final List<Foto> aceitas = [];

  Foto? fotoSelecionada;

  bool carregando = true;
  String mensagemErro = '';

  @override
  void initState() {
    super.initState();

    tabController = TabController(
      length: 3,
      vsync: this,
    );

    carregarFotos();
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  Future<void> carregarFotos() async {
    setState(() {
      carregando = true;
      mensagemErro = '';
    });

    try {
      final nomes = [
        'Computador',
        'Teclado',
        'Mouse',
        'Mousepad',
        'Fallen',
        'Coldzera',
        'Celular',
        'Cavalo',
        'Cr7',
        'Coala',
        'Messi',
        'Zebra',
        'Urso',
        'Bola',
        'Raposa',
        'Casa',
        'Tablet',
        'Tartaruga',
        'Futebol',
        'Arara',
      ];

      final titulos = nomes.join('|');

      final uri = Uri.parse(
        'https://pt.wikipedia.org/w/api.php'
        '?action=query'
        '&format=json'
        '&prop=pageimages'
        '&piprop=thumbnail'
        '&pithumbsize=600'
        '&titles=${Uri.encodeComponent(titulos)}'
        '&origin=*',
      );

      final cliente = HttpClient();

      try {
        final requisicao = await cliente.getUrl(uri);

        requisicao.headers.set(
          HttpHeaders.userAgentHeader,
          'FlutterGaleria/1.0',
        );

        final resposta = await requisicao.close();

        if (resposta.statusCode != 200) {
          throw Exception('Erro na conexão.');
        }

        final corpo = await resposta.transform(utf8.decoder).join();

        final dados = jsonDecode(corpo);

        final paginas = dados['query']['pages'] as Map<String, dynamic>;

        final lista = <Foto>[];

        for (final pagina in paginas.values) {
          final thumbnail = pagina['thumbnail'];

          if (thumbnail != null) {
            final titulo = pagina['title'];
            final imagem = thumbnail['source'];

            lista.add(
              Foto(
                titulo: titulo,
                url: imagem,
              ),
            );
          }
        }

        if (!mounted) return;

        setState(() {
          fotos.clear();
          fotos.addAll(lista);
          carregando = false;
        });
      } finally {
        cliente.close();
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        carregando = false;
        mensagemErro = 'Não foi possível carregar as imagens.';
      });
    }
  }

  void selecionarFoto(Foto foto) {
    setState(() {
      fotoSelecionada = foto;
    });

    tabController.animateTo(1);
  }

  void aceitarFoto() {
    if (fotoSelecionada == null) return;

    final foto = fotoSelecionada!;

    setState(() {
      if (!aceitas.contains(foto)) {
        aceitas.add(foto);
      }

      fotos.remove(foto);
      fotoSelecionada = null;
    });

    tabController.animateTo(0);
  }

  void recusarFoto() {
    if (fotoSelecionada == null) return;

    final foto = fotoSelecionada!;

    setState(() {
      fotos.remove(foto);
      fotoSelecionada = null;
    });

    tabController.animateTo(0);
  }

  void removerAceita(Foto foto) {
    setState(() {
      aceitas.remove(foto);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Galeria de Fotos',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.photo_library),
              text: 'Galeria',
            ),
            Tab(
              icon: Icon(Icons.rate_review),
              text: 'Avaliar',
            ),
            Tab(
              icon: Icon(Icons.star),
              text: 'Aceitas',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: tabController,
        children: [
          telaGaleria(),
          telaAvaliacao(),
          telaAceitas(),
        ],
      ),
    );
  }

  Widget telaGaleria() {
    if (carregando) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (mensagemErro.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 70,
                color: Colors.red,
              ),
              const SizedBox(height: 20),
              Text(
                mensagemErro,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: carregarFotos,
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    if (fotos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.done_all,
              size: 70,
              color: Colors.green,
            ),
            const SizedBox(height: 20),
            const Text(
              'Todas as fotos foram avaliadas!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: carregarFotos,
              icon: const Icon(Icons.refresh),
              label: const Text('Carregar novas fotos'),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.82,
      ),
      itemCount: fotos.length,
      itemBuilder: (context, index) {
        final foto = fotos[index];

        return GestureDetector(
          onTap: () => selecionarFoto(foto),
          child: Card(
            elevation: 4,
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                Expanded(
                  child: Image.network(
                    foto.url,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) {
                        return child;
                      }

                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(
                          Icons.broken_image,
                          size: 50,
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    foto.titulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget telaAvaliacao() {
    if (fotoSelecionada == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.touch_app,
              size: 80,
              color: Colors.grey,
            ),
            SizedBox(height: 20),
            Text(
              'Escolha uma foto na Galeria',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    final foto = fotoSelecionada!;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              foto.titulo,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 25),
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.network(
                foto.url,
                height: 350,
                width: double.infinity,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const SizedBox(
                    height: 350,
                    child: Icon(
                      Icons.broken_image,
                      size: 100,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              'Você aceita esta imagem?',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: recusarFoto,
                  icon: const Icon(Icons.close),
                  label: const Text('Recusar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 16,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: aceitarFoto,
                  icon: const Icon(Icons.check),
                  label: const Text('Aceitar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 16,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget telaAceitas() {
    if (aceitas.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.star_border,
              size: 80,
              color: Colors.grey,
            ),
            SizedBox(height: 20),
            Text(
              'Nenhuma foto aceita ainda.',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.78,
      ),
      itemCount: aceitas.length,
      itemBuilder: (context, index) {
        final foto = aceitas[index];

        return Card(
          elevation: 4,
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Expanded(
                child: Image.network(
                  foto.url,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Icon(
                        Icons.broken_image,
                        size: 50,
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 6,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        foto.titulo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      onPressed: () => removerAceita(foto),
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                      ),
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
}
