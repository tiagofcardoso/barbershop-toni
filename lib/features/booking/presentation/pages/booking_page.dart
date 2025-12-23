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
  DateTime _selectedDate = DateTime.now();
  String? _selectedTime;

  // Generate next 14 days
  final List<DateTime> _dates = List.generate(
    14,
    (index) => DateTime.now().add(Duration(days: index)),
  );

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
                    height: 80,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _dates.length,
                      separatorBuilder: (context, index) => const Gap(12),
                      itemBuilder: (context, index) {
                        final date = _dates[index];
                        final isSelected =
                            DateUtils.isSameDay(date, _selectedDate);

                        return GestureDetector(
                          onTap: () => setState(() => _selectedDate = date),
                          child: Container(
                            width: 60,
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.black : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.black
                                    : Colors.grey[300]!,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  DateFormat('EEE', 'pt_BR')
                                      .format(date)
                                      .toUpperCase(), // Day of week (SEG, TER)
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? Colors.white70
                                        : Colors.grey,
                                  ),
                                ),
                                const Gap(4),
                                Text(
                                  date.day.toString(),
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.black,
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
                  GridView.builder(
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
                      final isSelected = _selectedTime == time;

                      return GestureDetector(
                        onTap: () => setState(() => _selectedTime = time),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.black : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color:
                                  isSelected ? Colors.black : Colors.grey[300]!,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            time,
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: isSelected ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
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
