import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'reservas_provider.dart';
import 'package:flutter_booking/CORE/RESERVAS/reservas_provider.dart' show cancelarReserva, reservasProvider;

class ReservasScreen extends ConsumerWidget {
  const ReservasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reservasAsync = ref.watch(reservasProvider);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            GoRouter.of(context).go('/inicio');
          },
        ),
        title: const Text('Reservas'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('IMG/body_trans.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: reservasAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: \\${e.toString()}')),
          data: (data) {
            final reservasEnTusApartamentos = data.$1;
            final tusReservas = data.$2;
            String formatFecha(DateTime fecha) {
              return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
            }

            // Solo mostrar reservas confirmadas/canceladas
            final List<Widget> children = [
              const SizedBox(height: 12),
              Card(
                color: Colors.grey[200],
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      color: const Color(0xFF1976D2),
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Reservas en tus apartamentos',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                          Divider(
                            color: Colors.white,
                            thickness: 2,
                            height: 8,
                          ),
                        ],
                      ),
                    ),
                    if (reservasEnTusApartamentos.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Text('No hay reservas', style: TextStyle(color: Colors.grey)),
                      )
                    else ...[
                      for (int i = 0; i < reservasEnTusApartamentos.length; i++) ...[
                        GestureDetector(
                          onLongPress: () async {
                            final selected = await showModalBottomSheet<String>(
                              context: context,
                              builder: (ctx) => SafeArea(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ListTile(
                                      leading: const Icon(Icons.cancel, color: Colors.red),
                                      title: const Text('Cancelar reserva'),
                                      onTap: () => Navigator.of(ctx).pop('cancelar'),
                                    ),
                                  ],
                                ),
                              ),
                            );
                            if (selected == 'cancelar') {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Cancelar reserva'),
                                  content: const Text('¿Seguro que quieres cancelar esta reserva? Se eliminará para ambos usuarios.'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(ctx).pop(false),
                                      child: const Text('No'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.of(ctx).pop(true),
                                      child: const Text('Sí, cancelar'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await cancelarReserva(reservasEnTusApartamentos[i].id);
                                if (context.mounted) {
                                  ref.invalidate(reservasProvider);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Reserva cancelada correctamente')),
                                  );
                                }
                              }
                            }
                          },
                          child: ListTile(
                            title: Text(
                              'Apartamento: ' + reservasEnTusApartamentos[i].apartmentName,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              'Huésped: ' + reservasEnTusApartamentos[i].guestName +
                              '\nEmail: ' + reservasEnTusApartamentos[i].guestEmail +
                              '\nDesde: ' + formatFecha(reservasEnTusApartamentos[i].checkIn) +
                              '  Hasta: ' + formatFecha(reservasEnTusApartamentos[i].checkOut)
                            ),
                          ),
                        ),
                        if (i < reservasEnTusApartamentos.length - 1)
                          const Divider(),
                      ],
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const SizedBox(height: 24),
              Card(
                color: Colors.grey[200],
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      color: const Color(0xFFFF9800),
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tus reservas',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                          Divider(
                            color: Colors.white,
                            thickness: 2,
                            height: 8,
                          ),
                        ],
                      ),
                    ),
                    if (tusReservas.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Text('No hay reservas', style: TextStyle(color: Colors.grey)),
                      )
                    else ...[
                      for (int i = 0; i < tusReservas.length; i++) ...[
                        GestureDetector(
                          onLongPress: () async {
                            final selected = await showModalBottomSheet<String>(
                              context: context,
                              builder: (ctx) => SafeArea(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ListTile(
                                      leading: const Icon(Icons.cancel, color: Colors.red),
                                      title: const Text('Cancelar reserva'),
                                      onTap: () => Navigator.of(ctx).pop('cancelar'),
                                    ),
                                  ],
                                ),
                              ),
                            );
                            if (selected == 'cancelar') {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Cancelar reserva'),
                                  content: const Text('¿Seguro que quieres cancelar esta reserva? Se eliminará para ambos usuarios.'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(ctx).pop(false),
                                      child: const Text('No'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.of(ctx).pop(true),
                                      child: const Text('Sí, cancelar'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await cancelarReserva(tusReservas[i].id);
                                if (context.mounted) {
                                  ref.invalidate(reservasProvider);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Reserva cancelada correctamente')),
                                  );
                                }
                              }
                            }
                          },
                          child: ListTile(
                            title: Text(
                              'Apartamento: ' + tusReservas[i].apartmentName,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              'Desde: ' + formatFecha(tusReservas[i].checkIn) +
                              '  Hasta: ' + formatFecha(tusReservas[i].checkOut)
                            ),
                          ),
                        ),
                        if (i < tusReservas.length - 1)
                          const Divider(),
                      ],
                    ],
                  ],
                ),
              ),
            ];
            return ListView(
              padding: const EdgeInsets.all(16),
              children: children,
            );
          },
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Buscar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.apartment),
            label: 'Tus apartamentos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: 'Reservas',
          ),
        ],
        onTap: (index) {
          // Usa GoRouter solo si está disponible, si no, ignora
          final goRouter = GoRouter.of(context);
          if (index == 0) {
            goRouter.go('/buscar');
          } else if (index == 1) {
            goRouter.go('/apartments');
          } // index 2 ya está en reservas
        },
      ),
    );
  }
}
