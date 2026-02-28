import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'reservas_provider.dart';

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
                color: const Color(0xFFE3F2FD), // azul muy clarito
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text('Reservas en tus apartamentos', style: Theme.of(context).textTheme.titleLarge),
                    ),
                    const Divider(),
                    if (reservasEnTusApartamentos.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Text('No hay reservas confirmadas/canceladas', style: TextStyle(color: Colors.grey)),
                      )
                    else ...[
                      for (int i = 0; i < reservasEnTusApartamentos.length; i++) ...[
                        ListTile(
                          title: Text('Apartamento: ' + reservasEnTusApartamentos[i].apartmentName),
                          subtitle: Text(
                            'Huésped: ' + reservasEnTusApartamentos[i].guestName +
                            '\nEmail: ' + reservasEnTusApartamentos[i].guestEmail +
                            '\nDesde: ' + formatFecha(reservasEnTusApartamentos[i].checkIn) +
                            '  Hasta: ' + formatFecha(reservasEnTusApartamentos[i].checkOut)
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
              Card(
                color: const Color(0xFFE3F2FD), // azul muy clarito
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text('Tus reservas', style: Theme.of(context).textTheme.titleLarge),
                    ),
                    const Divider(),
                    if (tusReservas.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Text('No hay reservas confirmadas/canceladas', style: TextStyle(color: Colors.grey)),
                      )
                    else ...[
                      for (int i = 0; i < tusReservas.length; i++) ...[
                        ListTile(
                          title: Text('Apartamento: ' + tusReservas[i].apartmentName),
                          subtitle: Text(
                            'Desde: ' + formatFecha(tusReservas[i].checkIn) +
                            '  Hasta: ' + formatFecha(tusReservas[i].checkOut)
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
