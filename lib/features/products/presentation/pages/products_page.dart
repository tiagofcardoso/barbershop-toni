import 'package:barbershop/features/products/data/model/product_model.dart';
import 'package:barbershop/features/products/presentation/widgets/product_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ProductsPage extends StatelessWidget {
  const ProductsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Produtos'),
        centerTitle: false,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('products').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Erro ao carregar produtos'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2_outlined,
                      size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhum produto disponível.',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75, // Adjust based on card height
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              // Add ID to map for conversion
              data['id'] = docs[index].id;

              final product = ProductModel.fromMap(data);

              return ProductCard(
                product: product,
                onTap: () {
                  // TODO: Show Product Details / Schedule Purchase Logic matches Appointment
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Selecionado: ${product.name}')),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
