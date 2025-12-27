import 'package:barbershop/shared/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

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

  void _showProductSheet({String? id, Map<String, dynamic>? data}) {
    if (data != null) {
      _nameController.text = data['name'];
      _descriptionController.text = data['description'] ?? '';
      _priceController.text = data['price'].toString();
      _stockController.text = data['stock'].toString();
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
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                id == null ? 'Novo Produto' : 'Editar Produto',
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Gap(16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nome do Produto'),
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
                      decoration: const InputDecoration(labelText: 'Preço (€)'),
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
                    ),
                  ),
                  const Gap(12),
                  Expanded(
                    child: TextFormField(
                      controller: _stockController,
                      decoration: const InputDecoration(labelText: 'Estoque'),
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
                    ),
                  ),
                ],
              ),
              const Gap(24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      final productData = {
                        'name': _nameController.text,
                        'description': _descriptionController.text,
                        'price': double.parse(
                            _priceController.text.replaceAll(',', '.')),
                        'stock': int.parse(_stockController.text),
                        'imageUrl': data?['imageUrl'] ??
                            'assets/images/shampoo.png', // Placeholder logic
                      };

                      // NOTE: Image handling is skipped for simplicity as per previous context
                      // We default to a placeholder if no image exists or keep existing

                      if (id == null) {
                        await FirestoreService().addProduct(productData);
                      } else {
                        await FirestoreService().updateProduct(id, productData);
                      }

                      if (mounted) Navigator.pop(context);
                    }
                  },
                  child: Text(id == null ? 'Adicionar' : 'Salvar Alterações'),
                ),
              ),
              const Gap(40),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciar Produtos'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
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
