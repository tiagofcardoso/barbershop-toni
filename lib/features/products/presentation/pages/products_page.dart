import 'package:barbershop/features/auth/data/auth_service.dart';
import 'package:barbershop/features/products/data/model/product_model.dart';
import 'package:barbershop/features/products/presentation/pages/my_reservations_page.dart';
import 'package:barbershop/features/products/presentation/widgets/product_card.dart';
import 'package:barbershop/shared/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class ProductsPage extends StatelessWidget {
  const ProductsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Produtos'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_bag_outlined),
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const MyReservationsPage()));
            },
          )
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: FirestoreService().getProductsStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Erro ao carregar produtos'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final products = snapshot.data ?? [];

          if (products.isEmpty) {
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
              childAspectRatio: 0.75,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final data = products[index];
              final product = ProductModel.fromMap(data);

              return ProductCard(
                product: product,
                onTap: () => _showReservationDialog(context, product),
              );
            },
          );
        },
      ),
    );
  }

  void _showReservationDialog(BuildContext context, ProductModel product) {
    if (product.stock < 1) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Produto esgotado!')));
      return;
    }

    int quantity = 1;
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Faça login para reservar.')));
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Reservar ${product.name}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Preço Unitário: € ${product.price}'),
                const Gap(16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: quantity > 1
                          ? () => setState(() => quantity--)
                          : null,
                    ),
                    Text('$quantity',
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: quantity < product.stock
                          ? () => setState(() => quantity++)
                          : null,
                    ),
                  ],
                ),
                Text(
                    'Total: € ${(product.price * quantity).toStringAsFixed(2)}'),
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar')),
              ElevatedButton(
                onPressed: () async {
                  try {
                    final item = {
                      'productId': product.id,
                      'productName': product.name,
                      'quantity': quantity,
                      'price': product.price,
                      'imageUrl': product.imageUrl
                    };

                    await FirestoreService().createReservation(
                        user.uid,
                        user.displayName ?? 'Cliente',
                        [item],
                        product.price * quantity);

                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Reserva realizada com sucesso!'),
                          backgroundColor: Colors.green));
                    }
                  } catch (e) {
                    debugPrint('Error reserving: $e');
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Erro ao reservar: $e'),
                          backgroundColor: Colors.red));
                    }
                  }
                },
                child: const Text('Confirmar Reserva'),
              ),
            ],
          );
        },
      ),
    );
  }
}
