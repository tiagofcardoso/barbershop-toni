import 'package:barbershop/features/auth/data/auth_service.dart';
import 'package:barbershop/shared/services/firestore_service.dart';
import 'package:barbershop/features/admin/presentation/pages/admin_home_page.dart';
import 'package:barbershop/main.dart'; // Circular dependency if not careful, but okay for navigation for now.
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();

  String _fullPhoneNumber = ''; // Store complete number with country code

  bool _isLoading = false;
  bool _isCodeSent = false;
  String? _verificationId;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _verifyPhone() async {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, digite seu nome')),
      );
      return;
    }

    if (_fullPhoneNumber.isEmpty || _fullPhoneNumber.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, digite um telefone válido')),
      );
      return;
    }

    /* if (phone.isEmpty || phone.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Por favor, digite um telefone válido (ex: +5511999999999)')),
      );
      return;
    } */

    setState(() => _isLoading = true);

    await AuthService().verifyPhoneNumber(
      phoneNumber: _fullPhoneNumber,
      onCodeSent: (verificationId) {
        if (mounted) {
          setState(() {
            _verificationId = verificationId;
            _isCodeSent = true;
            _isLoading = false;
          });
        }
      },
      onError: (message) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro: $message')),
          );
        }
      },
    );
  }

  void _signInWithOtp() async {
    final otp = _otpController.text.trim();
    if (_verificationId == null || otp.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final userCredential =
          await AuthService().signInWithOtp(_verificationId!, otp);

      if (userCredential != null && userCredential.user != null) {
        // Update user name in Firebase Auth
        await userCredential.user!
            .updateDisplayName(_nameController.text.trim());
        await userCredential.user!.reload(); // Reload to apply changes locally

        // Save to Firestore
        await FirestoreService().saveUser(FirebaseAuth
            .instance.currentUser!); // Refetch current user to get updated name

        if (mounted) {
          final authService = AuthService();
          if (authService.isAdmin) {
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
          SnackBar(content: Text('Erro ao validar código: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool _isAdminLogin = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  void _signInAdmin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor, preencha todos os campos')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Direct Firebase Auth for Admin
      await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' ||
          e.code == 'invalid-credential' ||
          e.code == 'wrong-password') {
        // Dev helper: Create if doesn't exist (Only for admin specific email)
        if (email == 'admin@barber.com') {
          try {
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
                email: email, password: password);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Admin criado com sucesso! Entrando...')));
            }
          } catch (createError) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erro ao criar admin: $createError')));
            }
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Usuário ou senha incorretos.')));
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Erro: ${e.message}')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erro de login: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final userCredential = await AuthService().signInWithGoogle();

      if (userCredential != null && userCredential.user != null) {
        // Save to Firestore (Creates profile if not exists)
        await FirestoreService().saveUser(userCredential.user!);

        if (mounted) {
          // Admin check usually by email, but for Google login we assume Client for now unless specific logic needed
          if (userCredential.user!.email == 'admin@barber.com') {
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
          SnackBar(content: Text('Erro ao entrar com Google: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool _showInitialScreen = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: !_showInitialScreen
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.black),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  // If in Admin mode, go back to Phone mode, else go to Initial Screen
                  if (_isAdminLogin) {
                    setState(() => _isAdminLogin = false);
                  } else {
                    setState(() => _showInitialScreen = true);
                  }
                },
              ),
            )
          : null,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight -
                          (_showInitialScreen ? 0 : 80), // Adjust for AppBar
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_showInitialScreen) const Spacer(),
                          // Logo
                          Center(
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                image: const DecorationImage(
                                  image: AssetImage('assets/icon/app_icon.png'),
                                  fit: BoxFit.contain,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Gap(32),
                          Text(
                            'Antonio\nBarber Shop',
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                  height: 1.2,
                                ),
                          ),
                          const Gap(48),

                          if (_showInitialScreen) ...[
                            // --- INITIAL SCREEN (Google Only) ---
                            SizedBox(
                              height: 50,
                              child: OutlinedButton.icon(
                                onPressed:
                                    _isLoading ? null : _signInWithGoogle,
                                icon: Image.network(
                                  'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/1200px-Google_%22G%22_logo.svg.png',
                                  height: 24,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.g_mobiledata,
                                          color: Colors.blue, size: 30),
                                ), // Using Network PNG for compatibility
                                label: const Text(
                                  'Continuar com Google',
                                  style: TextStyle(
                                    color: Colors.black87,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  side: const BorderSide(color: Colors.grey),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        24), // Google style pill shape
                                  ),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                            const Gap(24),
                            TextButton(
                              onPressed: () =>
                                  setState(() => _showInitialScreen = false),
                              child: Text('Login com telefone / Admin',
                                  style: TextStyle(color: Colors.grey[600])),
                            ),
                            const Spacer(),
                          ] else ...[
                            // --- FORM SCREENS (Phone or Admin) ---
                            if (_isAdminLogin) ...[
                              // Admin Login Form
                              const Text('Acesso Administrativo',
                                  textAlign: TextAlign.center,
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              const Gap(24),
                              TextField(
                                controller: _emailController,
                                decoration: InputDecoration(
                                  labelText: 'E-mail',
                                  prefixIcon: const Icon(Icons.email_outlined),
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                              const Gap(16),
                              TextField(
                                controller: _passwordController,
                                decoration: InputDecoration(
                                  labelText: 'Senha',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                                obscureText: true,
                              ),
                              const Gap(24),
                              SizedBox(
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _signInAdmin,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.black,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: _isLoading
                                      ? const CircularProgressIndicator(
                                          color: Colors.white)
                                      : const Text('Entrar como Admin',
                                          style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ] else if (!_isCodeSent) ...[
                              // Step 1: Name and Phone Input
                              TextField(
                                controller: _nameController,
                                decoration: InputDecoration(
                                  labelText: 'Seu Nome',
                                  prefixIcon: const Icon(Icons.person_outline),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                              const Gap(16),
                              IntlPhoneField(
                                controller: _phoneController,
                                decoration: InputDecoration(
                                  labelText: 'Telefone',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                initialCountryCode: 'PT',
                                languageCode: 'pt',
                                onChanged: (phone) {
                                  _fullPhoneNumber = phone.completeNumber;
                                },
                              ),
                              const Gap(24),
                              SizedBox(
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: _isLoading
                                      ? null
                                      : () {
                                          _verifyPhone();
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.black,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: _isLoading
                                      ? const CircularProgressIndicator(
                                          color: Colors.white)
                                      : const Text(
                                          'Receber Código',
                                          style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold),
                                        ),
                                ),
                              ),
                              const Gap(12),
                              TextButton(
                                onPressed: () =>
                                    setState(() => _isAdminLogin = true),
                                child: const Text('Sou Admin'),
                              ),
                            ] else ...[
                              // Step 2: OTP Input
                              Text(
                                'Enviamos um código para ${_phoneController.text}',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              const Gap(24),
                              TextField(
                                controller: _otpController,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                maxLength: 6,
                                style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 8),
                                decoration: InputDecoration(
                                  counterText: '',
                                  hintText: '000000',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                              const Gap(24),
                              SizedBox(
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _signInWithOtp,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.black,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: _isLoading
                                      ? const CircularProgressIndicator(
                                          color: Colors.white)
                                      : const Text(
                                          'Entrar',
                                          style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold),
                                        ),
                                ),
                              ),
                              TextButton(
                                onPressed: () =>
                                    setState(() => _isCodeSent = false),
                                child: const Text('Alterar número'),
                              ),
                            ],
                            const Spacer(),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
