import 'package:barbershop/features/admin/presentation/pages/admin_home_page.dart';
import 'package:barbershop/main.dart';
import 'package:barbershop/shared/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class GDPRConsentPage extends StatefulWidget {
  const GDPRConsentPage({super.key});

  @override
  State<GDPRConsentPage> createState() => _GDPRConsentPageState();
}

class _GDPRConsentPageState extends State<GDPRConsentPage> {
  bool _isLoading = false;

  void _acceptTerms() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirestoreService().saveUserConsent(user.uid);
        if (mounted) {
          if (user.email == 'admin@barber.com') {
            // Basic admin check
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const AdminHomePage()),
            );
          } else {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const MainScreen()),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar consentimento: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const Icon(Icons.privacy_tip_outlined,
                  size: 64, color: Colors.black),
              const Gap(24),
              Text(
                'Proteção de Dados\n(RGPD)',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
              ),
              const Gap(32),
              Expanded(
                flex: 3,
                child: SingleChildScrollView(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Política de Privacidade e Tratamento de Dados',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Gap(12),
                        Text(
                          'Em conformidade com o Regulamento Geral sobre a Proteção de Dados (Regulamento (UE) 2016/679), informamos que:\n\n'
                          '1. Coleta e Finalidade:\n'
                          'Coletamos seu Nome, Telefone e E-mail exclusivamente para:\n'
                          '• Gestão de agendamentos e reservas;\n'
                          '• Envio de lembretes e notificações sobre serviços;\n'
                          '• Identificação única do cliente no sistema.\n\n'
                          '2. Armazenamento:\n'
                          'Seus dados são armazenados de forma segura em servidores protegidos (Google Cloud Platform).\n\n'
                          '3. Seus Direitos:\n'
                          'Você pode solicitar a consulta, retificação ou exclusão dos seus dados a qualquer momento, entrando em contato diretamente com a barbearia.\n\n'
                          'Ao clicar em "Aceitar e Continuar", você declara estar ciente e de acordo com o tratamento dos seus dados pessoais para as finalidades descritas acima.',
                          style: TextStyle(height: 1.5, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const Gap(24),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _acceptTerms,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Aceitar e Continuar',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const Gap(16),
              if (!_isLoading)
                TextButton(
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    // Will return to login via Stream logic
                  },
                  child: const Text('Recusar e Sair',
                      style: TextStyle(color: Colors.red)),
                ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
