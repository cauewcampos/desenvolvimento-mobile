import 'package:flutter/material.dart';
import 'package:flutter_application_2/helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.initialize();
  runApp(const AplicativoPet());
}

class AplicativoPet extends StatelessWidget {
  const AplicativoPet({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pets SQLite',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const PaginaInicialPet(),
    );
  }
}

class PaginaInicialPet extends StatefulWidget {
  const PaginaInicialPet({super.key});

  @override
  State<PaginaInicialPet> createState() => _PaginaInicialPetState();
}

class _PaginaInicialPetState extends State<PaginaInicialPet> {
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _idController = TextEditingController();
  final _updateNameController = TextEditingController();
  final _updateAgeController = TextEditingController();
  final _updateIdController = TextEditingController();
  String? _mensagemStatus;

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _idController.dispose();
    _updateNameController.dispose();
    _updateAgeController.dispose();
    _updateIdController.dispose();
    super.dispose();
  }

  Future<void> _salvarPet() async {
    final nome = _nameController.text.trim();
    final idade = int.tryParse(_ageController.text);

    if (nome.isEmpty || idade == null) {
      _mostrarMensagem('Nome e idade válidos.');
      return;
    }

    await DatabaseHelper.inserirPet({'name': nome, 'age': idade});
    _nameController.clear();
    _ageController.clear();
    _mostrarMensagem('Pet salvo!');
    setState(() {});
  }

  Future<void> _listarPets() async {
    await DatabaseHelper.listarPets();
    setState(() {});
  }

  Future<void> _atualizarPet() async {
    final petId = int.tryParse(_updateIdController.text);
    final nome = _updateNameController.text.trim();
    final idade = int.tryParse(_updateAgeController.text);

    if (petId == null || nome.isEmpty || idade == null) {
      _mostrarMensagem('ID, nome e idade válidos.');
      return;
    }

    final linhasAfetadas = await DatabaseHelper.atualizarPet(
      petId,
      {'name': nome, 'age': idade},
    );

    if (linhasAfetadas == 0) {
      _mostrarMensagem('Pet não encontrado.');
      return;
    }

    _updateIdController.clear();
    _updateNameController.clear();
    _updateAgeController.clear();
    _mostrarMensagem('Pet atualizado!');
    setState(() {});
  }

  Future<void> _apagarPet() async {
    final petId = int.tryParse(_idController.text);

    if (petId == null) {
      _mostrarMensagem('ID inválido.');
      return;
    }

    final linhasAfetadas = await DatabaseHelper.apagarPet(petId);

    if (linhasAfetadas == 0) {
      _mostrarMensagem('Pet não encontrado.');
      return;
    }

    _idController.clear();
    _mostrarMensagem('Pet removido!');
    setState(() {});
  }

  void _mostrarMensagem(String mensagem) {
    setState(() {
      _mensagemStatus = mensagem;
    });
  }

  Widget _botaoComMensagem({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon),
          label: Text(label),
        ),
        if (_mensagemStatus != null && _mensagemStatus!.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            _mensagemStatus!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.deepPurple,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  Widget _construirAbaSalvar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nome do pet',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _ageController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Idade do pet',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          _botaoComMensagem(
            onPressed: _salvarPet,
            icon: Icons.save,
            label: 'Salvar pet',
          ),
        ],
      ),
    );
  }

  FutureBuilder<List<Map<String, dynamic>>> _construirAbaListar() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: DatabaseHelper.getPets(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text('Nenhum pet cadastrado.'),
          );
        }

        final pets = snapshot.data!;

        return ListView.builder(
          itemCount: pets.length,
          itemBuilder: (context, index) {
            final pet = pets[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: ListTile(
                leading: CircleAvatar(
                  child: Text('${pet['id']}'),
                ),
                title: Text('${pet['name']}'),
                subtitle: Text('Idade: ${pet['age']} anos'),
              ),
            );
          },
        );
      },
    );
  }

  Widget _construirAbaAtualizar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _updateIdController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'ID do pet',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _updateNameController,
            decoration: const InputDecoration(
              labelText: 'Novo nome',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _updateAgeController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Nova idade',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          _botaoComMensagem(
            onPressed: _atualizarPet,
            icon: Icons.edit,
            label: 'Atualizar pet',
          ),
        ],
      ),
    );
  }

  Widget _construirAbaApagar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _idController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'ID do pet',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          _botaoComMensagem(
            onPressed: _apagarPet,
            icon: Icons.delete,
            label: 'Apagar pet',
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Pets'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Salvar'),
              Tab(text: 'Listar'),
              Tab(text: 'Atualizar'),
              Tab(text: 'Apagar'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _construirAbaSalvar(),
            _construirAbaListar(),
            _construirAbaAtualizar(),
            _construirAbaApagar(),
          ],
        ),
      ),
    );
  }
}
