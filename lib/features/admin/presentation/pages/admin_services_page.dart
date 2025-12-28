import 'dart:io';
import 'package:barbershop/shared/services/firestore_service.dart';
import 'package:barbershop/shared/services/storage_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';

class AdminServicesPage extends StatefulWidget {
  const AdminServicesPage({super.key});

  @override
  State<AdminServicesPage> createState() => _AdminServicesPageState();
}

class _AdminServicesPageState extends State<AdminServicesPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for Add/Edit
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _durationController = TextEditingController();

  String? _selectedImageUrl;
  XFile? _pickedFile;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final file = await StorageService().pickImage(ImageSource.gallery);
    if (file != null) {
      setState(() {
        _pickedFile = file;
      });
    }
  }

  void _showServiceSheet({String? id, Map<String, dynamic>? data}) {
    _selectedImageUrl = null;
    _pickedFile = null;

    if (data != null) {
      _nameController.text = data['name'];
      _priceController.text = data['price'].toString();
      _durationController.text = data['durationMinutes'].toString();
      _selectedImageUrl = data['imageUrl'];
    } else {
      _nameController.clear();
      _priceController.clear();
      _durationController.clear();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: StatefulBuilder(
          builder: (context, setSheetState) {
            return Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    id == null ? 'Novo Serviço' : 'Editar Serviço',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Gap(16),
                  // Image Picker UI
                  GestureDetector(
                    onTap: () async {
                      final file =
                          await StorageService().pickImage(ImageSource.gallery);
                      if (file != null) {
                        setSheetState(() {
                          _pickedFile = file;
                        });
                      }
                    },
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                        image: _pickedFile != null
                            ? DecorationImage(
                                image: kIsWeb
                                    ? NetworkImage(_pickedFile!.path)
                                    : FileImage(File(_pickedFile!.path))
                                        as ImageProvider,
                                fit: BoxFit.cover,
                              )
                            : (_selectedImageUrl != null
                                ? DecorationImage(
                                    image: _selectedImageUrl!.startsWith('http')
                                        ? NetworkImage(_selectedImageUrl!)
                                        : AssetImage(_selectedImageUrl!)
                                            as ImageProvider,
                                    fit: BoxFit.cover,
                                  )
                                : null),
                      ),
                      child: _pickedFile == null && _selectedImageUrl == null
                          ? const Icon(Icons.add_a_photo,
                              color: Colors.grey, size: 40)
                          : null,
                    ),
                  ),
                  const Gap(8),
                  TextButton(
                      onPressed: () async {
                        final file = await StorageService()
                            .pickImage(ImageSource.gallery);
                        if (file != null) {
                          setSheetState(() {
                            _pickedFile = file;
                          });
                        }
                      },
                      child: const Text("Alterar Foto")),
                  const Gap(16),
                  TextFormField(
                    controller: _nameController,
                    decoration:
                        const InputDecoration(labelText: 'Nome do Serviço'),
                    validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
                  ),
                  const Gap(12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _priceController,
                          decoration:
                              const InputDecoration(labelText: 'Preço (€)'),
                          keyboardType: TextInputType.number,
                          validator: (v) =>
                              v!.isEmpty ? 'Campo obrigatório' : null,
                        ),
                      ),
                      const Gap(12),
                      Expanded(
                        child: TextFormField(
                          controller: _durationController,
                          decoration:
                              const InputDecoration(labelText: 'Duração (min)'),
                          keyboardType: TextInputType.number,
                          validator: (v) =>
                              v!.isEmpty ? 'Campo obrigatório' : null,
                        ),
                      ),
                    ],
                  ),
                  const Gap(24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : () async {
                              if (_formKey.currentState!.validate()) {
                                setState(() => _isLoading = true);
                                try {
                                  debugPrint(
                                      'Starting service save process...');
                                  String imageUrl = _selectedImageUrl ??
                                      'assets/images/corte_classico.png';

                                  if (_pickedFile != null) {
                                    debugPrint('Uploading service image...');
                                    final url = await StorageService()
                                        .uploadImage('services', _pickedFile!);
                                    if (url != null) {
                                      imageUrl = url;
                                      debugPrint(
                                          'Service image uploaded: $url');
                                    }
                                  }

                                  final serviceData = {
                                    'name': _nameController.text,
                                    'price': double.parse(_priceController.text
                                        .replaceAll(',', '.')),
                                    'durationMinutes':
                                        int.parse(_durationController.text),
                                    'imageUrl': imageUrl,
                                    'description': 'Serviço profissional',
                                  };

                                  debugPrint(
                                      'Saving service to Firestore: $serviceData');

                                  if (id == null) {
                                    await FirestoreService()
                                        .addService(serviceData);
                                  } else {
                                    await FirestoreService()
                                        .updateService(id, serviceData);
                                  }
                                  debugPrint('Service saved successfully');

                                  if (mounted) Navigator.pop(context);
                                } catch (e) {
                                  debugPrint('Error saving service: $e');
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                            content: Text(
                                                'Erro ao salvar serviço: $e'),
                                            backgroundColor: Colors.red));
                                  }
                                } finally {
                                  if (mounted) {
                                    setState(() => _isLoading = false);
                                  }
                                }
                              }
                            },
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : Text(
                              id == null ? 'Adicionar' : 'Salvar Alterações'),
                    ),
                  ),
                  const Gap(40),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciar Serviços',
            style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showServiceSheet(),
        backgroundColor: Colors.black,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: FirestoreService().getServicesStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final services = snapshot.data ?? [];

              if (services.isEmpty) {
                return const Center(child: Text('Nenhum serviço cadastrado.'));
              }

              return ReorderableListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: services.length,
                onReorder: (oldIndex, newIndex) async {
                  if (newIndex > oldIndex) newIndex -= 1;
                  final item = services.removeAt(oldIndex);
                  services.insert(newIndex, item);

                  // Update logic
                  FirestoreService().updateServicesOrder(services);
                },
                itemBuilder: (context, index) {
                  final service = services[index];
                  return Card(
                    key: ValueKey(service['id']),
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage: service['imageUrl'].startsWith('http')
                            ? NetworkImage(service['imageUrl'])
                            : AssetImage(service['imageUrl']) as ImageProvider,
                        backgroundColor: Colors.grey[200],
                      ),
                      title: Text(service['name'],
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                          '${service['durationMinutes']} min • € ${service['price']}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Draggable Handle
                          const Icon(Icons.drag_handle, color: Colors.grey),
                          const Gap(8),
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _showServiceSheet(
                                id: service['id'], data: service),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              await FirestoreService()
                                  .deleteService(service['id']);
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
        ),
      ),
    );
  }
}
