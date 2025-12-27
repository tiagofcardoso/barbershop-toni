import 'package:barbershop/features/auth/data/auth_service.dart';
import 'package:barbershop/shared/services/firestore_service.dart';
import 'package:barbershop/features/home/data/mock_data.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BookingPage extends StatefulWidget {
  final ServiceModel service;

  const BookingPage({super.key, required this.service});

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  late List<DateTime> _dates;
  late DateTime _selectedDate;
  String? _selectedTime;

  @override
  void initState() {
    super.initState();
    _generateDates();
    // Default to the first available date
    try {
      _selectedDate = _dates.firstWhere((date) => _isDayAvailable(date));
    } catch (e) {
      if (_dates.isNotEmpty) {
        _selectedDate = _dates.first;
      } else {
        _selectedDate = DateTime.now();
      }
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
    // 1. Check Work Days (Tue-Sat)
    if (date.weekday == DateTime.sunday || date.weekday == DateTime.monday) {
      return false;
    }
    // 2. Check Holidays (Portugal)
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

  /// Calculates the duration of the service for a specific start time.
  /// Handles the rule: "a primeira marcação da parte da tarde durante a semana, seria de 45 min"
  /// Implies adding 15 min padding/duration to the first afternoon slot on weekdays.
  int _getServiceDuration(String startTime, bool isWeekday) {
    int baseDuration = widget.service.durationMinutes;

    // Special rule for 15:15 slot on Weekdays
    if (isWeekday && startTime == '15:15') {
      // "já cabelo e barba seria 1h 15min total". Normal is 60. So +15.
      // "mesmo que somente cabelo" (Normal 45). "seria de 45".
      // If standard haircut is 45, and user says "seria de 45", then no change?
      // But context implies a change. "logo... seria de 45".
      // Maybe standard haircut is 30? In mock_data, `Corte Degradê` is 45.
      // Let's assume +15 mins for ANY service at 15:15 to be safe/consistent with logic.
      // (Or maybe User means "Min duration is 45"?).
      // Given "já cabelo e barba seria 1h 15min" (Normal 60 -> 75), it's definitely +15.
      return baseDuration + 15;
    }

    return baseDuration;
  }

  /// Generates available time slots based on the selected date and service rules.
  List<String> _generateCandidateSlots(DateTime date) {
    final isSaturday = date.weekday == DateTime.saturday;
    final isWeekday =
        !isSaturday; // and not Sun/Mon because of _isDayAvailable check

    List<String> slots = [];

    // --- Morning Slots (Common) ---
    // 09:00 to 12:30 (intervals of 30 min)
    // 09:00, 09:30, 10:00, 10:30, 11:00, 11:30, 12:00, 12:30
    var morning = [
      '09:00',
      '09:30',
      '10:00',
      '10:30',
      '11:00',
      '11:30',
      '12:00',
      '12:30'
    ];
    slots.addAll(morning);

    // --- Afternoon Slots ---
    if (isWeekday) {
      // Lunch 13:00 - 15:15.
      // First slot: 15:15.
      slots.add('15:15');
      // Subsequent slots: 16:00, 16:30, 17:00 ... 18:30.
      // 15:15 + 45m = 16:00.
      var afternoon = ['16:00', '16:30', '17:00', '17:30', '18:00', '18:30'];
      slots.addAll(afternoon);
    } else {
      // Saturday
      // Lunch 13:00 - 15:00. (Assuming lunch ends 15:00 based on "Sábado das 13 às 15h")
      // First slot: 15:00.
      // Closes 18:00.
      // Slots: 15:00, 15:30, 16:00, 16:30, 17:00, 17:30.
      var afternoonSat = ['15:00', '15:30', '16:00', '16:30', '17:00', '17:30'];
      slots.addAll(afternoonSat);
    }

    return slots;
  }

  Stream<List<String>> _getAvailableSlotsStream(DateTime date) {
    return FirestoreService()
        .getBookedAppointmentsOnDate(date)
        .map((bookedDocs) {
      List<Map<String, dynamic>> bookings = [];
      for (var doc in bookedDocs) {
        final start = (doc['dateTime'] as Timestamp).toDate();
        int duration = doc['durationMinutes'] ?? 0;

        if (duration == 0) {
          // Fallback: try to find service in MockData
          final serviceName = doc['serviceName'] as String?;
          if (serviceName != null) {
            final mockService = MockData.services.firstWhere(
                (s) => s.name == serviceName,
                orElse: () => MockData.services.first // Fallback
                );
            duration = mockService.durationMinutes;
          } else {
            duration = 30; // Default fallback
          }
        }
        bookings.add({
          'start': start,
          'end': start.add(Duration(minutes: duration)),
        });
      }

      // 2. Generate Candidate Slots
      List<String> candidates = _generateCandidateSlots(date);
      List<String> available = [];

      final isSaturday = date.weekday == DateTime.saturday;
      final isWeekday = !isSaturday;

      // 3. Filter Candidates
      for (var timeStr in candidates) {
        final timeParts = timeStr.split(':');
        final startDateTime = DateTime(date.year, date.month, date.day,
            int.parse(timeParts[0]), int.parse(timeParts[1]));

        int effectiveDuration = _getServiceDuration(timeStr, isWeekday);
        final endDateTime =
            startDateTime.add(Duration(minutes: effectiveDuration));

        // Rule: "última marcação somente cabelo de manhã, 12:30… já cabelo e barba, 12h"
        // Only applies to morning slots (before 13:00)
        if (startDateTime.hour < 13) {
          final isHairAndBeard =
              widget.service.name.toLowerCase().contains('barba') &&
                  widget.service.name.toLowerCase().contains('cabelo');

          if (isHairAndBeard) {
            // Limit 12:00
            if (startDateTime.hour > 12 ||
                (startDateTime.hour == 12 && startDateTime.minute > 0)) {
              continue;
            }
          } else {
            // Limit 12:30 (Hair, Beard alone, etc)
            if (startDateTime.hour > 12 ||
                (startDateTime.hour == 12 && startDateTime.minute > 30)) {
              continue;
            }
          }
        }

        // Rule: Closing Time Logic
        if (isWeekday) {
          // Limit 18:30 for Start Time automatically handled by candidate list max 18:30
        } else {
          // Saturday
          final isHairAndBeard =
              widget.service.name.toLowerCase().contains('barba') &&
                  widget.service.name.toLowerCase().contains('cabelo');
          if (isHairAndBeard) {
            // Max start 17:00
            if (startDateTime.hour > 17 ||
                (startDateTime.hour == 17 && startDateTime.minute > 0)) {
              continue;
            }
          } else {
            // Max start 17:30
            if (startDateTime.hour > 17 ||
                (startDateTime.hour == 17 && startDateTime.minute > 30)) {
              continue;
            }
          }
        }

        // Rule: Collision with Bookmings
        bool hasCollision = false;
        for (var booking in bookings) {
          final bStart = booking['start'] as DateTime;
          final bEnd = booking['end'] as DateTime;

          // Check intersection
          if (startDateTime.isBefore(bEnd) && endDateTime.isAfter(bStart)) {
            hasCollision = true;
            break;
          }
        }

        if (!hasCollision) {
          available.add(timeStr);
        }
      }

      return available;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agendar Horário'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Service Info Header
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: widget.service.imageUrl.startsWith('http')
                      ? Image.network(
                          widget.service.imageUrl,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        )
                      : Image.asset(
                          widget.service.imageUrl,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.cut, size: 60),
                        ),
                ),
                const Gap(16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.service.name,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const Gap(4),
                      Text(
                        '€ ${widget.service.price.toStringAsFixed(2)} • ${widget.service.durationMinutes} min',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selecione a Data',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const Gap(12),
                  // Horizontal Date Picker
                  SizedBox(
                    height: 100,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _dates.length,
                      separatorBuilder: (context, index) => const Gap(12),
                      itemBuilder: (context, index) {
                        final date = _dates[index];
                        final isSelected =
                            DateUtils.isSameDay(date, _selectedDate);
                        final isAvailable = _isDayAvailable(date);

                        final monthName =
                            DateFormat('MMM', 'pt_BR').format(date);
                        final formattedMonth =
                            monthName[0].toUpperCase() + monthName.substring(1);

                        return GestureDetector(
                          onTap: isAvailable
                              ? () => setState(() {
                                    _selectedDate = date;
                                    _selectedTime =
                                        null; // Reset time on date change
                                  })
                              : () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Estamos fechados neste dia (Folga ou Feriado).'),
                                      duration: Duration(seconds: 1),
                                    ),
                                  );
                                },
                          child: Container(
                            width: 64,
                            decoration: BoxDecoration(
                              color: isAvailable
                                  ? (isSelected ? Colors.black : Colors.white)
                                  : Colors.grey[100],
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isAvailable
                                    ? (isSelected
                                        ? Colors.black
                                        : Colors.grey[200]!)
                                    : Colors.transparent,
                              ),
                              boxShadow: isAvailable && !isSelected
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      )
                                    ]
                                  : null,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  formattedMonth,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: isAvailable
                                        ? (isSelected
                                            ? Colors.white70
                                            : Colors.black54)
                                        : Colors.grey[400],
                                  ),
                                ),
                                const Gap(2),
                                Text(
                                  DateFormat('EEE', 'pt_BR')
                                      .format(date)
                                      .toUpperCase()
                                      .replaceAll('.', ''),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: isAvailable
                                        ? (isSelected
                                            ? Colors.white70
                                            : Colors.grey)
                                        : Colors.grey[400],
                                  ),
                                ),
                                const Gap(4),
                                Text(
                                  date.day.toString(),
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: isAvailable
                                        ? (isSelected
                                            ? Colors.white
                                            : Colors.black)
                                        : Colors.grey[400],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const Gap(24),

                  Text(
                    'Horários Disponíveis',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const Gap(12),
                  // Time Slots Grid
                  StreamBuilder<List<String>>(
                    stream: _getAvailableSlotsStream(_selectedDate),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final availableSlots = snapshot.data!;

                      if (availableSlots.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: Text(
                              'Sem horários disponíveis para esta data.',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ),
                        );
                      }

                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          childAspectRatio: 2.2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: availableSlots.length,
                        itemBuilder: (context, index) {
                          final time = availableSlots[index];
                          final isSelected = _selectedTime == time;

                          return GestureDetector(
                            onTap: () => setState(() => _selectedTime = time),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.black : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.black
                                      : Colors.grey[300]!,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                time,
                                style: TextStyle(
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Bottom Action Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _selectedTime != null
                    ? () async {
                        final user = AuthService().currentUser;
                        if (user == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Erro: Usuário não logado')),
                          );
                          return;
                        }

                        final timeParts = _selectedTime!.split(':');
                        final dateTime = DateTime(
                          _selectedDate.year,
                          _selectedDate.month,
                          _selectedDate.day,
                          int.parse(timeParts[0]),
                          int.parse(timeParts[1]),
                        );

                        // Calculate effective duration to save
                        final isWeekday =
                            _selectedDate.weekday != DateTime.saturday;
                        final duration =
                            _getServiceDuration(_selectedTime!, isWeekday);

                        await FirestoreService().addAppointment({
                          'customerId': user.uid,
                          'customerName': user.displayName ?? 'Cliente',
                          'serviceName': widget.service.name,
                          'dateTime': dateTime,
                          'price': widget.service.price,
                          'durationMinutes':
                              duration, // Save calculated duration
                          'status': 'Pendente',
                        });

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(
                                    'Agendamento confirmado para ${DateFormat('dd/MM').format(_selectedDate)} às $_selectedTime!')),
                          );
                          Navigator.pop(context);
                        }
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  disabledBackgroundColor: Colors.grey[300],
                ),
                child: const Text(
                  'Confirmar Agendamento',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
