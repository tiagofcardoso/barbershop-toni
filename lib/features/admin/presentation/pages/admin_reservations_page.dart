import 'package:barbershop/shared/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

class AdminReservationsPage extends StatelessWidget {
  const AdminReservationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Gerenciar Reservas'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Pendentes'),
              Tab(text: 'Concluídas'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _ReservationList(status: 'pending'),
            _ReservationList(status: 'completed'),
          ],
        ),
      ),
    );
  }
}

class _ReservationList extends StatelessWidget {
  final String status;

  const _ReservationList({required this.status});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: FirestoreService().getReservationsStream(status: status),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final reservations = snapshot.data ?? [];

        if (reservations.isEmpty) {
          return Center(
            child: Text(
              'Nenhuma reserva ${status == 'pending' ? 'pendente' : 'concluída'}.',
              style: TextStyle(color: Colors.grey[600]),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: reservations.length,
          itemBuilder: (context, index) {
            final reservation = reservations[index];
            final items = reservation['items'] as List;
            final userName = reservation['userName'] ?? 'Desconhecido';
            final total = reservation['totalPrice'];
            final date = (reservation['timestamp'] as dynamic)?.toDate();

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: ExpansionTile(
                title: Text('$userName - € $total'),
                subtitle: Text(date != null
                    ? DateFormat('dd/MM/yyyy HH:mm').format(date)
                    : 'Data desconhecida'),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Itens:',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const Gap(8),
                        ...items.map((item) => Row(
                              children: [
                                Text('${item['quantity']}x ',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                Expanded(child: Text(item['productName'])),
                                Text('€ ${item['price']}'),
                              ],
                            )),
                        const Gap(16),
                        if (status == 'pending')
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () =>
                                  _confirmCompletion(context, reservation),
                              icon: const Icon(Icons.check_circle_outline),
                              label:
                                  const Text('Concluir Venda e Baixar Estoque'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        if (status == 'pending') ...[
                          const Gap(8),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                await FirestoreService()
                                    .cancelReservation(reservation['id']);
                              },
                              icon: const Icon(Icons.cancel_outlined),
                              label: const Text('Cancelar Reserva'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                            ),
                          ),
                        ]
                      ],
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _confirmCompletion(
      BuildContext context, Map<String, dynamic> reservation) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Concluir Venda?'),
        content: const Text(
            'Isso marcará a reserva como concluída e descontará os itens do estoque automaticamente.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                // Must pass items for stock deduction
                await FirestoreService().completeReservation(
                    reservation['id'], reservation['items']);
                if (ctx.mounted) Navigator.pop(ctx);
              } catch (e) {
                debugPrint('Error completing reservation: $e');
                if (ctx.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Erro: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }
}
