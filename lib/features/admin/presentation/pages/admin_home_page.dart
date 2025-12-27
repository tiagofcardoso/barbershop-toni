import 'package:barbershop/features/admin/presentation/pages/admin_appointments_page.dart';
import 'package:barbershop/features/admin/presentation/pages/admin_services_page.dart';
import 'package:barbershop/features/admin/presentation/pages/admin_products_page.dart';
import 'package:barbershop/features/admin/presentation/pages/admin_settings_page.dart';
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
        title: const Text('Painel Administrativo'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_upload),
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
            icon: const Icon(Icons.logout),
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
                    childAspectRatio: 1.1,
                  ),
                  children: [
                    _buildMenuCard(
                        icon: Icons.calendar_month_rounded,
                        title: 'Agendamentos',
                        color: Colors.blue,
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const AdminAppointmentsPage()));
                        }),
                    _buildMenuCard(
                        icon: Icons.content_cut_rounded,
                        title: 'Serviços',
                        color: Colors.purple,
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const AdminServicesPage()));
                        }),
                    _buildMenuCard(
                        icon: Icons.inventory_2_rounded,
                        title: 'Produtos',
                        color: Colors.green,
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const AdminProductsPage()));
                        }),
                    _buildMenuCard(
                        icon: Icons.store_rounded,
                        title: 'Configurações',
                        color: Colors.grey,
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const AdminSettingsPage()));
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
      {required IconData icon,
      required String title,
      required Color color,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ]),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const Gap(12),
            Text(title,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
