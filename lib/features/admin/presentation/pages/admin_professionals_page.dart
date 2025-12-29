import 'package:barbershop/shared/services/firestore_service.dart';
import 'package:barbershop/shared/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';

class AdminProfessionalsPage extends StatefulWidget {
  const AdminProfessionalsPage({super.key});

  @override
  State<AdminProfessionalsPage> createState() => _AdminProfessionalsPageState();
}

class _AdminProfessionalsPageState extends State<AdminProfessionalsPage> {
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();

  // Image handling
  String? _imageUrl; // For editing existing url
  XFile? _pickedImage; // For new upload
  bool _isUploading = false;

  void _resetForm() {
    _nameController.clear();
    _bioController.clear();
    _imageUrl = null;
    _pickedImage = null;
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _pickedImage = image;
      });
    }
  }

  Future<void> _saveProfessional([String? id]) async {
    if (_nameController.text.isEmpty) return;

    setState(() => _isUploading = true);

    String finalImageUrl = _imageUrl ?? '';

    // Upload new image if picked
    if (_pickedImage != null) {
      final url =
          await StorageService().uploadImage('professionals', _pickedImage!);
      if (url != null) {
        finalImageUrl = url;
      }
    }

    final Map<String, dynamic> data = {
      'name': _nameController.text,
      'bio': _bioController.text,
      'imageUrl': finalImageUrl,
    };

    if (id == null) {
      await FirestoreService().addProfessional(data);
    } else {
      await FirestoreService().updateProfessional(id, data);
    }

    setState(() => _isUploading = false);
    if (mounted) Navigator.pop(context);
  }

  void _showProfessionalDialog({Map<String, dynamic>? professional}) {
    _resetForm();

    if (professional != null) {
      _nameController.text = professional['name'] ?? '';
      _bioController.text = professional['bio'] ?? '';
      _imageUrl = professional['imageUrl'];
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, setDialogState) {
        return AlertDialog(
          title: Text(professional == null
              ? 'Novo Profissional'
              : 'Editar Profissional'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () async {
                    await _pickImage();
                    setDialogState(() {});
                  },
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: _pickedImage != null
                        ? NetworkImage(_pickedImage!
                            .path) // Works on Web for XFile usually? Or use Image.network for web path logic if needed but XFile.path on web is blob.
                        : (_imageUrl != null && _imageUrl!.isNotEmpty)
                            ? NetworkImage(_imageUrl!)
                            : null,
                    child: (_pickedImage == null &&
                            (_imageUrl == null || _imageUrl!.isEmpty))
                        ? const Icon(Icons.add_a_photo, color: Colors.grey)
                        : null,
                  ),
                ),
                const Gap(16),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Nome'),
                ),
                const Gap(8),
                TextField(
                  controller: _bioController,
                  decoration:
                      const InputDecoration(labelText: 'Bio / Mensagem'),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            if (_isUploading)
              const CircularProgressIndicator()
            else
              ElevatedButton(
                onPressed: () => _saveProfessional(professional?['id']),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white),
                child: const Text('Salvar'),
              ),
          ],
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestão de Profissionais',
            style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showProfessionalDialog(),
        backgroundColor: Colors.black,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: FirestoreService().getProfessionalsStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          final pros = snapshot.data!;
          if (pros.isEmpty) {
            return const Center(child: Text('Nenhum profissional cadastrado.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: pros.length,
            separatorBuilder: (_, __) => const Gap(12),
            itemBuilder: (context, index) {
              final pro = pros[index];
              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: CircleAvatar(
                    radius: 25,
                    backgroundImage:
                        (pro['imageUrl'] != null && pro['imageUrl'].isNotEmpty)
                            ? NetworkImage(pro['imageUrl'])
                            : null,
                    child: (pro['imageUrl'] == null || pro['imageUrl'].isEmpty)
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  title: Text(pro['name'] ?? 'Sem nome',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(pro['bio'] ?? '',
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () =>
                            _showProfessionalDialog(professional: pro),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                      title: const Text('Excluir?'),
                                      content: const Text(
                                          'Isso não apagará os agendamentos já feitos para este profissional.'),
                                      actions: [
                                        TextButton(
                                            onPressed: () =>
                                                Navigator.pop(ctx, false),
                                            child: const Text('Não')),
                                        TextButton(
                                            onPressed: () =>
                                                Navigator.pop(ctx, true),
                                            child: const Text('Sim')),
                                      ]));
                          if (confirm == true) {
                            await FirestoreService()
                                .deleteProfessional(pro['id']);
                          }
                        },
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
