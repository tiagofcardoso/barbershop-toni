import 'package:barbershop/features/booking/presentation/pages/booking_page.dart';
import 'package:barbershop/features/home/data/mock_data.dart';
import 'package:barbershop/shared/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class SelectProfessionalPage extends StatelessWidget {
  final ServiceModel service;

  const SelectProfessionalPage({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escolha o Profissional',
            style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: FirestoreService().getProfessionalsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final pros = snapshot.data ?? [];

          if (pros.isEmpty) {
            // Fallback if no professionals: go straight to booking (or show error/default)
            // For now, let's show a "Default Team" option or similar logic.
            // But better to prompt admin to add proper ones.
            return const Center(
              child: Text(
                'Nenhum profissional disponível no momento.',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: GridView.builder(
                padding: const EdgeInsets.all(24),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // 2 columns (Side by side as requested)
                  crossAxisSpacing: 24,
                  mainAxisSpacing: 24,
                  childAspectRatio: 0.8,
                ),
                itemCount: pros.length,
                itemBuilder: (context, index) {
                  final pro = pros[index];
                  return _buildProfessionalCard(context, pro);
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfessionalCard(
      BuildContext context, Map<String, dynamic> pro) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BookingPage(
              service: service,
              professionalId: pro['id'],
              professionalName: pro['name'],
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                child: (pro['imageUrl'] != null && pro['imageUrl'].isNotEmpty)
                    ? Image.network(
                        pro['imageUrl'],
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.person,
                              size: 50, color: Colors.grey),
                        ),
                      )
                    : Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.person,
                            size: 60, color: Colors.grey),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    pro['name'] ?? 'Profissional',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (pro['bio'] != null && pro['bio'].isNotEmpty) ...[
                    const Gap(8),
                    Text(
                      pro['bio'],
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
