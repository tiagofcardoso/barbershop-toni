import 'package:barbershop/features/auth/data/auth_service.dart';
import 'package:barbershop/shared/services/firestore_service.dart';
import 'package:barbershop/features/home/data/mock_data.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BookingPage extends StatefulWidget {
  final ServiceModel service;
  final String? professionalId;
  final String? professionalName;

  const BookingPage({
    super.key,
    required this.service,
    this.professionalId,
    this.professionalName,
  });

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  late List<DateTime> _dates;
  late DateTime _selectedDate;
  String? _selectedTime;
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

  // Helper to parse HH:mm
  TimeOfDay _parseTime(String timeStr) {
    final parts = timeStr.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  // Helper to format TimeOfDay to HH:mm
  String _formatTime(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  // Convert TimeOfDay to minutes from midnight
  int _timeToMinutes(TimeOfDay time) {
    return time.hour * 60 + time.minute;
  }

  List<String> _generateCandidateSlots(DateTime date) {
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
      // Fallbacks if settings not loaded
      if (isSaturday) {
        closeStr = '18:00';
      }
    }

    TimeOfDay openTime = _parseTime(openStr);
    TimeOfDay closeTime = _parseTime(closeStr);
    TimeOfDay lunchStart = _parseTime(lunchStartStr);
    TimeOfDay lunchEnd = _parseTime(lunchEndStr);

    List<String> slots = [];

    // Loop from Open to Close
    int currentMinutes = _timeToMinutes(openTime);
    int closeMinutes = _timeToMinutes(closeTime);
    int lunchStartMinutes = _timeToMinutes(lunchStart);
    int lunchEndMinutes = _timeToMinutes(lunchEnd);
    int stepMinutes = widget.service.durationMinutes;

    // Safety check for invalid step
    if (stepMinutes < 15) stepMinutes = 30;

    while (currentMinutes + stepMinutes <= closeMinutes) {
      int endMinutes = currentMinutes + stepMinutes;

      // SPECIAL RULE: First Afternoon Slot (Weekday only)
      // "a primeira marcação da parte da tarde durante a semana, seria de 45 min..."
      // Logic: If currentMinutes == lunchEndMinutes (14:00), we add 15 minutes to the step.
      // This shifts the START of the next slot.
      int effectiveStep = stepMinutes;
      if (isWeekday && currentMinutes == lunchEndMinutes) {
        effectiveStep += 15;
        endMinutes = currentMinutes + effectiveStep;
      }

      bool overlapsLunch = false;

      // Strict Lunch Overlap Rule:
      if (currentMinutes < lunchEndMinutes && endMinutes > lunchStartMinutes) {
        overlapsLunch = true;
      }

      if (!overlapsLunch) {
        int h = currentMinutes ~/ 60;
        int m = currentMinutes % 60;
        slots.add(_formatTime(TimeOfDay(hour: h, minute: m)));

        currentMinutes += effectiveStep;
      } else {
        // If we hit lunch, jump to lunch end
        if (currentMinutes < lunchEndMinutes) {
          currentMinutes = lunchEndMinutes;
        } else {
          currentMinutes += stepMinutes; // Safe fallback
        }
      }
    }

    return slots;
  }

  Stream<List<String>> _getAvailableSlotsStream(DateTime date) {
    if (_isLoadingSettings) {
      return Stream.value([]);
    }

    return FirestoreService()
        .getBookedAppointmentsOnDate(date)
        .map((bookedDocs) {
      List<Map<String, dynamic>> bookings = [];
      for (var doc in bookedDocs) {
        // Filter by Professional
        if (widget.professionalId != null) {
          final bookingProId = doc['professionalId'];
          // If the booking is for another professional, it doesn't block me
          if (bookingProId != null && bookingProId != widget.professionalId) {
            continue;
          }
        }

        final start = (doc['dateTime'] as Timestamp).toDate();
        int duration = doc['durationMinutes'] ?? 0;

        if (duration == 0) {
          duration = 30; // Fallback
        }
        bookings.add({
          'start': start,
          'end': start.add(Duration(minutes: duration)),
        });
      }

      // 2. Generate Candidate Slots (Dynamic)
      List<String> candidates = _generateCandidateSlots(date);
      List<String> available = [];

      // 3. Filter Candidates
      for (var timeStr in candidates) {
        final timeParts = timeStr.split(':');
        final startDateTime = DateTime(date.year, date.month, date.day,
            int.parse(timeParts[0]), int.parse(timeParts[1]));

        final endDateTime = startDateTime
            .add(Duration(minutes: widget.service.durationMinutes));

        // Rule: Collision with Bookings
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

  // Helper for effective duration (Simplified now: just standard duration)
  int _getServiceDuration(String startTime, bool isWeekday) {
    // Dynamic logic request: "se degrade 30, slots de 30... se 60, slots de 60".
    // We already handled slot GENERATION. This is for SAVING the appointment.
    // We should respect the service duration.
    // The previous prompt mentioned "15:15" logic. I am removing it to be fully dynamic as requested.
    return widget.service.durationMinutes;
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
                          'dateTime': dateTime,
                          'serviceName': widget.service.name,
                          'servicePrice': widget.service.price,
                          'durationMinutes': duration,
                          'customerName': user.displayName ?? 'Cliente',
                          'customerEmail': user.email,
                          'customerId': user.uid,
                          'status': 'Confirmado', // Auto-confirm
                          'professionalId': widget.professionalId,
                          'professionalName': widget.professionalName,
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
