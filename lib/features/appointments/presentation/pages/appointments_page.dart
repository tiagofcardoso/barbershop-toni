import 'package:barbershop/features/auth/data/auth_service.dart';
import 'package:barbershop/shared/services/firestore_service.dart';
import 'package:barbershop/features/home/data/mock_data.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

class AppointmentsPage extends StatelessWidget {
  const AppointmentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Filter only my appointments (Tiago Silva)
    final appointments = MockData.appointments
        .where((a) => a.customerName == 'Tiago Silva')
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Agendamentos'),
        centerTitle: true,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: FirestoreService()
            .getMyAppointmentsStream(AuthService().currentUser?.uid ?? ''),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red),
                  ),
                  child: SelectableText(
                    // Allow copying the link
                    'Erro ao carregar agendamentos:\n${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final appointments = snapshot.data ?? [];

          if (appointments.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_today_outlined,
                      size: 64, color: Colors.grey[400]),
                  const Gap(16),
                  Text(
                    'Nenhum agendamento',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: appointments.length,
            separatorBuilder: (context, index) => const Gap(16),
            itemBuilder: (context, index) {
              final appointment = appointments[index];
              // Firestore Timestamp needs conversion usually, but our service mapped it?
              // Wait, if it's Timestamp in Firestore, .data() returns Timestamp.
              final dateTimeRaw = appointment['dateTime'];
              final DateTime date =
                  (dateTimeRaw as dynamic).toDate(); // Handle Timestamp
              final String serviceName = appointment['serviceName'];
              final double price =
                  ((appointment['servicePrice'] ?? 0) as num).toDouble();
              final String status = appointment['status'];

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Date Box
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Text(
                                DateFormat('d').format(date),
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                              ),
                              Text(
                                DateFormat('MMM', 'pt_BR')
                                    .format(date)
                                    .toUpperCase(),
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        const Gap(16),
                        // Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                DateFormat('HH:mm').format(date),
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                      color: Colors.blue[700],
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const Gap(4),
                              Text(
                                serviceName,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const Gap(4),
                              Text(
                                '€ ${price.toStringAsFixed(2)}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                              ),
                            ],
                          ),
                        ),
                        // Status Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: status == 'Confirmado'
                                ? Colors.green[50]
                                : Colors.orange[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: status == 'Confirmado'
                                  ? Colors.green[700]
                                  : Colors.orange[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Gap(16),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (status != 'Cancelado')
                          TextButton(
                            onPressed: () async {
                              await FirestoreService()
                                  .deleteAppointment(appointment['id']);
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                            child: const Text('Cancelar Agendamento'),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
