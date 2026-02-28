// Modelo reserva, guarda datos de cada reserva hecha
class Reserva {
  final String id;
  final String apartmentId;
  final String apartmentName;
  final String guestName;
  final String guestEmail;
  final DateTime checkIn;
  final DateTime checkOut;
  final double totalPrice;
  final String status;

  Reserva({
    required this.id,
    required this.apartmentId,
    required this.apartmentName,
    required this.guestName,
    required this.guestEmail,
    required this.checkIn,
    required this.checkOut,
    required this.totalPrice,
    required this.status,
  });

  // Crea reserva desde json, para pillar datos guardados
  factory Reserva.fromJson(Map<String, dynamic> json) {
    return Reserva(
      id: json['id'] as String,
      apartmentId: json['apartment_id'] as String,
      apartmentName: json['apartment_name'] as String? ?? '',
      guestName: json['guest_name'] as String,
      guestEmail: json['guest_email'] as String,
      checkIn: DateTime.parse(json['check_in'] as String),
      checkOut: DateTime.parse(json['check_out'] as String),
      totalPrice: (json['total_price'] as num).toDouble(),
      status: json['status'] as String,
    );
  }

  // Convierte reserva a json, para guardar en base datos
  Map<String, dynamic> toJson() => {
        'id': id,
        'apartment_id': apartmentId,
        'apartment_name': apartmentName,
        'guest_name': guestName,
        'guest_email': guestEmail,
        'check_in': checkIn.toIso8601String(),
        'check_out': checkOut.toIso8601String(),
        'total_price': totalPrice,
        'status': status,
      };
}
