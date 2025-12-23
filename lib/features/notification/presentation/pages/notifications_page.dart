import 'package:barbershop/features/auth/data/auth_service.dart';
import 'package:barbershop/shared/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = AuthService().currentUser?.uid;

    if (userId == null) {
      return const Scaffold(
          body: Center(child: Text("Faça login para ver notificações")));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificações'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
          stream: FirestoreService().getUserNotificationsStream(userId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final notifications = snapshot.data ?? [];

            if (notifications.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.notifications_off_outlined,
                        size: 64, color: Colors.grey[300]),
                    const Gap(16),
                    Text(
                      'Sem notificações novas',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              separatorBuilder: (context, index) => const Gap(12),
              itemBuilder: (context, index) {
                final notification = notifications[index];
                final String id = notification['id'];
                final String title = notification['title'];
                final String message = notification['message'];
                final bool read = notification['read'] ?? false;
                final timestamp =
                    (notification['timestamp'] as dynamic)?.toDate();

                // Mark as read when seen (simplistic approach)
                if (!read) {
                  FirestoreService().markNotificationAsRead(id);
                }

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: read ? Colors.white : Colors.blue.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: read
                          ? Colors.grey[200]!
                          : Colors.blue.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.notifications,
                            color: Colors.blue, size: 20),
                      ),
                      const Gap(16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  title,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: read
                                        ? Colors.black87
                                        : Colors.blue[900],
                                  ),
                                ),
                                if (timestamp != null)
                                  Text(
                                    DateFormat('dd/MM HH:mm').format(timestamp),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                              ],
                            ),
                            const Gap(4),
                            Text(
                              message,
                              style: TextStyle(
                                color: Colors.grey[700],
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          }),
    );
  }
}
