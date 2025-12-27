import 'package:barbershop/shared/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

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
  // Image URL handling would ideally be an upload, but for now text input or pre-set choice
  // Simplified for this iteration

  void _showServiceSheet({String? id, Map<String, dynamic>? data}) {
    if (data != null) {
      _nameController.text = data['name'];
      _priceController.text = data['price'].toString();
      _durationController.text = data['durationMinutes'].toString();
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
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                id == null ? 'Novo Serviço' : 'Editar Serviço',
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Gap(16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nome do Serviço'),
                validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
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
                      controller: _durationController,
                      decoration:
                          const InputDecoration(labelText: 'Duração (min)'),
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
                      final serviceData = {
                        'name': _nameController.text,
                        'price': double.parse(
                            _priceController.text.replaceAll(',', '.')),
                        'durationMinutes': int.parse(_durationController.text),
                        'imageUrl': data?['imageUrl'] ??
                            'assets/images/corte_classico.png', // Default or Keep
                        'description': 'Serviço profissional',
                      };

                      if (id == null) {
                        await FirestoreService().addService(serviceData);
                      } else {
                        await FirestoreService().updateService(id, serviceData);
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
        title: const Text('Gerenciar Serviços'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
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

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: services.length,
                separatorBuilder: (context, index) => const Gap(12),
                itemBuilder: (context, index) {
                  final service = services[index];
                  return Card(
                    elevation: 2,
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
