
// Provee reservas, busca en base datos y separa por dueño y usuario. Incluye función para cancelar reserva.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'reserva_model.dart';

// Función para cancelar (borrar) reserva por id
Future<void> cancelarReserva(String reservaId) async {
  final client = Supabase.instance.client;
  await client.from('bookings').delete().eq('id', reservaId);
}


// Proveedor que busca reservas, separa por dueño y usuario, devuelve dos listas
final reservasProvider = FutureProvider.autoDispose<(
  List<Reserva> reservasEnTusApartamentos,
  List<Reserva> tusReservas,
)>(
  (ref) async {
    // Pillar usuario actual, si no hay pues nada
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return (<Reserva>[], <Reserva>[]);

    // Buscar apartamentos donde usuario es dueño, para filtrar reservas
    final apartmentsRes = await Supabase.instance.client
      .from('apartments')
      .select('id, owner_id, name');
    final apartmentsList = (apartmentsRes is List ? List<Map<String, dynamic>>.from(apartmentsRes) : <Map<String, dynamic>>[]);
    final apartmentIdsOwned = apartmentsList
      .where((a) => a['owner_id'] == user.id)
      .map((a) => a['id'] as String)
      .toList();
    // Mapeo id a nombre apartamento
    final apartmentNames = {for (var a in apartmentsList) a['id'] as String: a['name'] as String? ?? ''};

    // Si no tienes apartamentos, solo filtra por email usuario
    final String orFilter = apartmentIdsOwned.isNotEmpty
      ? 'guest_email.eq.${user.email},apartment_id.in.(${apartmentIdsOwned.join(',')})'
      : 'guest_email.eq.${user.email}';
    // Consulta reservas confirmadas
    final bookingsRes = await Supabase.instance.client
      .from('bookings')
      .select()
      .or(orFilter)
      .eq('status', 'confirmed');
    final bookingsList = (bookingsRes is List ? List<Map<String, dynamic>>.from(bookingsRes) : <Map<String, dynamic>>[]);

    // Separar reservas en tus apartamentos y las tuyas
    final reservasEnTusApartamentosFinal = apartmentIdsOwned.isNotEmpty
      ? bookingsList
          .where((e) => apartmentIdsOwned.contains(e['apartment_id']))
          .map((e) => Reserva.fromJson({...e, 'apartment_name': apartmentNames[e['apartment_id']] ?? ''})).toList()
      : <Reserva>[];
    final tusReservasFinal = bookingsList
      .where((e) => e['guest_email'] == user.email)
      .map((e) => Reserva.fromJson({...e, 'apartment_name': apartmentNames[e['apartment_id']] ?? ''})).toList();

    // Devuelve las dos listas, una para dueño otra para usuario
    return (reservasEnTusApartamentosFinal, tusReservasFinal);
  }
);
