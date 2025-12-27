import 'package:barbershop/shared/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

class AdminAppointmentsPage extends StatefulWidget {
  const AdminAppointmentsPage({super.key});

  @override
  State<AdminAppointmentsPage> createState() => _AdminAppointmentsPageState();
}

class _AdminAppointmentsPageState extends State<AdminAppointmentsPage> {
  void _updateStatus(String id, String newStatus, String customerId) async {
    await FirestoreService().updateAppointment(id, {'status': newStatus});
    // Send Notification
    await FirestoreService().addNotification(
      customerId,
      'Agendamento $newStatus',
      'Seu agendamento foi $newStatus pelo barbearia.',
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status atualizado para $newStatus')),
      );
    }
  }

  Future<void> _rescheduleAppointment(
      String id, DateTime currentDateTime, String customerId) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: currentDateTime,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('pt', 'BR'),
    );

    if (pickedDate != null) {
      if (!mounted) return;
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(currentDateTime),
      );

      if (pickedTime != null) {
        final newDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        await FirestoreService().updateAppointment(id, {
          'dateTime': newDateTime,
          'status': 'Confirmado',
        });

        // Send Notification
        await FirestoreService().addNotification(
          customerId,
          'Agendamento Remarcado',
          'Novo horário: ${DateFormat('dd/MM HH:mm').format(newDateTime)}',
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Agendamento remarcado com sucesso!')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciar Agendamentos'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: FirestoreService().getAppointmentsStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final appointments = snapshot.data ?? [];

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: appointments.length,
                separatorBuilder: (context, index) => const Gap(12),
                itemBuilder: (context, index) {
                  final appointment = appointments[index];
                  final String id = appointment['id'];
                  final DateTime date =
                      (appointment['dateTime'] as dynamic).toDate();
                  final String customerId = appointment['customerId'] ?? '';
                  final String customerName = appointment['customerName'];
                  final String serviceName = appointment['serviceName'];
                  final String status = appointment['status'];

                  return Dismissible(
                    key: Key(id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      color: Colors.red,
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    confirmDismiss: (direction) async {
                      return await showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text("Confirmar exclusão?"),
                            content: const Text(
                                "Isso apagará o agendamento permanentemente."),
                            actions: <Widget>[
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                                child: const Text("Cancelar"),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                                child: const Text("Excluir",
                                    style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    onDismissed: (direction) async {
                      await FirestoreService().deleteAppointment(id);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Agendamento removido')),
                        );
                      }
                    },
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: Colors.grey[200],
                                  child: Text(customerName.isNotEmpty
                                      ? customerName[0]
                                      : '?'),
                                ),
                                const Gap(12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        customerName,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16),
                                      ),
                                      Text(
                                        '$serviceName - ${DateFormat('dd/MM HH:mm').format(date)}',
                                        style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                                // Reschedule Button
                                IconButton(
                                  icon: const Icon(Icons.edit_calendar,
                                      color: Colors.blue),
                                  onPressed: () => _rescheduleAppointment(
                                      id, date, customerId),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(status)
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    status,
                                    style: TextStyle(
                                      color: _getStatusColor(status),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            // Actions hidden for simple view or added here?
                            // Let's keep existing actions
                            const Gap(12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (status != 'Cancelado')
                                  TextButton(
                                    onPressed: () => _updateStatus(
                                        id, 'Cancelado', customerId),
                                    child: const Text('Cancelar',
                                        style: TextStyle(color: Colors.red)),
                                  ),
                                if (status != 'Confirmado')
                                  ElevatedButton(
                                    onPressed: () => _updateStatus(
                                        id, 'Confirmado', customerId),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 0),
                                    ),
                                    child: const Text('Confirmar'),
                                  ),
                              ],
                            )
                          ],
                        ),
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

  Color _getStatusColor(String status) {
    if (status == 'Confirmado') return Colors.green;
    if (status == 'Cancelado') return Colors.red;
    return Colors.orange;
  }
}
