import 'package:barbershop/features/admin/presentation/pages/admin_appointments_page.dart';
import 'package:barbershop/features/admin/presentation/pages/admin_services_page.dart';
import 'package:barbershop/features/admin/presentation/pages/admin_products_page.dart';
import 'package:barbershop/features/admin/presentation/pages/admin_reservations_page.dart';
import 'package:barbershop/features/admin/presentation/pages/admin_settings_page.dart';
import 'package:barbershop/features/admin/presentation/pages/admin_professionals_page.dart';
import 'package:barbershop/features/auth/presentation/pages/login_page.dart';
import 'package:barbershop/features/home/data/mock_data.dart';
import 'package:barbershop/shared/services/firestore_service.dart';
import 'package:barbershop/features/auth/data/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Painel Administrativo',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        actionsIconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_upload, color: Colors.white),
            tooltip: 'Migrar Serviços',
            onPressed: () async {
              await FirestoreService().seedServices(MockData.services);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Serviços migrados com sucesso!')));
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await AuthService().signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Stats Section (Keep this helpful view)
                StreamBuilder<List<Map<String, dynamic>>>(
                    stream: FirestoreService().getAppointmentsStream(),
                    builder: (context, snapshot) {
                      final appointments = snapshot.data ?? [];

                      final now = DateTime.now();
                      final todayCount = appointments.where((a) {
                        final dt = (a['dateTime'] as dynamic).toDate();
                        return dt.year == now.year &&
                            dt.month == now.month &&
                            dt.day == now.day;
                      }).length;

                      final pendingCount = appointments
                          .where((a) => a['status'] == 'Pendente')
                          .length;

                      return Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              )
                            ]),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStat(
                                'Hoje', todayCount.toString(), Colors.blue),
                            _buildStat('Pendentes', pendingCount.toString(),
                                Colors.orange),
                            _buildStat('Total', appointments.length.toString(),
                                Colors.white),
                          ],
                        ),
                      );
                    }),

                const Gap(24),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Menu Principal',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                const Gap(16),

                // Grid Menu
                GridView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.9, // Taller cards for images
                  ),
                  children: [
                    _buildMenuCard(
                        imagePath: 'assets/images/admin_calendar.png',
                        title: 'Agendamentos',
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const AdminAppointmentsPage()));
                        }),
                    _buildMenuCard(
                        imagePath: 'assets/images/admin_services.png',
                        title: 'Serviços',
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const AdminServicesPage()));
                        }),
                    _buildMenuCard(
                        imagePath: 'assets/images/admin_products.png',
                        title: 'Produtos',
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const AdminProductsPage()));
                        }),
                    _buildMenuCard(
                        imagePath: 'assets/images/admin_reservations.png',
                        title: 'Reservas',
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const AdminReservationsPage()));
                        }),
                    _buildMenuCard(
                        imagePath: 'assets/images/admin_settings.png',
                        title: 'Configurações',
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const AdminSettingsPage()));
                        }),
                    _buildMenuCard(
                        imagePath: 'assets/images/admin_team.png',
                        title: 'Equipe',
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const AdminProfessionalsPage()));
                        }),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                color: color, fontSize: 24, fontWeight: FontWeight.bold)),
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  Widget _buildMenuCard(
      {required String imagePath,
      required String title,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // 1. Full Background Image
              Positioned.fill(
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[200],
                      child: const Center(
                          child: Icon(Icons.broken_image, color: Colors.grey)),
                    );
                  },
                ),
              ),

              // 2. Gradient Overlay for Text Readability
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.0),
                        Colors.black.withOpacity(0.6),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),

              // 3. Title at Bottom
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Colors.black45,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            )
                          ]),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: Colors.white70,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
