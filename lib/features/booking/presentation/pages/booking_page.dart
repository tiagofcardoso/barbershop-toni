import 'package:barbershop/features/auth/data/auth_service.dart';
import 'package:barbershop/shared/services/firestore_service.dart';
import 'package:barbershop/features/home/data/mock_data.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

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

  final List<String> _timeSlots = [
    '09:00',
    '09:30',
    '10:00',
    '10:30',
    '11:00',
    '11:30',
    '13:00',
    '13:30',
    '14:00',
    '14:30',
    '15:00',
    '15:30',
    '16:00',
    '16:30',
    '17:00',
    '17:30',
    '18:00',
    '18:30',
    '19:00'
  ];

  @override
  void initState() {
    super.initState();
    _generateDates();
    // Default to the first available date
    try {
      _selectedDate = _dates.firstWhere((date) => _isDayAvailable(date));
    } catch (e) {
      // Fallback if no dates available (unlikely with 60 days)
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
    // Generate for next 60 days (Show ALL days)
    for (int i = 0; i < 60; i++) {
      _dates.add(now.add(Duration(days: i)));
    }
  }

  bool _isDayAvailable(DateTime date) {
    // 1. Check Work Days (Tue-Sat)
    // DateTime.monday = 1, ... DateTime.sunday = 7
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
    // Portugal Fixed Holidays
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
                    height: 100, // Increased height to fit Month
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _dates.length,
                      separatorBuilder: (context, index) => const Gap(12),
                      itemBuilder: (context, index) {
                        final date = _dates[index];
                        final isSelected =
                            DateUtils.isSameDay(date, _selectedDate);
                        final isAvailable = _isDayAvailable(date);

                        // Format Month (e.g., "Dez")
                        final monthName =
                            DateFormat('MMM', 'pt_BR').format(date);
                        // Capitalize first letter
                        final formattedMonth =
                            monthName[0].toUpperCase() + monthName.substring(1);

                        return GestureDetector(
                          onTap: isAvailable
                              ? () => setState(() => _selectedDate = date)
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
                            width: 64, // Slightly wider
                            decoration: BoxDecoration(
                              color: isAvailable
                                  ? (isSelected ? Colors.black : Colors.white)
                                  : Colors.grey[100],
                              borderRadius:
                                  BorderRadius.circular(16), // More rounded
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
                                // Month Name
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
                                // Weekday Name
                                Text(
                                  DateFormat('EEE', 'pt_BR')
                                      .format(date)
                                      .toUpperCase()
                                      .replaceAll(
                                          '.', ''), // Remove dot from abbr
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
                                // Day Number
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
                  StreamBuilder<List<DateTime>>(
                    stream:
                        FirestoreService().getBookedSlotsStream(_selectedDate),
                    builder: (context, snapshot) {
                      Set<String> bookedTimes = {};
                      if (snapshot.hasData) {
                        bookedTimes = snapshot.data!
                            .map((dt) => DateFormat('HH:mm').format(dt))
                            .toSet();
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
                        itemCount: _timeSlots.length,
                        itemBuilder: (context, index) {
                          final time = _timeSlots[index];
                          final isBooked = bookedTimes.contains(time);
                          final isSelected = _selectedTime == time;

                          // If selected time turns out to be booked (auto-refresh), deselect it
                          if (isBooked && isSelected) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) {
                                setState(() {
                                  _selectedTime = null;
                                });
                              }
                            });
                          }

                          return GestureDetector(
                            onTap: isBooked
                                ? () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Este horário já está reservado.'),
                                        duration: Duration(seconds: 1),
                                      ),
                                    );
                                  }
                                : () => setState(() => _selectedTime = time),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isBooked
                                    ? Colors.grey[200]
                                    : (isSelected
                                        ? Colors.black
                                        : Colors.white),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isBooked
                                      ? Colors.grey[300]!
                                      : (isSelected
                                          ? Colors.black
                                          : Colors.grey[300]!),
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                time,
                                style: TextStyle(
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  color: isBooked
                                      ? Colors.grey
                                      : (isSelected
                                          ? Colors.white
                                          : Colors.black87),
                                  decoration: isBooked
                                      ? TextDecoration.lineThrough
                                      : null,
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

                        await FirestoreService().addAppointment({
                          'customerId': user.uid,
                          'customerName': user.displayName ?? 'Cliente',
                          'serviceName': widget.service.name,
                          'dateTime': dateTime,
                          'price': widget.service.price,
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
