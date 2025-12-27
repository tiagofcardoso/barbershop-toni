import 'package:barbershop/shared/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class AdminSettingsPage extends StatefulWidget {
  const AdminSettingsPage({super.key});

  @override
  State<AdminSettingsPage> createState() => _AdminSettingsPageState();
}

class _AdminSettingsPageState extends State<AdminSettingsPage> {
  final _openController = TextEditingController(text: '09:00');
  final _closeController = TextEditingController(text: '19:00');
  final _saturdayOpenController = TextEditingController(text: '09:00');
  final _saturdayCloseController = TextEditingController(text: '18:00');

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    final settings = await FirestoreService().getBusinessSettings();
    if (settings != null) {
      _openController.text = settings['weekdayOpen'] ?? '09:00';
      _closeController.text = settings['weekdayClose'] ?? '19:00';
      _saturdayOpenController.text = settings['saturdayOpen'] ?? '09:00';
      _saturdayCloseController.text = settings['saturdayClose'] ?? '18:00';
    }
    setState(() => _isLoading = false);
  }

  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);
    await FirestoreService().saveBusinessSettings({
      'weekdayOpen': _openController.text,
      'weekdayClose': _closeController.text,
      'saturdayOpen': _saturdayOpenController.text,
      'saturdayClose': _saturdayCloseController.text,
    });
    setState(() => _isLoading = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configurações salvas com sucesso!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações da Barbearia'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Horário de Funcionamento (Semana)',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      const Gap(12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _openController,
                              decoration: const InputDecoration(
                                  labelText: 'Abertura (HH:mm)'),
                            ),
                          ),
                          const Gap(16),
                          Expanded(
                            child: TextFormField(
                              controller: _closeController,
                              decoration: const InputDecoration(
                                  labelText: 'Fechamento (HH:mm)'),
                            ),
                          ),
                        ],
                      ),
                      const Gap(24),
                      const Text('Horário de Funcionamento (Sábado)',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      const Gap(12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _saturdayOpenController,
                              decoration: const InputDecoration(
                                  labelText: 'Abertura (HH:mm)'),
                            ),
                          ),
                          const Gap(16),
                          Expanded(
                            child: TextFormField(
                              controller: _saturdayCloseController,
                              decoration: const InputDecoration(
                                  labelText: 'Fechamento (HH:mm)'),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _saveSettings,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Salvar Alterações'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
