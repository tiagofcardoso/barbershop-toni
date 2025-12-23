class ServiceModel {
  final String id;
  final String name;
  final String imageUrl;
  final double price;
  final int durationMinutes;

  ServiceModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.durationMinutes,
  });
}

class MockData {
  static List<ServiceModel> get services => [
        ServiceModel(
          id: '1',
          name: 'Corte Degradê',
          imageUrl:
              'https://images.unsplash.com/photo-1622286342621-4bd786c2447c?q=80&w=800&auto=format&fit=crop', // Man getting haircut
          price: 14.00,
          durationMinutes: 45,
        ),
        ServiceModel(
          id: '2',
          name: 'Barba Completa',
          imageUrl:
              'https://images.unsplash.com/photo-1621605815971-fbc98d665033?q=80&w=800&auto=format&fit=crop', // Man with beard/shaving
          price: 14.00,
          durationMinutes: 30,
        ),
        ServiceModel(
          id: '3',
          name: 'Combo (Corte + Barba)',
          imageUrl: 'assets/images/combo.jpg',
          price: 20.00,
          durationMinutes: 60,
        ),
        ServiceModel(
          id: '4',
          name: 'Acabamento',
          imageUrl: 'assets/images/acabamento.png',
          price: 10.00,
          durationMinutes: 15,
        ),
      ];

  static List<AppointmentModel> appointments = [
    AppointmentModel(
      id: '1',
      customerName: 'Tiago Silva',
      serviceName: 'Corte Degradê',
      dateTime: DateTime.now().add(const Duration(days: 1, hours: 4)),
      price: 45.00,
      status: 'Confirmado',
    ),
    AppointmentModel(
      id: '2',
      customerName: 'João Santos',
      serviceName: 'Barba Completa',
      dateTime: DateTime.now().add(const Duration(days: 0, hours: 2)),
      price: 35.00,
      status: 'Pendente',
    ),
    AppointmentModel(
      id: '3',
      customerName: 'Tiago Silva', // User's own appointment
      serviceName: 'Acabamento',
      dateTime: DateTime.now().add(const Duration(days: 2, hours: 5)),
      price: 20.00,
      status: 'Pendente',
    ),
  ];
}

class AppointmentModel {
  final String id;
  final String customerName;
  final String serviceName;
  DateTime dateTime; // Mutable for rescheduling
  final double price;
  String status; // 'Confirmado', 'Pendente', 'Cancelado'

  AppointmentModel({
    required this.id,
    required this.customerName,
    required this.serviceName,
    required this.dateTime,
    required this.price,
    required this.status,
  });
}
