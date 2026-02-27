import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'CORE/LOGIN/login_screen.dart';
import 'CORE/MODELS/apartament_model.dart';
import 'CORE/LOGIN/register_screen.dart';
import 'CORE/SCREENS/add_apartment_screen.dart';
import 'CORE/SCREENS/apartment_detail_screen.dart';
import 'CORE/SCREENS/apartaments_screen.dart';
import 'CORE/SCREENS/home_screens.dart';
import 'CORE/SCREENS/search_screen.dart';

final GoRouter _appRouter = GoRouter(
  initialLocation: '/',
  routes: [
      GoRoute(
        path: '/',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/inicio',
        name: 'inicio',
        builder: (context, state) => const InicioScreen(),
      ),
      GoRoute(
        path: '/buscar',
        name: 'buscar',
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: '/apartments',
        name: 'apartments',
        builder: (context, state) => ApartmentsListScreen(
          key: ValueKey(state.uri.queryParameters['refresh']),
        ),
      ),
      GoRoute(
        path: '/add-apartment',
        name: 'add-apartment',
        builder: (context, state) {
          final apartamento = state.extra as Apartamento?;
          final enfocarImagenes = state.uri.queryParameters['focus'] == 'images';
          return AddApartmentScreen(
            apartamento: apartamento,
            enfocarImagenes: enfocarImagenes,
          );
        },
      ),
      GoRoute(
        path: '/apartment-detail',
        name: 'apartment-detail',
        builder: (context, state) {
          final extra = state.extra;
          late final Apartamento apartamento;
          bool modoClienteDesdeExtra = false;

          if (extra is Map<String, dynamic>) {
            apartamento = extra['apartamento'] as Apartamento;
            modoClienteDesdeExtra = extra['modoCliente'] == true;
          } else {
            apartamento = extra as Apartamento;
          }

          final modoCliente =
              modoClienteDesdeExtra || state.uri.queryParameters['mode'] == 'cliente';
          return ApartmentDetailScreen(
            apartamento: apartamento,
            modoCliente: modoCliente,
          );
        },
      ),
      GoRoute(
        path: '/dashboard',
        redirect: (context, state) => '/inicio',
      ),
      GoRoute(
        path: '/daashboard',
        redirect: (context, state) => '/inicio',
      ),
      GoRoute(
        path: '/bookings',
        name: 'bookings',
        builder: (context, state) => const BookingsScreen(),
      ),
      GoRoute(
        path: '/perfil',
        name: 'perfil',
        builder: (context, state) => const PerfilScreen(),
      ),
  ],
  errorBuilder: (context, state) => ErrorScreen(error: state.error.toString()),
);

final routerProvider = Provider<GoRouter>((ref) => _appRouter);
