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
      title: 'Galeria de Futebol',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const GaleriaPage(),
    );
  }
}

class GaleriaPage extends StatefulWidget {
  const GaleriaPage({super.key});

  @override
  State<GaleriaPage> createState() => _GaleriaPageState();
}

class _GaleriaPageState extends State<GaleriaPage> {
  final List<String> imagens = [
    'https://upload.wikimedia.org/wikipedia/commons/6/6e/Football_%28soccer_ball%29.svg',
    'https://upload.wikimedia.org/wikipedia/commons/1/15/Soccer_ball.svg',
    'https://upload.wikimedia.org/wikipedia/commons/c/c9/Football_pitch.svg',
    'https://upload.wikimedia.org/wikipedia/commons/8/82/Soccer_Field_Transparant.svg',
    'https://upload.wikimedia.org/wikipedia/commons/4/45/Football_field.svg',
  ];

  int indiceAtual = 0;

  final Set<int> imagensFavoritas = {};

  void _proximaImagem() {
    if (indiceAtual < imagens.length - 1) {
      setState(() {
        indiceAtual++;
      });
    }
  }

  void _imagemAnterior() {
    if (indiceAtual > 0) {
      setState(() {
        indiceAtual--;
      });
    }
  }

  void _alternarFavorito() {
    setState(() {
      if (imagensFavoritas.contains(indiceAtual)) {
        imagensFavoritas.remove(indiceAtual);
      } else {
        imagensFavoritas.add(indiceAtual);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool favoritada = imagensFavoritas.contains(indiceAtual);

    return Scaffold(
      backgroundColor: const Color(0xFF101510),

      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.green.shade800,
        foregroundColor: Colors.white,
        title: const Text(
          '⚽ Galeria de Futebol',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              // Imagem
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 300,
                  height: 250,
                  color: Colors.white,
                  child: Image.network(
                    imagens[indiceAtual],
                    fit: BoxFit.contain,

                    loadingBuilder: (
                      context,
                      child,
                      loadingProgress,
                    ) {
                      if (loadingProgress == null) {
                        return child;
                      }

                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    },

                    errorBuilder: (
                      context,
                      error,
                      stackTrace,
                    ) {
                      return const Center(
                        child: Icon(
                          Icons.broken_image,
                          size: 70,
                          color: Colors.grey,
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Contador
              Text(
                '${indiceAtual + 1} / ${imagens.length}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 15),

              // Favoritar
              IconButton(
                onPressed: _alternarFavorito,
                iconSize: 45,
                icon: Icon(
                  favoritada
                      ? Icons.favorite
                      : Icons.favorite_border,
                  color: favoritada
                      ? Colors.red
                      : Colors.white,
                ),
              ),

              Text(
                favoritada
                    ? 'Você curtiu essa imagem!'
                    : 'Gostou da imagem?',
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 30),

              // Botões
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed:
                        indiceAtual > 0 ? _imagemAnterior : null,
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Anterior'),
                  ),

                  const SizedBox(width: 20),

                  ElevatedButton.icon(
                    onPressed:
                        indiceAtual < imagens.length - 1
                            ? _proximaImagem
                            : null,
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Próxima'),
                  ),
                ],
              ),

              const SizedBox(height: 25),

              Text(
                'Favoritas: ${imagensFavoritas.length}',
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}