import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _apiUrl = 'http://10.106.76.3/receber.php';
const _authUrl = 'http://10.106.76.3/auth.php';
const _serverUrl = 'http://10.106.76.3';

Future<Map<String, dynamic>?> _loadCurrentUser() async {
  final prefs = await SharedPreferences.getInstance();
  final rawUser = prefs.getString('session_user');

  if (rawUser == null || rawUser.isEmpty) {
    return null;
  }

  return Map<String, dynamic>.from(jsonDecode(rawUser));
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Publicacoes',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: FutureBuilder<Map<String, dynamic>?>(
        future: _loadCurrentUser(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final user = snapshot.data;
          if (user != null && user['id'] != null) {
            return HomePage(user: user);
          }

          return const AuthPage();
        },
      ),
    );
  }
}

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  bool _loading = false;
  String? _message;

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final nome = _nomeController.text.trim();
    final email = _emailController.text.trim();
    final senha = _passwordController.text.trim();

    if (!_isLogin && nome.isEmpty) {
      setState(() => _message = 'Informe o nome para cadastrar.');
      return;
    }

    if (email.isEmpty || senha.isEmpty) {
      setState(() => _message = 'Preencha e-mail e senha.');
      return;
    }

    setState(() {
      _loading = true;
      _message = null;
    });

    try {
      final response = await http.post(
        Uri.parse(_authUrl),
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        body: jsonEncode({
          'action': _isLogin ? 'login' : 'register',
          if (!_isLogin) 'nome': nome,
          'email': email,
          'senha': senha,
        }),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final ok = response.statusCode >= 200 &&
          response.statusCode < 300 &&
          data['ok'] == true;

      if (!ok) {
        setState(() {
          _message = data['mensagem']?.toString() ?? 'Erro na autenticacao.';
        });
        return;
      }

      final user = data['user'] as Map<String, dynamic>? ?? {};
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('session_user', jsonEncode(user));
      await prefs.setBool('is_logged_in', true);

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => HomePage(user: user)),
        (route) => false,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _message = 'Nao foi possivel conectar ao servidor.';
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: 360,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      _isLogin
                          ? Icons.login_rounded
                          : Icons.person_add_alt_1_rounded,
                      size: 56,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _isLogin ? 'Entrar' : 'Cadastrar',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 24),
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(value: true, label: Text('Login')),
                        ButtonSegment(value: false, label: Text('Cadastro')),
                      ],
                      selected: {_isLogin},
                      onSelectionChanged: (value) => setState(() {
                        _isLogin = value.first;
                        _message = null;
                      }),
                    ),
                    const SizedBox(height: 20),
                    if (!_isLogin)
                      TextField(
                        controller: _nomeController,
                        decoration: const InputDecoration(
                          labelText: 'Nome',
                          prefixIcon: Icon(Icons.person_outline),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    if (!_isLogin) const SizedBox(height: 16),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'E-mail',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Senha',
                        prefixIcon: Icon(Icons.lock_outline),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: _loading ? null : _submit,
                      icon: _loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.arrow_forward_rounded),
                      label: Text(
                        _loading
                            ? 'Enviando...'
                            : (_isLogin ? 'Entrar' : 'Cadastrar'),
                      ),
                    ),
                    if (_message != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _message!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({required this.user, super.key});
  final Map<String, dynamic> user;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final userName = widget.user['nome']?.toString() ?? 'Usuario';

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Publicacoes - $userName'),
          actions: [
            IconButton(
              icon: const Icon(Icons.people_alt_outlined),
              tooltip: 'Solicitacoes',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => FriendRequestsPage(user: widget.user),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.logout_rounded),
              tooltip: 'Sair',
              onPressed: _logout,
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.upload_outlined), text: 'Publicar'),
              Tab(icon: Icon(Icons.dynamic_feed_outlined), text: 'Feed'),
              Tab(icon: Icon(Icons.search_rounded), text: 'Buscar'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            PublishPage(user: widget.user),
            FeedPage(user: widget.user),
            SearchPage(user: widget.user),
          ],
        ),
      ),
    );
  }
}

class PublishPage extends StatefulWidget {
  const PublishPage({required this.user, super.key});
  final Map<String, dynamic> user;

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
      request.fields['action'] = 'publish';
      request.fields['user_id'] = widget.user['id'].toString();
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

class SearchPage extends StatefulWidget {
  const SearchPage({required this.user, super.key});
  final Map<String, dynamic> user;

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  Future<List<Map<String, dynamic>>>? _searchFuture;

  Future<List<Map<String, dynamic>>> _runSearch(String query) async {
    final cleanQuery = query.trim();

    if (cleanQuery.isEmpty) {
      return const [];
    }

    final response = await http.get(
      Uri.parse(
        '$_apiUrl?action=search&user_id=${widget.user['id']}&query=${Uri.encodeQueryComponent(cleanQuery)}',
      ),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Erro ao buscar publicacoes');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return (data['dados'] as List<dynamic>)
        .map((item) => item as Map<String, dynamic>)
        .toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _searchFuture = _runSearch(value);
              });
            },
            decoration: InputDecoration(
              hintText: 'Pesquise por usuário ou texto',
              prefixIcon: const Icon(Icons.search_rounded),
              border: const OutlineInputBorder(),
              suffixIcon: _searchController.text.trim().isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchFuture = null;
                        });
                      },
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _searchFuture == null
                ? const Center(
                    child: Text('Digite algo para encontrar postagens.'),
                  )
                : FutureBuilder<List<Map<String, dynamic>>>(
                    future: _searchFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Text('Erro ao buscar: ${snapshot.error}'),
                        );
                      }

                      final posts = snapshot.data ?? [];
                      if (posts.isEmpty) {
                        return const Center(
                          child: Text('Nenhuma postagem encontrada.'),
                        );
                      }

                      return ListView.separated(
                        itemCount: posts.length,
                        separatorBuilder: (_, __) => const Divider(height: 24),
                        itemBuilder: (context, index) => _PostItem(
                          user: widget.user,
                          post: posts[index],
                          onRefresh: () {
                            if (_searchController.text.trim().isNotEmpty) {
                              setState(() {
                                _searchFuture =
                                    _runSearch(_searchController.text);
                              });
                            }
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class FeedPage extends StatefulWidget {
  const FeedPage({required this.user, super.key});
  final Map<String, dynamic> user;

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
    final userId = widget.user['id']?.toString() ?? '0';
    final response = await http.get(
      Uri.parse('$_apiUrl?action=feed&user_id=$userId'),
    );
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
                  itemBuilder: (context, index) => _PostItem(
                    user: widget.user,
                    post: posts[index],
                    onRefresh: () => setState(_reload),
                  ),
                ),
        );
      },
    );
  }
}

class _PostItem extends StatefulWidget {
  const _PostItem({
    required this.user,
    required this.post,
    required this.onRefresh,
  });

  final Map<String, dynamic> user;
  final Map<String, dynamic> post;
  final VoidCallback onRefresh;

  @override
  State<_PostItem> createState() => _PostItemState();
}

class _PostItemState extends State<_PostItem> {
  final TextEditingController _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _toggleLike() async {
    final userId = widget.user['id']?.toString() ?? '0';
    final postId = widget.post['id']?.toString() ?? '0';

    final response = await http.post(
      Uri.parse(_apiUrl),
      body: {
        'action': 'like',
        'user_id': userId,
        'post_id': postId,
      },
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      widget.onRefresh();
    }
  }

  Future<void> _requestFriend() async {
    final userId = widget.user['id']?.toString() ?? '0';
    final authorId = widget.post['autor_id']?.toString() ?? '0';

    final response = await http.post(
      Uri.parse(_apiUrl),
      body: {
        'action': 'friend_request',
        'user_id': userId,
        'author_id': authorId,
      },
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      widget.onRefresh();
    }
  }

  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final response = await http.post(
      Uri.parse(_apiUrl),
      body: {
        'action': 'comment',
        'user_id': widget.user['id'].toString(),
        'post_id': widget.post['id'].toString(),
        'texto': text,
      },
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      _commentController.clear();
      widget.onRefresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final photo = widget.post['foto']?.toString();
    final description = widget.post['descricao']?.toString();
    final imageUrl =
        photo == null || photo.isEmpty ? null : '$_serverUrl/uploads/$photo';
    final int authorId =
        int.tryParse(widget.post['autor_id']?.toString() ?? '0') ?? 0;
    final int currentUserId =
        int.tryParse(widget.user['id']?.toString() ?? '0') ?? 0;
    final String statusAmizade =
        widget.post['status_amizade']?.toString() ?? 'none';
    final bool liked = widget.post['curtido_por_mim'] == true;
    final int likes =
        int.tryParse(widget.post['curtidas']?.toString() ?? '0') ?? 0;
    final List<dynamic> comments = widget.post['comentarios'] ?? const [];
    final bool canComment =
        currentUserId == authorId || statusAmizade == 'aceita';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.post['autor_nome']?.toString() ?? 'Usuario',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            if (currentUserId != authorId)
              switch (statusAmizade) {
                'aceita' =>
                  const Text('Amigos', style: TextStyle(color: Colors.green)),
                'pendente' => const Text('Solicitacao enviada',
                    style: TextStyle(color: Colors.orange)),
                _ => TextButton(
                    onPressed: _requestFriend,
                    child: const Text('Solicitar amizade'),
                  ),
              },
          ],
        ),
        const SizedBox(height: 8),
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
          description?.isNotEmpty == true ? description! : 'Sem descricao.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            IconButton(
              onPressed: _toggleLike,
              icon: Icon(
                liked ? Icons.favorite : Icons.favorite_border,
                color: liked ? Colors.red : null,
              ),
            ),
            Text('$likes curtidas'),
          ],
        ),
        if (comments.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: comments.map((comment) {
                final nome = (comment['autor_nome'] ?? 'Usuario').toString();
                final texto = (comment['texto'] ?? '').toString();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(color: Colors.black87),
                      children: [
                        TextSpan(
                          text: '$nome: ',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        TextSpan(text: texto),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
        const SizedBox(height: 8),
        if (canComment)
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  decoration: const InputDecoration(
                    hintText: 'Escreva um comentario',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _sendComment,
                child: const Text('Comentar'),
              ),
            ],
          )
        else if (currentUserId != authorId)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Apenas amigos podem comentar nesta postagem.',
              style: TextStyle(color: Colors.grey[700]),
            ),
          ),
      ],
    );
  }
}

class FriendRequestsPage extends StatefulWidget {
  const FriendRequestsPage({required this.user, super.key});
  final Map<String, dynamic> user;

  @override
  State<FriendRequestsPage> createState() => _FriendRequestsPageState();
}

class _FriendRequestsPageState extends State<FriendRequestsPage> {
  late Future<List<Map<String, dynamic>>> _requestsFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _requestsFuture = _fetchRequests();
  }

  Future<List<Map<String, dynamic>>> _fetchRequests() async {
    final userId = widget.user['id']?.toString() ?? '0';
    final response = await http.get(
      Uri.parse('$_apiUrl?action=pending_requests&user_id=$userId'),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Erro ao carregar requisicoes');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return (data['dados'] as List<dynamic>)
        .map((item) => item as Map<String, dynamic>)
        .toList();
  }

  Future<void> _respond(int friendId, String status) async {
    final response = await http.post(
      Uri.parse(_apiUrl),
      body: {
        'action': 'friend_response',
        'user_id': widget.user['id'].toString(),
        'friend_id': friendId.toString(),
        'status': status,
      },
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (mounted) {
        setState(_reload);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Solicitacoes de amizade')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _requestsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(
                child: Text('Nao foi possivel carregar solicitacoes.'));
          }

          final requests = snapshot.data ?? [];
          if (requests.isEmpty) {
            return const Center(child: Text('Nenhuma solicitacao pendente.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final request = requests[index];
              final nome = request['requester_nome']?.toString() ?? 'Usuario';
              final friendId =
                  int.tryParse(request['requester_id']?.toString() ?? '0') ?? 0;

              return Card(
                child: ListTile(
                  title: Text(nome),
                  subtitle: const Text('Deseja ser seu amigo?'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: () => _respond(friendId, 'aceita'),
                        child: const Text('Aceitar'),
                      ),
                      TextButton(
                        onPressed: () => _respond(friendId, 'recusada'),
                        child: const Text('Recusar'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
