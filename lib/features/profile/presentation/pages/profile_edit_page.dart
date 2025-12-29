import 'package:barbershop/shared/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({super.key});

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String _completePhoneNumber = '';
  bool _isLoading = false;
  bool _isLoadingData = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _nameController.text = user.displayName ?? '';

      // Load saved phone from Firestore if available
      try {
        final doc = await FirestoreService().getUserData(user.uid);
        if (doc.exists) {
          final data = doc.data();
          if (data != null && data['phoneNumber'] != null) {
            _completePhoneNumber = data['phoneNumber'] ?? '';
          }
        }
      } catch (e) {
        debugPrint('Error loading user data: $e');
      }
    }
    if (mounted) setState(() => _isLoadingData = false);
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          // 1. Update Firebase Auth Profile (Name)
          await user.updateDisplayName(_nameController.text.trim());

          // 2. Update Firestore User Document
          await FirestoreService().saveUser(user); // Updates basic info

          // 3. Specific update for phone number (manual field)
          // We use the FirestoreService directly to update potential extra fields
          // Note: saveUser might overwrite some things, so we update phone specifically after or modify saveUser
          // Let's doing a manual update for phone to be sure
          await FirestoreService().updateUserFields(user.uid, {
            'name': _nameController.text.trim(),
            'phoneNumber': _completePhoneNumber,
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Perfil atualizado com sucesso!')),
            );
            Navigator.pop(context);
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao atualizar: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Editar Meus Dados'),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        titleTextStyle: const TextStyle(
            color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
      ),
      body: _isLoadingData
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Nome Completo',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const Gap(8),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: 'Seu nome',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.person_outline),
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Informe seu nome'
                          : null,
                    ),
                    const Gap(24),
                    const Text('Telefone Celular',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const Gap(8),
                    IntlPhoneField(
                      decoration: InputDecoration(
                        labelText: 'Número de Telefone',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      initialCountryCode: 'PT', // Default Portugal
                      initialValue: _completePhoneNumber.startsWith('+351')
                          ? _completePhoneNumber.substring(4) // Remove +351
                          : _completePhoneNumber,
                      onChanged: (phone) {
                        _completePhoneNumber = phone.completeNumber;
                      },
                    ),
                    const Gap(8),
                    Text(
                      'Usado para contato sobre seus agendamentos.',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    const Gap(40),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Text('Salvar Alterações',
                                style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
