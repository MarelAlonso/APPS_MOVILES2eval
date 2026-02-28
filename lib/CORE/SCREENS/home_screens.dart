import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class InicioScreen extends StatelessWidget {
  const InicioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inicio'),
        actions: [
          TextButton(
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) context.go('/');
            },
            child: const Text(
              'Salir',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 220,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'IMG/header_inicio.jpg',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      alignment: Alignment.center,
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image_outlined, size: 42),
                          SizedBox(height: 8),
                          Text('Imagen de cabecera pendiente'),
                        ],
                      ),
                    );
                  },
                ),
                Container(color: Colors.black.withValues(alpha: 0.30)),
                Center(
                  child: FutureBuilder<Map<String, dynamic>?>(
                    future: user == null
                        ? Future.value(null)
                        : Supabase.instance.client
                            .from('profiles')
                            .select('username')
                            .eq('id', user.id)
                            .maybeSingle(),
                    builder: (context, snapshot) {
                      final usernamePerfil = snapshot.data?['username']?.toString();
                      final usernameMetadata = user?.userMetadata?['username']?.toString();
                      final usernameEmail = user?.email?.split('@').first;
                      final username = (usernamePerfil != null && usernamePerfil.isNotEmpty)
                          ? usernamePerfil
                          : ((usernameMetadata != null && usernameMetadata.isNotEmpty)
                              ? usernameMetadata
                              : usernameEmail);
                      return Text(
                        username != null && username.isNotEmpty
                            ? 'Hola $username, benvenido a pulping reservs'
                            : 'Hola, benvenido a pulping reservs',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.40,
                    child: Image.asset(
                      'IMG/body_trans.jpg',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      '¡Encuentra las mejores estancias para una experiencia inolvidable!',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
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
          if (index == 0) {
            context.go('/buscar');
          } else if (index == 1) {
            context.go('/apartments');
          } else if (index == 2) {
            context.go('/reservas');
          }
        },
      ),
    );
  }
}

class BookingsScreen extends StatelessWidget {
  const BookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reservas'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Lista de Reservas',
              style: TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => context.go('/inicio'),
              child: const Text('Volver al Inicio'),
            ),
          ],
        ),
      ),
    );
  }
}

class PerfilScreen extends StatelessWidget {
  const PerfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Perfil de Usuario',
              style: TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('Volver al Inicio'),
            ),
          ],
        ),
      ),
    );
  }
}

class ErrorScreen extends StatelessWidget {
  final String error;

  const ErrorScreen({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Error'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error: $error',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('Volver al Inicio'),
            ),
          ],
        ),
      ),
    );
  }
}
