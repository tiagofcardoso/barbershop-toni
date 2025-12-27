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

  factory ServiceModel.fromMap(Map<String, dynamic> map) {
    return ServiceModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      durationMinutes: map['durationMinutes'] ?? 0,
    );
  }
}

class MockData {
  static List<ServiceModel> get services => [
        ServiceModel(
          id: '1',
          name: 'Corte Degradê',
          imageUrl: 'assets/images/corte_degrade.png',
          price: 14.00,
          durationMinutes: 45,
        ),
        ServiceModel(
          id: '2',
          name: 'Corte Clássico',
          imageUrl: 'assets/images/corte_classico.png',
          price: 14.00,
          durationMinutes: 45,
        ),
        ServiceModel(
          id: '3',
          name: 'Corte Criança',
          imageUrl: 'assets/images/corte_crianca.png',
          price: 14.00,
          durationMinutes: 30,
        ),
        ServiceModel(
          id: '4',
          name: 'Corte Degradê Máquina',
          imageUrl: 'assets/images/corte_degrade_maquina.png',
          price: 12.00,
          durationMinutes: 30,
        ),
        ServiceModel(
          id: '5',
          name: 'Barba',
          imageUrl: 'assets/images/barba.png',
          price: 10.00,
          durationMinutes: 30,
        ),
        ServiceModel(
          id: '6',
          name: 'Barba e Cabelo',
          imageUrl: 'assets/images/barba_e_cabelo.png',
          price: 19.00,
          durationMinutes: 60,
        ),
        ServiceModel(
          id: '7',
          name: 'Barba, Cabelo e Lavagem',
          imageUrl: 'assets/images/barba_cabelo_lavagem.png',
          price: 20.00,
          durationMinutes: 75,
        ),
        ServiceModel(
          id: '8',
          name: 'Depilação de Nariz',
          imageUrl: 'assets/images/depilacao_nariz.png',
          price: 4.00,
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
