import 'package:barbershop/shared/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

class MyReservationsPage extends StatelessWidget {
  const MyReservationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null)
      return const Scaffold(body: Center(child: Text('Faça login')));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Reservas'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: FirestoreService().getMyReservationsStream(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final reservations = snapshot.data ?? [];

          if (reservations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_bag_outlined,
                      size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Você não tem reservas ativas.',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reservations.length,
            itemBuilder: (context, index) {
              final reservation = reservations[index];
              final items = reservation['items'] as List;
              final status = reservation['status'];
              final total = reservation['totalPrice'];
              final date = (reservation['timestamp'] as dynamic)?.toDate();

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            date != null
                                ? DateFormat('dd/MM/yyyy HH:mm').format(date)
                                : 'Data pendente',
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 12),
                          ),
                          _buildStatusChip(status),
                        ],
                      ),
                      const Divider(),
                      ...items.map((item) {
                        final imageUrl = item['imageUrl'] as String?;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              if (imageUrl != null && imageUrl.isNotEmpty)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: Image.network(
                                    imageUrl,
                                    width: 40,
                                    height: 40,
                                    fit: BoxFit.cover,
                                    errorBuilder: (c, o, s) => Container(
                                        width: 40,
                                        height: 40,
                                        color: Colors.grey[200],
                                        child: const Icon(Icons.broken_image,
                                            size: 20)),
                                  ),
                                )
                              else
                                Container(
                                  width: 40,
                                  height: 40,
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.image,
                                      size: 20, color: Colors.grey),
                                ),
                              const Gap(12),
                              Text('${item['quantity']}x',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              const Gap(8),
                              Expanded(child: Text(item['productName'])),
                              Text('€ ${item['price']}'),
                            ],
                          ),
                        );
                      }),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total:',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('€ $total',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                      if (status == 'pending') ...[
                        const Gap(8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () async {
                              await FirestoreService()
                                  .cancelReservation(reservation['id']);
                            },
                            style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red),
                            child: const Text('Cancelar Reserva'),
                          ),
                        )
                      ]
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

  Widget _buildStatusChip(String status) {
    Color color;
    String label;
    switch (status) {
      case 'completed':
        color = Colors.green;
        label = 'Concluído';
        break;
      case 'cancelled':
        color = Colors.red;
        label = 'Cancelado';
        break;
      default:
        color = Colors.orange;
        label = 'Pendente';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }
}
