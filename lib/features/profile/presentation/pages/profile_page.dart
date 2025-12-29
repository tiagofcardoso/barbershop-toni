import 'package:barbershop/features/auth/presentation/pages/login_page.dart';
import 'package:barbershop/features/auth/data/auth_service.dart';
import 'package:barbershop/features/profile/presentation/pages/profile_edit_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:barbershop/shared/utils/pwa_utils.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Meu Perfil'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // User Header
            Builder(
              builder: (context) {
                final user = AuthService().currentUser;
                return Center(
                  child: Column(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          backgroundColor: Colors.black,
                          backgroundImage: user?.photoURL != null
                              ? NetworkImage(user!.photoURL!)
                              : null,
                          child: user?.photoURL == null
                              ? const Icon(Icons.person,
                                  size: 50, color: Colors.white)
                              : null,
                        ),
                      ),
                      const Gap(16),
                      Text(
                        user?.displayName ?? 'Cliente',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const Gap(4),
                      Text(
                        user?.email ?? '',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const Gap(32),

            // Menu Options
            Container(
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
                  _buildMenuItem(
                    context,
                    icon: Icons.person_outline,
                    title: 'Meus Dados',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ProfileEditPage()),
                      );
                    },
                  ),
                  // const Divider(height: 1),
                  // _buildMenuItem(
                  //   context,
                  //   icon: Icons.payment_outlined,
                  //   title: 'Formas de Pagamento',
                  //   onTap: () {},
                  // ),
                  // const Divider(height: 1),
                  // _buildMenuItem(
                  //   context,
                  //   icon: Icons.settings_outlined,
                  //   title: 'Configurações',
                  //   onTap: () {},
                  // ),
                  const Divider(height: 1),
                  _buildMenuItem(
                    context,
                    icon: Icons.download_rounded,
                    title: 'Instalar App',
                    onTap: () => _showInstallInstructions(context),
                  ),
                  const Divider(height: 1),
                  // _buildMenuItem(
                  //   context,
                  //   icon: Icons.help_outline,
                  //   title: 'Ajuda (WhatsApp)',
                  //   onTap: _openWhatsApp,
                  // ),
                ],
              ),
            ),

            const Gap(32),

            // Logout Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton(
                onPressed: () {
                  // Navigate back to Login Page (Remove all previous routes)
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                    (route) => false,
                  );
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  foregroundColor: Colors.red,
                ),
                child: const Text(
                  'Sair da Conta',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const Gap(32),
            Text(
              'Versão 1.0.0',
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.black87, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios_rounded,
          size: 16, color: Colors.grey),
      onTap: onTap,
    );
  }

  Future<void> _openWhatsApp() async {
    // Start with the standard API URL which is more reliable across platforms
    final Uri whatsappUrl =
        Uri.parse('https://api.whatsapp.com/send?phone=351914216075');
    try {
      if (kIsWeb) {
        if (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS) {
          // Web on Mobile (PWA):
          // Try to launch external app first (to trigger native WhatsApp)
          // If that fails, fallback to platformDefault which should handle the redirect
          if (!await launchUrl(whatsappUrl,
              mode: LaunchMode.externalApplication)) {
            await launchUrl(whatsappUrl, mode: LaunchMode.platformDefault);
          }
        } else {
          // Web on Desktop:
          // Open in new tab/window. This allows the browser to show the WhatsApp Web interstitial
          await launchUrl(whatsappUrl, mode: LaunchMode.platformDefault);
        }
      } else {
        // Native Mobile App (APK/IPA):
        // Force external application
        if (!await launchUrl(whatsappUrl,
            mode: LaunchMode.externalApplication)) {
          await launchUrl(whatsappUrl);
        }
      }
    } catch (e) {
      debugPrint('Could not launch WhatsApp: $e');
    }
  }

  void _showInstallInstructions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Instalar Aplicativo',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Gap(16),
              _buildInstallStep(
                icon: Icons.apple,
                title: 'iPhone (iOS)',
                subtitle:
                    "1. Toque no botão Compartilhar (quadrado com seta)\n2. Role para baixo e escolha 'Adicionar à Tela de Início'",
              ),
              const Gap(16),
              _buildInstallStep(
                icon: Icons.android,
                title: 'Android',
                subtitle:
                    "1. Toque no menu do navegador (três pontinhos)\n2. Escolha 'Instalar aplicativo' ou 'Adicionar à tela inicial'",
              ),
              if (defaultTargetPlatform != TargetPlatform.android &&
                  defaultTargetPlatform != TargetPlatform.iOS) ...[
                const Gap(16),
                _buildInstallStep(
                  icon: Icons.desktop_windows,
                  title: 'PC / Mac',
                  subtitle:
                      "1. Olhe para a barra de endereço do navegador\n2. Clique no ícone de instalar (uma tela com seta para baixo)",
                ),
              ],
              const Gap(24),
              if (kIsWeb && defaultTargetPlatform == TargetPlatform.android)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        safeTriggerInstall();
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Instalar Agora',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Entendi',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInstallStep(
      {required IconData icon,
      required String title,
      required String subtitle}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 28),
        const Gap(16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              const Gap(4),
              Text(subtitle,
                  style: TextStyle(color: Colors.grey[700], height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }
}
