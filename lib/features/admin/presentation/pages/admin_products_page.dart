import 'dart:io';
import 'package:barbershop/shared/services/firestore_service.dart';
import 'package:barbershop/shared/services/storage_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';

class AdminProductsPage extends StatefulWidget {
  const AdminProductsPage({super.key});

  @override
  State<AdminProductsPage> createState() => _AdminProductsPageState();
}

class _AdminProductsPageState extends State<AdminProductsPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for Add/Edit
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();

  String? _selectedImageUrl;
  XFile? _pickedFile;
  bool _isLoading = false;

  void _showProductSheet({String? id, Map<String, dynamic>? data}) {
    _selectedImageUrl = null;
    _pickedFile = null;

    if (data != null) {
      _nameController.text = data['name'];
      _descriptionController.text = data['description'] ?? '';
      _priceController.text = data['price'].toString();
      _stockController.text = data['stock'].toString();
      _selectedImageUrl = data['imageUrl'];
    } else {
      _nameController.clear();
      _descriptionController.clear();
      _priceController.clear();
      _stockController.clear();
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
                    id == null ? 'Novo Produto' : 'Editar Produto',
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
                        const InputDecoration(labelText: 'Nome do Produto'),
                    validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
                  ),
                  const Gap(12),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(labelText: 'Descrição'),
                    maxLines: 2,
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
                          controller: _stockController,
                          decoration:
                              const InputDecoration(labelText: 'Estoque'),
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
                                  debugPrint('Starting save process...');
                                  String imageUrl = _selectedImageUrl ??
                                      'assets/images/combo.jpg';

                                  if (_pickedFile != null) {
                                    debugPrint('Uploading image...');
                                    final url = await StorageService()
                                        .uploadImage('products', _pickedFile!);
                                    if (url != null) {
                                      imageUrl = url;
                                      debugPrint('Image uploaded: $url');
                                    } else {
                                      debugPrint('Image upload failed');
                                    }
                                  }

                                  final productData = {
                                    'name': _nameController.text,
                                    'description': _descriptionController.text,
                                    'price': double.parse(_priceController.text
                                        .replaceAll(',', '.')),
                                    'stock': int.parse(_stockController.text),
                                    'imageUrl': imageUrl,
                                  };

                                  debugPrint(
                                      'Saving to Firestore: $productData');

                                  if (id == null) {
                                    await FirestoreService()
                                        .addProduct(productData);
                                  } else {
                                    await FirestoreService()
                                        .updateProduct(id, productData);
                                  }
                                  debugPrint('Saved successfully');

                                  if (mounted) Navigator.pop(context);
                                } catch (e) {
                                  debugPrint('Error saving product: $e');
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                            content: Text('Erro ao salvar: $e'),
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
        title: const Text('Gerenciar Produtos',
            style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showProductSheet(),
        backgroundColor: Colors.green, // Differentiate from Services
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: FirestoreService().getProductsStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final products = snapshot.data ?? [];

              if (products.isEmpty) {
                return const Center(child: Text('Nenhum produto cadastrado.'));
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: products.length,
                separatorBuilder: (context, index) => const Gap(12),
                itemBuilder: (context, index) {
                  final product = products[index];
                  final int stock = product['stock'] ?? 0;

                  return Card(
                    elevation: 2,
                    child: ListTile(
                      leading: Container(
                        width: 50,
                        height: 50,
                        color: Colors.grey[200],
                        child: const Icon(Icons.shopping_bag,
                            color: Colors.grey), // Placeholder
                      ),
                      title: Text(product['name'],
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('€ ${product['price']} • Estoque: $stock'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _showProductSheet(
                                id: product['id'], data: product),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              await FirestoreService()
                                  .deleteProduct(product['id']);
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
