import 'package:barbershop/shared/services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

class AdminCreateAppointmentPage extends StatefulWidget {
  const AdminCreateAppointmentPage({super.key});

  @override
  State<AdminCreateAppointmentPage> createState() =>
      _AdminCreateAppointmentPageState();
}

class _AdminCreateAppointmentPageState
    extends State<AdminCreateAppointmentPage> {
  // Selections
  Map<String, dynamic>? _selectedService;
  Map<String, dynamic>? _selectedProfessional;
  DateTime _selectedDate = DateTime.now();
  String? _selectedTime;

  // Form
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String? _customerPhone;

  // Data helpers
  late List<DateTime> _dates;
  Map<String, dynamic>? _businessSettings;
  bool _isLoadingSettings = true;

  @override
  void initState() {
    super.initState();
    _generateDates();
    _loadSettingsAndDefaults();
  }

  Future<void> _loadSettingsAndDefaults() async {
    _businessSettings = await FirestoreService().getBusinessSettings();
    if (mounted) {
      setState(() {
        _isLoadingSettings = false;
        // Default to first available date
        try {
          _selectedDate = _dates.firstWhere((date) => _isDayAvailable(date));
        } catch (e) {
          if (_dates.isNotEmpty) {
            _selectedDate = _dates.first;
          }
        }
      });
    }
  }

  void _generateDates() {
    _dates = [];
    final now = DateTime.now();
    for (int i = 0; i < 60; i++) {
      _dates.add(now.add(Duration(days: i)));
    }
  }

  bool _isDayAvailable(DateTime date) {
    if (date.weekday == DateTime.sunday || date.weekday == DateTime.monday) {
      return false;
    }
    if (_isHoliday(date)) {
      return false;
    }
    return true;
  }

  bool _isHoliday(DateTime date) {
    final holidays = {
      '1,1': 'Ano Novo',
      '4,25': 'Dia da Liberdade',
      '5,1': 'Dia do Trabalhador',
      '6,10': 'Dia de Portugal',
      '8,15': 'Assunção de Nossa Senhora',
      '10,5': 'Implantação da República',
      '11,1': 'Dia de Todos os Santos',
      '12,1': 'Restauração da Independência',
      '12,8': 'Imaculada Conceição',
      '12,25': 'Natal',
    };
    final key = '${date.month},${date.day}';
    return holidays.containsKey(key);
  }

  // --- Slot Logic (Copied from BookingPage) ---
  TimeOfDay _parseTime(String timeStr) {
    final parts = timeStr.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String _formatTime(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  int _timeToMinutes(TimeOfDay time) {
    return time.hour * 60 + time.minute;
  }

  List<String> _generateCandidateSlots(DateTime date, int durationMinutes) {
    final isSaturday = date.weekday == DateTime.saturday;
    final isWeekday = !isSaturday;

    String openStr = '09:00';
    String closeStr = '19:00';
    String lunchStartStr = '13:00';
    String lunchEndStr = '14:00';

    if (_businessSettings != null) {
      if (isWeekday) {
        openStr = _businessSettings!['weekdayOpen'] ?? '09:00';
        closeStr = _businessSettings!['weekdayClose'] ?? '19:00';
        lunchStartStr = _businessSettings!['weekdayLunchStart'] ?? '13:00';
        lunchEndStr = _businessSettings!['weekdayLunchEnd'] ?? '14:00';
      } else {
        openStr = _businessSettings!['saturdayOpen'] ?? '09:00';
        closeStr = _businessSettings!['saturdayClose'] ?? '18:00';
        lunchStartStr = _businessSettings!['saturdayLunchStart'] ?? '13:00';
        lunchEndStr = _businessSettings!['saturdayLunchEnd'] ?? '14:00';
      }
    } else {
      if (isSaturday) {
        closeStr = '18:00';
      }
    }

    TimeOfDay openTime = _parseTime(openStr);
    TimeOfDay closeTime = _parseTime(closeStr);
    TimeOfDay lunchStart = _parseTime(lunchStartStr);
    TimeOfDay lunchEnd = _parseTime(lunchEndStr);

    List<String> slots = [];

    int currentMinutes = _timeToMinutes(openTime);
    int closeMinutes = _timeToMinutes(closeTime);
    int lunchStartMinutes = _timeToMinutes(lunchStart);
    int lunchEndMinutes = _timeToMinutes(lunchEnd);
    int stepMinutes = durationMinutes;
    if (stepMinutes < 15) {
      stepMinutes = 30;
    }
    // For services >= 60 min, allow one extra slot starting 30 min before close
    // Example: Close at 19:00, service 60min -> allow slot at 18:30 (ends 19:30)
    int effectiveCloseMinutes = closeMinutes;
    if (stepMinutes >= 60) {
      effectiveCloseMinutes = closeMinutes + 30; // Allow 30 min overtime
    }

    while (currentMinutes + stepMinutes <= effectiveCloseMinutes) {
      int endMinutes = currentMinutes + stepMinutes;

      bool overlapsLunch = false;
      // Lunch Overlap Rule: Skip slots that overlap with lunch break
      if (currentMinutes < lunchEndMinutes && endMinutes > lunchStartMinutes) {
        overlapsLunch = true;
      }

      if (!overlapsLunch) {
        int h = currentMinutes ~/ 60;
        int m = currentMinutes % 60;
        slots.add(_formatTime(TimeOfDay(hour: h, minute: m)));
        currentMinutes += stepMinutes;
      } else {
        if (currentMinutes < lunchEndMinutes) {
          currentMinutes = lunchEndMinutes;
        } else {
          currentMinutes += stepMinutes;
        }
      }
    }
    return slots;
  }

  Stream<List<String>> _getAvailableSlotsStream(DateTime date) {
    if (_isLoadingSettings || _selectedService == null) {
      return Stream.value([]);
    }

    final duration = _selectedService!['durationMinutes'] ?? 30;

    return FirestoreService()
        .getBookedAppointmentsOnDate(date)
        .map((bookedDocs) {
      List<Map<String, dynamic>> bookings = [];
      for (var doc in bookedDocs) {
        // Filter by Professional
        if (_selectedProfessional != null) {
          final bookingProId = doc['professionalId'];
          if (bookingProId != null &&
              bookingProId != _selectedProfessional!['id']) {
            continue;
          }
        }

        final start = (doc['dateTime'] as Timestamp).toDate();
        int dur = doc['durationMinutes'] ?? 0;
        if (dur == 0) {
          dur = 30;
        }
        bookings.add({
          'start': start,
          'end': start.add(Duration(minutes: dur)),
        });
      }

      List<String> candidates = _generateCandidateSlots(date, duration);
      List<String> available = [];

      for (var timeStr in candidates) {
        final timeParts = timeStr.split(':');
        final startDateTime = DateTime(date.year, date.month, date.day,
            int.parse(timeParts[0]), int.parse(timeParts[1]));
        final endDateTime = startDateTime.add(Duration(minutes: duration));

        bool hasCollision = false;
        for (var booking in bookings) {
          final bStart = booking['start'] as DateTime;
          final bEnd = booking['end'] as DateTime;
          if (startDateTime.isBefore(bEnd) && endDateTime.isAfter(bStart)) {
            hasCollision = true;
            break;
          }
        }
        if (!hasCollision) available.add(timeStr);
      }
      return available;
    });
  }

  Future<void> _submit() async {
    if (_selectedService == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione um serviço e horário.')),
      );
      return;
    }
    if (!_formKey.currentState!.validate() || _customerPhone == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha os dados do cliente.')),
      );
      return;
    }

    // Prepare Data
    final timeParts = _selectedTime!.split(':');
    final dateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      int.parse(timeParts[0]),
      int.parse(timeParts[1]),
    );

    await FirestoreService().addAppointment({
      'dateTime': dateTime,
      'serviceName': _selectedService!['name'],
      'servicePrice': _selectedService!['price'],
      'durationMinutes': _selectedService!['durationMinutes'],
      'customerName': _nameController.text.trim(),
      'customerEmail': 'admin_entry@barbershop.com', // Placeholder
      'customerPhone': _customerPhone,
      'customerId': 'manual-entry', // Or null
      'status': 'Confirmado',
      'professionalId': _selectedProfessional?['id'],
      'professionalName': _selectedProfessional?['name'],
      'createdBy': 'admin',
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agendamento criado com sucesso!')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Novo Agendamento (Admin)')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Service Selection
              const Text('1. Serviço',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const Gap(8),
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: FirestoreService().getServicesStream(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) return Text('Erro: ${snapshot.error}');
                  if (!snapshot.hasData) return const LinearProgressIndicator();

                  final services = snapshot.data!;
                  if (services.isEmpty) {
                    return const Text('Nenhum serviço disponível.');
                  }

                  // Verify current selection is valid
                  String? selectedServiceId = _selectedService?['id'];
                  // Verify current selection is valid
                  if (selectedServiceId != null &&
                      !services.any((s) => s['id'] == selectedServiceId)) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        setState(() {
                          _selectedService = null;
                          _selectedTime = null;
                        });
                      }
                    });
                    selectedServiceId = null;
                  }

                  return DropdownButtonFormField<String>(
                    decoration:
                        const InputDecoration(border: OutlineInputBorder()),
                    hint: const Text('Selecione o Serviço'),
                    value: selectedServiceId,
                    items: services.map((s) {
                      return DropdownMenuItem<String>(
                        value: s['id'],
                        child:
                            Text('${s['name']} (${s['durationMinutes']} min)'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedService =
                            services.firstWhere((s) => s['id'] == val);
                        _selectedTime = null; // reset time
                      });
                    },
                  );
                },
              ),
              const Gap(20),

              // 2. Professional Selection
              const Text('2. Profissional (Opcional)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const Gap(8),
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: FirestoreService().getProfessionalsStream(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) return Text('Erro: ${snapshot.error}');
                  if (!snapshot.hasData) return const LinearProgressIndicator();

                  final pros = snapshot.data!;

                  String? selectedProId = _selectedProfessional?['id'];
                  if (selectedProId != null &&
                      !pros.any((p) => p['id'] == selectedProId)) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        setState(() {
                          _selectedProfessional = null;
                        });
                      }
                    });
                    selectedProId = null;
                  }

                  return DropdownButtonFormField<String>(
                    decoration:
                        const InputDecoration(border: OutlineInputBorder()),
                    hint: const Text('Qualquer Profissional'),
                    value: selectedProId,
                    items: pros.map((p) {
                      return DropdownMenuItem<String>(
                        value: p['id'],
                        child: Text(p['name']),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedProfessional =
                            pros.firstWhere((p) => p['id'] == val);
                        _selectedTime = null;
                      });
                    },
                  );
                },
              ),
              const Gap(20),

              // 3. Date Selection
              const Text('3. Data',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const Gap(8),
              SizedBox(
                height: 90,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _dates.length,
                  separatorBuilder: (context, index) => const Gap(10),
                  itemBuilder: (context, index) {
                    final date = _dates[index];
                    final isSelected = DateUtils.isSameDay(date, _selectedDate);
                    final isAvailable = _isDayAvailable(date);
                    return GestureDetector(
                      onTap: isAvailable
                          ? () => setState(() {
                                _selectedDate = date;
                                _selectedTime = null;
                              })
                          : null,
                      child: Container(
                        width: 60,
                        decoration: BoxDecoration(
                          color: isAvailable
                              ? (isSelected ? Colors.black : Colors.white)
                              : Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                isSelected ? Colors.black : Colors.grey[300]!,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              DateFormat('MMM', 'pt_BR').format(date),
                              style: TextStyle(
                                  fontSize: 12,
                                  color:
                                      isSelected ? Colors.white : Colors.grey),
                            ),
                            Text(
                              date.day.toString(),
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      isSelected ? Colors.white : Colors.black),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const Gap(20),

              // 4. Time Selection
              if (_selectedService != null) ...[
                const Text('4. Horário',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const Gap(8),
                StreamBuilder<List<String>>(
                  stream: _getAvailableSlotsStream(_selectedDate),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final slots = snapshot.data!;
                    if (slots.isEmpty) {
                      return const Text('Nenhum horário disponível.');
                    }

                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        childAspectRatio: 2.2,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: slots.length,
                      itemBuilder: (context, index) {
                        final time = slots[index];
                        final isSelected = _selectedTime == time;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedTime = time),
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.black : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: isSelected
                                      ? Colors.black
                                      : Colors.grey[300]!),
                            ),
                            child: Text(
                              time,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
                const Gap(20),
              ],

              // 5. Customer Details
              const Text('5. Dados do Cliente',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const Gap(8),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome do Cliente',
                  border: OutlineInputBorder(),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Informe o nome' : null,
              ),
              const Gap(12),
              IntlPhoneField(
                decoration: const InputDecoration(
                  labelText: 'Telefone',
                  border: OutlineInputBorder(),
                ),
                initialCountryCode: 'PT',
                onChanged: (phone) {
                  _customerPhone = phone.completeNumber;
                },
              ),
              const Gap(24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Registrar Agendamento'),
                ),
              ),
              const Gap(40),
            ],
          ),
        ),
      ),
    );
  }
}
