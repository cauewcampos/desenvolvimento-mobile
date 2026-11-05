import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

const _apiUrl = 'http://10.106.76.3/receber.php';
const _serverUrl = 'http://10.106.76.3';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Publicacoes',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Publicacoes'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Publicar'),
              Tab(text: 'Feed'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            PublishPage(),
            FeedPage(),
          ],
        ),
      ),
    );
  }
}

class PublishPage extends StatefulWidget {
  const PublishPage({super.key});

  @override
  State<PublishPage> createState() => _PublishPageState();
}

class _PublishPageState extends State<PublishPage> {
  final _picker = ImagePicker();
  final _descriptionController = TextEditingController();
  XFile? _photo;
  bool _sending = false;
  String? _message;
  bool _success = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final photo = await _picker.pickImage(
      source: source,
      imageQuality: 85,
    );

    if (!mounted || photo == null) return;
    setState(() {
      _photo = photo;
      _message = null;
    });
  }

  Future<void> _publish() async {
    final photo = _photo;
    final description = _descriptionController.text.trim();

    if (photo == null || description.isEmpty || _sending) return;

    setState(() {
      _sending = true;
      _message = null;
    });

    try {
      final request = http.MultipartRequest('POST', Uri.parse(_apiUrl));
      request.fields['descricao'] = description;
      request.files.add(await http.MultipartFile.fromPath('foto', photo.path));

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final data = jsonDecode(responseBody) as Map<String, dynamic>;

      if (!mounted) return;
      setState(() {
        _success = response.statusCode >= 200 && response.statusCode < 300;
        _message = data['mensagem']?.toString() ?? 'Resposta recebida.';
        if (_success) {
          _photo = null;
          _descriptionController.clear();
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _success = false;
        _message = 'Nao foi possivel enviar a publicacao.';
      });
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto = _photo != null;
    final canPublish =
        hasPhoto && _descriptionController.text.trim().isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          SizedBox(
            height: 260,
            width: double.infinity,
            child: hasPhoto
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(_photo!.path),
                      fit: BoxFit.contain,
                    ),
                  )
                : const Center(child: Text('Escolha uma foto.')),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickPhoto(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Galeria'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _pickPhoto(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: const Text('Camera'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descriptionController,
            maxLines: 3,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Descricao',
              hintText: 'Escreva uma descricao para a foto',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: canPublish && !_sending ? _publish : null,
              icon: _sending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.cloud_upload_outlined),
              label: Text(_sending ? 'Enviando...' : 'Publicar'),
            ),
          ),
          if (_message != null) ...[
            const SizedBox(height: 12),
            Text(
              _message!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _success ? Colors.green : Colors.red,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  late Future<List<Map<String, dynamic>>> _postsFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _postsFuture = _fetchPosts();
  }

  Future<List<Map<String, dynamic>>> _fetchPosts() async {
    final response = await http.get(Uri.parse(_apiUrl));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Erro ao carregar feed');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return (data['dados'] as List<dynamic>)
        .map((item) => item as Map<String, dynamic>)
        .toList();
  }

  Future<void> _refresh() async {
    setState(_reload);
    await _postsFuture;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _postsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: TextButton.icon(
              onPressed: () => setState(_reload),
              icon: const Icon(Icons.refresh),
              label: const Text('Nao foi possivel carregar o feed'),
            ),
          );
        }

        final posts = snapshot.data ?? [];
        return RefreshIndicator(
          onRefresh: _refresh,
          child: posts.isEmpty
              ? ListView(
                  children: const [
                    SizedBox(height: 240),
                    Center(child: Text('Nenhuma publicacao encontrada.')),
                  ],
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: posts.length,
                  separatorBuilder: (_, __) => const Divider(height: 24),
                  itemBuilder: (context, index) =>
                      _PostItem(post: posts[index]),
                ),
        );
      },
    );
  }
}

class _PostItem extends StatelessWidget {
  const _PostItem({required this.post});

  final Map<String, dynamic> post;

  @override
  Widget build(BuildContext context) {
    final photo = post['foto']?.toString();
    final description = post['descricao']?.toString();
    final oldText = post['texto']?.toString();
    final imageUrl =
        photo == null || photo.isEmpty ? null : '$_serverUrl/uploads/$photo';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (imageUrl != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              imageUrl,
              width: double.infinity,
              height: 220,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox(
                height: 220,
                child: Center(child: Text('Imagem indisponivel.')),
              ),
            ),
          ),
        const SizedBox(height: 8),
        Text(
          description?.isNotEmpty == true
              ? description!
              : (oldText ?? 'Sem descricao.'),
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }
}
